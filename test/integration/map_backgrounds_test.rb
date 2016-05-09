require 'test_helper'

class MapBackgroundsTest < CapybaraIntegrationTest
  setup do
    # FIXME: use locale param instead of user language
    I18n.locale = @locale = ENV['LOCALE'] || I18n.default_locale
    login_with_user
  end

  teardown do
    Warden.test_reset!
  end

  def load_defaults
    MapBackground.destroy_all
    visit('/backend/map_backgrounds')
    # assert has_no_selector?('.map-backgrounds-viewport .map-background-container')
    click_on :load.ta
    assert_selector '.map-background-container', count: MapBackgrounds::Layer.items.count
  end

  def check_enabled_map_backgrounds
    visit('/backend/land_parcels')
    assert_selector '[name=leaflet-base-layers]', count: MapBackground.availables.size
  end

  test 'loading defaults' do
    load_defaults
    check_enabled_map_backgrounds
  end

  test 'enabling a map background' do
    load_defaults

    count_before = MapBackground.availables.size

    visit('/backend/map_backgrounds')
    first("a.map-background-display:not('.active')").click

    assert_equal count_before + 1, MapBackground.availables.size

    check_enabled_map_backgrounds
  end
end
