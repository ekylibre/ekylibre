require 'test_helper'

module Backend
  class DebtTransfersControllerTest < ActionController::TestCase
    # TODO: Re-activate #create and #destroy tests
    test_restfully_all_actions except: [:destroy, :create]
  end
end
