require 'test_helper'
module Backend
  class PlantCountingsControllerTest < ActionController::TestCase
    test_restfully_all_actions except: %i[create edit new]
    # TODO: Re-activate #create, #new and :edit tests
  end
end
