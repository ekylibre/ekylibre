module Procedo
  module Engine
    module Reassignable
      extend ActiveSupport::Concern

      # Assign value if different
      def assign(attribute, value)
        assign!(attribute, value) if value != send(attribute)
      end

      # Assign value in all cases
      def assign!(attribute, value)
        send(attribute.to_s + '=', value)
      end

      # Re-assign value if different
      def reassign(attribute)
        assign(attribute, send(attribute))
      end

      # Re-assign value in all cases
      def reassign!(attribute)
        assign!(attribute, send(attribute))
      end
    end
  end
end
