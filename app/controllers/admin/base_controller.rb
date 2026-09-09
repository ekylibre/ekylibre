class Admin::BaseController < ActionController::Base
  # The admin panel runs outside any tenant context and can create, drop and
  # restore tenants. It must never be reachable with built-in credentials.
  MINIMUM_PASSWORD_LENGTH = 16

  before_action :ensure_admin_credentials_configured!
  before_action :authenticate_admin!
  layout 'admin'

  class << self
    # @return [Boolean] true when both credentials are set and the password is
    #   long enough to be worth protecting a tenant-wide RCE surface.
    def credentials_configured?
      username = ENV['ADMIN_USERNAME'].to_s
      password = ENV['ADMIN_PASSWORD'].to_s
      username.present? && password.length >= MINIMUM_PASSWORD_LENGTH
    end
  end

  private

    # Fail closed: with no credentials configured, the panel is unavailable
    # rather than open.
    def ensure_admin_credentials_configured!
      return if self.class.credentials_configured?

      Rails.logger.error(
        '[Admin] Refusing access: ADMIN_USERNAME must be set and ADMIN_PASSWORD ' \
        "must be at least #{MINIMUM_PASSWORD_LENGTH} characters."
      )
      render plain: "Admin panel is not configured. Set ADMIN_USERNAME and an ADMIN_PASSWORD of at least #{MINIMUM_PASSWORD_LENGTH} characters.",
             status: :service_unavailable
    end

    def authenticate_admin!
      authenticate_or_request_with_http_basic('Ekylibre Admin') do |username, password|
        ActiveSupport::SecurityUtils.secure_compare(username, ENV.fetch('ADMIN_USERNAME')) &
          ActiveSupport::SecurityUtils.secure_compare(password, ENV.fetch('ADMIN_PASSWORD'))
      end
    end
end
