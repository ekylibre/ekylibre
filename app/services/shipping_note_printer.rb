class ShippingNotePrinter
  include PdfPrinter

  attr_reader :document_nature

  def initialize(options)
    @document_nature = Nomen::DocumentNature.find(:shipping_note)
    @template_path = find_open_document_template(:shipping_note)
    @shipment = options[:shipment]
  end

  def run_pdf
    # Companies
    company = EntityDecorator.decorate(Entity.of_company)
    receiver = EntityDecorator.decorate(@shipment.sale&.client || @shipment.recipient)

    # Title
    title = document_nature.name.tl

    # Custom_fields
    custom_fields = @shipment.custom_fields ? @shipment.custom_fields.map(&:last).join('\n') : ''

    generate_report(@template_path) do |r|
      # Title
      r.add_field :title, title.mb_chars.upcase

      # Date
      r.add_field :date, Time.zone.now.l(format: '%d %B %Y')

      # Company_logo
      r.add_image :company_logo, company.picture.path if company.has_picture?

      # Company_address
      r.add_field :company_name, company.full_name
      r.add_field :company_address, company.address.upcase
      r.add_field :company_email, company.email
      r.add_field :company_phone, company.phone
      r.add_field :company_website, company.website

      # Receiver_address
      r.add_field :receiver, receiver.full_name
      r.add_field :receiver_address, receiver.address.upcase
      r.add_field :receiver_phone, receiver.phone
      r.add_field :receiver_email, receiver.email

      # Shipping_number
      r.add_field :shipping_number, @shipment.number

      # Planned_at
      r.add_field :planned_at, @shipment.planned_at.l(format: '%d %B %Y')

      # Custom_field
      r.add_field :custom_fieldS, custom_fields

      # Parcels
      r.add_table('parcels', @shipment.items) do |t|
        # Parcel_number
        t.add_field(:parcel_number) { |item| item.variant.number }

        # Parcel_variant
        t.add_field(:parcel_variant) { |item| item.variant.name }

        # Parcel_quantity
        t.add_field(:parcel_quantity, &:quantity)

        # Unit
        t.add_field(:unit) { |item| item.variant.unit_name }
      end
    end
  end

  def key
    @shipment.number
  end
end
