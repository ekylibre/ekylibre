require 'test_helper'
module Backend
  class MapEditorsControllerTest < ActionController::TestCase
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

    test 'upload JSON' do
      geometry = file_upload('map.geojson', 'application/json')
      post :upload, importer_format: :geojson, import_file: geometry, format: :json
    end

    test 'upload KML' do
      geometry = file_upload('map.kml', 'application/vnd.google-earth.kml+xml')
      post :upload, importer_format: :kml, import_file: geometry, format: :json
    end

    test 'upload GML' do
      geometry = file_upload('map.gml', 'application/xml')
      post :upload, importer_format: :gml, import_file: geometry, format: :json
    end
  end
end
