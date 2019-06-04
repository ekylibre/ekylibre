module Agroedi
  class DaplosExchanger < ActiveExchanger::Base
    class Output < DaplosInterventionParameter
      alias_method :procedure_output, :procedure_parameter
      alias_method :procedure_output=, :procedure_parameter=

      delegate :output_name, to: :daplos

      def attributes
        {
          reference_name: procedure_output.name,
          variant_id: variant.id,
          new_name: output_name,
          quantity_handler: handler.name,
          quantity_value: value.to_f
        }
      end
      alias_method :to_attributes, :attributes

      def coherent?(with: @procedure_parameter)
        with &&
          variant.of_expression(with.filter)
      end

      def variant
        @variant ||= find_or_create_variant!
      end

      def value
        Measure.new(daplos.output_quantity.to_f, daplos_unit.ekylibre_value&.to_sym)
      end

      def handler
        super value
      end

      def name
        "#{output_name} | #{nature_edicode.reference_label}"
      end

      def nature_edicode
        @nature_edicode ||= RegisteredAgroediCode.find_by(
          repository_id: 15,
          reference_code: daplos.output_nature_edicode)
      end

      def specie_edicode
        @specie_edicode ||= RegisteredAgroediCode.find_by(
          repository_id: 18,
          reference_code: daplos.output_specie_edicode)
      end

      def unit_edicode
        daplos.output_unity_edicode
      end

      private

        def target_variety
          Nomen::Variety[intervention.activity_production.cultivation_variety]
        end

        def find_or_create_variant!
          varieties = [target_variety, *target_variety.parents]
          possible_variants = ProductNatureVariant.where(
              variety: nature_edicode.ekylibre_value,
              active: true
          )
          variant = varieties.lazy.map do |variety|
            possible_variants.find_by(derivative_of: variety.name)
          end.find(&:present?)

          return variant if variant

          variant = ProductNatureVariant.find_or_import!(
            nature_edicode.ekylibre_value.to_sym).first
          variant ||= ProductNatureVariant.import_from_nomenclature(
            nature_edicode.ekylibre_value&.to_sym,
            force: true)

          variant.name = output_name
          variant.tap(&:save!)
        end
    end
  end
end
