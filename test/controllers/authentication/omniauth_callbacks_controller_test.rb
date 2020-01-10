require 'test_helper'
module Authentication
  class OmniauthCallbacksControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    # TODO: Reactivate #failure, #ekylibre and #passthru tests
    test_restfully_all_actions except: %i[failure passthru ekylibre]
  end
end
