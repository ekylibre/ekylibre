# frozen_string_literal: true

module Printers
  # Replaces config/locales/fra/reporting/cultivable_zone_sheet.jrxml (Jasper).
  class CultivableZoneSheetPrinter < PrinterBase
    class << self
      def build_key(id:, updated_at:)
        "#{id}-#{updated_at}"
      end
    end

    # @param [CultivableZone] cultivable_zone
    def initialize(*_args, cultivable_zone:, template:, **_options)
      super(template: template)

      @cultivable_zone = cultivable_zone
    end

    def key
      self.class.build_key(id: @cultivable_zone.id, updated_at: @cultivable_zone.updated_at.to_s)
    end

    def document_name
      "#{template.nature.human_name} - #{@cultivable_zone.work_number || @cultivable_zone.name}"
    end

    def compute_dataset
      {
        zone: @cultivable_zone,
        productions: @cultivable_zone.activity_productions.includes(:activity).order(:started_on),
        company: Entity.of_company
      }
    end

    def generate(report)
      dataset = compute_dataset
      zone = dataset[:zone]

      report.add_field 'DOCUMENT_NAME', document_name
      report.add_field 'COMPANY_NAME', dataset[:company]&.full_name
      report.add_field 'NAME', zone.name
      report.add_field 'WORK_NUMBER', zone.work_number
      report.add_field 'CAP_NUMBER', zone.cap_number
      report.add_field 'DESCRIPTION', zone.description
      report.add_field 'HUMAN_SHAPE_AREA', zone.human_shape_area
      report.add_field 'PRINTED_AT', Time.zone.now.l(format: '%d/%m/%Y %T')

      report.add_table('PRODUCTIONS', dataset[:productions], header: true) do |t|
        t.add_column(:production_name, &:name)
        t.add_column(:activity_name) { |production| production.activity&.name }
        t.add_column(:started_on) { |production| production.started_on&.l }
        t.add_column(:stopped_on) { |production| production.stopped_on&.l }
        t.add_column(:production_area, &:human_support_shape_area)
      end
    end
  end
end
