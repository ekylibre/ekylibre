# frozen_string_literal: true

module Printers
  # Replaces config/locales/fra/reporting/outgoing_delivery_docket.jrxml (Jasper).
  class OutgoingDeliveryDocketPrinter < PrinterBase
    class << self
      def build_key(id:, updated_at:)
        "#{id}-#{updated_at}"
      end
    end

    # @param [Delivery] delivery
    def initialize(*_args, delivery:, template:, **_options)
      super(template: template)

      @delivery = delivery
    end

    def key
      self.class.build_key(id: @delivery.id, updated_at: @delivery.updated_at.to_s)
    end

    def document_name
      "#{template.nature.human_name} - #{@delivery.number}"
    end

    def compute_dataset
      parcels = @delivery.parcels.includes(:items)
      {
        delivery: @delivery,
        parcels: parcels,
        items: parcels.flat_map { |parcel| parcel.items.to_a },
        company: Entity.of_company
      }
    end

    def generate(report)
      dataset = compute_dataset
      delivery = dataset[:delivery]

      report.add_field 'DOCUMENT_NAME', document_name
      report.add_field 'COMPANY_NAME', dataset[:company]&.full_name
      report.add_field 'DELIVERY_NUMBER', delivery.number
      report.add_field 'DELIVERY_REFERENCE_NUMBER', delivery.reference_number
      report.add_field 'DELIVERY_MODE', delivery.mode
      report.add_field 'STARTED_AT', delivery.started_at&.l
      report.add_field 'STOPPED_AT', delivery.stopped_at&.l
      report.add_field 'TRANSPORTER_FULL_NAME', delivery.transporter&.full_name
      report.add_field 'DRIVER_FULL_NAME', delivery.driver&.full_name
      report.add_field 'RESPONSIBLE_FULL_NAME', delivery.responsible&.full_name
      report.add_field 'PRINTED_AT', Time.zone.now.l(format: '%d/%m/%Y %T')

      report.add_table('ITEMS', dataset[:items], header: true) do |t|
        t.add_column(:parcel_number) { |item| item.parcel&.number }
        t.add_column(:recipient_full_name) { |item| item.parcel&.recipient&.full_name }
        t.add_column(:product_name) { |item| item.product&.name || item.variant&.name }
        t.add_column(:product_number) { |item| item.product&.number }
        t.add_column(:population) { |item| item.population.to_s }
      end
    end
  end
end
