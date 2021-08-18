require 'test_helper'

module Printers
  class InventorySheetPrinterTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    setup do
      @template = Minitest::Mock.new
      @template.expect :nature, :inventory_sheet
      @template.expect :nature, Onoma::DocumentNature[:inventory_sheet]
      @template.expect :nil?, false
      @template.expect :managed?, true
    end

    teardown do
      @template.verify
    end

    test 'should print inventory_sheet' do
      inventory = inventories(:inventories_001)
      assert inventory.valid?, "Fixture inventory is not valid (#{inventory.errors.inspect})"

      printer = Printers::InventorySheetPrinter.new(template: @template, id: inventory.id)
      generator = Ekylibre::DocumentManagement::DocumentGenerator.build
      pdf_data = generator.generate_pdf(template: @template, printer: printer)
      assert pdf_data
    end
  end
end
