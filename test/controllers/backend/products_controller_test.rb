require 'test_helper'
module Backend
  class ProductsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    # TODO: Re-activate #show and #edit tests
    test_restfully_all_actions except: %i[show edit update_many sort_by_time_use]

    test 'update_many' do
      activity = create(:activity)
      activity_production = create(:activity_production, activity: activity)
      land_parcel = create(:land_parcel)
      put :update_many, params: {
        activity_id: activity.id,
        target_distributions: { land_parcel.id.to_s => { target_id: land_parcel.id, activity_production_id: activity_production.id } }
      }
      assert_equal activity_production.id, LandParcel.find(land_parcel.id).activity_production_id
    end
  end
end
