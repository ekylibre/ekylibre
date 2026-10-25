require 'test_helper'

module Backend
  class DukeWidgetControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    setup_sign_in

    test 'config returns json with token, tenant, ws_url' do
      get :show
      assert_response :ok
      json = JSON.parse(response.body)

      expected_keys = %w[locale stt_server_enabled stt_url tenant token user ws_url].sort
      assert_equal expected_keys, json.keys.sort
      assert json['token'].present?, 'token must be set'
      assert json['tenant'].present?, 'tenant must be set'
      assert json['ws_url'].start_with?('ws://') || json['ws_url'].start_with?('wss://')
      assert json['user']['email'].present?
    end

    test 'config defaults stt_server_enabled to false and omits stt_url' do
      original = ENV['DUKE_STT_SERVER_ENABLED']
      ENV['DUKE_STT_SERVER_ENABLED'] = nil
      begin
        get :show
        assert_response :ok
        json = JSON.parse(response.body)
        assert_equal false, json['stt_server_enabled']
        assert_nil json['stt_url']
      ensure
        ENV['DUKE_STT_SERVER_ENABLED'] = original
      end
    end

    test 'config exposes stt_url when DUKE_STT_SERVER_ENABLED is true' do
      original_enabled = ENV['DUKE_STT_SERVER_ENABLED']
      original_ws = ENV['DUKE_WS_URL']
      original_http = ENV['DUKE_HTTP_URL']
      ENV['DUKE_STT_SERVER_ENABLED'] = 'true'
      ENV['DUKE_WS_URL'] = 'wss://duke.example.com/ws'
      ENV['DUKE_HTTP_URL'] = nil
      begin
        get :show
        assert_response :ok
        json = JSON.parse(response.body)
        assert_equal true, json['stt_server_enabled']
        # Derived from DUKE_WS_URL by swapping the scheme and stripping `/ws`.
        assert_equal 'https://duke.example.com/api/v1/stt/transcribe', json['stt_url']
      ensure
        ENV['DUKE_STT_SERVER_ENABLED'] = original_enabled
        ENV['DUKE_WS_URL'] = original_ws
        ENV['DUKE_HTTP_URL'] = original_http
      end
    end

    test 'config honors explicit DUKE_HTTP_URL override for stt_url' do
      original_enabled = ENV['DUKE_STT_SERVER_ENABLED']
      original_http = ENV['DUKE_HTTP_URL']
      ENV['DUKE_STT_SERVER_ENABLED'] = 'true'
      ENV['DUKE_HTTP_URL'] = 'https://api.duke.example.com'
      begin
        get :show
        assert_response :ok
        json = JSON.parse(response.body)
        assert_equal 'https://api.duke.example.com/api/v1/stt/transcribe', json['stt_url']
      ensure
        ENV['DUKE_STT_SERVER_ENABLED'] = original_enabled
        ENV['DUKE_HTTP_URL'] = original_http
      end
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
