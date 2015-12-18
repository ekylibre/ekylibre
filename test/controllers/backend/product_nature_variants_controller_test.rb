require 'test_helper'

module Backend
  class ProductNatureVariantsControllerTest < ActionController::TestCase
    test_restfully_all_actions last_purchase_item: :show, quantifiers: { format: :json, mode: :show }
  end
end
