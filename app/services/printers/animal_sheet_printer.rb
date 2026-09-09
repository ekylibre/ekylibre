# frozen_string_literal: true

module Printers
  # Replaces config/locales/fra/reporting/animal_sheet.xml (Jasper).
  class AnimalSheetPrinter < PrinterBase
    class << self
      def build_key(id:, updated_at:)
        "#{id}-#{updated_at}"
      end
    end

    # @param [Animal] animal
    def initialize(*_args, animal:, template:, **_options)
      super(template: template)

      @animal = animal
    end

    def key
      self.class.build_key(id: @animal.id, updated_at: @animal.updated_at.to_s)
    end

    def document_name
      "#{template.nature.human_name} - #{@animal.identification_number || @animal.name}"
    end

    def compute_dataset
      { animal: @animal, company: Entity.of_company, readings: @animal.readings.order(:id) }
    end

    def generate(report)
      dataset = compute_dataset
      animal = dataset[:animal]

      report.add_field 'DOCUMENT_NAME', document_name
      report.add_field 'COMPANY_NAME', dataset[:company]&.full_name
      report.add_field 'NAME', animal.name
      report.add_field 'IDENTIFICATION_NUMBER', animal.identification_number
      report.add_field 'WORK_NUMBER', animal.work_number
      report.add_field 'VARIETY', animal.variety
      report.add_field 'SEX', animal.sex
      report.add_field 'BORN_AT', animal.born_at&.l
      report.add_field 'DEAD_AT', animal.dead_at&.l
      report.add_field 'MOTHER_NAME', animal.mother&.name
      report.add_field 'FATHER_NAME', animal.father&.name
      report.add_field 'NATURE_NAME', animal.nature&.name
      report.add_field 'DESCRIPTION', animal.description
      report.add_field 'PRINTED_AT', Time.zone.now.l(format: '%d/%m/%Y %T')

      report.add_table('READINGS', dataset[:readings], header: true) do |t|
        t.add_column(:indicator, &:indicator_name)
        t.add_column(:value) { |reading| reading.value.to_s }
        t.add_column(:read_at) { |reading| reading.read_at&.l }
      end
    end
  end
end
