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
  class JournalsController < Backend::BaseController
    include JournalEntriesCondition
    include PdfPrinter

    manage_restfully nature: 'params[:nature]'.c, currency: 'Preference[:currency]'.c

    unroll

    list(order: :name) do |t|
      # t.action :document_print, url: {:code => :JOURNAL, :journal => "RECORD.id"}
      t.action :edit
      t.action :destroy
      t.column :name, url: true
      t.column :code, url: true
      t.column :nature
      t.column :currency
    end

    hide_action :journal_views

    @@journal_views = %w[items entries mixed]
    cattr_reader :journal_views

    list(:items, model: :journal_entry_items, conditions: journal_entries_conditions, joins: :entry, line_class: "(RECORD.position==1 ? 'first-item' : '') + (RECORD.entry_balanced? ? '' : ' error')".c, order: "entry_id DESC, #{JournalEntryItem.table_name}.position") do |t|
      t.column :entry_number, url: true
      t.column :printed_on, through: :entry, datatype: :date
      t.column :account, url: true
      t.column :account_number, through: :account, label_method: :number, url: true, hidden: true
      t.column :account_name, through: :account, label_method: :name, url: true, hidden: true
      t.column :displayed_label_in_accountancy, label: :entry_item_label
      t.column :variant
      t.column :reference_number, through: :entry
      t.column :state_label
      t.column :real_debit,  currency: :real_currency
      t.column :real_credit, currency: :real_currency
      t.column :debit,  currency: true, hidden: true
      t.column :credit, currency: true, hidden: true
      t.column :absolute_debit,  currency: :absolute_currency, hidden: true
      t.column :absolute_credit, currency: :absolute_currency, hidden: true
      t.column :product_item_to_tax_label, label: :tax_label, hidden: true
      t.column :number, through: :bank_statement, label: :bank_statement_number, url: true, hidden: true
    end

    list(:entries, model: :journal_entries, conditions: journal_entries_conditions, line_class: "(RECORD.balanced? ? '' : 'error')".c, order: { created_at: :desc }) do |t|
      t.action :edit, if: :updateable?
      t.action :destroy, if: :destroyable?
      t.column :number, url: true
      t.column :printed_on
      t.column :state_label
      t.column :real_debit,  currency: :real_currency
      t.column :real_credit, currency: :real_currency
      t.column :debit,  currency: true, hidden: true
      t.column :credit, currency: true, hidden: true
      t.column :absolute_debit,  currency: :absolute_currency, hidden: true
      t.column :absolute_credit, currency: :absolute_currency, hidden: true
    end

    list(:mixed, model: :journal_entries, conditions: journal_entries_conditions, children: :items, line_class: "(RECORD.balanced? ? '' : 'error')".c, order: { created_at: :desc }, per_page: 10) do |t|
      t.action :edit, if: :updateable?
      t.action :destroy, if: :destroyable?
      t.column :number, url: true, children: :name
      t.column :printed_on, datatype: :date, children: false
      # t.column :label, through: :account, url: {action: :account}
      t.column :state_label
      t.column :real_debit,  currency: :real_currency
      t.column :real_credit, currency: :real_currency
      t.column :debit,  currency: true, hidden: true
      t.column :credit, currency: true, hidden: true
      t.column :absolute_debit,  currency: :absolute_currency, hidden: true
      t.column :absolute_credit, currency: :absolute_currency, hidden: true
    end

    def index
      @draft_entries_count = JournalEntry.where(state: :draft).count
      @unbalanced_entries_count = JournalEntry.all.reject(&:balanced?).count
      respond_to do |format|
        format.html
        format.xml  { render xml:  Journal.all }
        format.json { render json: Journal.all }
      end
    end

    # Displays details of one journal selected with +params[:id]+
    def show
      return unless @journal = find_and_check
      journal_view = current_user.preference("interface.journal.#{@journal.code}.view")
      journal_view.value = journal_views[0] unless journal_views.include? journal_view.value
      if view = journal_views.detect { |x| params[:view] == x }
        journal_view.value = view
        journal_view.save
      end
      @journal_view = journal_view.value
      t3e @journal
      @draft_entries_count = JournalEntry.where(journal_id: params[:id], state: :draft).count
      current_financial_year = current_user.current_financial_year
      @current_financial_year_period = "#{current_financial_year.started_on}_#{current_financial_year.stopped_on}"

      # build variables for reporting (document_nature, key, filename and dataset)
      document_nature = Nomen::DocumentNature.find(:journal_ledger)
      key = "#{document_nature.name}-#{Time.zone.now.l(format: '%Y-%m-%d-%H:%M:%S')}"
      respond_to do |format|
        format.html
        format.pdf do
          template_path = find_open_document_template(:journal_ledger)
          raise 'Cannot find template' if template_path.nil?
          @journal_ledger = JournalEntry.journal_ledger(params, @journal.id) if params
          send_file to_odt(@journal_ledger, document_nature, key, template_path, params), type: 'application/pdf', disposition: 'attachment', filename: key << '.pdf'
        end
      end
    end

    def close
      return unless @journal = find_and_check
      unless @journal.closable?
        notify(:no_closable_journal)
        redirect_to action: :index
        return
      end
      if request.post?
        if @journal.close(params[:closed_on].to_date)
          notify_success(:journal_closed_on, closed_on: @journal.closed_on.l, journal: @journal.name)
          redirect_to action: :index
        end
      end
      t3e @journal
    end

    def bookkeep
      params[:stopped_on] = begin
                              params[:stopped_on].to_date
                            rescue
                              Time.zone.today
                            end
      params[:started_on] = begin
                              params[:started_on].to_date
                            rescue
                              (params[:stopped_on] - 1.year).beginning_of_month
                            end
      @natures = %i[sale incoming_payment deposit purchase purchase_payment
                    cash_transfer parcel intervention inventory tax_declaration
                    loan intervention parcel inventory bank_statement
                    sale_gap purchase_gap payslip payslip_payment]

      if request.get?
        notify_now(:bookkeeping_works_only_with, list: @natures.map { |x| x.to_s.classify.constantize.model_name.human }.to_sentence)
        @step = 1
      elsif request.put?
        @step = 2
      elsif request.post?
        @step = 3
      end

      if @step >= 2
        session[:stopped_on] = params[:stopped_on]
        session[:started_on] = params[:started_on]
        @records = {}
        @natures.each do |nature|
          conditions = ['created_at::DATE BETWEEN ? AND ?', session[:started_on], session[:stopped_on]]
          @records[nature] = nature.to_s.classify.constantize.where(conditions)
        end

        if @step == 3
          state = (params[:save_in_draft].to_i == 1 ? :draft : :confirmed)
          @natures.each do |nature|
            @records[nature].each do |record|
              record.bookkeep(:create, state)
            end
          end
          notify_success(:bookkeeping_is_finished)
          redirect_to (state == :draft ? { controller: :draft_journals, action: :show } : { action: :bookkeep })
        end
      end
    end

    protected

    def to_odt(journal_ledger, document_nature, key, template_path, params)
      report = generate_document(document_nature, key, template_path) do |r|
        # TODO: add a helper with generic metod to implemend header and footer

        data_filters = []
        if params[:states]&.any?
          content = []
          content << :draft.tl if params[:states].include?('draft') && params[:states]['draft'].to_i == 1
          content << :confirmed.tl if params[:states].include?('confirmed') && params[:states]['confirmed'].to_i == 1
          content << :closed.tl if params[:states].include?('closed') && params[:states]['closed'].to_i == 1
          data_filters << :journal_entries_states.tl + ' : ' + content.to_sentence
        end

        e = Entity.of_company
        company_name = e.full_name
        company_address = e.default_mail_address.coordinate

        r.add_field 'COMPANY_ADDRESS', company_address
        r.add_field 'DOCUMENT_NAME', document_nature.human_name + ' | ' + @journal.name
        r.add_field 'FILE_NAME', key
        r.add_field 'PERIOD', params[:period] == 'all' ? :on_all_exercises.tl : t('labels.from_to_date', from: Date.parse(params[:period].split('_').first).l, to: Date.parse(params[:period].split('_').last).l)
        r.add_field 'DATE', Date.today.l
        r.add_field 'PRINTED_AT', Time.zone.now.l(format: '%d/%m/%Y %T')
        r.add_field 'DATA_FILTERS', data_filters * ' | '


        r.add_section('Section2', journal_ledger[0...-1]) do |sm|

          sm.add_field(:month_name) { |month| month[:name] }

          sm.add_section('Section3', "items") do |s|
              s.add_field(:entry_number) { |item| item[:entry_number] }
              s.add_field(:printed_on) { |item| item[:printed_on] }
              s.add_field(:journal_name) { |item| item[:journal_name] }
              s.add_field(:reference_number) { |item| item[:reference_number] }
              s.add_field(:label) { |item| item[:label] }
              s.add_field(:continuous_number) { |item| item[:continuous_number] }

              s.add_table('Tableau7', "entry_items") do |t|
                t.add_column(:item_account_number) { |entry_item| entry_item[:account_number] }
                t.add_column(:item_account_name) { |entry_item| entry_item[:account_name] }
                t.add_column(:item_real_debit) { |entry_item| entry_item[:real_debit] }
                t.add_column(:item_real_credit) { |entry_item| entry_item[:real_credit] }
              end

              s.add_field(:state) { |item| item[:state] }
              s.add_field(:real_debit) { |item| item[:real_debit] }
              s.add_field(:real_credit) { |item| item[:real_credit] }
              s.add_field(:balance) { |item| item[:balance] }
          end

          sm.add_field(:month_total_debit) { |month| month[:total_debit] }
          sm.add_field(:month_total_credit) { |month| month[:total_credit] }
          sm.add_field(:month_balance) { |month| month[:balance] }
          sm.add_field(:month_entry_count) { |month| month[:entry_count] }

        end

        r.add_field :entry_count, journal_ledger.last[:entry_count]
        r.add_field :total_credit, journal_ledger.last[:total_credit]
        r.add_field :total_debit, journal_ledger.last[:total_debit]
        r.add_field :total_balance, journal_ledger.last[:total_balance]
      end
      report.file.path
    end
  end
end
