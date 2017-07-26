require 'test_helper'
module Authentication
  class OmniauthCallbacksControllerTest < ActionController::TestCase
    # TODO: Reactivate #failure, #ekylibre and #passthru tests
    test_restfully_all_actions except: %i[failure passthru ekylibre]
  end
end
