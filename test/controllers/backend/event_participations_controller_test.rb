require 'test_helper'
class Backend::EventParticipationsControllerTest < ActionController::TestCase
  test_restfully_all_actions show: :redirected_get, index: :redirected_get
end
