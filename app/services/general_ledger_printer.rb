
# This object allow printing the general ledger
class GeneralLedgerPrinter
  def run(options = {})
    options[:started_on] ||= '2016-01-01'
    options[:stopped_on] ||= '2016-12-31'

    # puts 'STEP 1 - Build dataset'.inspect.yellow

    a_start = Time.zone.now

    human_action_name = 'Grand livre général'

    document_name = human_action_name.to_s
    filename = "#{human_action_name}_#{Time.zone.now.l(format: '%Y%m%d%H%M%S')}"
    general_ledger_dataset = Account.ledger(options[:started_on], options[:stopped_on]) if options

    a_stop = Time.zone.now
    d = (a_stop - a_start).seconds

    # puts "STEP 1 - Done in #{d} seconds".inspect.green

    # puts "STEP 2 - Populate report #{filename}".inspect.yellow

    b_start = Time.zone.now

    # TODO: add a generic template system path
    template = Rails.root.join('config', 'locales', 'fra', 'reporting', 'general_ledger.odt')

    report = ODFReport::Report.new(template) do |r|
      # TODO: add a helper with generic metod to implemend header and footer

      e = Entity.of_company
      company_name = e.full_name
      company_address = e.default_mail_address.coordinate

      r.add_field 'COMPANY_ADDRESS', company_address
      r.add_field 'DOCUMENT_NAME', document_name
      r.add_field 'FILENAME', filename
      r.add_field 'PRINTED_AT', Time.zone.now.l(format: '%d/%m/%Y %T')
      r.add_field 'STARTED_ON', options[:started_on].to_date.strftime('%d/%m/%Y')
      r.add_field 'STOPPED_ON', options[:stopped_on].to_date.strftime('%d/%m/%Y')

      r.add_section('Section1', general_ledger_dataset) do |s|
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
          t.add_column(:printed_on) { |item| item[:printed_on] }
          t.add_column(:name) { |item| item[:name] }
          t.add_column(:variant) { |item| item[:variant] }
          t.add_column(:journal_name) { |item| item[:journal_name] }
          t.add_column(:letter) { |item| item[:letter] }
          t.add_column(:real_debit) { |item| item[:real_debit] }
          t.add_column(:real_credit) { |item| item[:real_credit] }
          t.add_column(:cumulated_balance) { |item| item[:cumulated_balance] }
        end
      end
    end

    b_stop = Time.zone.now
    d = (b_stop - b_start).seconds

    # puts "STEP 2 - Done in #{d} seconds".inspect.green

    # generate the report

    # puts "STEP 3 - Generate #{filename}".inspect.yellow

    c_start = Time.zone.now

    report.generate(Rails.root.join('tmp', "#{filename}.odt"))

    c_stop = Time.zone.now
    d = (c_stop - c_start).seconds

    # puts "STEP 3 - Done in #{d} seconds".inspect.green
  end
end
