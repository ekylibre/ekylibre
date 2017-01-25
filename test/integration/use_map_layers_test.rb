require 'test_helper'

class UseMapLayersTest < CapybaraIntegrationTest
  setup do
    login_with_user
  end

  teardown do
    Warden.test_reset!
  end

  test 'loading defaults' do
    load_defaults
    check_enabled_map_backgrounds
  end

  test 'enabling a map background' do
    count_before = MapLayer.available_backgrounds.size

    visit('/backend/map-layers')
    first('div.map-background:not(.active)').click
    sleep(1)

    assert_equal count_before + 1, MapLayer.available_backgrounds.size

    check_enabled_map_backgrounds
  end

  def load_defaults
    visit('/backend/map-layers')
    assert_selector '.map-background-container', count: Map::Layer.count
  end

  def check_enabled_map_backgrounds
    visit('/backend/land-parcels')
    page.execute_script("$(\"*[data-toggle='face'][href='map']\").trigger('click');")
    assert_selector '[name="leaflet-base-layers"]', visible: false, count: MapLayer.available_backgrounds.count
  end
end
