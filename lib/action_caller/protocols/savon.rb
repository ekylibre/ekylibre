module ActionCaller
  module Protocols
    # Methods to do calls with Savon.
    # TODO: Actually implement it.
    module Savon
      # Sets up the format to SOAP so it's not saved as a "savon" format request.
      FORMAT = :soap

      def call(operation, message, options)
        client = Savon.client(options)
        response = client.call(operation, message)
        request_log = CallRequest.create_from_savon!(operation, message, client, @format)
        messages << resquest_log
        messages << CallResponse.create_from_savon!(response, request_log, @format)
      end
    end
  end
end
