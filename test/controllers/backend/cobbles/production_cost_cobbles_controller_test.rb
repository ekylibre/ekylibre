require 'test_helper'
module Backend
  module Cobbles
    class ProductionCostCobblesControllerTest < ActionController::TestCase
      test_restfully_all_actions except: :show
    end
  end
end
