require 'test_helper'

module Backend
  class ActivitiesControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions duplicate: { params: { source_activity_id: 1 } },
                               except: %i[show compute_pfi_report add_itk_on_activities generate_budget]

    test 'show action' do
      get :show, params: { id: 'NaID', redirect: root_url, locale: @locale }
      assert_redirected_to root_url
      Activity.limit(5).find_each do |record|
        get :show, params: { id: record.id, locale: @locale }
        assert_response :success
        assert_not_nil assigns(:activity)
      end
    end

    test 'show action with inspections displays the inspection chart' do
      inspected_activity = create :corn_activity, :fully_inspectable
      get :show, params: { id: inspected_activity.id, locale: @locale }
      assert_response :success
      assert_select 'div.cobble-stock-in-ground'

      activity_wo_inspections = create :corn_activity
      get :show, params: { id: activity_wo_inspections.id, locale: @locale }
      assert_response :success
      assert_select 'div.cobble-stock-in-ground', count: 0
    end

    # Uncomment when action cable becomes testable

    # test 'generate_budget action' do
    #   activity = create :activity
    #   post :generate_budget, params: { id: activity.id }
    #   assert_redirect
    # end
  end
end
