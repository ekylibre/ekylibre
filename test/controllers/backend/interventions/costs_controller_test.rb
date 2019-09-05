require 'test_helper'
module Backend
  module Interventions
    class CostsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
      test_restfully_all_actions except: :parameter_cost
    end
  end
end
