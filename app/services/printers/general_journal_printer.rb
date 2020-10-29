module Printers
  class GeneralJournalPrinter < PrinterBase

    class << self
      # TODO move this elsewhere when refactoring the Document Management System
      def build_key(financial_year:)
        financial_year.code
      end
    end

    def initialize(*_args, financial_year:, template:, **_options)
      super(template: template)
      @financial_year = financial_year
    end

    def key
      self.class.build_key(financial_year: @financial_year)
    end

    def document_name
      "#{@template.nature.human_name} (#{@financial_year.code})"
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

      generate_report(@template_path) do |r|

        e = Entity.of_company
        company_name = e.full_name
        company_address = e.default_mail_address&.coordinate

        r.add_field 'COMPANY_ADDRESS', company_address
        r.add_field 'DOCUMENT_NAME', document_name
        r.add_field 'FILE_NAME', key
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
    end
  end
end
