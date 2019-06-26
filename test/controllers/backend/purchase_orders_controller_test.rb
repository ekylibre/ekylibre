require 'test_helper'
module Backend
  class PurchaseOrdersControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions open: :touch, close: :touch
  end
end
