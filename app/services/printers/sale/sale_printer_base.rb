# frozen_string_literal: true

module Printers
  module Sale
    class SalePrinterBase < PrinterBase
      attr_reader :sale

      def initialize(sale:, template:)
        super(template: template)

        @sale = sale
      end

      # @return [Maybe<Cash>]
      def get_company_cash
        Maybe(sale).nature.payment_mode.cash
                   .recover { Cash.bank_accounts.find_by(by_default: true) }
                   .recover { Cash.bank_accounts.first }
      end

      # @return [ { } ]
      def build_vat_totals
        dataset = []
        sale.items.group_by(&:tax).each do |tax, items|
          h = {}
          h[:tax_name] = tax.name
          h[:tax_rate] = tax.amount
          h[:tax_base_pretax_amount] = items.pluck(:pretax_amount).compact.sum.round_l
          h[:tax_amount] = (items.pluck(:amount).compact.sum - items.pluck(:pretax_amount).compact.sum).round_l
          dataset << h
        end
        dataset
      end

      # @return [String]
      def key
        sale.number
      end
    end
  end
end
