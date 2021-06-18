# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
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
  class DraftJournalsController < Backend::BaseController
    include JournalEntriesCondition

    list(:journal_entry_items, selectable: true, conditions: journal_entries_conditions(with_journals: true, state: :draft), joins: :entry, line_class: "(RECORD.position==1 ? 'first-item' : '')".c, order: "entry_id DESC, #{JournalEntryItem.table_name}.position", export_class: ListExportJob) do |t|
      t.column :journal, url: true
      t.column :entry_number, url: true
      t.column :printed_on, datatype: :date
      t.column :account, url: true
      t.column :account_number, through: :account, label_method: :number, url: true, hidden: true
      t.column :account_name, through: :account, label_method: :name, url: true, hidden: true
      t.column :name
      t.column :real_debit,  currency: :real_currency, hidden: true
      t.column :real_credit, currency: :real_currency, hidden: true
      t.column :debit,  currency: true
      t.column :credit, currency: true
      t.column :absolute_debit,  currency: :absolute_currency, hidden: true
      t.column :absolute_credit, currency: :absolute_currency, hidden: true
      t.empty :fec_compliance, class: 'fec-compliance', condition: 'JournalEntry.fec_compliance_preference'
    end

    # this method lists all the entries generated in draft mode
    def show
      @redirection = params[:redirection]
      @current_page = 1
      @current_from_date = params[:current_financial_year] ? FinancialYear.find(params[:current_financial_year]).started_on : FinancialYear.current.started_on
      @current_to_date = params[:current_financial_year] ? FinancialYear.find(params[:current_financial_year]).stopped_on : Date.today
      @journal_id = params[:journal_id] ? params[:journal_id].to_i : ''
      journal_entries = @journal_id.blank? ? JournalEntry.all : JournalEntry.where(journal_id: @journal_id)
      @draft_entries = journal_entries.where(state: :draft).where('printed_on BETWEEN ? AND ?', @current_from_date, @current_to_date).order(:printed_on)
      @draft_entries_count = @draft_entries.count
      @draft_entries = @draft_entries.page(@current_page).per(20)
      @entries_to_validate_count = @draft_entries.where(financial_year_exchange_id: nil).count
      @unbalanced_entries_count = journal_entries.where('printed_on BETWEEN ? AND ?', @current_from_date, @current_to_date).reject(&:balanced?).count
      @can_validate = (@entries_to_validate_count > 0 && @unbalanced_entries_count == 0)
      notify_warning_now(:there_are_x_remaining_unbalanced_entries, count: @unbalanced_entries_count) if @unbalanced_entries_count > 0
    end

    def list
      @redirection = params[:redirection]
      @current_page = params[:page] ? params[:page].to_i : 1
      @current_from_date = Date.parse(params[:from]) if params[:from]
      @current_to_date = Date.parse(params[:to]) if params[:to]
      @journal_id = params[:journal_id].blank? ? params[:journal_id] : params[:journal_id].to_i
      journal_entries = @journal_id.blank? ? JournalEntry.all : JournalEntry.where(journal_id: @journal_id)
      @draft_entries = journal_entries.where(state: :draft).where('printed_on BETWEEN ? AND ?', @current_from_date, @current_to_date).order(:printed_on)
      @draft_entries_count = @draft_entries.count
      @draft_entries = @draft_entries.page(@current_page).per(20)
      @entries_to_validate_count = @draft_entries.where(financial_year_exchange_id: nil).count
      @unbalanced_entries_count = journal_entries.where('printed_on BETWEEN ? AND ?', @current_from_date, @current_to_date).reject(&:balanced?).count
      @can_validate = (@entries_to_validate_count > 0 && @unbalanced_entries_count == 0)
      notify_warning_now(:there_are_x_remaining_unbalanced_entries, count: @unbalanced_entries_count) if @unbalanced_entries_count > 0
    end

    # This method confirm all draft entries
    def confirm
      entries = entries_to_validate
      entries_count = entries.count

      ValidateDraftJournalEntriesService.new(entries).validate
      notify_success(:draft_journal_entries_have_been_validated, count: entries_count)
      redirect_to action: :show
    end

    def fec_compliance_errors
      fec_method = "fec_#{params[:category]}_errors"
      entry = JournalEntry.find(params[:entry_id])
      raise StandardError.new("Method #{fec_method} does not exist") if !entry.respond_to?(fec_method)

      errors = entry.send(fec_method)
      render partial: 'fec_compliance_errors', locals: { errors: errors, entry: entry }
    end

    def confirmation_modal
      if JournalEntry.fec_compliance_preference
        entries = entries_to_validate

        entries_fec_errors = entries.with_compliance_errors('fec', 'journal_entries')

        @fec_error_count = {}
        FEC::Check::JournalEntry.errors_name.each do |name|
          @fec_error_count[name] = entries_fec_errors.with_compliance_error('fec', 'journal_entries', name).count
        end

        respond_to do |format|
          format.js
        end
      end
    end

    private

      def entries_to_validate
        journal_id = params[:journal_id].blank? ? params[:journal_id] : params[:journal_id].to_i
        journal_entries = journal_id.blank? ? JournalEntry.all : JournalEntry.where(journal_id: journal_id)

        journal_entries.where(state: :draft, financial_year_exchange_id: nil).where('printed_on BETWEEN ? AND ?', params[:from], params[:to]).order(:printed_on)
      end
  end
end
