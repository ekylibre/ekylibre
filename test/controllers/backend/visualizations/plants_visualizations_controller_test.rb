require 'test_helper'
module Backend
  module Visualizations
    class PlantsVisualizationsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
      setup do
        # Ekylibre::Tenant.switch!('test')
        # @locale = ENV['LOCALE'] || I18n.default_locale
        @user = users(:users_001)
        @user.update_column(:language, I18n.locale)
        sign_in(@user)
      end

      teardown do
        sign_out(@user)
      end

      test 'async loading plants visualization' do
        campaign = Campaign.first
        plants = Plant.of_campaign(campaign).order(born_at: :asc)
        expected_plants_count = plants.count

        get :show, params: { current_campaign: campaign.harvest_year, format: :json }, xhr: true
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
