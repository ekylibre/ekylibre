module Printers
  module Sale
    class SalesOrderPrinter < SalesEstimateAndOrderPrinter
      def signatures
        WITHOUT_SIGNATURE
      end

      def parcels
        sale.parcel_items.any? ? [sale] : WITHOUT_PARCELS
      end

      def title
        I18n.t('labels.export_sales_order')
      end

      def general_conditions
        WITHOUT_CONDITIONS
      end

      def should_display_affair
        true
      end

    end
  end
end
