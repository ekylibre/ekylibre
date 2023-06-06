require 'test_helper'
module Backend
  class ProductGroupsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    # TODO: Re-activate #index and #list, #show and #edit tests
    test_restfully_all_actions except: %i[index list edit show update_many edit_many sort_by_time_use list_yield_observations]
  end
end
