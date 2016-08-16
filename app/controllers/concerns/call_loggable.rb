module CallLoggable
  extend ActiveSupport::Concern

  included do
    before_action :log_request
    hide_action :log_request

    after_action :log_response
    hide_action :log_response
  end

  def log_request
    @call_log_request = CallRequest.create_from_request!(request)
  end

  def log_response
    CallResponse.create_from_response!(response, @call_log_request)
  end
end
