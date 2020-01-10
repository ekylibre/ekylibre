require 'test_helper'
module Backend
  class InterventionParticipationsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions convert: :touch
  end
end
