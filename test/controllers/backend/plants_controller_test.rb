require 'test_helper'
module Backend
  class PlantsControllerTest < ActionController::TestCase
    test_restfully_all_actions except: %i[update_many edit_many]
  end
end
