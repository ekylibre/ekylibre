module ActionCaller
  module Protocols
    # Methods used by every other protocol
    module Base
      private
      def get_base(path)
        url = URI.parse(path)
        http = Net::HTTP.new(url.host, url.port)
        request = Net::HTTP::Get.new(url.path)

        response = execute_request(http, request)

        yield (ActionCaller::Response.new(response))
      end

      def post_base(path, data, &block)
        yield(push_base(path, data, :post, &block))
      end

      def put_base(path, data, &block)
        yield(push_base(path, data, :put, &block))
      end

      def patch_base(path, data, &block)
        yield(push_base(path, data, :patch, &block))
      end

      def push_base(path, data, action)
        url = URI.parse(path)
        http = Net::HTTP.new(url.host, url.port)

        action_class = "Net::HTTP::#{action.to_s.camelize}".constantize
        request = action_class.new(url.path, ::JSON.parse(data.to_json))
        request.body = data.to_json

        response = execute_request(http, request)

        ActionCaller::Response.new(response)
      end

      def delete_base(path)
        url = URI.parse(path)
        http = Net::HTTP.new(url.host, url.port)
        request = Net::HTTP::Delete.new(url.path)

        response = execute_request(http, request)

        yield(ActionCaller::Response.new(response))
      end

      def execute_request(http, request)
        request_log = CallRequest.create_from_net_request!(http, request, @format)
        messages << request_log
        Rails.logger.info "Launching #{@format.to_s.upcase} request."

        response = http.request(request)

        response_log = CallResponse.create_from_net_response!(response, request_log)
        messages << response_log
        Rails.logger.info "#{response_log.format.upcase} response received."

        response
      end
    end
  end
end
