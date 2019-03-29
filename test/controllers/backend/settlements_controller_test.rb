require 'test_helper'

module Backend
  class SettlementsControllerTest < ActionController::TestCase
    test_restfully_all_actions except: %i[update_many edit_many]
  end
end
