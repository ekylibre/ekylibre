require 'test_helper'

module Backend
  class DukeWidgetControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    setup_sign_in

    test 'config returns json with token, tenant, ws_url' do
      get :show
      assert_response :ok
      json = JSON.parse(response.body)

      assert_equal %w[locale tenant token user ws_url].sort, json.keys.sort
      assert json['token'].present?, 'token must be set'
      assert json['tenant'].present?, 'tenant must be set'
      assert json['ws_url'].start_with?('ws://') || json['ws_url'].start_with?('wss://')
      assert json['user']['email'].present?
    end

    test 'config requires authentication' do
      sign_out(@user)
      get :show
      # Devise either redirects (HTML) or returns 401 (JSON). Either is fine
      # as long as anonymous users do not get a token.
      assert_includes [302, 401], response.status
      refute response.body.include?('"token":'), 'token must not leak to anonymous'
    end

    test 'config respects DUKE_WS_URL env override' do
      original = ENV['DUKE_WS_URL']
      ENV['DUKE_WS_URL'] = 'wss://duke.example.com/ws'
      begin
        get :show
        assert_response :ok
        assert_equal 'wss://duke.example.com/ws', JSON.parse(response.body)['ws_url']
      ensure
        ENV['DUKE_WS_URL'] = original
      end
    end
  end
end
