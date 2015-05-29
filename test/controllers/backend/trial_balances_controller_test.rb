require 'test_helper'
class Backend::TrialBalancesControllerTest < ActionController::TestCase
  test_restfully_all_actions show: :index

  test "with period" do
    get :show, period: "2007-01-01_2015-12-31", states: [:draft, :confirmed, :closed]
  end
  
end
