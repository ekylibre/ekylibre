require 'test_helper'
module Backend
  class PlantDensityAbaciControllerTest < ActionController::TestCase
    test_restfully_all_actions show: { format: :json }
  end
end
