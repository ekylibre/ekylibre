require 'test_helper'
module Backend
  class ActivityBudgetsControllerTest < ActionController::TestCase
    test_restfully_all_actions except: :show

    test 'show action' do
      get :show, id: 'NaID', redirect: root_url, locale: @locale
      assert_redirected_to root_url
      ActivityBudget.limit(5).find_each do |record|
        get :show, id: record.id, locale: @locale
        assert_redirected_to controller: :activities, action: :show, id: record.activity_id

        assert_not_nil assigns(:activity_budget)
      end
    end
  end
end
