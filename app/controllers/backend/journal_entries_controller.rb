# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

module Backend
  class JournalEntriesController < Backend::BaseController
    manage_restfully only: %i[show destroy]

    respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

    unroll

    list(children: :items, order: { created_at: :desc }, per_page: 10) do |t|
      t.action :edit, if: :updateable?
      t.action :destroy, if: :destroyable?
      t.column :number, url: true, children: :name
      t.column :printed_on, datatype: :date, children: false
      t.column :state_label
      t.column :real_debit,  currency: :real_currency
      t.column :real_credit, currency: :real_currency
      t.column :real_balance, currency: :real_currency
      t.column :debit,  currency: true, hidden: true
      t.column :credit, currency: true, hidden: true
      t.column :absolute_debit,  currency: :absolute_currency, hidden: true
      t.column :absolute_credit, currency: :absolute_currency, hidden: true
    end

    list(:items, model: :journal_entry_items, conditions: { entry_id: 'params[:id]'.c }, order: :position) do |t|
      t.column :name
      t.column :account, url: true
      t.column :account_number, through: :account, label_method: :number, url: true, hidden: true
      t.column :account_name, through: :account, label_method: :name, url: true, hidden: true
      t.column :bank_statement, url: true, hidden: true
      # t.column :number, through: :account, url: true
      # t.column :name, through: :account, url: true
      # t.column :number, through: :bank_statement, url: true, hidden: true
      t.column :variant, url: true
      t.column :letter, through: :journal_entry
      t.column :real_debit,  currency: :real_currency
      t.column :real_credit, currency: :real_currency
      t.column :debit,  currency: true, hidden: true
      t.column :credit, currency: true, hidden: true
      t.column :balance, currency: true, hidden: true
      t.column :absolute_debit,  currency: :absolute_currency, hidden: true
      t.column :absolute_credit, currency: :absolute_currency, hidden: true
      t.column :activity_budget, hidden: true
      t.column :team, hidden: true
      t.column :product_item_to_tax_label, label: :tax_label, hidden: true
    end

    def index
      redirect_to controller: :journals, action: :index
    end

    def show
      return unless @journal_entry = find_and_check
      t3e @journal_entry
      respond_with(@journal_entry, methods: %i[state_label bank_statement_number],
                                   include: [
                                     { financial_year: {} },
                                     { journal: {} },
                                     { resource: {} },
                                     { bank_statements: {} },
                                     { creator: {} },
                                     { updater: {} },
                                     { items: { include: %i[account tax tax_declaration_item] } }
                                   ],
                                   procs: proc { |options| options[:builder].tag!(:url, backend_journal_entry_url(@journal_entry)) })
    end

    def new
      if params[:duplicate_of]
        @journal_entry = JournalEntry.find_by(id: params[:duplicate_of])
                                     .deep_clone(include: :items, except: :number)
      else
        journal = Journal.find_by(id: params[:journal_id])
        @journal_entry = JournalEntry.new(journal: journal, real_currency: Maybe(journal).currency.or_else(nil))
        @journal_entry.printed_on = params[:printed_on] || Time.zone.today
        # Check if the method is called from "account/:id/mark" view
        if params[:journal_entry_items_ids]
          journal_entry_items_ids = params[:journal_entry_items_ids].split(',')
          journal_entry_items = JournalEntryItem.where(id: journal_entry_items_ids)

          balance = journal_entry_items.sum('real_debit - real_credit')
          balanced_credit = 0
          balanced_debit = 0
          if balance > 0
            balanced_debit = balance
          else
            balanced_credit = -balance
          end
          # Create a line which will the one used to balance the credit and
          # debit sum amounts of lines selected in "account/:id/mark" view
          @journal_entry.items.new(
            account: journal_entry_items.first.account,
            real_debit: balanced_credit,
            real_credit: balanced_debit
          )
          # Create a line to balance the previous line
          @journal_entry.items.new(
            real_debit: balanced_debit,
            real_credit: balanced_credit
          )
        end
      end
      @journal_entry.real_currency_rate = if @journal_entry.need_currency_change?
                                            if params[:exchange_rate]
                                              params[:exchange_rate].to_f
                                            else
                                              I18n.currency_rate(@journal_entry.real_currency, FinancialYear.on(@journal_entry.printed_on).currency) || 1
                                            end
                                          else
                                            1
                                          end
      t3e Maybe(@journal_entry.journal).attributes.or_else({})
    end

    def create
      @journal_entry = JournalEntry.new(permitted_params)
      if @journal_entry.save
        if params[:affair_id]
          affair = Affair.find_by(id: params[:affair_id])
          if affair
            Regularization.create!(affair: affair, journal_entry: @journal_entry)
          end
        end
        if @journal_entry.number == params[:theoretical_number]
          notify_success(:journal_entry_has_been_saved, number: @journal_entry.number)
        else
          notify_success(:journal_entry_has_been_saved_with_a_new_number, number: @journal_entry.number)
        end

        # TODO: Extract this somewhere else, this isn't SRP
        # Check if the method is called from "account/:id/mark" view
        if params[:journal_entry_items_ids].present?
          # Get all journal_entry_items id selected from the view
          journal_entry_items_ids = params[:journal_entry_items_ids].split(',').map(&:to_i)
          journal_entry_items = JournalEntryItem.where(id: journal_entry_items_ids)
          if journal_entry_items.any?
            account = journal_entry_items.first.account
            # Get the journal_entry_item id created to balance the previous ones
            journal_entry_items_ids.push(@journal_entry.items.where(account: account).first.id)
            # Mark the journal_entry_items
            account.mark(journal_entry_items_ids)
          end
        end
        redirect_to params[:redirect] || {
          controller: :journal_entries,
          action: :new,
          journal_id: @journal_entry.journal_id,
          exchange_rate: @journal_entry.real_currency_rate,
          printed_on: @journal_entry.printed_on
        }
        return
      end
      notify_global_errors
      t3e @journal_entry.journal.attributes if @journal_entry.journal
    end

    def edit
      return unless find_and_check_updateability
      t3e @journal_entry.attributes
    end

    def update
      return unless find_and_check_updateability
      if @journal_entry.update_attributes(permitted_params)
        redirect_to params[:redirect] || { action: :show, id: @journal_entry.id }
        return
      end
      notify_global_errors
      t3e @journal_entry.attributes
    end

    def currency_state
      state = {}
      checked_on = params[:on] ? Date.parse(params[:on]) : Time.zone.today
      financial_year = FinancialYear.on(checked_on)
      unless financial_year.nil?
        state[:from] = params[:from]
        state[:to] = financial_year.currency
        state[:exchange_rate] = if state[:from] != state[:to]
                                  I18n.currency_rate(state[:from], state[:to])
                                else
                                  1
                                end
      end
      render json: state.to_json
    end

    def toggle_autocompletion
      choice = (params[:autocompletion] == 'true')
      return unless Preference.set!(:entry_autocompletion, choice, :boolean)
      respond_to do |format|
        format.json { render json: { status: :success, preference: choice } }
      end
    end

    protected

    def permitted_params
      params.require(:journal_entry).permit(:printed_on, :journal_id, :number, :real_currency_rate, items_attributes: %i[id name variant_id account_id real_debit real_credit activity_budget_id project_budget_id team_id equipment_id _destroy])
    end

    def notify_global_errors
      @journal_entry.errors.messages.except(:printed_on).each do |field, messages|
        next if /items\./ =~ field
        messages.each { |m| notify_error_now m }
      end
    end

    def find_and_check_updateability
      return false unless (@journal_entry = find_and_check)
      unless @journal_entry.updateable?
        notify_error(:journal_entry_already_validated)
        redirect_to_back
        return
      end
      @journal_entry
    end
  end
end
