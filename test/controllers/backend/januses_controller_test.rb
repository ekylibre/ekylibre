require 'test_helper'
class Backend::JanusesControllerTest < ActionController::TestCase
  test_restfully_all_actions toggle: { mode: :soft_touch, params: { id: 'backend/accounts' } }
end
