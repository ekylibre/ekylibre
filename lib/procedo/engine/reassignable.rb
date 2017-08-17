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
        update_intervention(@attributes,value) if attribute == "working_zone"          
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

      def update_intervention(attributes,value)
        InterventionProductParameter.find(attributes[:id]).update(working_zone: value) rescue ""
      end
    end
  end
end