require 'test_helper'
module Backend
  class CobblersControllerTest < ActionController::TestCase
    test_restfully_all_actions except: [:update]
  end
end
