# frozen_string_literal: true

module Interventions
  module Phytosanitary
    class ProductUsageMerger
      class << self
        def build(area: None())
          new(
            converter: Interventions::ProductUnitConverter.new,
            area: area
          )
        end
      end

      class MergeResult
        protected :initialize

        def success?
          false
        end

        def error?
          false
        end

        def cata(success:, error:)
          raise NotImplementedError.new("Should be implemented in subclasses")
        end
      end

      class MergeSuccessful < MergeResult
        # @return [Models::ProductWithUsage]
        attr_reader :value

        # @param [Models::ProductWithUsage] value
        def initialize(value)
          @value = value
        end

        def success?
          true
        end

        def cata(success:, **)
          success.call(value)
        end
      end

      class MergeError < MergeResult
        # @return [String]
        attr_reader :maaid
        # @return [Symbol]
        attr_reader :vote
        # @return [String]
        attr_reader :message

        # @param [String] maaid
        # @param [Symbol] vote
        # @param [String] message
        def initialize(maaid, vote, message)
          @maaid = maaid
          @vote = vote
          @message = message
        end

        def error?
          true
        end

        def cata(error:, **)
          error.call(maaid, vote, message)
        end
      end

      # @return [ProductUnitConverter]
      attr_reader :converter
      # @return [Maybe<Measure<area>>]
      attr_reader :area

      # @param [ProductUnitConverter] converter
      # @param [Maybe<Measure<area>>]
      def initialize(converter:, area:)
        @converter = converter
        @area = area
      end

      # @param [String] maaid
      # @param [Models::ProductWithUsage]
      # @param [Models::ProductWithUsage]
      # @return [MergeResult]
      def merge_product_usages(maaid, pu, pu2)
        if pu.usage != pu2.usage
          MergeError.new(maaid, :forbidden, :identical_usage_should_be_selected.tl)
        else
          zero_as_nil = ->(value) { value.zero? ? None() : value }

          converter
            .convert(
              pu2.measure,
              into: Nomen::Unit.find(pu.measure.unit),
              area: area,
              net_mass: Maybe(pu.product.net_mass).fmap(&zero_as_nil),
              net_volume: Maybe(pu.product.net_volume).fmap(&zero_as_nil),
              spray_volume: Maybe(pu.spray_volume).fmap(&zero_as_nil)
            )
            .cata(
              none: -> { MergeError.new(maaid, :unknown, "Unable to convert the applied dose") },
              some: ->(measure) {
                MergeSuccessful.new(
                  Models::ProductWithUsage.new(
                    pu.product,
                    pu.phyto,
                    pu.usage,
                    pu.measure + measure,
                    pu.spray_volume
                  )
                )
              }
            )
        end
      end

      # Merge Models::ProductWithUsage based on their maaid
      #
      # @param [Array<Models::ProductWithUsage>] product_usages
      # @return [Array<MergeResult>]
      def merge(product_usages)
        groups = product_usages.group_by { |pu| pu.phyto.france_maaid }
        groups.map do |maaid, product_usages|
          first, *rest = product_usages

          rest.reduce(MergeSuccessful.new(first)) do |acc, pu|
            acc.cata(
              error: ->(vote, message) { MergeError.new(maaid, vote, message) },
              success: ->(value) { merge_product_usages(maaid, value, pu) }
            )
          end
        end
      end
    end
  end
end
