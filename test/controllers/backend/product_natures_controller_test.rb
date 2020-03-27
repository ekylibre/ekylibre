require 'test_helper'
module Backend
  class ProductNaturesControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions except: %i[edit compatible_varieties]
  end
end
