require 'test_helper'
class Api::V1::CrumbsControllerTest < ActionController::TestCase
  test_restfully_all_actions except: :create, index: {format: :json}
end
