require 'test_helper'

class ProductionControllerTest < ActionController::TestCase
  fixtures :companies, :users
  test_all_actions
end
