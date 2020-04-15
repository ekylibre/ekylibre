require 'test_helper'
module Backend
  module Visualizations
    class LandParcelsVisualizationsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
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

      test 'async loading land parcels visualization' do
        land_parcels = LandParcel.supports_of_campaign(@user.current_campaign).all
        expected_land_parcels_count = land_parcels.count

        get :show, xhr: true, format: :json
        r = JSON.parse(@response.body)

        assert r.key? 'series'
        assert r['series'].key? 'main'
        assert_equal expected_land_parcels_count, r['series']['main'].count

        geo = Charta.new_geometry(land_parcels.first.shape)

        assert_equal land_parcels.first.name, r['series']['main'].first['name']
        assert_equal geo.transform(:WGS84), Charta.new_geometry(r['series']['main'].first['shape'])
      end
    end
  end
end
