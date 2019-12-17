require 'test_helper'

module Printers
  class ShippingNotePrinterTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures

    setup do
      @template = Minitest::Mock.new
      @template.expect :nature, :shipping_note
      @template.expect :nil?, false
      @template.expect :managed?, true
    end

    teardown do
      @template.verify
    end

    test 'should print a shipping note' do
      shipment = parcels(:shipments_006)
      assert shipment.valid?, "Shipment 006 must be valid (#{shipment.errors.inspect})"

      printer = Printers::ShippingNotePrinter.new(template: @template, shipment: shipment)
      assert printer.run_pdf
    end
  end
end
