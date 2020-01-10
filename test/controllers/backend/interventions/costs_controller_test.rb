require 'test_helper'
module Backend
  module Interventions
    class CostsControllerTest < ActionController::TestCase
      test_restfully_all_actions except: :parameter_cost
    end
  end
end
