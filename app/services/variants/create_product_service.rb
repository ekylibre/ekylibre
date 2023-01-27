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

      variant.products.create(default_attributes.merge(born_at: born_at))
    end

    private

      attr_reader :variant, :current_time

      def born_at
        born_at = if (last_inventory = variant.last_inventory)
                    last_inventory.achieved_at + 1.day
                  else
                    current_time - 1.year
                  end
      end

      def default_attributes
        {
          name: variant.name,
          initial_population: 0,
          conditioning_unit: variant.default_unit,
          type: type.to_s.camelize
        }
      end

      def type
        variant_type = variant.variant_type
        return :matter if variant_type  == :article

        variant_type
      end

  end
end
