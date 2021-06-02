# require 'procedo/engine/intervention/product_parameter'

module Procedo
  module Engine
    class Intervention
      class Output < Procedo::Engine::Intervention::Quantified
        attr_reader :variant

        attr_reader :new_name, :specie_variety_name, :identification_number, :variety, :batch_number

        def initialize(intervention, id, attributes = {})
          super(intervention, id, attributes)
          if @attributes[:variant_id].present?
            @variant = ProductNatureVariant.find_by(id: @attributes[:variant_id])
          end
          @new_name = @attributes[:new_name]
          @identification_number = @attributes[:identification_number]
          @specie_variety_name = @attributes[:specie_variety_name]
          @variety = @attributes[:variety]
          @batch_number = @attributes[:batch_number]
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

        def variety=(variety)
          @variety = variety
          impact_dependencies!(:variety)
        end

        def specie_variety_name=(specie_variety_name)
          @specie_variety_name = specie_variety_name
          impact_dependencies!(:specie_variety_name)
        end

        def batch_number=(batch_number)
          @batch_number = batch_number
          impact_dependencies!(:batch_number)
        end

        def new_name=(name)
          @new_name = name
          impact_dependencies!(:new_name)
        end

        def identification_number=(identification_number)
          @identification_number = identification_number
          impact_dependencies!(:identification_number)
        end

        def to_hash
          hash = super
          hash[:variant_id] = @variant.id if @variant
          hash[:new_name] = @new_name if @new_name.present?
          hash[:identification_number] = @identification_number if @identification_number.present?
          hash[:variety] = @variety if @variety.present?
          hash[:specie_variety_name] = @specie_variety_name if @specie_variety_name.present?
          hash[:batch_number] = @batch_number if @batch_number.present?
          hash
        end

        def to_attributes
          hash = super
          hash[:variant_id] = @variant.id if @variant
          hash[:new_name] = @new_name if @new_name.present?
          hash[:identification_number] = @identification_number if @identification_number.present?
          hash[:variety] = @variety if @variety.present?
          hash[:specie_variety_name] = @specie_variety_name if @specie_variety_name.present?
          hash[:batch_number] = @batch_number if @batch_number.present?
          hash
        end

        def env
          super.merge(variant: variant, new_name: new_name, identification_number: identification_number, specie_variety_name: specie_variety_name, variety: variety, batch_number: batch_number)
        end
      end
    end
  end
end
