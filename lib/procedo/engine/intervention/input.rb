# require 'procedo/engine/intervention/product_parameter'

module Procedo
  module Engine
    class Intervention
      class Input < Procedo::Engine::Intervention::Quantified
        attr_reader :usage, :allowed_entry_factor, :allowed_harvest_factor
        attr_accessor :spray_volume_value

        def initialize(intervention, id, attributes = {})
          super(intervention, id, attributes)
          if @attributes[:usage_id].present?
            self.usage_id = @attributes[:usage_id]
          end
          @spray_volume_value = @attributes[:spray_volume_value].to_d if @attributes[:spray_volume_value].present?
        end

        def usage_id
          usage&.id
        end

        def usage=(value)
          self.usage_id = value.id
        end

        def usage_id=(value)
          @usage = RegisteredPhytosanitaryUsage.find(value)

          if @usage.present?
            self.allowed_harvest_factor = @usage.pre_harvest_delay
            self.allowed_entry_factor = @usage.product.in_field_reentry_delay
          end
        end

        def allowed_harvest_factor=(value)
          @allowed_harvest_factor = value
        end

        def allowed_entry_factor=(value)
          @allowed_entry_factor = value
        end

        def to_attributes
          hash = super
          hash[:usage_id] = usage_id if usage_id.present?
          hash[:allowed_entry_factor] = allowed_entry_factor if allowed_entry_factor.present?
          hash[:allowed_harvest_factor] = allowed_harvest_factor if allowed_harvest_factor.present?
          hash[:spray_volume_value] = spray_volume_value if spray_volume_value.present?
          hash
        end

        def env
          super.merge(
            usage_id: usage_id,
            allowed_entry_factor: allowed_entry_factor,
            allowed_harvest_factor: allowed_harvest_factor,
            spray_volume_value: spray_volume_value
          )
        end
      end
    end
  end
end
