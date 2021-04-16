require 'test_helper'

module Printers
  class InterventionSheetPrinterTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    setup do
      @template = Minitest::Mock.new
      @template.expect :nature, :intervention_sheet
      @template.expect :nil?, false
      @template.expect :managed?, true
    end

    teardown do
      @template.verify
    end

    test 'should print an intervention sheet' do
      intervention = interventions(:interventions_003)
      assert intervention.valid?, "Intervention 003 must be valid (#{intervention.errors.inspect})"

      printer = Printers::InterventionSheetPrinter.new(template: @template, id: intervention.id)
      generator = Ekylibre::DocumentManagement::DocumentGenerator.build
      pdf_data = generator.generate_pdf(template: @template, printer: printer)
      assert pdf_data
    end

    test 'should print an intervention sheet for equipment maintenance interventions' do
      intervention = interventions(:interventions_022)
      assert intervention.valid?, "Intervention 022 must be valid (#{intervention.errors.inspect})"

      printer = Printers::InterventionSheetPrinter.new(template: @template, id: intervention.id)
      generator = Ekylibre::DocumentManagement::DocumentGenerator.build
      pdf_data = generator.generate_pdf(template: @template, printer: printer)
      assert pdf_data
    end
  end
end
