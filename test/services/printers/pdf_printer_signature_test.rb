require 'test_helper'

module Printers
  class PdfPrinterSignatureTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures

    setup do
      @template = document_templates(:document_templates_001)
    end


    test 'should print a signed invoice document' do
      sale = sales(:sales_001)
      assert sale.valid?, "Sales 001 must be valid (#{sale.errors.inspect})"
      printer = Printers::Sale::SalesInvoicePrinter.new(template: @template, sale: sale)
      pdf_data = printer.run_pdf
      document = printer.archive_report_template(pdf_data, nature: "sales_invoice", key: printer.key, template: @template, document_name: "swzyutybgehqdiuyhb")
      assert printer.run_pdf
      assert document
      assert document.signature.present?
    end

  end
end
