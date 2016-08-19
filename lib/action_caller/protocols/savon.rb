module ActionCaller
  module Protocols
    # Methods to do calls with Savon.
    # TODO: Actually implement it.
    module Savon
      include Protocols::Base

      # Sets up the format to SOAP so it's not saved as a "savon" format request.
      FORMAT = :soap

      def get(path)
        path
      end

      def post
        raise NotImplementedError
      end

      def put
        raise NotImplementedError
      end

      def patch
        raise NotImplementedError
      end

      def delete
        raise NotImplementedError
      end
    end
  end
end
