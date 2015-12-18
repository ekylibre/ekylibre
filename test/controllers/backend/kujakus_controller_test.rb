require 'test_helper'
module Backend
  class KujakusControllerTest < ActionController::TestCase
    test_restfully_all_actions toggle: { mode: :soft_touch, params: { id: 'backend/accounts' } }
  end
end
