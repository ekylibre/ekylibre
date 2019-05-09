require 'test_helper'

module Backend
  class ProductNatureVariantsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions last_purchase_item: :show, quantifiers: { format: :json, mode: :show }
  end
end
