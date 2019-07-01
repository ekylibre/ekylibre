require 'test_helper'
module Backend
  class CobblersControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions except: [:update]
  end
end
