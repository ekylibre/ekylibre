require 'test_helper'
module Backend
  class PayslipsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions except: %i[create new]
  end
end
