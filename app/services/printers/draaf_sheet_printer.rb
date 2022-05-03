# frozen_string_literal: true

module Printers
  class DraafSheetPrinter < PrinterBase
    def initialize(*_args, intervention:, template:, **_options)
      super(template: template)
      @intervention = intervention
    end

    attr_reader :intervention

    def generate(r)
      r.add_field(:max_entry_factor, dataset.fetch(:max_entry_factor)&.in_second&.in_hour&.round_l)
      r.add_field(:max_harvest_factor, dataset.fetch(:max_harvest_factor)&.in_second&.in_day&.round_l)
      r.add_field(:max_untreated_buffer_aquatic, dataset.fetch(:max_untreated_buffer_aquatic))
      r.add_table('inputs', dataset.fetch(:inputs), header: true) do |t|
        t.add_field(:target_names) { |wp| wp[:target_names] }
        t.add_field(:working_zone) { |wp| wp[:working_zone] }
        t.add_field(:equipment) { |wp| wp[:equipment] }
        t.add_field(:product_name) { |wp| wp[:product_name] }
        t.add_field(:quantity) { |wp| wp[:quantity] }
        t.add_field(:allowed_entry_factor) { |wp| wp[:allowed_entry_factor]&.in_second&.in_hour&.round_l }
        t.add_field(:untreated_buffer_aquatic) { |wp| wp[:untreated_buffer_aquatic]}
        t.add_field(:allowed_harvest_factor) { |wp| wp[:allowed_harvest_factor]&.in_second&.in_day&.round_l }
        t.add_field(:france_maid) { |wp| wp[:france_maid] }
      end
    end

    def dataset
      return @dataset if @dataset.present?

      target_names = Product.joins(:intervention_product_parameters).merge(intervention.targets).pluck(:name).join(', ')
      working_zone = intervention.decorate.sum_targets_working_zone_area
      equipment = Product.joins(:intervention_product_parameters).merge(intervention.tools.where(reference_name: 'sprayer')).pluck(:name).join(', ')
      inputs = intervention.inputs

      @dataset = {
        max_entry_factor: inputs.map(&:allowed_entry_factor).compact.max,
        max_harvest_factor: inputs.map(&:allowed_harvest_factor).compact.max,
        max_untreated_buffer_aquatic: inputs.map(&:usage).compact.map(&:untreated_buffer_aquatic).compact.max,
        inputs: intervention.inputs.map do |input|
                  {
                    target_names: target_names,
                    working_zone: working_zone,
                    equipment: equipment,
                    product_name: input.product.name,
                    quantity: input.input_quantity_per_area.round_l,
                    allowed_entry_factor: input.allowed_entry_factor,
                    untreated_buffer_aquatic: input.usage&.untreated_buffer_aquatic,
                    allowed_harvest_factor: input.allowed_harvest_factor,
                    france_maid: input.usage&.france_maaid
                  }
                end
      }
    end

    def document_name
      template.nature.human_name.to_s
    end
  end
end
