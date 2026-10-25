class Admin::BaseController < ActionController::Base
  before_action :authenticate_admin!
  layout 'admin'

  private

  def authenticate_admin!
    authenticate_or_request_with_http_basic('Ekylibre Admin') do |username, password|
      ActiveSupport::SecurityUtils.secure_compare(username, ENV.fetch('ADMIN_USERNAME', 'admin')) &
        ActiveSupport::SecurityUtils.secure_compare(password, ENV.fetch('ADMIN_PASSWORD', 'admin'))
    end
  end
end
