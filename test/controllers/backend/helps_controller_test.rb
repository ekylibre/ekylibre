require 'test_helper'

module Backend
  class HelpsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions except: %i[show toggle]
  end
end
