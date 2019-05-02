require 'test_helper'

module Backend
  class GuidesControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions run: :touch
  end
end
