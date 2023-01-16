require 'test_helper'
module Iot
  class AnalysesControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions only: %i[create]
  end
end
