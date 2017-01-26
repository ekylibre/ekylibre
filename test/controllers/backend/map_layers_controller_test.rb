require 'test_helper'

module Backend
  class MapLayersControllerTest < ActionController::TestCase
    setup do
      Ekylibre::Tenant.switch!('test')
      @locale = ENV['LOCALE'] || I18n.default_locale
      @user = users(:users_001)
      sign_in(@user)
    end

    test 'loading defaults' do
      MapLayer.destroy_all
      assert_difference 'MapLayer.count', Map::Layer.items.count do
        post :load
      end
      assert_redirected_to backend_map_layers_path
    end

    test 'toggling activation' do
      m = MapLayer.available_backgrounds.first
      state = m.enabled
      post :toggle, id: m.id, format: :json
      assert_equal !state, m.reload.enabled
    end

    test 'toggling by_default' do
      m = MapLayer.available_backgrounds.second
      state = m.by_default
      put :star, id: m.id
      assert_equal !state, m.reload.by_default
    end

    teardown do
      sign_out(@user)
    end
  end
end
