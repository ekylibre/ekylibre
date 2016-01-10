# require 'procedo/engine/intervention/parameter'

module Procedo
  module Engine
    class Intervention
      class ProductParameter < Procedo::Engine::Intervention::Parameter
        attr_reader :product, :working_zone

        delegate :get, to: :product

        def initialize(intervention, id, attributes = {})
          super(intervention, id, attributes)
          if @attributes[:product_id].present?
            @product = Product.find_by(id: @attributes[:product_id])
          end
          if attributes[:working_zone].present?
            @working_zone = Charta.from_geojson(attributes[:working_zone])
          end
        end

        def product_id
          @product ? @product.id : nil
        end

        def product=(record)
          self.product_id = record.id
        end

        def product_id=(id)
          @product = Product.find_by(id: id)
          impact_on_attributes(:product)
        end

        def working_zone=(value)
          @working_zone = Charta.new_geometry(value)
          impact_on_attributes(:working_zone)
        end

        def to_hash
          hash = { reference_name: @reference.name }
          hash[:product_id] = @product ? @product.id : nil
          hash[:working_zone] = @working_zone ? @working_zone.to_json : nil
          hash
        end

        def impact_with(steps)
          fail 'Invalid steps: ' + steps.inspect if steps.size != 1
          impact(steps.first)
        end

        # Impact changes on attributes of parameter based on given field
        def impact_on_attributes(field)
          reference.attributes.each do |attribute|
            # Default value
            if attribute.default_value? &&
               attribute.default_value_with_environment_variable?(field)
              send(attribute.name.to_s + '=', attribute_default_value(attribute))
            end
            # Value
            if attribute.value? && attribute.value_with_environment_variable?(field)
              send(attribute.name.to_s + '=', attribute_value(attribute))
            end
          end
        end

        # Compute value of given attribute
        def attribute_value(attribute, env = {})
          return nil unless attribute.value?
          intervention.interpret(attribute.value_tree, env.merge(self: self, product: product))
        end

        # Compute default-value of given attribute
        def attribute_default_value(attribute, env = {})
          return nil unless attribute.default_value?
          intervention.interpret(attribute.default_value_tree, env.merge(self: self, product: product))
        end

        # Test if a handler is usable
        def usable_handler?(handler, env = {})
          return true unless handler.condition?
          intervention.interpret(handler.condition_tree, env.merge(self: self, product: product))
        end
      end
    end
  end
end
