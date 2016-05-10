require 'test_helper'

class Backend::MapBackgroundsControllerTest < ActionController::TestCase
  setup do
    Ekylibre::Tenant.switch!('test')
    @locale = ENV['LOCALE'] || I18n.default_locale
    @user = users(:users_001)
    sign_in(@user)
  end

  test 'loading defaults' do
    MapBackground.destroy_all
    assert_difference 'MapBackground.count', MapBackgrounds::Layer.items.count do
      post :load
    end
    assert_redirected_to backend_map_backgrounds_path
  end

  test 'toggling activation' do
    m = MapBackground.first
    state = m.enabled
    put :toggle, id: m.id
    assert_equal !state, m.reload.enabled
  end

  test 'toggling by_default' do
    m = MapBackground.first
    state = m.by_default
    put :star, id: m.id
    assert_equal !state, m.reload.by_default
  end

  teardown do
    sign_out(@user)
  end
end
