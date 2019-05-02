require 'test_helper'
module Backend
  class PlantCountingsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions except: %i[create edit new]
    # TODO: Re-activate #create, #new and :edit tests
  end
end
