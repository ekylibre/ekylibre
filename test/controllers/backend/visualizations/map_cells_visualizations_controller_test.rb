require 'test_helper'
module Backend
  module Visualizations
    class MapCellsVisualizationsControllerTest < ActionController::TestCase
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

      test 'async loading map cells visualization' do
        productions = ActivityProduction.of_campaign(@user.current_campaign)
        expected_productions_count = productions.count

        get :show, campaigns: @user.current_campaign, visualization: 'grain_yield', xhr: true, format: :json
        r = JSON.parse(@response.body)

        assert r.key? 'series'
        assert r['series'].key? 'main'
        assert_equal expected_productions_count, r['series']['main'].count

        geo = Charta.new_geometry(productions.first.support_shape)

        assert_equal productions.first.name, r['series']['main'].first['name']
        assert_equal geo.transform(:WGS84), Charta.new_geometry(r['series']['main'].first['shape'])
      end
    end
  end
end
