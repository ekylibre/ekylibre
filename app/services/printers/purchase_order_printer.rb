# frozen_string_literal: true

module Printers
  class PurchaseOrderPrinter < PrinterBase
    def initialize(purchase_order:, template:)
      super(template: template)
      @purchase_order = purchase_order
    end

    def compute_dataset
      report = HashWithIndifferentAccess.new
      supplier_email = @purchase_order.supplier.addresses.where(canal: 'email')

      report[:purchase_number] = @purchase_order.reference_number
      report[:purchase_ordered_at] = @purchase_order.ordered_at.l(format: '%d/%m/%Y') if @purchase_order.ordered_at.present?
      report[:purchase_estimate_reception_date] = @purchase_order.estimate_reception_date.l(format: '%d/%m/%Y') if @purchase_order.estimate_reception_date.present?
      report[:purchase_responsible] = @purchase_order.responsible&.full_name || ""
      report[:purchase_responsible_email] = @purchase_order.responsible&.email || ""
      report[:supplier_name] = @purchase_order.supplier.full_name
      report[:supplier_phone] = @purchase_order.supplier.phones.first.coordinate if @purchase_order.supplier.phones.any?
      report[:supplier_mobile_phone] = @purchase_order.supplier.mobiles.first.coordinate if @purchase_order.supplier.mobiles.any?
      report[:supplier_address] = @purchase_order.supplier_address if @purchase_order.supplier_address.present?
      report[:supplier_email] = supplier_email.first.coordinate if supplier_email.any?
      report[:entity_picture] = Entity.of_company.picture.path

      report[:items] = []

      @purchase_order.items.each do |item|
        i = HashWithIndifferentAccess.new
        i[:variant] = item.variant.name
        i[:quantity] = item.quantity
        i[:unity] = item.variant.unit_name
        i[:unit_pretax_amount] = format('%.2f', item.unit_pretax_amount)
        i[:pretax_amount] = format('%.2f', item.pretax_amount)
        i[:amount] = format('%.2f', item.amount)
        report[:items] << i
      end

      report[:purchase_pretax_amount] = format('%.2f', @purchase_order.pretax_amount)
      report[:purchase_amount] = format('%.2f', @purchase_order.amount)
      report[:purchase_currency] = Onoma::Currency.find(@purchase_order.currency).symbol
      report
    end

    def generate(r)
      dataset = compute_dataset

      e = Entity.of_company
      company_name = e.full_name
      company_address = e.default_mail_address.present? ? e.default_mail_address.coordinate : '-'
      company_phone = e.phones.present? ? e.phones.first.coordinate : '-'
      company_email = dataset[:purchase_responsible_email]

      r.add_field 'COMPANY_ADDRESS', company_address
      r.add_field 'COMPANY_NAME', company_name
      r.add_field 'COMPANY_PHONE', company_phone
      r.add_field 'COMPANY_EMAIL', company_email
      r.add_field 'FILENAME', document_name
      r.add_field 'PRINTED_AT', Time.zone.now.l(format: '%d/%m/%Y %T')

      r.add_field 'PURCHASE_NUMBER', dataset[:purchase_number]
      r.add_field 'PURCHASE_ORDERED_AT', dataset[:purchase_ordered_at]
      r.add_field 'PURCHASE_ESTIMATE_RECEPTION_DATE', dataset[:purchase_estimate_reception_date]
      r.add_field 'PURCHASE_RESPONSIBLE', dataset[:purchase_responsible]
      r.add_field 'SUPPLIER_NAME', dataset[:supplier_name]
      r.add_field 'SUPPLIER_PHONE', dataset[:supplier_phone]
      r.add_field 'SUPPLIER_MOBILE_PHONE', dataset[:supplier_mobile_phone]
      r.add_field 'SUPPLIER_ADDRESS', dataset[:supplier_address]
      r.add_field 'SUPPLIER_EMAIL', dataset[:supplier_email]
      r.add_image :company_logo, dataset[:entity_picture], keep_ratio: true if dataset[:entity_picture]

      r.add_table('P_ITEMS', dataset[:items], header: true) do |t|
        t.add_column(:variant)
        t.add_column(:quantity)
        t.add_column(:unity)
        t.add_column(:unit_pretax_amount)
        t.add_column(:pretax_amount)
        t.add_column(:amount)
      end

      r.add_field 'PURCHASE_PRETAX_AMOUNT', dataset[:purchase_pretax_amount]
      r.add_field 'PURCHASE_AMOUNT', dataset[:purchase_amount]
      r.add_field 'PURCHASE_CURRENCY', dataset[:purchase_currency]
    end

    def key
      @purchase_order.number
    end

    def document_name
      "#{:export_purchase_order.tl} (#{key})"
    end
  end
end
