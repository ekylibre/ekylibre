require 'procedo/engine/parameter'

module Procedo
  module Engine
    class ProductParameter < Procedo::Engine::Parameter
      def initialize(intervention, id, attributes = {})
        super(intervention, id, attributes)
        if @attributes[:product_id].present?
          @product = Product.find(@attributes[:product_id])
        end
      end

      def to_hash
        hash = { reference_name: @reference.name }
        hash[:product_id] = @product.id if @product
        hash
      end
    end
  end
end
