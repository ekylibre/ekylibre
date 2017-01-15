require 'test_helper'

class UseMapBackgroundsTest < CapybaraIntegrationTest
  setup do
    login_with_user
  end

  teardown do
    Warden.test_reset!
  end

  def load_defaults
    visit('/backend/map_backgrounds')
    assert_selector '.map-background-container', count: MapBackgrounds::Layer.items.count
  end

  def check_enabled_map_backgrounds
    visit('/backend/land-parcels')
    page.execute_script("$(\"*[data-toggle='face'][href='map']\").trigger('click');")
    assert_selector '[name="leaflet-base-layers"]', visible: false, count: MapBackground.where(enabled: true).count
  end

  test 'loading defaults' do
    load_defaults
    check_enabled_map_backgrounds
  end

  test 'enabling a map background' do
    count_before = MapBackground.availables.size

    visit('/backend/map_backgrounds')
    first('div.map-background:not(.active)').click
    sleep(1)

    assert_equal count_before + 1, MapBackground.availables.size

    check_enabled_map_backgrounds
  end
end
