# require 'procedo/engine/intervention/product_parameter'

module Procedo
  module Engine
    class Intervention
      class Target < Procedo::Engine::Intervention::ProductParameter
        attr_reader :new_group, :new_container
        attr_accessor :new_variant, :identification_number

        def initialize(intervention, id, attributes = {})
          super(intervention, id, attributes)
          attributes = Maybe(attributes)
          @new_group = Product.find_by(id: attributes[:new_group].to_i.or_else(0))
          @new_container = Product.find_by(id: attributes[:new_container].to_i.or_else(0))
        end

        def new_group_id
          @new_group ? @new_group.id : nil
        end

        def new_group=(record)
          self.new_group_id = record.id
        end

        def new_group_id=(id)
          @new_group = Product.find_by(id: id)
          impact_dependencies!(:new_group)
        end

        def new_container_id
          @new_container ? @new_container.id : nil
        end

        def new_container=(record)
          self.new_container_id = record.id
        end

        def new_container_id=(id)
          @new_container = Product.find_by(id: id)
          impact_dependencies!(:new_container)
        end

        def new_variant_id
          new_variant ? new_variant.id : nil
        end

        def new_variant_id=(id)
          self.new_variant = ProductNatureVariant.find_by(id: id)
        end

        def to_hash
          hash = super
          hash[:new_group_id] = new_group_id if @new_group
          hash[:new_container_id] = new_container_id if @new_container
          hash[:new_variant_id] = new_variant_id unless new_variant_id.nil?
          hash[:identification_number] = identification_number if @identification_number
          hash
        end

        def to_attributes
          hash = super
          hash[:new_group_id] = new_group_id if @new_group
          hash[:new_container_id] = new_container_id if @new_container
          hash[:new_variant_id] = new_variant_id unless new_variant_id.nil?
          hash[:identification_number] = identification_number if @identification_number
          hash
        end

        def env
          super.merge(new_group: new_group)
        end
      end
    end
  end
end
