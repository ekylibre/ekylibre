require 'test_helper'
module Backend
  class SnippetsControllerTest < ActionController::TestCase
    test_restfully_all_actions toggle: { mode: :soft_touch, params: { id: 'help' } }
  end
end
