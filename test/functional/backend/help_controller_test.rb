require 'test_helper'

class Backend::HelpControllerTest < BackendControllerTest
  test_restfully_all_actions :except=>:show
end
