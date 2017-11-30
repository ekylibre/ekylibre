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
  class AccountsController < Backend::BaseController
    manage_restfully number: 'params[:number]'.c

    respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

    unroll

    def self.accounts_conditions
      code = ''
      code << search_conditions(accounts: %i[name number description]) + ';'
      code << "if params[:prefix]\n"
      code << "  c[0] += ' AND number LIKE ?'\n"
      code << "  c << params[:prefix].to_s+'%'\n"
      code << "end\n"
      code << "unless params[:period].blank? or params[:period]='all'\n"
      code << "  c[0] += ' AND id IN (SELECT account_id FROM #{JournalEntryItem.table_name} AS jel JOIN #{JournalEntry.table_name} AS je ON (entry_id=je.id) WHERE '+JournalEntry.period_condition(params[:period], params[:started_on], params[:stopped_on], 'je')+')'\n"
      code << "end\n"
      code << "c\n"
      # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
      code.c
    end

    list(conditions: accounts_conditions, order: :number, per_page: 20) do |t|
      t.action :edit
      t.action :destroy, if: :destroyable?
      t.column :number, url: true
      t.column :name, url: true
      t.column :usages, hidden: true
      t.column :reconcilable
      t.column :description
    end

    # Displays the main page with the list of accounts
    def index; end

    def show
      return unless @account = find_and_check
      t3e @account
      respond_with(@account, methods: [],
                             include: [
                               { journal_entry_items: { include: %i[financial_year tax tax_declaration_item] } }
                             ],
                             procs: proc { |options| options[:builder].tag!(:url, backend_account_url(@account)) })
    end

    def self.account_moves_conditions(_options = {})
      code = ''
      code << search_conditions({ journal_entry_item: %i[name debit credit real_debit real_credit], journal_entry: [:number], product_nature_variant: [:name] }, conditions: 'c', variable: 'params[:b]'.c) + "\n"
      code << journal_period_crit('params')
      code << journal_entries_states_crit('params')
      # code << journals_crit("params")
      code << "c[0] << ' AND #{JournalEntryItem.table_name}.account_id = ?'\n"
      code << "c << params[:id]\n"
      code << "c\n"
      code.c
    end

    list(:journal_entry_items, joins: :entry, conditions: account_moves_conditions, line_class: "(RECORD.completely_lettered? ? 'lettered-item' : '')".c, order: "entry_id DESC, #{JournalEntryItem.table_name}.position") do |t|
      t.column :journal, url: true
      t.column :entry_number, url: true
      t.column :printed_on, datatype: :date, label: :column
      t.column :name
      t.column :variant, url: true
      t.column :state_label
      t.column :letter
      t.column :real_debit,  currency: :real_currency, hidden: true
      t.column :real_credit, currency: :real_currency, hidden: true
      t.column :debit,  currency: true, hidden: true
      t.column :credit, currency: true, hidden: true
      t.column :absolute_debit,  currency: :absolute_currency, on_select: :sum
      t.column :absolute_credit, currency: :absolute_currency, on_select: :sum
    end

    list(:entities, conditions: ['? IN (client_account_id, supplier_account_id)', 'params[:id]'.c], order: { created_at: :desc }) do |t|
      t.column :number, url: true
      t.column :full_name, url: true
      t.column :client_account, url: true
      t.column :supplier_account, url: true
    end

    list(:product_nature_variants, joins: :category, conditions: ['? IN (product_nature_categories.charge_account_id, product_nature_categories.product_account_id, product_nature_categories.fixed_asset_account_id, product_nature_categories.stock_account_id)', 'params[:id]'.c], order: { created_at: :desc }) do |t|
      t.column :number, url: true
      t.column :name, url: true
    end

    def self.account_reconciliation_conditions
      code = search_conditions(accounts: %i[name number description], journal_entries: [:number], JournalEntryItem.table_name => %i[name debit credit]) + "[0] += ' AND accounts.reconcilable = ?'\n"
      code << "c << true\n"
      code << "c[0] += ' AND (letter IS NULL OR LENGTH(TRIM(letter)) <= 0)'\n"
      code << 'c'
      code.c
    end

    list(:reconciliation, model: :journal_entry_items, joins: %i[entry account], conditions: account_reconciliation_conditions, order: 'accounts.number, journal_entries.printed_on') do |t|
      t.column :account_number, through: :account, label_method: :number, url: { action: :mark }
      t.column :account_name, through: :account, label_method: :name, url: { action: :mark }
      t.column :entry_number
      t.column :name
      t.column :real_debit,  currency: :real_currency, hidden: true
      t.column :real_credit, currency: :real_currency, hidden: true
      t.column :debit,  currency: true, hidden: true
      t.column :credit, currency: true, hidden: true
      t.column :absolute_debit,  currency: :absolute_currency
      t.column :absolute_credit, currency: :absolute_currency
    end

    def reconciliation; end

    def set_interval_preference(attribute)
      if preference = current_user.preferences.find_by(name: "accounts_interval.#{attribute}")
        preference.set(params[attribute])
      else
        current_user.preferences.get("accounts_interval.#{attribute}", params[attribute], :string)
      end
    end

    def mark
      params[:started_on] ||= current_user.preferences.find_by(name: 'accounts_interval.started_on').try(:value)
      params[:stopped_on] ||= current_user.preferences.find_by(name: 'accounts_interval.stopped_on').try(:value)
      params[:period]     ||= current_user.preferences.find_by(name: 'accounts_interval.period').try(:value) || :interval

      return unless @account = find_and_check
      if request.post?
        if params[:journal_entry_item]
          letter = @account.mark(params[:journal_entry_item].select { |_k, v| v[:to_mark].to_i == 1 }.collect { |k, _v| k.to_i })
          if letter.nil?
            notify_error_now(:cannot_mark_entry_items)
          else
            notify_success_now(:journal_entry_items_marked_with_letter, letter: letter)
          end
        else
          notify_warning_now(:select_entry_items_to_mark_together)
        end
      end
      t3e @account.attributes

      # Set the preference in function of the search
      if params[:period].present? && params[:period] != 'all' && params[:period] == 'interval'
        set_interval_preference(:started_on)
        set_interval_preference(:stopped_on)
        current_user.preferences.find_by(name: 'accounts_interval.period').try(:destroy)
      elsif params[:period] != 'interval'
        set_interval_preference(:period)
      end
    end

    def unmark
      return unless @account = find_and_check
      @account.unmark(params[:letter]) if params[:letter]
      redirect_to_back
    end

    def load
      if request.post?
        Account.accounting_system = params[:accounting_system]
        if Nomen::Account.property_natures.keys.include?(Account.accounting_system.to_s)
          Account.load_defaults
        else
          raise 'Arrrggggg'
        end
        redirect_to action: :index
      end
    end

    def mask_lettered_items
      preference_name = 'backend/accounts'
      preference_name << ".#{params[:context]}" if params[:context]
      preference_name << '.lettered_items.masked'
      current_user.prefer!(preference_name, params[:masked].to_s == 'true', :boolean)
      head :ok
    end
  end
end
