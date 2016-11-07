module ActionIntegration
  module Protocols
    # Methods to do calls with Savon.
    module Savon
      # Sets up the format to SOAP so it's not saved as a "savon" format request.
      FORMAT = :soap

      def authenticate(options, message = {})
        request(:authenticate, options, message)
      end

      def call(operation, options, message = {}, &block)
        request(operation, options, message, &block)
      end

      private

      def request(operation, options, message = {})
        client = ::Savon.client(options[:globals])

        request_log = CallRequest.create_from_savon_httpi_request!(
          client.build_request(operation, options[:locals].merge(message: message)),
          @format
        )
        messages << request_log

        response = client.call(operation, options[:locals].merge(message: message))

        messages << CallResponse.create_from_savon_httpi_response!(
          response.http,
          request_log
        )

        res = ActionIntegration::Response.new_from_savon(response)
        yield res if block_given?
        res
      end
    end
  end
end
