require 'test_helper'
module Backend
  module Visualizations
    class ResourcesVisualizationsControllerTest < ActionController::TestCase
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

      test 'async loading resources visualization' do
        resource_model = CultivableZone
        resource_name = resource_model.model_name.singular

        expected_cultivable_zones_count = resource_model.count

        get :show, resource_name: resource_name, xhr: true, format: :json
        r = JSON.parse(@response.body)

        assert r.key? 'series'
        assert r['series'].key? 'main'
        assert_equal expected_cultivable_zones_count, r['series']['main'].count

        geo = Charta.new_geometry(resource_model.first.shape)

        assert_equal resource_model.first.name, r['series']['main'].first['name']
        assert_equal geo.transform(:WGS84), Charta.new_geometry(r['series']['main'].first['shape'])

      end
    end
  end
end
