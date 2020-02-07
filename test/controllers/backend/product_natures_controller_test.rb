require 'test_helper'
module Backend
  class ProductNaturesControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions except: :edit
  end
end
