module Procedo
  module Engine
    class Intervention
      class Quantified < Procedo::Engine::Intervention::ProductParameter
        attr_reader :quantity_handler, :quantity_population, :quantity_value

        def initialize(intervention, id, attributes = {})
          super(intervention, id, attributes)
          @quantity_handler = attributes[:quantity_handler]
          @quantity_value = attributes[:quantity_value].to_d if attributes[:quantity_value]
          @quantity_population = attributes[:quantity_population].to_d if attributes[:quantity_population]
        end

        def to_hash
          hash = super
          hash[:quantity_handler] = @quantity_handler if @quantity_handler
          hash[:quantity_value] = @quantity_value.to_s.to_f unless @quantity_value.nil?
          hash[:quantity_population] = @quantity_population.to_s.to_f unless @quantity_population.nil?
          hash
        end

        def to_attributes
          hash = super
          hash[:quantity_handler] = @quantity_handler if @quantity_handler
          hash[:quantity_value] = @quantity_value.to_s.to_f unless @quantity_value.nil?
          hash[:quantity_population] = @quantity_population.to_s.to_f unless @quantity_population.nil?
          hash
        end

        def handlers_states
          reference.handlers.each_with_object({}) do |handler, hash|
            hash[handler.name] = usable_handler?(handler)
          end
        end

        def quantity_handler_reference
          @quantity_handler ? reference.handler(@quantity_handler) : nil
        end

        # On handler change, only value is affected, population still
        # remains equal.
        def quantity_handler=(handler)
          rh = reference.handler(handler)
          raise 'Invalid handler: ' + handler.inspect unless rh
          unless usable_handler?(rh)
            rh = reference.handlers.detect { |h| usable_handler?(h) }
            handler = rh.name.to_s if rh
          end
          @quantity_handler = handler
          return unless @quantity_population
          @quantity_value = compute_value if quantity_handler_reference.backward?
        end

        # On population change, only value is affected, handler still
        # remains equal. No more impact on value
        def quantity_population=(population)
          @quantity_population = population
          @quantity_handler ||= reference.handlers.first.name if reference.handlers.first
          return unless quantity_handler_reference
          @quantity_value = compute_value if quantity_handler_reference.backward?
          impact_dependencies! :population
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
            impact_dependencies! :population
          end
        end

        def impact_dependencies!(field)
          super(field)
          impact_on_handlers(field)
        end

        # Checks that handler is always valid and fix it if possible
        def impact_on_handlers(_field)
          rh = reference.handler(@quantity_handler) if @quantity_handler.present?
          unless @quantity_handler && usable_handler?(rh)
            rh = reference.handlers.detect { |h| usable_handler?(h) }
            self.quantity_handler = rh.name.to_s if rh
          end
        end

        def compute_value
          ref = quantity_handler_reference
          intervention.interpret(ref.backward_tree, env).round(4)
        end

        def compute_population
          ref = quantity_handler_reference
          intervention.interpret(ref.forward_tree, env).round(4)
        end

        def env
          super.merge(value: quantity_value, population: quantity_population)
        end
      end
    end
  end
end
