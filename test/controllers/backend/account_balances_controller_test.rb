require 'test_helper'
module Backend
  class AccountBalancesControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions except: :show
  end
end
