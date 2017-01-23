require 'test_helper'

module Backend
  class ActivitiesControllerTest < ActionController::TestCase
    test_restfully_all_actions family: { mode: :index, name: :animal_farming, format: :json },
                               duplicate: { params: { source_activity_id: 1 } },
                               except: :show

    test 'show action' do
      get :show, id: 'NaID', redirect: root_url, locale: @locale
      assert_redirected_to root_url
      Activity.limit(5).find_each do |record|
        get :show, id: record.id, locale: @locale
        assert_response :success
        assert_not_nil assigns(:activity)
      end
    end
  end
end
