module Printers
  class ShippingNotePrinter < PrinterBase

    attr_reader :shipment

    def initialize(template:, shipment:)
      super(template: template)

      @shipment = shipment
    end

    def run_pdf
      # Companies
      company = EntityDecorator.decorate(Entity.of_company)
      receiver = EntityDecorator.decorate(shipment.recipient)

      # Custom_fields
      custom_fields = Maybe(shipment).custom_fields.map(&:last).join('\n').or_else('')

      generate_report(template_path) do |r|
        # Company_logo
        r.add_image :company_logo, company.picture.path if company.has_picture?

        # Company_address
        r.add_field :company_address, company.address.upcase
        r.add_field :company_phone, company.phone
        r.add_field :company_email, company.email
        r.add_field :company_website, company.website

        # Receiver_address
        r.add_field :receiver_address, receiver.address.upcase

        # Shipping_number
        r.add_field :shipping_number, shipment.number

        # Planned_at
        r.add_field :planned_at, shipment.planned_at.l(format: '%d %B %Y')

        # Custom_fields
        r.add_field :custom_fields, custom_fields

        # Parcels
        r.add_table(:parcels, shipment.items) do |t|
          # Parcel_number
          t.add_field(:product_number) { |item| item.source_product.number }

          # Parcel_variant
          t.add_field(:product_name) { |item| item.source_product.name }

          # Parcel_quantity
          t.add_field(:parcel_quantity, &:quantity)

          # Unit
          t.add_field(:unit) { |item| item.variant.unit_name }
        end
      end
    end

    def key
      shipment.number
    end
  end
end