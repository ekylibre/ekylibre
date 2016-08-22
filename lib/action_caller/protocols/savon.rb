module ActionCaller
  module Protocols
    # Methods to do calls with Savon.
    module Savon
      # Sets up the format to SOAP so it's not saved as a "savon" format request.
      FORMAT = :soap

      def authenticate(options, message = {})
        request(:authenticate, message, options)
      end

      def call(operation, options, message = {})
        request(operation, message, options)
      end

      private

      def request(operation, options, message = {})
        client = Savon.client(options)

        request_log = CallRequest.create_from_savon_httpi_request!(
          s.build_request(operation, message: message),
          @format
        )
        messages << request_log

        response = client.call(operation, message: message)

        messages << CallResponse.create_from_savon_httpi_response!(
          response.http,
          request_log,
          @format
        )

        ActionCaller::Response.new_from_savon(response)
      end
    end
  end
end
