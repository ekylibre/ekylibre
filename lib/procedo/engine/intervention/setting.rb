# require 'procedo/engine/intervention/parameter'

module Procedo
  module Engine
    class Intervention
      class Setting < Procedo::Engine::Intervention::Parameter
        attr_reader :product, :variant, :text

        def initialize(intervention, id, attributes = {})
          super(intervention, id, attributes)
          @product = Product.find_by(id: @attributes[:product_id]) if @attributes[:product_id].present?
          @variant = ProductNatureVariant.find_by(id: @attributes[:variant_id]) if @attributes[:variant_id].present?
        end

        def product_id
          @product ? @product.id : nil
        end

        def product=(record)
          self.product_id = record.id
        end

        def product?
          @product.present?
        end

        def product_id=(id)
          @product = id.blank? ? nil : Product.find_by!(id: id)
          # Can impact on own attributes, own readings, and other parameters
          impact_dependencies!(:product)
        end

        def variant_id
          @variant ? @variant.id : nil
        end

        def variant=(record)
          self.variant_id = record.id
        end

        def variant?
          @variant.present?
        end

        def variant_id=(id)
          @variant = id.blank? ? nil : ProductNatureVariant.find_by!(id: id)
          impact_dependencies!(:variant)
        end

        def to_hash
          hash = super
          hash[:product_id] = product_id if product?
          hash[:variant_id] = variant_id if variant?
          hash[:dynascope] = reference.scope_hash
          hash
        end

        def impact_with(steps)
          if steps.size != 1
            raise ArgumentError, 'Invalid steps: got ' + steps.inspect
          end
          reassign!(steps.first)
        end

        def impact_dependencies!(field = nil)
          super(field)
          impact_on_parameters(field)
        end

        def value
          return variant if variant?
          product if product?
        end

        def impact_on_parameters(field)
          procedure.product_parameters(true).each do |parameter|
            intervention.parameters_of_name(parameter.name).each do |ip|
              ip.impact_dependencies!(field)
            end
          end
        end

        def env
          super.merge(product: product, variant: variant)
        end
      end
    end
  end
end
