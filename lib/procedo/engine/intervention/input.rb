# require 'procedo/engine/intervention/product_parameter'

module Procedo
  module Engine
    class Intervention
      class Input < Procedo::Engine::Intervention::ProductParameter
        attr_reader :quantity_handler, :quantity_population, :quantity_value

        def initialize(intervention, id, attributes = {})
          super(intervention, id, attributes)
          @quantity_handler = attributes[:quantity_handler]
          @quantity_value = attributes[:quantity_value].to_d
          @quantity_population = attributes[:quantity_population].to_d
        end

        def to_hash
          hash = super
          hash[:quantity_handler] = @quantity_handler
          hash[:quantity_value] = @quantity_value.to_s.to_f
          hash[:quantity_population] = @quantity_population.to_s.to_f
          hash
        end

        def quantity_handler_reference
          @quantity_handler ? reference.handler(@quantity_handler) : nil
        end

        # On handler change, only value is affected, population still
        # remains equal.
        def quantity_handler=(handler)
          rh = reference.handler(handler)
          fail 'Invalid handler: ' + handler.inspect unless rh
          unless usable_handler?(rh)
            # fail 'Unusable handler: ' + rh.name.inspect
            rh = reference.handlers.detect { |h| usable_handler?(h) }
            handler = rh.name if rh
          end
          @quantity_handler = handler
          return unless @quantity_population
          @quantity_value = compute_value if quantity_handler_reference.backward?
        end

        # On population change, only value is affected, handler still
        # remains equal. No more impact on value
        def quantity_population=(population)
          @quantity_population = population
          @quantity_handler ||= reference.handlers.first.name
          return unless quantity_handler_reference
          @quantity_value = compute_value if quantity_handler_reference.backward?
          impact_quantity_population!
        end

        # On value change, only population is affected, handler still
        # remains equal.
        def quantity_value=(value)
          @quantity_value = value
          return unless quantity_handler_reference
          if quantity_handler_reference.forward?
            population = compute_population
            return if @quantity_population == population
            @quantity_population = population
            impact_quantity_population!
          end
        end

        def compute_value
          ref = quantity_handler_reference
          env = { self: self, product: product, population: quantity_population, value: quantity_population }
          intervention.interpret(ref.backward_tree, env).round(4)
        end

        def compute_population
          ref = quantity_handler_reference
          env = { self: self, product: product, value: quantity_value }
          intervention.interpret(ref.forward_tree, env).round(4)
        end

        # Impact population change on foreign data
        def impact_quantity_population!
          puts 'Impact quantity population!'.red
        end
      end
    end
  end
end
