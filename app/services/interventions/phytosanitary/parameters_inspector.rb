module Interventions
  module Phytosanitary
    class ParametersInspector

      # @param [Boolean] live_data
      # @param [Intervention] intervention
      # @param [Array<Integer>] targets_ids
      # @param [Array<Hash{Symbol => InterventionInput, Integer, String}>] inputs_data
      # @return [Boolean]
      def relevant_parameters_modified?(live_data:, intervention:, targets_ids:, inputs_data:)
        live_data || !intervention || targets_changed?(intervention, targets_ids) || inputs_changed?(inputs_data)
      end

      private

        def targets_changed?(intervention, targets_ids)
          intervention.targets.pluck(:product_id).sort != targets_ids.sort
        end

        def inputs_changed?(inputs_data)
          inputs_data.any? { |data| !data[:input] || data[:input].product_id != data[:product_id] || data[:input].usage_id != data[:usage_id] }
        end
    end
  end
end
