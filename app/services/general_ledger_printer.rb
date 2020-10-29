class GeneralLedgerPrinter
  include PdfPrinter

  def initialize(options)
    @general_ledger  = options[:general_ledger]
    @document_nature = options[:document_nature]
    @key             = options[:key]
    @template_path   = options[:template_path]
    @params          = options[:params]
    @mandatory       = options[:mandatory]
    @closer          = options[:closer]
  end

  def run
    report = generate_document(@document_nature, @key, @template_path, @mandatory, @closer) do |r|
      data_filters = []

      if @params[:ledger]
        if @params[:ledger] == 'general_ledger'
          data_filters << "#{:centralizing_accounts.tl} : 401, 411"
        else
          data_filters << "#{:centralizing_account.tl} : #{@params[:ledger]}"
        end
      end

      if @params[:lettering_state]
        content = []
        content << :unlettered.tl if @params[:lettering_state].include?('unlettered')
        content << :partially_lettered.tl if @params[:lettering_state].include?('partially_lettered')
        content << :lettered.tl if @params[:lettering_state].include?('lettered')
        data_filters << :lettering_state.tl + ' : ' + content.to_sentence
      end

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

      started_on = @params[:period].split('_').first if @params[:period]
      stopped_on = @params[:period].split('_').last if @params[:period]

      r.add_field 'COMPANY_ADDRESS', company_address
      r.add_field 'DOCUMENT_NAME', @document_nature.human_name
      r.add_field 'FILE_NAME', @key
      r.add_field 'PERIOD', @params[:period] == 'all' ? :on_all_exercises.tl : I18n.translate('labels.from_to_date', from: Date.parse(@params[:period].split('_').first).l, to: Date.parse(@params[:period].split('_').last).l)
      r.add_field 'DATE', Date.today.l
      r.add_field 'PRINTED_AT', Time.zone.now.l(format: '%d/%m/%Y %T')
      r.add_field 'STARTED_ON', started_on.to_date.strftime('%d/%m/%Y') if started_on
      r.add_field 'STOPPED_ON', stopped_on.to_date.strftime('%d/%m/%Y') if stopped_on
      r.add_field 'DATA_FILTERS', data_filters * ' | '

      r.add_section('Section1', @general_ledger) do |s|
        s.add_field(:account_number, :account_number)
        s.add_field(:account_name, :account_name)
        s.add_field(:count, :count)
        s.add_field(:currency, :currency)
        s.add_field(:total_debit, :total_debit)
        s.add_field(:total_credit, :total_credit)
        s.add_field(:total_cumulated_balance) do |acc|
          acc[:total_debit] - acc[:total_credit]
        end

        s.add_table('Tableau1', :items, header: true) do |t|
          t.add_column(:entry_number) { |item| item[:entry_number] }
          t.add_column(:continuous_number) { |item| item[:continuous_number] }
          t.add_column(:reference_number) { |item| item[:reference_number] }
          t.add_column(:printed_on) { |item| item[:printed_on] }
          t.add_column(:name) { |item| item[:name] }
          t.add_column(:journal_name) { |item| item[:journal_name] }
          t.add_column(:letter) { |item| item[:letter] }
          t.add_column(:real_debit) { |item| item[:real_debit] }
          t.add_column(:real_credit) { |item| item[:real_credit] }
          t.add_column(:cumulated_balance) { |item| item[:cumulated_balance] }
        end
      end
    end
    report.file.path
  end
end
