require 'test_helper'

class HelpControllerTest < ActionController::TestCase
  test_restfully_all_actions :except=>:show
end
