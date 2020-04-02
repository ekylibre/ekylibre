module Printers
  module Sale
    class SalePrinterBase < PrinterBase
      attr_reader :sale

      def initialize(template:, sale:)
        super(template: template)

        @sale = sale
      end

      # @return [Maybe<Cash>]
      def get_company_cash
        Maybe(sale).nature.payment_mode.cash
                   .recover { Cash.bank_accounts.find_by(by_default: true) }
                   .recover { Cash.bank_accounts.first }
      end

      # @return [String]
      def key
        sale.number
      end

    end
  end
end
