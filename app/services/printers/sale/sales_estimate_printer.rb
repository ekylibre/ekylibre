module Printers
  module Sale
    class SalesEstimatePrinter < SalesEstimateAndOrderPrinter
      def signatures
        WITH_SIGNATURE
      end

      def parcels
        WITHOUT_PARCELS
      end

      def title
        I18n.t('labels.export_sales_estimate')
      end

      def general_conditions
        WITH_CONDITIONS
      end
    end
  end
end
