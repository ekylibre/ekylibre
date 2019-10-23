class JournalPrinter
  include PdfPrinter

  def initialize(options)
    @journal         = options[:journal]
    @journal_ledger  = options[:journal_ledger]
    @document_nature = options[:document_nature]
    @key             = options[:key]
    @template_path   = find_open_document_template(:journal_ledger)
    @params          = options[:params]
    @mandatory       = options[:mandatory]
    @closer          = options[:closer]
  end

  def run
    report = generate_document(@document_nature, @key, @template_path, @mandatory, @closer) do |r|
      data_filters = []
      if @params[:states]&.any?
        content = []
        content << :draft.tl if @params[:states].include?('draft') && @params[:states]['draft'].to_i == 1
        content << :confirmed.tl if @params[:states].include?('confirmed') && @params[:states]['confirmed'].to_i == 1
        content << :closed.tl if @params[:states].include?('closed') && @params[:states]['closed'].to_i == 1
        data_filters << :journal_entries_states.tl + ' : ' + content.to_sentence
      end

      e = Entity.of_company
      company_name = e.full_name
      company_address = e.default_mail_address&.coordinate

      r.add_field 'COMPANY_ADDRESS', company_address
      r.add_field 'DOCUMENT_NAME', @document_nature.human_name + ' | ' + @journal.name
      r.add_field 'FILE_NAME', @key
      r.add_field 'PERIOD', @params[:period] == 'all' ? :on_all_exercises.tl : I18n.translate('labels.from_to_date', from: Date.parse(@params[:period].split('_').first).l, to: Date.parse(@params[:period].split('_').last).l)
      r.add_field 'DATE', Date.today.l
      r.add_field 'PRINTED_AT', Time.zone.now.l(format: '%d/%m/%Y %T')
      r.add_field 'DATA_FILTERS', data_filters * ' | '


      r.add_section('Section2', @journal_ledger[0...-1]) do |sm|

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

      r.add_field :entry_count, @journal_ledger.last[:entry_count]
      r.add_field :total_credit, @journal_ledger.last[:total_credit]
      r.add_field :total_debit, @journal_ledger.last[:total_debit]
      r.add_field :total_balance, @journal_ledger.last[:total_balance]
    end
    report.file.path
  end
end
