require 'test_helper'
module Backend
  class NamingFormatLandParcelsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions except: %i[build index create update destroy show]
    setup do
      NamingFormatLandParcel.load_defaults
    end

    test 'action index' do
      get :index
      assert_response :success
    end

    test 'get #build' do
      activity = Activity.find(1)
      custom_name = "custom name"
      expected_name = [CultivableZone.find(1).name,
                       activity.name,
                       Campaign.find(1).name,
                       custom_name,
                       "##{activity.productions_next_rank_number}"].join(' ')
      get :build, { activity_id: 1, cultivable_zone_id: 1, campaign_id: 1, free_field: custom_name }
      assert_response :success
      assert_equal "La Boutanche Blé tendre 2013 custom name #6", JSON.parse(response.body)["name"], 'should return the right name'
      assert JSON.parse(response.body)["has_free_field"], '#has_free_field? should return true'
    end
  end
end
