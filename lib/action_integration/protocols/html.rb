module ActionIntegration
  module Protocols
    # Basic HTML Get operation.
    module HTML
      include Protocols::RestBase

      def get(path, headers = {}, &block)
        get_base(path, headers, &block)
      end
    end
  end
end
