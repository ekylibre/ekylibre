# require 'procedo/engine/intervention/product_parameter'

module Procedo
  module Engine
    class Intervention
      class Output < Procedo::Engine::Intervention::Quantified
        attr_reader :variant

        attr_reader :new_name

        def initialize(intervention, id, attributes = {})
          super(intervention, id, attributes)
          if @attributes[:variant_id].present?
            @variant = ProductNatureVariant.find_by(id: @attributes[:variant_id])
          end
          @new_name = @attributes[:new_name]
        end

        def variant_id
          @variant ? @variant.id : nil
        end

        def variant=(record)
          self.variant_id = record.id
        end

        def variant_id=(id)
          @variant = ProductNatureVariant.find_by(id: id)
          impact_dependencies!(:variant)
        end

        def new_name=(name)
          @new_name = name
          impact_dependencies!(:new_name)
        end

        def mergeable_with
          time_of_creation = @intervention.working_periods.to_a.lazy.map(&:last).map(&:stopped_at).max
          @variant.present? && !@variant.population_counting_unitary? && Product.matching_products(@variant, @new_container, time_of_creation).first
        end

        def to_hash
          hash = super
          hash[:variant_id] = @variant.id if @variant
          hash[:new_name] = @new_name unless @new_name.blank?
          hash[:attributes] ||= {}
          hash[:attributes][:new_container_id] ||= {}
          hash[:attributes][:new_container_id][:dynascope] ||= {}
          hash[:attributes][:new_container_id][:dynascope][:of_expression] ||= 'is building_division'
          hash[:attributes][:new_container_id][:dynascope][:of_expression] << " or can store(#{@variant.variety})" if @variant
          hash[:attributes][:merge_stocks] ||= {}
          hash[:attributes][:merge_stocks][:with] = mergeable_with && mergeable_with.name
          hash
        end

        def env
          super.merge(variant: variant, new_name: new_name)
        end
      end
    end
  end
end
