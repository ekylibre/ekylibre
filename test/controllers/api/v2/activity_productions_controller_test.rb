require 'test_helper'
module Api
  module V2
    class ActivityProductionsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
      connect_with_token

      def returned_ids
        json_response['data'].map { |production| production['id'] }
      end

      def busiest_campaign
        Campaign.all.max_by { |campaign| ActivityProduction.of_campaign(campaign).count }
      end

      test '#index requires authentication' do
        @request.headers['Authorization'] = nil
        get :index, params: { campaign: busiest_campaign.harvest_year }
        assert_response :unauthorized
      end

      test '#index requires a valid campaign' do
        get :index, params: {}
        assert_response :bad_request
        assert(json_response['errors'].any? { |e| e.include?('campaign') })

        get :index, params: { campaign: 'last' }
        assert_response :bad_request
      end

      test '#index returns an empty list for an unknown campaign without creating it' do
        assert_no_difference 'Campaign.count' do
          get :index, params: { campaign: 1066 }
        end
        assert_response :ok
        assert_empty json_response['data']
        assert_equal 0, json_response['pagination']['total_elements']
      end

      test '#index returns the productions of the campaign' do
        campaign = busiest_campaign
        expected = ActivityProduction.of_campaign(campaign).reorder(:id).limit(50).pluck(:id)

        get :index, params: { campaign: campaign.harvest_year }
        assert_response :ok
        assert_equal expected, returned_ids
        assert_equal ActivityProduction.of_campaign(campaign).count, json_response['pagination']['total_elements']

        item = json_response['data'].first
        %w[id name started_on stopped_on state usage activity cultivation_variety cultivation_variety_name
           net_surface_area_value net_surface_area_unit support cultivable_zone target_product_ids].each do |key|
          assert item.key?(key), "Missing key #{key}"
        end
        %w[id name family nature production_cycle].each do |key|
          assert item['activity'].key?(key), "Missing activity key #{key}"
        end
      end

      test '#index exposes surface, support, zone and target products' do
        production = ActivityProduction.where.not(support_shape: nil).where.not(cultivable_zone_id: nil)
                                       .detect { |ap| ap.campaigns.any? }
        assert production, 'needs a production with a shape, a zone and a campaign in fixtures'

        get :index, params: { campaign: production.campaigns.first.harvest_year, cultivable_zone_id: production.cultivable_zone_id, per_page: 100 }
        assert_response :ok
        item = json_response['data'].detect { |p| p['id'] == production.id }
        assert item

        assert_equal production.activity_id, item['activity']['id']
        assert_equal production.activity.cultivation_variety, item['cultivation_variety']
        assert_equal 'hectare', item['net_surface_area_unit']
        assert_in_delta production.net_surface_area.to_d(:hectare).to_f, item['net_surface_area_value'], 0.0001
        assert_equal production.support_id, item['support']['id']
        assert_equal production.support.name, item['support']['name']
        assert_equal production.cultivable_zone_id, item['cultivable_zone']['id']
        assert_equal production.cultivable_zone.name, item['cultivable_zone']['name']
        assert_equal Product.where(activity_production: production).order(:id).pluck(:id), item['target_product_ids']
      end

      test '#index filters on activity_id' do
        campaign = busiest_campaign
        activity_id = ActivityProduction.of_campaign(campaign).group(:activity_id).count.max_by(&:last).first

        get :index, params: { campaign: campaign.harvest_year, activity_id: activity_id, per_page: 100 }
        assert_response :ok
        assert_equal ActivityProduction.of_campaign(campaign).where(activity_id: activity_id).reorder(:id).pluck(:id), returned_ids
        assert(json_response['data'].all? { |p| p['activity']['id'] == activity_id })

        get :index, params: { campaign: campaign.harvest_year, activity_id: Activity.maximum(:id) + 1000 }
        assert_response :ok
        assert_empty json_response['data']

        get :index, params: { campaign: campaign.harvest_year, activity_id: 'abc' }
        assert_response :bad_request
      end

      test '#index filters on cultivable_zone_id' do
        campaign = busiest_campaign
        zone_id = ActivityProduction.of_campaign(campaign).where.not(cultivable_zone_id: nil)
                                    .group(:cultivable_zone_id).count.max_by(&:last).first

        get :index, params: { campaign: campaign.harvest_year, cultivable_zone_id: zone_id, per_page: 100 }
        assert_response :ok
        assert_equal ActivityProduction.of_campaign(campaign).where(cultivable_zone_id: zone_id).reorder(:id).pluck(:id), returned_ids
        assert(json_response['data'].all? { |p| p['cultivable_zone']['id'] == zone_id })

        get :index, params: { campaign: campaign.harvest_year, cultivable_zone_id: '-1' }
        assert_response :bad_request
      end

      test '#index paginates' do
        campaign = busiest_campaign
        total = ActivityProduction.of_campaign(campaign).count
        assert total > 2, 'needs at least 3 productions in a campaign'

        get :index, params: { campaign: campaign.harvest_year, per_page: 2, page: 1 }
        first_page = returned_ids
        assert_equal 2, first_page.size
        assert_equal (total / 2.0).ceil, json_response['pagination']['page_count']

        get :index, params: { campaign: campaign.harvest_year, per_page: 2, page: 2 }
        assert_equal 2, json_response['pagination']['page']
        assert_empty first_page & returned_ids

        get :index, params: { campaign: campaign.harvest_year, per_page: 2, page: 10_000 }
        assert_response :ok
        assert_empty json_response['data']

        get :index, params: { campaign: campaign.harvest_year, per_page: 101 }
        assert_response :bad_request
      end
    end
  end
end
