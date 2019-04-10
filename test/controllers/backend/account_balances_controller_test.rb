require 'test_helper'
module Backend
  class AccountBalancesControllerTest < ActionController::TestCase
    test_restfully_all_actions except: :show
  end
end
