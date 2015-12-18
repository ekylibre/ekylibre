require 'test_helper'
module Backend
  class LoanRepaymentsControllerTest < ActionController::TestCase
    test_restfully_all_actions show: :redirected_get, index: :redirected_get
  end
end
