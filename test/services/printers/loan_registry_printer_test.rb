require 'test_helper'

module Printers
  class LoanRegistryPrinterTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    setup do
      @template = Minitest::Mock.new
      @template.expect :nature, :loan_registry
      @template.expect :nature, Onoma::DocumentNature[:loan_registry]
      @template.expect :nil?, false
      @template.expect :managed?, true
    end

    teardown do
      @template.verify
    end

    test 'should print a loan registry' do
      printer = Printers::LoanRegistryPrinter.new(template: @template, stopped_on: Date.today.to_s)
      generator = Ekylibre::DocumentManagement::DocumentGenerator.build
      pdf_data = generator.generate_pdf(template: @template, printer: printer)
      assert pdf_data
    end
  end
end
