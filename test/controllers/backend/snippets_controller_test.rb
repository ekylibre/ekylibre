require 'test_helper'
class Backend::SnippetsControllerTest < ActionController::TestCase
  test_restfully_all_actions toggle: { mode: :soft_touch, params: { id: 'help' } }
end
