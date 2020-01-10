require 'test_helper'
module Backend
  module Calculators
    class GrainsCommercializationThresholdSimulatorsControllerTest < ActionController::TestCase
      test_restfully_all_actions except: :show
    end
  end
end
