require 'test_helper'

module Backend
  class MapEditorShapesControllerTest < ActionController::TestCase
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

    test 'async loading of land_parcel shapes' do
      started_at = LandParcel.first.created_at
      current_land_parcels = LandParcel.at(started_at).count
      current_layer = :land_parcels

      get :index, layers: [current_layer], started_at: started_at, xhr: true, format: :json
      r = JSON.parse(@response.body)['show']

      # Checks if land parcels layers is loaded
      assert_equal 1, r['layers'].count
      layer = r['layers'].first
      assert_equal current_layer.to_s, layer['name']

      # Checks if land parcel serie is loaded and filled with land parcel shapes
      serie_name = layer['serie']
      assert r['series'].key? serie_name

      assert_equal current_land_parcels, r['series'][serie_name]['features'].count
    end

    test 'async loading of plant shapes' do
      started_at = Plant.first.created_at
      current_plants = Plant.at(started_at).count
      current_layer = :plants

      get :index, layers: [current_layer], started_at: started_at, xhr: true, format: :json
      r = JSON.parse(@response.body)['show']

      # Checks if plant layers is loaded
      assert_equal 1, r['layers'].count
      layer = r['layers'].first
      assert_equal current_layer.to_s, layer['name']

      # Checks if plant serie is loaded and filled with plant shapes
      serie_name = layer['serie']
      assert r['series'].key? serie_name

      assert_equal current_plants, r['series'][serie_name]['features'].count
    end
  end
end
