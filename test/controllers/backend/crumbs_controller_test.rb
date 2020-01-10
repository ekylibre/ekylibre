require 'test_helper'
module Backend
  class CrumbsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    # TODO: Re-activate #convert and #index tests
    test_restfully_all_actions except: %i[convert index] # convert: touch
  end
end
