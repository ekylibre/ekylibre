require 'test_helper'

module Ekylibre
  module DocumentManagement
    class DocumentArchiverTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
      setup do
        @template = document_templates(:document_templates_001)
      end

      test 'should print a signed invoice document' do
        sale = sales(:sales_001)
        assert sale.valid?, "Sales 001 must be valid (#{sale.errors.inspect})"

        printer = Printers::Sale::SalesInvoicePrinter.new(template: @template, sale: sale)

        generator = Ekylibre::DocumentManagement::DocumentGenerator.build
        pdf_data = generator.generate_pdf(template: @template, printer: printer)
        assert pdf_data

        archiver = Ekylibre::DocumentManagement::DocumentArchiver.build
        document = archiver.archive_document(pdf_content: pdf_data, template: @template, key: printer.key, name: printer.document_name)
        assert document
        assert document.signature.present?
      end
    end
  end
end
