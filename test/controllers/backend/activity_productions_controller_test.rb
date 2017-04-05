require 'test_helper'

module Backend
  class ActivityProductionsControllerTest < ActionController::TestCase
    test_restfully_all_actions new: { params: { activity_id: 1, campaign_id: 6 } }, index: :redirected_get, except: :create

    test 'create action' do
      activity_production = activity_productions(:activity_productions_001)
      attribute_names = %i[
        size_value size_indicator_name size_unit_name
        cultivable_zone_id support_shape support_nature
        irrigated nitrate_fixing usage
        started_on stopped_on state rank_number custom_fields
      ]
      attributes = activity_production.attributes.symbolize_keys
                                      .slice(attribute_names)
      post :create, params: { activity_production: attributes.merge(activity_id: 1, campaign_id: 6), locale: @locale }
    end
  end
end
