# frozen_string_literal: true

module Printers
  # Replaces config/locales/fra/reporting/deposit_list.xml (Jasper).
  class DepositListPrinter < PrinterBase
    class << self
      def build_key(id:, updated_at:)
        "#{id}-#{updated_at}"
      end
    end

    # @param [Deposit] deposit
    def initialize(*_args, deposit:, template:, **_options)
      super(template: template)

      @deposit = deposit
    end

    def key
      self.class.build_key(id: @deposit.id, updated_at: @deposit.updated_at.to_s)
    end

    def document_name
      "#{template.nature.human_name} - #{@deposit.number}"
    end

    def compute_dataset
      { deposit: @deposit, payments: @deposit.payments.order(:id), company: Entity.of_company }
    end

    def generate(report)
      dataset = compute_dataset
      deposit = dataset[:deposit]
      cash = deposit.cash

      report.add_field 'DOCUMENT_NAME', document_name
      report.add_field 'COMPANY_NAME', dataset[:company]&.full_name
      report.add_field 'NUMBER', deposit.number
      report.add_field 'AMOUNT', deposit.amount.to_f.round(2).l(currency: deposit.currency)
      report.add_field 'CREATED_AT', deposit.created_at&.l
      report.add_field 'ACCOUNTED_AT', deposit.accounted_at&.l
      report.add_field 'MODE_NAME', deposit.mode&.name
      report.add_field 'RESPONSIBLE_FULL_NAME', deposit.responsible&.full_name
      report.add_field 'CASH_NAME', cash&.name
      report.add_field 'CASH_IBAN', cash&.iban
      report.add_field 'CASH_BANK_NAME', cash&.bank_name
      report.add_field 'PRINTED_AT', Time.zone.now.l(format: '%d/%m/%Y %T')

      report.add_table('PAYMENTS', dataset[:payments], header: true) do |t|
        t.add_column(:payment_number, &:number)
        t.add_column(:payer_full_name) { |payment| payment.payer&.full_name }
        t.add_column(:bank_check_number, &:bank_check_number)
        t.add_column(:to_bank_at) { |payment| payment.to_bank_at&.l }
        t.add_column(:payment_amount) { |payment| payment.amount.to_f.round(2).l(currency: payment.currency) }
      end
    end
  end
end
