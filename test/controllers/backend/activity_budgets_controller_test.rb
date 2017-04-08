require 'test_helper'
module Backend
  class ActivityBudgetsControllerTest < ActionController::TestCase
    test_restfully_all_actions  new: { params: { activity_id: 1, campaign_id: 6 } },
                                create: { params: { activity_id: 1, campaign_id: 6 } },
                                duplicate: { params: { activity_id: 1, campaign_id: 6 } },
                                except: %i[show index]

    test 'show action' do
      get :show, id: 'NaID', redirect: root_url, locale: @locale
      assert_redirected_to root_url
      ActivityBudget.limit(5).find_each do |record|
        get :show, id: record.id, locale: @locale
        assert_redirected_to controller: :activities, action: :show, id: record.activity_id

        assert_not_nil assigns(:activity_budget)
      end
    end

    test 'index action' do
      get :index, redirect: root_url, locale: @locale
      assert_redirected_to backend_activities_url
    end
  end
end
