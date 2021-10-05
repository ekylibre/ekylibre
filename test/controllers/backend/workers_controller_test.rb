require 'test_helper'

module Backend
  class WorkersControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions except: %i[update_many edit_many sort_by_time_use]
  end
end
