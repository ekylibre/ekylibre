# require 'procedo/engine/intervention_product_parameter'

module Procedo
  module Engine
    class InterventionOutput < Procedo::Engine::InterventionProductParameter
      attr_reader :variant

      def initialize(intervention, id, attributes = {})
        super(intervention, id, attributes)
        if @attributes[:variant_id].present?
          @variant = ProductNatureVariant.find_by(id: @attributes[:variant_id])
        end
      end

      def to_hash
        hash = super
        hash[:variant_id] = @variant ? @variant.id : nil
        hash
      end
    end
  end
end
