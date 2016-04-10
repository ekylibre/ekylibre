require 'test_helper'

class Backend::MapBackgroundsControllerTest < ActionController::TestCase
  setup do
    Ekylibre::Tenant.switch!('test')
    @locale = ENV['LOCALE'] || I18n.default_locale
    @user = users(:users_001)
    sign_in(@user)
  end

  test 'loading defaults' do
    assert_difference 'MapBackground.count', MapBackgrounds::Layer.items.count do
      post :load
    end
    assert_redirected_to backend_map_backgrounds_path
  end

  teardown do
    sign_out(@user)
  end

end
