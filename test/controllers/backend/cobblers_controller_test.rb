require 'test_helper'
class Backend::CobblersControllerTest < ActionController::TestCase
  test_restfully_all_actions except: [:update]
end
