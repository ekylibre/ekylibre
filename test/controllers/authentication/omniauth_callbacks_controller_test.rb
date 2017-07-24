require 'test_helper'
module Authentication
  class OmniauthCallbacksControllerTest < ActionController::TestCase
    test_restfully_all_actions except: [:failure, :passthru]
    # TODO: Reactivate failure & passthru tests
  end
end
