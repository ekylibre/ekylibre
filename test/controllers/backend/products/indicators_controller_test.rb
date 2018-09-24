require 'test_helper'
module Backend
  module Products
    class IndicatorsControllerTest < ActionController::TestCase
      test_restfully_all_actions except: :variable_indicators
    end
  end
end
