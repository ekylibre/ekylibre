require 'test_helper'

class ManagementControllerTest < ActionController::TestCase
  fixtures :companies, :users
  test_all_actions
end
