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
        Nomen::Unit.items.values.find do |e|
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
        #BUG: What if we don't find a handler?
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
                       Nomen::Unit.find(edi_unit.ekylibre_value.to_sym)
                     end
        return nomen_unit if nomen_unit
        #BUG: What if the unit isn't in the lexicon or not in Nomen?
        raise "No unit for #{unit_edicode}"
      end

      def daplos_area_unit
        edi_unit = RegisteredAgroediCode.of_reference_code(area_unit_edicode).first
        nomen_unit = if edi_unit && edi_unit.ekylibre_value
                       unit_name = edi_unit.ekylibre_value
                       # Always in hectare in Daplos
                       dimensioned = (unit_name =~ /_per_hectare$/)
                       unit_name += '_per_hectare' unless dimensioned
                       Nomen::Unit.find(unit_name.to_sym)
                     end
        return nomen_unit if nomen_unit
        raise "No unit for #{area_unit_edicode}"
      end

      # The reference is the DISTRIBUTED quantity (dimension_per_area) always
      def daplos_quantity(area: true)
        if area
          daplos.input_quantity_per_hectare.to_f.in daplos_area_unit
        else
          daplos.input_quantity.to_f.in daplos_unit
        end
      end

      def article
        article = RegisteredAgroediCode.of_reference_code(nature_edicode)
                                       .first
                                       &.ekylibre_value
                                       &.to_sym
        article || raise("Nature code #{nature_edicode.inspect} has no equivalent in Ekylibre reference")
      end

      private

        def find_or_create_product!(variety = nil)
          variant = find_or_create_variant

          return variant.products.first if variant.products.any?

          store_in = BuildingDivision.first
          product_model = variant.nature.matching_model
          #BUG: What if building_division.blank?
          matter = product_model.create!(variant: variant,
                                         initial_born_at: intervention.started_at,
                                         initial_population: 0.0,
                                         initial_owner: Entity.of_company,
                                         initial_container: store_in,
                                         default_storage: store_in)

          if article && article.to_s == "seed" && variety
            matter.derivative_of = variety
            matter.save!
          end
          matter
        end

        def find_or_create_variant
          name = daplos.input_name
          variant = ProductNatureVariant.where(name: name, active: true).first

          unless variant
            #BUG: what if article.blank?
            variant = ProductNatureVariant.import_from_nomenclature(article, force: true) if article
            variant.name = name
            variant.save!
          end

          if daplos.input_phytosanitary_number.present?
            #BUG: What if two inputs with different MAAID have the same variant
            # (since the find_by is on `name` only)
            variant.france_maaid = daplos.input_phytosanitary_number
            variant.save!
          end

          variant
        end
    end
  end
end
