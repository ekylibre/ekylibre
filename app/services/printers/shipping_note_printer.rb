# frozen_string_literal: true

module Printers
  class ShippingNotePrinter < PrinterBase
    attr_reader :shipment

    def initialize(shipment:, template:)
      super(template: template)

      @shipment = shipment
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
      end
    end

    def key
      shipment.number
    end
  end
end
