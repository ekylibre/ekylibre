require 'test_helper'

module Backend
  class IssuesControllerTest < ActionController::TestCase
    test_restfully_all_actions close: :touch, reopen: :touch
  end
end
