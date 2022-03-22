# frozen_string_literal: true

module Agroedi
  class DaplosExchanger < ActiveExchanger::Base
    class Input < DaplosInterventionParameter
      include Comparable

      alias_method :procedure_input, :procedure_parameter
      alias_method :procedure_input=, :procedure_parameter=

      def to_attributes
        {
          reference_name: reference_name,
          product_id: product_id,
          quantity_handler: handler.name,
          quantity_unit: quantity_unit,
          quantity_value: quantity_value
        }
      end

      def <=>(oth)
        oth_quantity = oth.quantity_value.in(oth.quantity_unit)
        qty_base_unit = base_unit(quantity)
        oth_base_unit = base_unit(oth_quantity)
        [reference_name.to_s, product_id, quantity.in(qty_base_unit)] <=>
          [oth.reference_name.to_s, oth.product_id, oth_quantity.in(oth_base_unit)]
      end

      def hash
        qty_base_unit = base_unit(quantity)
        [reference_name.to_s, product_id, quantity.in(qty_base_unit)].hash
      end

      def eql?(oth)
        self == oth
      end

      def quantity_value
        daplos_quantity.in(handler.unit).to_d
      end

      def quantity_unit
        handler.unit
      end

      def quantity
        quantity_value.in(quantity_unit)
      end

      def base_unit(unit)
        Onoma::Unit.items.values.find do |e|
          (e.dimension.to_s == unit.dimension.to_s) &&
            (e.a == 1)
        end
      end

      def reference_name
        procedure_input.name
      end

      def product_id
        matching_product.id
      end

      def coherent?(with: @procedure_parameter)
        with &&
          matching_product.of_expression(with.filter)
      end

      def matching_product
        @memo_product ||= find_or_create_product!
      end

      def handler
        # BUG: What if we don't find a handler?
        super(daplos_quantity)
      end

      def nature_edicode
        daplos.input_nature_edicode
      end

      def unit_edicode
        daplos.input_unity_edicode
      end

      def area_unit_edicode
        daplos.per_area_unity_edicode
      end

      def daplos_unit
        edi_unit = RegisteredAgroediCode.of_reference_code(unit_edicode).first
        nomen_unit = if edi_unit && edi_unit.ekylibre_value
                       Onoma::Unit.find(edi_unit.ekylibre_value.to_sym)
                     end
        nomen_unit || nil
      end

      def daplos_area_unit
        edi_unit = RegisteredAgroediCode.of_reference_code(area_unit_edicode).first
        nomen_unit = if edi_unit && edi_unit.ekylibre_value
                       unit_name = edi_unit.ekylibre_value
                       # Always in hectare in Daplos
                       dimensioned = (unit_name =~ /_per_hectare$/)
                       unit_name += '_per_hectare' unless dimensioned
                       Onoma::Unit.find(unit_name.to_sym)
                     end
        nomen_unit || nil
      end

      # The reference is the DISTRIBUTED quantity (dimension_per_area) always
      def daplos_quantity(area: true)
        if daplos.input_quantity_per_hectare && area && daplos_area_unit
          daplos.input_quantity_per_hectare.to_f.in daplos_area_unit
        elsif daplos.input_quantity && daplos_unit
          daplos.input_quantity.to_f.in daplos_unit
        else
          raise "No quantity computed concerning  unit : #{daplos_unit}  and area_unit : #{daplos_area_unit} for #{daplos.inspect}"
        end
      end

      def article
        item = {}
        article = RegisteredAgroediCode.of_reference_code(nature_edicode).first
        item[:name] = article.reference_label
        item[:nature] = article.ekylibre_value
        item.to_struct || raise("Nature code #{nature_edicode.inspect} has no equivalent in Ekylibre reference")
      end

      private

        def find_or_create_product!(variety = nil)
          born_at = intervention.started_at - 2.hours
          variant = find_or_create_variant
          products = variant.products.where(name: daplos.input_name)
          if products.any?
            matter = products.first
            if born_at < matter.initial_born_at
              matter.initial_born_at = born_at
              matter.born_at = born_at
              matter.save!
              matter.readings.update_all(read_at: born_at)
            end
            matter
          else
            store_in = BuildingDivision.first
            product_model = variant.matching_model
            conditioning_data = variant.guess_conditioning
            unit = find_product_unit
            # BUG: What if building_division.blank?
            matter = product_model.create!(variant: variant,
                                           name: daplos.input_name,
                                           initial_born_at: born_at,
                                           initial_population: 1.0,
                                           conditioning_unit: unit,
                                           initial_owner: Entity.of_company,
                                           initial_container: store_in,
                                           default_storage: store_in)

            if article.nature.present? && (article.nature == "seed" ||article.nature == "seedling") && variety
              matter.derivative_of = variety
              matter.read!(:net_mass, Measure.new(1.0, :kilogram), at: born_at, force: true)
            elsif article.nature.present? && (article.nature == "mineral_fertilizer" || article.nature == "organic_fertilizer")
              if unit.dimension == 'mass'
                matter.read!(:net_mass, Measure.new(unit.coefficient, :kilogram), at: born_at, force: true)
              elsif unit.dimension == 'volume'
                matter.read!(:net_volume, Measure.new(unit.coefficient, :liter), at: born_at, force: true)
              end
            end
            matter
          end
        end

        # return a conditioning_unit Unit
        def find_product_unit
          if daplos_unit.name && MasterUnit.find_by(reference_name: daplos_unit.name)
            Unit.import_from_lexicon(daplos_unit.name)
          else
            raise "No way to find unit from daplos_unit : #{daplos_unit.inspect}"
          end
        end

        def find_or_create_variant
          nature = ProductNature.import_from_lexicon(article.nature)
          variant = ProductNatureVariant.where(name: daplos.input_name, nature_id: nature.id, active: true).first
          return variant if variant

          if article.nature.to_sym == :plant_medicine && daplos.input_phytosanitary_number.present?
            variant = ProductNatureVariant.import_from_lexicon(daplos.input_phytosanitary_number)
          elsif article.nature.present?
            lexicon_variants = MasterVariant.where(family: 'article', nature: article.nature)
            if lexicon_variants.any?
              ref = lexicon_variants.first.reference_name
              variant = ProductNatureVariant.import_from_lexicon(ref, true)
            end
          end

          # set thousand_grains_mass on seed
          if variant && article.nature.to_sym == :seed || article.nature.to_sym == :seedling
            variant.read! :thousand_grains_mass, Measure.new(50, :gram)
          end

          unless variant
            raise "No way to create variant #{daplos.input_name} from nature #{article.nature} and edicode #{nature_edicode.inspect}"
          end

          if article.nature.present? && (article.nature == "mineral_fertilizer" || article.nature == "organic_fertilizer" || article.nature == "plant_medicine")
            variant.read! :net_mass, Measure.new(1.0, :kilogram)
            variant.read! :net_volume, Measure.new(1.0, :liter)
          elsif article.nature.present? && article.nature == "seedling"
            variant.read! :net_mass, Measure.new(1.0, :kilogram)
          end

          variant.name = daplos.input_name
          variant.tap(&:save!)

          variant
        end

    end
  end
end
