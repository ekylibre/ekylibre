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
    end
  end
end