require 'test_helper'

module Backend
  class ActivitiesControllerTest < ActionController::TestCase
    test_restfully_all_actions family: { mode: :index, name: :mussel_farming, format: :json }, except: :show

    test 'show action' do
      get :show, id: 'NaID', redirect: root_url, locale: @locale
      assert_redirected_to root_url
      Activity.limit(5).find_each do |record|
        get :show, id: record.id, locale: @locale
        if record.plant_farming?
          assert_redirected_to backend_vegetal_activity_url(record)
        else
          assert_response :success
          assert_not_nil assigns(:activity)
        end
      end
    end
  end
end
