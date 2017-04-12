# require 'procedo/engine/intervention/product_parameter'

module Procedo
  module Engine
    class Intervention
      class Output < Procedo::Engine::Intervention::Quantified
        attr_reader :variant

        attr_reader :new_name, :identification_number, :variety, :derivative_of

        def initialize(intervention, id, attributes = {})
          super(intervention, id, attributes)
          if @attributes[:variant_id].present?
            @variant = ProductNatureVariant.find_by(id: @attributes[:variant_id])
          end
          @new_name = @attributes[:new_name]
          @variety = @attributes[:variety]
          @derivative_of = @attributes[:derivative_of]
          @identification_number = @attributes[:identification_number]
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

        def variety=(value)
          unless value.blank? || Nomen::Variety.find(value)
            raise 'Invalid variety: ' + value.inspect
          end
          @variety = value
          impact_dependencies!(:variety)
        end

        def derivative_of=(value)
          unless value.blank? || Nomen::Variety.find(value)
            raise 'Invalid derivative_of: ' + value.inspect
          end
          @derivative_of = value
          impact_dependencies!(:derivative_of)
        end

        def identification_number=(identification_number)
          @identification_number = identification_number
          impact_dependencies!(:identification_number)
        end

        def to_hash
          hash = super
          hash[:variant_id] = @variant.id if @variant
          hash[:new_name] = @new_name if @new_name.present?
          hash[:attributes] ||= {}
          hash[:attributes][:new_container_id] ||= {}
          hash[:attributes][:new_container_id][:dynascope] ||= {}
          hash[:attributes][:new_container_id][:dynascope][:of_expression] ||= 'is building_division'
          hash[:attributes][:new_container_id][:dynascope][:of_expression] << " or can store(#{@variant.variety})" if @variant
          hash[:attributes][:merge_stocks] ||= {}
          hash[:attributes][:merge_stocks][:with] = mergeable_with && mergeable_with.name
          hash[:variety] = @variety if @variety.present?
          hash[:derivative_of] = @derivative_of if @derivative_of.present?
          hash[:identification_number] = @identification_number if @identification_number.present?
          hash
        end

        def env
          super.merge(variant: variant, new_name: new_name, identification_number: identification_number, variety: variety, derivative_of: derivative_of)
        end
      end
    end
  end
end
