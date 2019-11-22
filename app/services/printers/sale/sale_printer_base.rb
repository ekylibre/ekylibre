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

      # TODO: To be removed after ruby 2.6
      # @deprecated
      def upcase(str)
        I18n.transliterate(str).upcase
      end
    end
  end
end
