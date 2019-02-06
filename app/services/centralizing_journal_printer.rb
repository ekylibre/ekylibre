class CentralizingJournalPrinter
  include PdfPrinter

  def initialize(options)
    @document_nature = Nomen::DocumentNature.find(options[:document_nature])
    @key             = options[:key]
    @template_path   = find_open_document_template(options[:document_nature])
    @financial_year  = FinancialYear.find(options[:financial_year])
  end

  def compute_dataset
    monthly_data = (@financial_year.started_on..@financial_year.stopped_on).group_by { |d| [I18n.t('date.month_names')[d.month], d.year] }.map do |month, dates|

      journals_data = Journal.all.map do |journal|
        entries = journal.entries.where('printed_on BETWEEN ? AND ?', dates.first, dates.last).where.not(state: 'draft')
        next unless entries.any?

        { journal_code: journal.code,
          journal_name: journal.name,
          journal_debit: entries.pluck(:debit).sum,
          journal_credit: entries.pluck(:credit).sum }
      end.compact

      { month: month.join(' '),
        month_debit: journals_data.map { |j| j[:journal_debit] }.sum,
        month_credit: journals_data.map { |j| j[:journal_credit] }.sum,
        journals: journals_data }
    end

    { year_debit: monthly_data.map { |m| m[:month_debit] }.sum,
      year_credit: monthly_data.map { |m| m[:month_credit] }.sum,
      months: monthly_data }
  end

  def run_pdf
    dataset = compute_dataset

    report = generate_document(@document_nature, @key, @template_path, false, nil, name: "#{:centralizing_journal.tl} (#{@financial_year.code})") do |r|

      e = Entity.of_company
      company_name = e.full_name
      company_address = e.default_mail_address&.coordinate

      r.add_field 'COMPANY_ADDRESS', company_address
      r.add_field 'DOCUMENT_NAME', "#{:centralizing_journal.tl} (#{@financial_year.code})"
      r.add_field 'FILE_NAME', @key
      r.add_field 'STARTED_ON', @financial_year.started_on.l
      r.add_field 'STOPPED_ON', @financial_year.stopped_on.l
      r.add_field 'PRINTED_AT', Time.zone.now.l(format: '%d/%m/%Y %T')
      r.add_field 'YEAR_DEBIT', dataset[:year_debit]
      r.add_field 'YEAR_CREDIT', dataset[:year_credit]

      r.add_section('Section1', dataset[:months]) do |s|
        s.add_field(:month) { |month| month[:month] }
        s.add_field(:month_debit) { |month| month[:month_debit] }
        s.add_field(:month_credit) { |month| month[:month_credit] }

        s.add_table('Table5', :journals) do |t|
          t.add_column(:journal_code) { |journal| journal[:journal_code] }
          t.add_column(:journal_name) { |journal| journal[:journal_name] }
          t.add_column(:journal_debit) { |journal| journal[:journal_debit] }
          t.add_column(:journal_credit) { |journal| journal[:journal_credit] }
        end
      end
    end
    report.file.path
  end
end
