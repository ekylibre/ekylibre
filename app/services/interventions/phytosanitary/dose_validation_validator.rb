module Interventions
  module Phytosanitary
    class DoseValidationValidator < ProductApplicationValidator
      attr_reader :targets_and_shape, :dose_computation, :unit_converter

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
            result.merge(validate_dose(pu))
          end
        end

        result
      end

      # @param [Models::ProductWithUsage]
      # @return [Models::ProductApplicationResult]
      def validate_dose(product_usage)
        result = Models::ProductApplicationResult.new

        zero_as_nil = ->(value) { value.zero? ? None() : value }
        params = {
          into: product_usage.usage.dose_unit,
          area: Maybe(shapes_area.in(:hectare)).fmap(&zero_as_nil),
          net_mass: Maybe(product_usage.product.net_mass).fmap(&zero_as_nil),
          net_volume: Maybe(product_usage.product.net_volume).fmap(&zero_as_nil),
          spray_volume: Maybe(product_usage.spray_volume).fmap(&zero_as_nil).in(:liter_per_hectare)
        }

        if product_usage.measure.dimension == 'none' && into.dimension != 'none' && params.fetch(params[:into].base_dimension.to_sym, None()).is_some?
          unit_converter.convert(product_usage.measure, **params)
                        .cata(
                          none: ->{result.vote_unknown(product_usage.product)},
                          some: ->(converted_dose){
                            usage = product_usage.usage
                            reference = product_usage.max_dose_measure

                            if converted_dose > reference
                              result.vote_forbidden(product_usage.product, :dose_bigger_than_max.tl)
                            end
                          }
                        )
        else
          result.vote_unknown(product_usage.product)
        end

        result
      end

      private

        def targets_data
          targets_and_shape.map.with_index { |e, i| [i.to_s, { shape: e.shape }] }.to_h
        end

        # @return [Measure<area>]
        def shapes_area
          value = targets_and_shape.sum do |ts|
            if ts.shape.nil?
              0
            else
              ts.shape.area
            end
          end

          Measure.new(value, :square_meter)
        end
    end
  end
end
