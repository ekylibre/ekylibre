require 'test_helper'
module Backend
  class BeehivesControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions except: %i[update reset]
  end
end
