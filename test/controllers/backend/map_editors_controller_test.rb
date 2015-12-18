require 'test_helper'
module Backend
  class MapEditorsControllerTest < ActionController::TestCase
    test 'upload JSON' do
      geometry = file_upload('map.geojson', 'application/json')
      post :upload, importer_format: :json, import_file: geometry
    end

    test 'upload KML' do
      geometry = file_upload('map.kml', 'application/vnd.google-earth.kml+xm')
      post :upload, importer_format: :kml, import_file: geometry
    end
  end
end
