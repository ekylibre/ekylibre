require 'test_helper'

class Backend::IssuesControllerTest < ActionController::TestCase
  test_restfully_all_actions close: :touch, reopen: :touch
end
