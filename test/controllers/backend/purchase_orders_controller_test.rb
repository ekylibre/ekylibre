require 'test_helper'
module Backend
  class PurchaseOrdersControllerTest < ActionController::TestCase
    test_restfully_all_actions open: :touch, close: :touch
  end
end
