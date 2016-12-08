require 'test_helper'
module Backend
  class CompaniesControllerTest < ActionController::TestCase
    test_restfully_all_actions class_name: 'Entity'
  end
end
