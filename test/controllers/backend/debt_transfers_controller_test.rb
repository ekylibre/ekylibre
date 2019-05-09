require 'test_helper'

module Backend
  class DebtTransfersControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    # TODO: Re-activate #create and #destroy tests
    test_restfully_all_actions except: %i[destroy create]
  end
end
