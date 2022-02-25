# frozen_string_literal: true

using Ekylibre::Utils::NumericLocalization

module Printers
  module Sale
    class SalesInvoiceShipmentPrinter < SalePrinterBase
      include ApplicationHelper
      def initialize(sale:, template:)
        super(sale: SaleDecorator.decorate(sale), template: template)
      end

      def delivery_address_dataset(sale, client)
        if sale.has_same_delivery_address?
          []
        else
          [{ delivery_address: Maybe(sale).delivery_address.mail_coordinate.recover { client.full_name }.or_else("") }]
        end
      end

      def build_shipment_sale_items(sale)
        dataset = []
        sale.items.group_by(&:shipment).each do |shipment, items|
          h = {}
          h[:number] = "#{:shipping_note.tl} #{shipment.number}" if shipment
          h[:reference_number] = shipment&.reference_number
          h[:given_at] = shipment&.given_at&.l(format: '%d %B %Y')
          h[:address] = shipment&.address&.coordinate
          h[:global_pretax_amount] = items.pluck(:pretax_amount).compact.sum.round_l
          h[:global_vat_amount] = (items.pluck(:amount).compact.sum - items.pluck(:pretax_amount).compact.sum).round_l
          h[:global_amount] = items.pluck(:amount).compact.sum.round_l
          h[:items] = []
          items.each do |item|
            h_i = {}
            h_i[:code] = item.variant.number
            h_i[:variant] = "#{item.variant.name} (#{item.conditioning_unit.name})"
            h_i[:quantity] = item.conditioning_quantity.round_l
            h_i[:unit_pretax_amount] = item.unit_pretax_amount.round_l_auto
            h_i[:discount] = item.reduction_percentage.round_l || '0.00'
            h_i[:pretax_amount] = item.pretax_amount.round_l
            h_i[:vat_amount] = (item.pretax_amount * item.tax.amount / 100).abs.round_l
            h_i[:vat_rate] = item.tax.amount.round_l
            h_i[:amount] = item.amount.round_l
            h[:items] << h_i
          end
          dataset << h
        end
        dataset
      end

      def generate(r)
        # Companies
        company = EntityDecorator.decorate(Entity.of_company)
        receiver = EntityDecorator.decorate(sale.client)

        # Cash
        cash = get_company_cash

        client_reference = Maybe(sale).client_reference.fmap(&:presence).or_else('Non renseigné')

        # Header
        r.add_image :company_logo, company.picture.path, keep_ratio: true if company.has_picture?

        # Date
        r.add_field :date, Time.zone.now.l(format: '%d %B %Y')

        # Title
        r.add_field :title, I18n.t('labels.export_sales_invoice')
        r.add_field :invoiced_at, sale.invoiced_at.l(format: '%d %B %Y') if sale.invoiced_at.present?
        r.add_field :responsible, Maybe(sale).responsible.full_name.or_else('Non renseigné')
        r.add_field :client_reference, client_reference

        # Expired_at
        r.add_field :expired_at, Delay.new(sale.payment_delay).compute(sale.invoiced_at).l(format: '%d %B %Y') if sale.invoiced_at.present?

        # Company_address
        r.add_field :company_name, company.full_name
        r.add_field :company_address, company.address
        r.add_field :company_email, company.email
        r.add_field :company_phone, company.phone
        r.add_field :company_website, company.website

        # Invoice_address
        r.add_field :invoice_address, Maybe(sale).invoice_address.mail_coordinate.recover { receiver.full_name }.or_else('')

        # Receiver vat_number
        r.add_field :receiver_vat_number, receiver.vat_number

        # Estimate_number
        r.add_field :number, sale.number
        r.add_field :description, sale.description

        # details group by parcel
        dataset_shipment_items = build_shipment_sale_items(sale)
        r.add_section('Section-parcel', dataset_shipment_items) do |pa|
          pa.add_field(:number) { |item| item[:number] }
          pa.add_field(:given_at) { |item| item[:given_at] }
          pa.add_field(:address) { |item| item[:address] }
          pa.add_field(:g_pt_am) { |item| item[:global_pretax_amount] }
          pa.add_field(:g_vt_am) { |item| item[:global_vat_amount] }
          pa.add_field(:g_am) { |item| item[:global_amount] }
          pa.add_table('parcel-items', :items) do |t|
            t.add_field(:code) { |item| item[:code] }
            t.add_field(:variant) { |item| item[:variant] }
            t.add_field(:quantity) { |item| item[:quantity] }
            t.add_field(:pu) { |item| item[:unit_pretax_amount] }
            t.add_field(:rem) { |item| item[:discount] }
            t.add_field(:ht) { |item| item[:pretax_amount] }
            t.add_field(:vat) { |item| item[:vat_amount] }
            t.add_field(:vat_rate) { |item| item[:vat_rate] }
            t.add_field(:ttc) { |item| item[:amount] }
          end
        end

        # Sales conditions
        r.add_field :sales_conditions, Preference[:sales_conditions]
        # Sales payment mode complement
        r.add_field :payment_mode_complement, sale.nature.payment_mode_complement

        # Totals
        r.add_field :total_pretax, sale.pretax_amount.round_l
        r.add_field :total_vat, (sale.amount - sale.pretax_amount).round_l
        r.add_field :total, sale.amount.round_l

        # Details
        r.add_table('details', sale.other_deals) do |s|
          s.add_field(:payment_date) { |item| AffairableDecorator.decorate(item).payment_date.l(format: '%d %B %Y') }
          s.add_field(:payment_mode) { |item| (item.is_a?(IncomingPayment) ? item.mode.name : '') }
          s.add_field(:payment_number, &:number)
          s.add_field(:payment_amount) { |item| if item.class == sale.class
                                                  ''
                                                else
                                                  item.attribute_names.include?('amount') ? item.amount.round_l : item.affair.credit.round_l
                                                end}
          s.add_field(:sale_affair) { |item| item.class == sale.class ? item.amount.round_l : '' }
        end

        # vat totals
        r.add_table('vat-totals', build_vat_totals, headers: true) do |v|
          v.add_field(:vat_name) { |item| item[:tax_name] }
          v.add_field(:vat_rate) { |item| item[:tax_rate] }
          v.add_field(:vat_base) { |item| item[:tax_base_pretax_amount] }
          v.add_field(:vat_amount) { |item| item[:tax_amount] }
        end

        # Affair + left to pay or receive
        r.add_field :affair_number, sale.affair.number
        if (sale.affair.debit - sale.affair.credit).negative?
          r.add_field :action, I18n.t('labels.receive').downcase
        else
          r.add_field :action, I18n.t('labels.pay').downcase
        end
        r.add_field :left_to_pay, (sale.affair.debit - sale.affair.credit).round_l

        # Footer
        r.add_field :footer, "#{I18n.t 'attributes.intracommunity_vat'} : #{company.vat_number} - #{I18n.t 'attributes.siret'} : #{company.siret_number} - #{I18n.t 'attributes.activity_code'} : #{company.activity_code}"
        r.add_field :client_number, receiver.number

        # Bank details
        r.add_field :account_holder_name, cash.bank_account_holder_name.recover { company.bank_account_holder_name }.or_else('')
        r.add_field :bank_name, cash.bank_name.or_else('')
        r.add_field :bank_identifier_code, cash.bank_identifier_code.or_else('')
        r.add_field :iban, cash.iban.scan(/.{1,4}/).join(' ').or_else('')
      end
    end
  end
end
