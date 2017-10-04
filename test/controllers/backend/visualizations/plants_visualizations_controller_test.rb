require 'test_helper'
module Backend
  module Visualizations
    class PlantsVisualizationsControllerTest < ActionController::TestCase
      setup do
        Ekylibre::Tenant.switch!('test')
        @locale = ENV['LOCALE'] || I18n.default_locale
        @user = users(:users_001)
        @user.update_column(:language, @locale)
        sign_in(@user)
      end

      teardown do
        sign_out(@user)
      end

      test 'async loading plants visualization' do
        campaign = Campaign.first
        plants = Plant.of_campaign(campaign).order(born_at: :asc)
        expected_plants_count = plants.count

        get :show, current_campaign: campaign.harvest_year, xhr: true, format: :json
        r = JSON.parse(@response.body)

        assert r.key? 'series'
        assert r['series'].key? 'main'
        assert_equal expected_plants_count, r['series']['main'].count

        geo = Charta.new_geometry(plants.first.shape)

        # Test data on first plant
        assert_equal plants.first.name, r['series']['main'].first['name']
        assert_equal geo.transform(:WGS84), Charta.new_geometry(r['series']['main'].first['shape'])
      end
    end
  end
end
