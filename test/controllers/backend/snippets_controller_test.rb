require 'test_helper'
module Backend
  class SnippetsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions toggle: { mode: :soft_touch, params: { id: 'help' } }
  end
end
