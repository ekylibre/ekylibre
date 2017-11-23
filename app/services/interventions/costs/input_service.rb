module Interventions
  module Costs
    class InputService
      attr_reader :product

      def initialize(product: nil)
        @product = product
      end

      def perform(quantity: 0, unit_name: nil)
        incoming_parcel = @product.incoming_parcel_item

        options = { quantity: quantity, unit_name: unit_name }

        if incoming_parcel && incoming_parcel.purchase_item
          options[:purchase_item] = incoming_parcel.purchase_item

          return InterventionParameter::AmountComputation.quantity(:purchase, options)
        end

        options[:catalog_usage] = :purchase
        options[:catalog_item] = product.default_catalog_item(options[:catalog_usage])
        InterventionParameter::AmountComputation.quantity(:catalog, options)
      end
    end
  end
end
