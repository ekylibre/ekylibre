module ActionIntegration
  module Protocols
    # Methods used by every other protocol
    module RestBase
      private

      def get_base(path, &block)
        action_base(path, nil, :get, &block)
      end

      def post_base(path, data, options = {}, &block)
        action_base(path, data, :post, options, &block)
      end

      def put_base(path, data, options = {}, &block)
        action_base(path, data, :put, options, &block)
      end

      def patch_base(path, data, options = {}, &block)
        action_base(path, data, :patch, options, &block)
      end

      def delete_base(path, &block)
        action_base(path, nil, :delete, &block)
      end

      def action_base(path, data, action, options = {}, &block)
        url = URI.parse(path)
        http = Net::HTTP.new(url.host, url.port)

        action_class = "Net::HTTP::#{action.to_s.camelize}".constantize

        request = action_class.new(url)
        request.body = data.to_json if data
        request.content_type = options["content-type"] if options["content-type"]

        handle_request(http, request, &block)
      end

      # Sends request, sets up the response to be usable by the handling block and
      # returns the state of that response to be used by the outside call block.
      def handle_request(http, request)
        response = execute_request(http, request)
        response = ActionIntegration::Response.new_from_net(response)

        yield(response) if block_given?
        response
      end

      # Actually sends the HTTP request and logs both request and response.
      def execute_request(http, request)
        request_log = CallRequest.create_from_net_request!(http, request, @format)
        messages << request_log

        response = http.request(request)

        response_log = CallResponse.create_from_net_response!(response, request_log)
        messages << response_log

        # HTTPResponse
        response
      end
    end
  end
end
