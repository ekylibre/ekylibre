# require 'procedo/engine/intervention/product_parameter'

module Procedo
  module Engine
    class Intervention
      class Input < Procedo::Engine::Intervention::Quantified
        attr_reader :usage

        attr_reader :allowed_entry_factor, :allowed_harvest_factor

        def initialize(intervention, id, attributes = {})
          super(intervention, id, attributes)
          if @attributes[:usage_id].present?
            self.usage_id = @attributes[:usage_id]
          end
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

        def spray_volume=(value)
          @spray_volume = value
        end

        # @return [Number, nil]
        #   Returns the value for spray_volume if the handler requires it, nil otherwise
        def spray_volume
          handler_requires_spray_volume? ? @spray_volume : nil
        end

        def to_attributes
          hash = super
          hash[:usage_id] = usage_id if usage_id.present?
          hash[:allowed_entry_factor] = allowed_entry_factor if allowed_entry_factor.present?
          hash[:allowed_harvest_factor] = allowed_harvest_factor if allowed_harvest_factor.present?
          hash[:spray_volume] = spray_volume if spray_volume.present?
          hash
        end

        def to_hash
          hash = super
          hash[:usage_id] = usage_id if usage_id.present?
          hash[:allowed_entry_factor] = allowed_entry_factor if allowed_entry_factor.present?
          hash[:allowed_harvest_factor] = allowed_harvest_factor if allowed_harvest_factor.present?
          hash[:spray_volume] = spray_volume
          hash
        end

        def env
          super.merge(usage_id: usage_id, usage: usage, allowed_entry_factor: allowed_entry_factor, allowed_harvest_factor: allowed_harvest_factor, spray_volume: spray_volume)
        end

        private

          # @return [Boolean]
          #   Returns true if the handler requires spray_volume
          def handler_requires_spray_volume?
            if quantity_handler_reference.nil? || quantity_handler_reference.unit.nil?
              false
            else
              %w[liter_per_hectoliter kilogram_per_hectoliter].include? quantity_handler_reference.unit.name
            end
          end
      end
    end
  end
end
