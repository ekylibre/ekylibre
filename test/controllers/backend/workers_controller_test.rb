require 'test_helper'

module Backend
  class WorkersControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    WorkerTimeIndicator.refresh
    test_restfully_all_actions except: %i[update_many edit_many sort_by_time_use list_yield_observations]
  end
end
