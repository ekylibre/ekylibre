require 'test_helper'

module Printers
  class AcWorkSheetPrinterTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    setup do
      @template = Minitest::Mock.new
      @template.expect :nature, :ac_work_sheet
      @template.expect :nil?, false
      @template.expect :managed?, true
      @intervention = create(:intervention)
    end

    attr_reader :intervention

    teardown do
      @template.verify
    end

    test 'should print draaf sheet' do
      printer = Printers::AcWorkSheetPrinter.new(template: @template, intervention: intervention)
      generator = Ekylibre::DocumentManagement::DocumentGenerator.build
      odf_data = generator.generate_odt(template: @template, printer: printer)
      assert odf_data
    end
  end
end
