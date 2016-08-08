# require 'procedo/engine/intervention/product_parameter'

module Procedo
  module Engine
    class Intervention
      class Input < Procedo::Engine::Intervention::Quantified
        attr_reader :assembly, :component_id, :schematic_id

        def initialize(intervention, id, attributes = {})
          super(intervention, id, attributes)
          attributes = Maybe(attributes)
          @assembly = Product.find_by(id: attributes[:assembly_id].to_i.or_else(0))
          @component_id = attributes[:component_id].to_i.or_else(nil)
          @schematic_id = attributes[:schematic_id].to_i.or_else(nil)
        end

        def to_hash
          hash = super
          hash[:assembly_id] = assembly_id if assembly
          hash[:component_id] = component_id if component_id
          hash[:schematic_id] = schematic_id if schematic_id
          hash
        end

        def impact_dependencies!(field)
          super(field)
          reassign(:assembly)
          reassign(:component_id)
          reassign(:schematic_id)
        end

        def assembly_id
          @assembly ? @assembly.id : nil
        end

        def assembly=(record)
          if record.is_a?(Procedo::Engine::Set)
            if record.size != 1
              raise ArgumentError, 'Can only accept Set with size=1. Got: ' + record.inspect
            end
            record = record.parameters.first.product
          end
          self.assembly_id = Maybe(record).id.or_else(nil)
          self.schematic_id = Maybe(assembly).variant_id.or_else(nil)
        end

        def assembly_id=(id)
          @assembly = id.blank? ? nil : Product.find_by!(id: id)
          impact_dependencies! :assembly
        end

        def schematic_id=(value)
          @schematic_id = value
          impact_dependencies! :schematic
        end

        def component_id=(value)
          @component_id = value
          impact_dependencies! :component
        end
      end
    end
  end
end
