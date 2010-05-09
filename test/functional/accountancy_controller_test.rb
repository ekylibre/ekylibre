require 'test_helper'

class AccountancyControllerTest < ActionController::TestCase
  fixtures :companies, :users
  test_all_actions
end
