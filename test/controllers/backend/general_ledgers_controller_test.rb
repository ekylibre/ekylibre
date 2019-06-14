require 'test_helper'
module Backend
  class GeneralLedgersControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions only: %i[index]
  end
end
