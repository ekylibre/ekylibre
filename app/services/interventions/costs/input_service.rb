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

        # TODO: Check if incoming_parcel.purchase_invoice_item is the last
        # purchase_invoice of the product when the lines below
        # are uncommented.
        # if incoming_parcel
        #  purchase_item = incoming_parcel.purchase_invoice_item
        #  purchase_item ||= incoming_parcel.purchase_order_item

        #  return purchase_item_amount(purchase_item, options) if purchase_item
        # end

        options[:catalog_usage] = :purchase
        options[:catalog_item] = product.default_catalog_item(options[:catalog_usage])

        InterventionParameter::AmountComputation.quantity(:catalog, options)
      end

      private

      def purchase_item_amount(purchase_item, options)
        options[:purchase_item] = purchase_item

        InterventionParameter::AmountComputation.quantity(:purchase, options)
      end
    end
  end
end
