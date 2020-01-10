require 'test_helper'
module Backend
  module Products
    class IndicatorsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
      test_restfully_all_actions except: :variable_indicators
    end
  end
end
