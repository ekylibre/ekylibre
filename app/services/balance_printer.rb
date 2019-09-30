class BalancePrinter
  include PdfPrinter

  def initialize(options)
    @balance         = options[:balance]
    @prev_balance    = options[:prev_balance]
    @document_nature = options[:document_nature]
    @key             = options[:key]
    @template_path   = find_open_document_template(:trial_balance)
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

      if @params[:balance]
        data_filters << :display_accounts.tl + ' : ' + @params[:balance].to_sym.tl
      end

      if @params[:accounts]&.present?
        data_filters << :accounts_starting_with.tl + ' : ' + @params[:accounts].split(' ').to_sentence
      end

      if @params[:centralize]&.present?
        data_filters << :group_by_centralizing_accounts.tl + ' : ' + @params[:centralize].split(' ').to_sentence
      end

      e = Entity.of_company
      company_name = e.full_name
      company_address = e.default_mail_address&.coordinate
      balances = @balance.map.with_index { |_item, index| [@balance[index], @prev_balance[index] || []] }

      r.add_field 'COMPANY_ADDRESS', company_address
      r.add_field 'DOCUMENT_NAME', @document_nature.human_name
      r.add_field 'FILE_NAME', @key
      r.add_field 'PERIOD', @params[:period] == 'all' ? :on_all_exercises.tl : I18n.translate('labels.from_to_date', from: Date.parse(@params[:period].split('_').first).l, to: Date.parse(@params[:period].split('_').last).l)
      r.add_field 'DATE', Date.today.l
      r.add_field 'PRINTED_AT', Time.zone.now.l(format: '%d/%m/%Y %T')
      r.add_field 'DATA_FILTERS', data_filters * ' | '

      r.add_table('Tableau2', balances, header: false) do |t|
        t.add_column(:a) { |item| item[0][0] if item[0][1].to_i > 0 }
        t.add_column(:b) do |item|
          if item[0][1].to_i > 0
            Account.find(item[0][1]).name
          elsif item[0][1] == '-1'
            :total.tl
          elsif item[0][1] == '-2'
            I18n.translate('labels.subtotal', name: item[0][0])
          elsif item[0][1] == '-3'
            I18n.translate('labels.centralized_account', name: item[0][0])
          end
        end
        t.add_column(:debit) { |item| item[0][2].to_f }
        t.add_column(:credit) { |item| item[0][3].to_f }
        t.add_column(:debit_n) { |item| item[1].any? ? item[1][2].to_f : '' }
        t.add_column(:credit_n) { |item| item[1].any? ? item[1][3].to_f : '' }
        t.add_column(:balance) { |item| item[0][4].to_f }
        t.add_column(:balance_n) { |item| item[1].any? ? item[1][4].to_f : '' }
      end
    end
    report.file.path
  end
end
