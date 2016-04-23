require 'test_helper'

class MapBackgroundsTest < CapybaraIntegrationTest
  setup do
    I18n.locale = @locale = ENV['LOCALE'] || I18n.default_locale
    visit("/authentication/sign_in?locale=#{@locale}")
    login_as(users(:users_001), scope: :user)
  end

  teardown do
    Warden.test_reset!
  end

  test 'loading defaults' do
    visit('/backend/map_backgrounds')
    assert has_no_selector?('.map-backgrounds-viewport .map-background-container')
    click_on :load.tl
    assert_selector '.map-background-container', count: MapBackgrounds::Layer.items.count
  end

  test 'loading map backgrounds with defaults' do

    visit('/backend/land_parcels')
    assert_selector '[name=leaflet-base-layers]', count: MapBackground.availables
  end

  test 'enabling a map background' do

    visit('/backend/map_backgrounds')
    count_before = MapBackground.availables

    first("a.map-background-display:not('.active')").click

    assert_equal count_before+1, MapBackground.availables

    visit('/backend/land_parcels')
    assert_selector '[name=leaflet-base-layers]', count: MapBackground.availables
  end

end
