require 'test_helper'
module Backend
  class LoanRepaymentsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    # TODO: Re-activate #new test
    test_restfully_all_actions show: :redirected_get, index: :redirected_get, except: :new
  end
end
