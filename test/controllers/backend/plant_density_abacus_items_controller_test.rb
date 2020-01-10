require 'test_helper'
module Backend
  class PlantDensityAbacusItemsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    # TODO: Re-activate #new test
    test_restfully_all_actions except: :new
  end
end
