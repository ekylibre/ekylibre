require 'test_helper'
module Backend
  class PurchaseInvoicesControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions pay: { mode: :create, id: '20,21', mode_id: 1 }, except: :payment_mode
  end
end
