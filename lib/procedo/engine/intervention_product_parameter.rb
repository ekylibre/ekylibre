# require 'procedo/engine/intervention_parameter'

module Procedo
  module Engine
    class InterventionProductParameter < Procedo::Engine::InterventionParameter
      attr_reader :product

      def initialize(intervention, id, attributes = {})
        super(intervention, id, attributes)
        if @attributes[:product_id].present?
          @product = Product.find_by(id: @attributes[:product_id])
        end
      end

      def product_id
        @product ? @product.id : nil
      end

      def product_id=(id)
        @product = Product.find_by(id: id)
      end

      def to_hash
        hash = { reference_name: @reference.name }
        hash[:product_id] = @product ? @product.id : nil
        hash
      end

      def impact_with(steps)
        fail 'Invalid steps: ' + steps.inspect if steps.size != 1
        impact(steps.first)
      end
    end
  end
end
