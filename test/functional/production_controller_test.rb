require 'test_helper'

class ProductionControllerTest < ActionController::TestCase
  fixtures :companies, :users
  test_all_actions :except=>[:operation_line_create, :operation_use_create]
end
