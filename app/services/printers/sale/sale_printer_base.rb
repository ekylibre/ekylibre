module Printers
  module Sale
    class SalePrinterBase < PrinterBase
      attr_reader :sale

      def initialize(template:, sale:)
        super(template: template)

        @sale = sale
      end

      def key
        sale.number
      end

    end
  end
end
