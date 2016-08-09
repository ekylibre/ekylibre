# require 'procedo/engine/intervention/product_parameter'

module Procedo
  module Engine
    class Intervention
      class Input < Procedo::Engine::Intervention::Quantified
        attr_reader :assembly, :component_id

        def initialize(intervention, id, attributes = {})
          super(intervention, id, attributes)
          attributes = Maybe(attributes)
          @assembly = Product.find_by(id: attributes[:assembly_id].to_i.or_else(0))
          @component_id = attributes[:component_id].to_i.or_else(nil)
        end

        def to_hash
          hash = super
          hash[:assembly_id] = assembly_id
          hash[:component_id] = component_id if component_id
          hash
        end

        def impact_dependencies!(field)
          super(field)
          reassign(:assembly)
          reassign(:component_id)
        end

        def assembly_id
          @assembly ? @assembly.id : nil
        end

        def assembly=(record)
          self.assembly_id = Maybe(record).id.or_else(nil)
        end

        def assembly_id=(id)
          @assembly = id.blank? ? nil : Product.find_by!(id: id)
          impact_dependencies! :assembly
        end

        def component_id=(value)
          @component_id = value
          impact_dependencies! :component
        end
      end
    end
  end
end
