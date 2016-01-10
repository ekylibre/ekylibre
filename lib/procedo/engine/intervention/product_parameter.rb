# require 'procedo/engine/intervention/parameter'

module Procedo
  module Engine
    class Intervention
      class ProductParameter < Procedo::Engine::Intervention::Parameter
        attr_reader :product

        delegate :get, to: :product

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
          # Find and impact dependencies
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

        # Test if a handler is usable
        def usable_handler?(handler, env = {})
          intervention.interpret(handler.condition_tree, env.merge(self: product))
        end
      end
    end
  end
end
