require 'test_helper'
module Backend
  class JanusesControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions toggle: { mode: :soft_touch, params: { id: 'backend/accounts' } }
  end
end
