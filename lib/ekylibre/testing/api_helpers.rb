module Ekylibre
  module Testing
    module ApiHelpers
      def json_response
        JSON.parse(response.body)
      end
    end
  end
end
