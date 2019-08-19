require 'test_helper'
module Backend
  class ShipmentsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions ship: { mode: :multi_touch, fixture: { first: 3, second: 4 } },
                               check: :touch,
                               order: :touch,
                               prepare: :touch,
                               cancel: :touch,
                               give: :touch

    test 'should print a shipping note' do
      shipment = parcels(:shipments_006)
      assert shipment.valid?, "Shipment 006 must be valid (#{shipment.errors.inspect})"

      printer = ShippingNotePrinter.new(shipment: shipment)
      file_path = printer.run_pdf
      begin
        assert File.exist? file_path
      ensure
        File.delete file_path if File.exist?(file_path)
      end
    end
  end
end
