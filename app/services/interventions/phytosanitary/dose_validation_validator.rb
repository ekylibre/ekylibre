# frozen_string_literal: true

module Interventions
  module Phytosanitary
    class DoseValidationValidator < ProductApplicationValidator
      attr_reader :targets_zone, :unit_converter

      # @param [Array<Models::TargetZone>] targets_zone
      # @param [ProductUnitConverter] unit_converter
      def initialize(targets_zone:, unit_converter:)
        @targets_zone = targets_zone
        @unit_converter = unit_converter
      end

      # @param [Array<Models::ProductWithUsage>] products_usages
      # @return [Models::ProductApplicationResult]
      def validate(products_usages)
        result = Models::ProductApplicationResult.new

        if targets_zone.empty? || area.to_f.zero? || products_usages.any? { |pu| pu.usage.nil? }
          products_usages.each { |pu| result.vote_unknown(pu.product) }
        else
          products_usages.each do |pu|
            result = result.merge(validate_dose(pu))
          end
        end

        result
      end

      # @param [Models::ProductWithUsage]
      # @return [Models::ProductApplicationResult]
      def validate_dose(product_usage)
        result = Models::ProductApplicationResult.new

        params = build_params(product_usage)

        if product_usage.measure.dimension != 'none' || params.fetch(:"net_#{params[:into].base_dimension.to_sym}", None()).is_some?
          params.delete(:into)
            .fmap { |into| unit_converter.convert(product_usage.measure, into: into, **params) }
            .cata(
              none: -> { result.vote_unknown(product_usage.product) },
              some: ->(converted_dose) {
                reference = product_usage.usage.max_dose_measure

                if converted_dose > reference
                  result.vote_forbidden(product_usage.product, :dose_bigger_than_max.tl, on: :quantity)
                end
              }
            )
        else
          result.vote_unknown(product_usage.product)
        end

        result
      end

      private

        # @param [Models::ProductWithUsage] product_usage
        def build_params(product_usage)
          zero_as_nil = ->(value) { value.zero? ? None() : value }

          {
            into: Maybe(Onoma::Unit.find(product_usage.usage.dose_unit)),
            area: Maybe(area.in(:hectare)).fmap(&zero_as_nil),
            net_mass: Maybe(product_usage.product.net_mass).fmap(&zero_as_nil),
            net_volume: Maybe(product_usage.product.net_volume).fmap(&zero_as_nil),
            spray_volume: Maybe(product_usage.spray_volume).fmap(&zero_as_nil).in(:liter_per_hectare)
          }
        end

        # @return [Measure<area>]
        def area
          targets_zone.sum(&:area)
        end
    end
  end
end
