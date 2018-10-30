class BalancePrinter
  include PdfPrinter

  def initialize(options)
    @balance         = options[:balance]
    @prev_balance    = options[:prev_balance]
    @document_nature = options[:document_nature]
    @key             = options[:key]
    @template_path   = options[:template_path]
    @period          = options[:period]
  end

  def run
    report = generate_document(@document_nature, @key, @template_path) do |r|
      e = Entity.of_company
      company_name = e.full_name
      company_address = e.default_mail_address.coordinate
      balances = @balance.map.with_index { |_item, index| [@balance[index], @prev_balance[index] || []] }

      r.add_field 'COMPANY_ADDRESS', company_address
      r.add_field 'DOCUMENT_NAME', @document_nature.human_name
      r.add_field 'FILE_NAME', @key
      r.add_field 'PERIOD', @period == 'all' ? :on_all_exercises.tl : I18n.translate('labels.from_to_date', from: Date.parse(@period.split('_').first).l, to: Date.parse(@period.split('_').last).l)
      r.add_field 'DATE', Date.today.l
      r.add_field 'PRINTED_AT', Time.zone.now.l(format: '%d/%m/%Y %T')
      r.add_field 'DATA_FILTERS', ''

      r.add_table('Tableau2', balances, header: false) do |t|
        t.add_column(:a) { |item| item[0][0] }
        t.add_column(:b) do |item|
          Account.find(item[0][1]).name if item[0][1].to_i > 0
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
