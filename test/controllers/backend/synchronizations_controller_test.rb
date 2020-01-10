require 'test_helper'
module Backend
  class SynchronizationsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions except: %i[update run]
  end
end
