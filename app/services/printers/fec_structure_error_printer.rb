# frozen_string_literal: true

module Printers
  class FecStructureErrorPrinter < PrinterBase
    DISPLAYED_LINES_COUNT = 50

    class << self
      # TODO: move this elsewhere when refactoring the Document Management System
      def build_key(financial_year:)
        financial_year.stopped_on
      end
    end

    def initialize(*_args, financial_year:, template:, xsd:, fec_parser:, **_options)
      super(template: template)
      @financial_year = financial_year
      @stopped_on = financial_year.stopped_on
      @started_on = financial_year.started_on
      @xsd = xsd
      @fec_parser = fec_parser
    end

    def key
      self.class.build_key(financial_year: @financial_year)
    end

    def document_name
      "#{@template.nature.human_name}_#{@stopped_on.l(format: '%Y%m%d')}"
    end

    def compute_dataset
      @xsd.validate(@fec_parser)
    end

    def generate(report)
      errors = compute_dataset

      # Translations + more readeable sentences
      errors_as_html = XmlErrorsParser::Parser.new(errors).errors_as_html
      errors_count = errors_as_html.each_line.count
      # Only display a few number of lines and warn the user there are lines not displayed
      if errors_count > DISPLAYED_LINES_COUNT
        truncated_errors = errors_as_html.each_line.first(DISPLAYED_LINES_COUNT).join
        hidden_lines_count = errors_count - DISPLAYED_LINES_COUNT
        display_info = :display_x_lines_hide_x_lines.tl(display_lines_count: DISPLAYED_LINES_COUNT, hidden_lines_count: hidden_lines_count)
        errors_as_html = truncated_errors + "\n" + display_info
      end
      report.add_field "ERRORS", errors_as_html
    end
  end
end
