# frozen_string_literal: true

module Variants
  class CreateProductService

    def self.call(*args)
      new(*args).call
    end

    def initialize(variant:, current_time: Time.zone.now )
      @variant = variant
      @current_time = current_time
    end

    def call
      return nil if variant.products.find_by(default_attributes)

      born_at = current_time - 1.year
      variant.products.create(default_attributes.merge(born_at: born_at))
    end

    private

      attr_reader :variant, :current_time

      def default_attributes
        {
          name: variant.name,
          initial_population: 0,
          conditioning_unit: variant.default_unit
        }
      end
  end
end
