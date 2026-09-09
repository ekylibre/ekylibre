# frozen_string_literal: true

module Printers
  # Replaces config/locales/fra/reporting/purchases_invoice.jrxml (Jasper).
  class PurchasesInvoicePrinter < PrinterBase
    # for accessing to number_to_accountancy
    include ApplicationHelper

    class << self
      def build_key(id:, updated_at:)
        "#{id}-#{updated_at}"
      end
    end

    # @param [PurchaseInvoice] purchase
    def initialize(*_args, purchase:, template:, **_options)
      super(template: template)

      @purchase = purchase
    end

    def key
      self.class.build_key(id: @purchase.id, updated_at: @purchase.updated_at.to_s)
    end

    def document_name
      "#{template.nature.human_name} - #{@purchase.number}"
    end

    def compute_dataset
      { purchase: @purchase, items: @purchase.items.includes(:variant), company: Entity.of_company }
    end

    def generate(report)
      dataset = compute_dataset
      purchase = dataset[:purchase]
      supplier = purchase.supplier

      report.add_field 'DOCUMENT_NAME', document_name
      report.add_field 'COMPANY_NAME', dataset[:company]&.full_name
      report.add_field 'COMPANY_ADDRESS', dataset[:company]&.default_mail_address&.coordinate
      report.add_field 'NUMBER', purchase.number
      report.add_field 'REFERENCE_NUMBER', purchase.reference_number
      report.add_field 'INVOICED_ON', purchase.invoiced_on&.l
      report.add_field 'DESCRIPTION', purchase.description
      report.add_field 'SUPPLIER_FULL_NAME', supplier&.full_name
      report.add_field 'SUPPLIER_ADDRESS', supplier&.default_mail_address&.coordinate
      report.add_field 'SUPPLIER_SIREN', supplier&.siren_number
      report.add_field 'SUPPLIER_VAT_NUMBER', supplier&.vat_number
      report.add_field 'CURRENCY', purchase.currency
      report.add_field 'PRETAX_AMOUNT', number_to_accountancy(purchase.pretax_amount)
      report.add_field 'TAXES_AMOUNT', number_to_accountancy(purchase.amount - purchase.pretax_amount)
      report.add_field 'AMOUNT', number_to_accountancy(purchase.amount)
      report.add_field 'PRINTED_AT', Time.zone.now.l(format: '%d/%m/%Y %T')

      report.add_table('ITEMS', dataset[:items], header: true) do |t|
        t.add_column(:label) { |item| item.label || item.variant&.name }
        t.add_column(:annotation, &:annotation)
        t.add_column(:quantity) { |item| item.quantity.to_s }
        t.add_column(:unit_name) { |item| item.conditioning_unit&.name }
        t.add_column(:unit_pretax_amount) { |item| number_to_accountancy(item.unit_pretax_amount) }
        t.add_column(:tax_name) { |item| item.tax&.name }
        t.add_column(:item_pretax_amount) { |item| number_to_accountancy(item.pretax_amount) }
        t.add_column(:item_amount) { |item| number_to_accountancy(item.amount) }
      end
    end
  end
end
