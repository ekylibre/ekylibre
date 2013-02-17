require 'test_helper'

class Backend::HelpControllerTest < ActionController::TestCase
  test_restfully_all_actions :except=>:show
end
