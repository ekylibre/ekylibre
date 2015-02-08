require 'test_helper'
class Backend::BeehivesControllerTest < ActionController::TestCase
  test_restfully_all_actions except: [:update, :reset]
end
