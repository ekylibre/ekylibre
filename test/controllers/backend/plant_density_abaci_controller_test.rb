require 'test_helper'
module Backend
  class PlantDensityAbaciControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    # TODO: Re-activate #destroy tests
    test_restfully_all_actions show: { format: :json }, except: :destroy
  end
end
