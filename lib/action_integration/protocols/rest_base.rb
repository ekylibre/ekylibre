require 'net/https'

module ActionIntegration
  module Protocols
    # Methods used by every other protocol
    module RestBase
      private

      def get_base(path, headers = {}, &block)
        action_base(path, nil, Net::HTTP::Get, headers, &block)
      end

      def post_base(path, data, headers = {}, &block)
        action_base(path, data, Net::HTTP::Post, headers, &block)
      end

      def put_base(path, data, headers = {}, &block)
        action_base(path, data, Net::HTTP::Put, headers, &block)
      end

      def patch_base(path, data, headers = {}, &block)
        action_base(path, data, Net::HTTP::Patch, headers, &block)
      end

      def delete_base(path, &block)
        action_base(path, nil, Net::HTTP::Delete, &block)
      end

      def action_base(path, data, action_class, headers = {}, &block)
        url = URI.parse(path)
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true if url.scheme == 'https'

        request = action_class.new(url)
        request.body = data.to_json if data
        # request.content_type = headers['content-type'] if headers['content-type']
        headers.each do |key, value|
          request[key] = value
        end

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
