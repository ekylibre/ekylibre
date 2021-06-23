# frozen_string_literal: true

module Printers
  class FecDataErrorPrinter < PrinterBase

    class << self
      # TODO: move this elsewhere when refactoring the Document Management System
      def build_key(financial_year:)
        financial_year.stopped_on
      end
    end

    def initialize(*_args, financial_year:, fiscal_position:, template:, **_options)
      super(template: template)
      @financial_year = financial_year
      @stopped_on = financial_year.stopped_on
      @started_on = financial_year.started_on
      @fiscal_position = fiscal_position
      @journals = Journal.where.not(nature: %w[closure result])
    end

    def key
      self.class.build_key(financial_year: @financial_year)
    end

    def document_name
      "#{@template.nature.human_name}_#{@stopped_on.l(format: '%Y%m%d')}"
    end

    def compute_dataset
      FEC::Datasource::Error.new(@financial_year, @fiscal_position, @started_on, @stopped_on).perform
    end

    def global_entries
      JournalEntry.where(financial_year_id: @financial_year.id, journal_id: @journals.pluck(:id)).between(@started_on, @stopped_on)
    end

    def generate(report)
      entries = compute_dataset

      dataset = []
      FEC::Check::JournalEntry.errors_name.each do |error|
        error_count = HashWithIndifferentAccess.new
        v = entries.with_compliance_error('fec', 'journal_entries', error).count
        error_count[:value] = v
        error_count[:percent] = (global_entries.count > 0 ? ((v.to_d / global_entries.count.to_d) * 100 ).to_f.round(2) : '--')
        # because translation is not iso for all error name
        # account_number_with_less_than_3_caracters and entry_item_account_name_not_uniq is a Hash
        if error == "account_number_with_less_than_3_caracters" || error == "entry_item_account_name_not_uniq"
          error_count[:error] = error.tl[:none]
        else
          error_count[:error] = error.tl
        end
        dataset << error_count
      end

      report.add_field "STARTED_ON", @started_on.strftime("%d/%m/%Y")
      report.add_field "STOPPED_ON", @stopped_on.strftime("%d/%m/%Y")
      report.add_field "YEAR", @financial_year.code
      report.add_field "ERRORS_ENTRIES_COUNT", entries.count
      report.add_field "GLOBAL_ENTRIES_COUNT", global_entries.count
      report.add_table('Tableau2', dataset, header: true) do |t|
        t.add_column(:error) { |error_count| error_count[:error] }
        t.add_column(:value) { |error_count| error_count[:value] }
        t.add_column(:percent) { |error_count| error_count[:percent] }
      end
    end
  end
end
