module ::Rack
  class Lint
    alias check_status_orig check_status
    alias check_headers_orig check_headers
    alias check_content_type_orig check_content_type
    alias check_content_length_orig check_content_length
    alias check_hijack_orig check_hijack
    alias _call_orig _call

    def _call(env)
      @web_socket = env['REQUEST_PATH'] == '/cable'
      _call_orig(env)
    end

    def check_status(status)
      return if @web_socket

      check_status_orig(status)
    end

    def check_headers(headers)
      return if @web_socket

      check_headers_orig(headers)
    end

    def check_content_type(status, headers)
      return if @web_socket

      check_content_type_orig(status, headers)
    end

    def check_content_length(status, headers)
      return if @web_socket

      check_content_type_orig(status, headers)
    end

    def check_hijack(env)
      # Don't know why, but HijackWrapper break WebSocket!
      return if @web_socket

      check_hijack_orig(env)
    end
  end
end
