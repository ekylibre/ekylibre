require 'test_helper'

module Backend
  class SettlementsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions except: %i[update_many edit_many]
  end
end
