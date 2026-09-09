# frozen_string_literal: true

module Printers
  # Replaces config/locales/fra/reporting/animal_list.xml (Jasper).
  class AnimalListPrinter < PrinterBase
    class << self
      def build_key(printed_at: Time.zone.now)
        printed_at.strftime('%Y%m%d%H%M%S')
      end
    end

    # @param [ActiveRecord::Relation, Array<Animal>] animals
    def initialize(*_args, template:, animals: nil, **_options)
      super(template: template)

      @animals = animals || Animal.all
      @printed_at = Time.zone.now
    end

    def key
      self.class.build_key(printed_at: @printed_at)
    end

    def document_name
      "#{template.nature.human_name} - #{@printed_at.l(format: '%d/%m/%Y')}"
    end

    def compute_dataset
      { animals: @animals.to_a, company: Entity.of_company }
    end

    def generate(report)
      dataset = compute_dataset

      report.add_field 'DOCUMENT_NAME', document_name
      report.add_field 'COMPANY_NAME', dataset[:company]&.full_name
      report.add_field 'ANIMAL_COUNT', dataset[:animals].size
      report.add_field 'PRINTED_AT', @printed_at.l(format: '%d/%m/%Y %T')

      report.add_table('ANIMALS', dataset[:animals], header: true) do |t|
        t.add_column(:identification_number, &:identification_number)
        t.add_column(:name, &:name)
        t.add_column(:work_number, &:work_number)
        t.add_column(:variety, &:variety)
        t.add_column(:sex, &:sex)
        t.add_column(:born_at) { |animal| animal.born_at&.l }
        t.add_column(:mother_name) { |animal| animal.mother&.name }
      end
    end
  end
end
