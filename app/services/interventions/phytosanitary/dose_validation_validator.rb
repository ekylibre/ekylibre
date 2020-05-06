module Interventions
  module Phytosanitary
    class DoseValidationValidator < ProductApplicationValidator
      attr_reader :targets_and_shape, :dose_computation

      # @param [Array<Models::TargetAndShape>] targets_and_shape
      # @param [RegisteredPhytosanitaryUsageDoseComputation] dose_computation
      def initialize(targets_and_shape:, dose_computation:)
        @targets_and_shape = targets_and_shape
        @dose_computation = dose_computation
      end

      # @param [Array<Models::ProductWithUsage>] products_usages
      # @return [Models::ProductApplicationResult]
      def validate(products_usages)
        result = Models::ProductApplicationResult.new

        if targets_and_shape.empty? || shapes_area.to_f.zero? || products_usages.any? { |pu| pu.usage.nil? }
          products_usages.each { |pu| result.vote_unknown(pu.product) }
        else
          products_usages.each do |pu|
            validation = dose_computation.validate_dose(pu.usage, pu.product, pu.quantity, pu.dimension, targets_data)

            if validation.key? :none
              result.vote_unknown(pu.product)
            elsif validation.key? :stop
              result.vote_forbidden(pu.product, validation.fetch(:stop), on: :quantity)
            end
          end
        end

        result
      end

      private

        def targets_data
          targets_and_shape.map.with_index { |e, i| [i.to_s, { shape: e.shape }] }.to_h
        end

        def shapes_area
          targets_and_shape.sum do |ts|
            if ts.shape.nil?
              0
            else
              ts.shape.area
            end
          end
        end
    end
  end
end