# frozen_string_literal: true

require 'test_helper'

module Admin
  # The admin panel runs outside any tenant context and can create, drop and
  # restore tenants. It used to accept `admin` / `admin` whenever the
  # environment did not set ADMIN_USERNAME / ADMIN_PASSWORD, which put the
  # tenant restore path (a shell command built around an uploaded filename)
  # behind a documented default.
  class BaseControllerTest < ActionController::TestCase
    tests Admin::TenantsController

    setup do
      @previous = ENV.to_hash.slice('ADMIN_USERNAME', 'ADMIN_PASSWORD')
    end

    teardown do
      %w[ADMIN_USERNAME ADMIN_PASSWORD].each { |key| ENV.delete(key) }
      @previous.each { |key, value| ENV[key] = value }
    end

    test 'refuses to serve the panel when no credentials are configured' do
      ENV.delete('ADMIN_USERNAME')
      ENV.delete('ADMIN_PASSWORD')

      get :index

      assert_response :service_unavailable
      assert_not_equal 401, response.status,
                       'a 401 would mean the panel is live and merely asking for a password'
    end

    test 'refuses to serve the panel when the password is too short' do
      ENV['ADMIN_USERNAME'] = 'operator'
      ENV['ADMIN_PASSWORD'] = 'admin'

      get :index

      assert_response :service_unavailable
    end

    test 'never accepts the historical admin/admin default' do
      ENV.delete('ADMIN_USERNAME')
      ENV.delete('ADMIN_PASSWORD')
      request.env['HTTP_AUTHORIZATION'] =
        ActionController::HttpAuthentication::Basic.encode_credentials('admin', 'admin')

      get :index

      assert_response :service_unavailable
    end

    test 'challenges for credentials once configured' do
      ENV['ADMIN_USERNAME'] = 'operator'
      ENV['ADMIN_PASSWORD'] = 'a' * Admin::BaseController::MINIMUM_PASSWORD_LENGTH

      get :index

      assert_response :unauthorized
    end

    test 'credentials_configured? requires a long enough password' do
      ENV['ADMIN_USERNAME'] = 'operator'

      ENV['ADMIN_PASSWORD'] = 'a' * (Admin::BaseController::MINIMUM_PASSWORD_LENGTH - 1)
      assert_not Admin::BaseController.credentials_configured?

      ENV['ADMIN_PASSWORD'] = 'a' * Admin::BaseController::MINIMUM_PASSWORD_LENGTH
      assert Admin::BaseController.credentials_configured?

      ENV.delete('ADMIN_USERNAME')
      assert_not Admin::BaseController.credentials_configured?
    end
  end
end
