module Printers
  module Sale
    class SalesInvoicePrinter < SalePrinterBase
      def initialize(template:, sale:)
        super(template: template, sale: SaleDecorator.decorate(sale))
      end

      def delivery_address_dataset(sale, client)
        if sale.has_same_delivery_address?
          []
        else
          [{ delivery_address: Maybe(sale).delivery_address.mail_coordinate.recover { client.full_name }.or_else("") }]
        end
      end

      def run_pdf
        # Companies
        company = EntityDecorator.decorate(Entity.of_company)
        receiver = EntityDecorator.decorate(sale.client)

        # Cash
        cash = get_company_cash

        client_reference = Maybe(sale).client_reference.fmap(&:presence).or_else('Non renseigné')

        description = Maybe(sale).description.fmap { |d| [{ description: d }] }.or_else([])

        generate_report(@template_path) do |r|
          # Header
          r.add_image :company_logo, company.picture.path, keep_ratio: true if company.has_picture?

          # Date
          r.add_field :date, Time.zone.now.l(format: '%d %B %Y')

          # Title
          r.add_field :title, I18n.t('labels.export_sales_invoice')
          r.add_field :invoiced_at, sale.invoiced_at.l(format: '%d %B %Y')
          r.add_field :responsible, Maybe(sale).responsible.full_name.or_else { "Non renseigné" }
          r.add_field :client_reference, client_reference

          # Expired_at
          r.add_field :expired_at, Delay.new(sale.payment_delay).compute(sale.invoiced_at).l(format: '%d %B %Y')

          # Company_address
          r.add_field :company_name, company.full_name
          r.add_field :company_address, company.address
          r.add_field :company_email, company.email
          r.add_field :company_phone, company.phone
          r.add_field :company_website, company.website

          # Invoice_address
          r.add_field :invoice_address, Maybe(sale).invoice_address.mail_coordinate.recover { receiver.full_name }.or_else('')

          r.add_section('Section-delivery-address', delivery_address_dataset(sale, receiver)) do |da_s|
            da_s.add_field(:delivery_address) { |e| e[:delivery_address] }
          end

          # Estimate_number
          r.add_field :number, sale.number

          r.add_section('Section-description', description) do |sd|
            sd.add_field(:description) { |item| item[:description] }
          end

          # Items_table
          r.add_table('items', sale.items) do |t|
            t.add_field(:code) { |item| item.variant.number }
            t.add_field(:variant) { |item| item.variant.name }
            t.add_field(:quantity) { |item| item.quantity.round_l }
            t.add_field(:unit_pretax_amount) { |item| item.unit_pretax_amount.round_l }
            t.add_field(:discount) { |item| item.reduction_percentage.round_l || '0.00' }
            t.add_field(:pretax_amount) { |item| item.pretax_amount.round_l }
            t.add_field(:vat_amount) { |item| (item.pretax_amount * item.tax.amount / 100).abs.round_l }
            t.add_field(:vat_rate) { |item| item.tax.amount.round_l }
            t.add_field(:amount) { |item| item.amount.round_l }
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
            s.add_field(:payment_number, &:number)
            s.add_field(:payment_amount) { |item| item.class == sale.class ? '' : item.amount.round_l }
            s.add_field(:sale_affair) { |item| item.class == sale.class ? item.amount.round_l : '' }
          end

          # Affair + left to pay or receive
          r.add_field :affair_number, sale.affair.number
          if (sale.affair.debit - sale.affair.credit).negative?
            r.add_field :action, I18n.t('labels.receive').downcase
          else
            r.add_field :action, I18n.t('labels.pay').downcase
          end
          r.add_field :left_to_pay, (sale.affair.debit - sale.affair.credit).round_l

          # Parcels
          parcels = sale.parcel_items.any? ? [sale] : []

          r.add_section('Section-parcels', parcels) do |s|
            s.add_table('parcels', :parcel_items) do |t|
              t.add_field(:parcel_code) { |item| item.variant.number }
              t.add_field(:parcel_variant) { |item| item.variant.name }
              t.add_field(:parcel_quantity) { |item| item.quantity.round_l }
              t.add_field(:parcel_number) { |item| item.parcel.number }
              t.add_field(:planned_at) { |item| item.parcel.planned_at.l(format: '%d %B %Y') }
            end
          end

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
end
