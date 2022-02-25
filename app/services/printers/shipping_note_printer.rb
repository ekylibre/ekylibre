# frozen_string_literal: true

module Printers
  class ShippingNotePrinter < PrinterBase
    attr_reader :shipment

    def initialize(shipment:, template:)
      super(template: template)
      @currency = Onoma::Currency.find(Preference[:currency] || 'EUR')
      @shipment = shipment
    end

    def as_currency(value)
      value.l(currency: @currency.name, precision: 2)
    end

    def generate(r)
      # Companies
      company = EntityDecorator.decorate(Entity.of_company)

      # custom_fields
      custom_fields = if Shipment.customizable?
                        Shipment.custom_fields.map do |f|
                          next unless (value = shipment.custom_value(f))

                          if f.nature == :boolean
                            value = :y.tl if value == '1'
                            value = :n.tl if value == '0'
                          end
                          "#{f.name}: #{value}"
                        end
                      else
                        []
                      end

      # Company_logo
      r.add_image :company_logo, company.picture.path, keep_ratio: true if company.has_picture?

      # Company_address
      r.add_field :company_address, company.address
      r.add_field :company_phone, company.phone
      r.add_field :company_email, company.email
      r.add_field :company_website, company.website

      # Receiver_address
      r.add_field :receiver_address, shipment.address.mail_coordinate

      # Shipping_number
      r.add_field :shipping_number, shipment.number

      # Planned_at
      r.add_field :planned_at, shipment.planned_at.l(format: '%d %B %Y')

      # Custom_fields
      r.add_field :custom_fields, custom_fields.join('\n')

      # Parcels
      r.add_table(:parcels, shipment.items) do |t|
        # Parcel_number
        t.add_field(:product_number) { |item| item.source_product.number }

        # Parcel_variant
        t.add_field(:product_name) { |item| item.source_product.name }

        # Parcel_quantity
        t.add_field(:parcel_quantity) { |item| item.conditioning_quantity.round_l }

        # Unit
        t.add_field(:unit) { |item| item.conditioning_unit.name }

        # Total_quantity
        t.add_field(:total_quantity) { |item|  (item.conditioning_quantity * item.conditioning_unit.coefficient).round_l}

        # PU HT
        t.add_field(:amount) { |item| as_currency(item.unit_pretax_sale_amount) }

        # PU HT
        t.add_field(:global_amount) { |item| as_currency(item.conditioning_quantity * item.conditioning_unit.coefficient * item.unit_pretax_sale_amount) }

        # base unit name
        t.add_field(:base_unit) { |item| item.conditioning_unit.base_unit.symbol}
      end

      # Footer
      r.add_field :company_activity_code, company.activity_code
      r.add_field :company_vat, company.vat_number
      r.add_field :company_siret, company.siret_number
    end

    def key
      shipment.number
    end
  end
end
