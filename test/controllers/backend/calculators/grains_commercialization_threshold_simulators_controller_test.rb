require 'test_helper'
module Backend
  module Calculators
    class GrainsCommercializationThresholdSimulatorsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
      test_restfully_all_actions except: :show
    end
  end
end
