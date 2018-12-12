class CentralizingJournalPrinter
  include PdfPrinter

  def initialize(options)
    @document_nature = Nomen::DocumentNature.find(options[:document_nature])
    @key             = options[:key]
    @template_path   = find_open_document_template(options[:document_nature])
    @financial_year  = FinancialYear.find(options[:financial_year])
  end

  def compute_dataset
    monthly_data = (@financial_year.started_on..@financial_year.stopped_on).group_by { |d| [Date::MONTHNAMES[d.month], d.year] }.map do |month, dates|

      journals_data = Journal.all.map do |journal|
        entries = journal.entries.where('printed_on BETWEEN ? AND ?', dates.first, dates.last)
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
    pp dataset

    # report = generate_document(@document_nature, @key, @template_path) do |r|

    # end
    # report.file.path
  end
end
