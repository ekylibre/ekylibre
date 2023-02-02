# frozen_string_literal: true

module Printers
  class AcWorkSheetPrinter < PrinterBase
    def initialize(*_args, intervention:, template:, **_options)
      super(template: template)
      @intervention = intervention
    end

    attr_reader :intervention

    def generate(r)
      r.add_field(:activity_name, dataset.fetch(:activity_name))
      r.add_field(:projected_work_period, dataset.fetch(:projected_work_period))
      r.add_field(:date, dataset.fetch(:date))
      r.add_field(:workers, dataset.fetch(:workers))
      r.add_field(:manager_full_name, dataset.fetch(:manager_full_name))
      r.add_field(:working_zone_overlaps_nta, dataset.fetch(:working_zone_overlaps_nta))
      r.add_field(:max_entry_factor, dataset.fetch(:max_entry_factor))
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

      target_names = intervention.targets.map(&:variant).pluck(:name).join(', ')
      working_zone = intervention.decorate.sum_targets_working_zone_area
      equipment = Product.joins(:intervention_product_parameters).merge(intervention.tools.where(reference_name: 'sprayer')).pluck(:name).join(', ')
      activity_name = intervention.activities.pluck(:name).join(', ')
      projected_work_period = intervention.started_at.strftime('%d-%m-%Y')
      workers = Product.joins(:intervention_product_parameters).where(variety: 'worker').pluck(:name).uniq.join(', ')
      manager_full_name = Entity.where(nature: 'organization').of_company.full_name
      inputs = intervention.inputs
      working_zone_overlaps_nta = check_overlaps_nta(intervention)

      @dataset = {
        activity_name: activity_name,
        projected_work_period: projected_work_period,
        date: intervention.created_at.strftime('%d-%m-%Y'),
        workers: workers,
        manager_full_name: manager_full_name,
        working_zone_overlaps_nta: working_zone_overlaps_nta,
        max_entry_factor: inputs.map(&:allowed_entry_factor).compact.max,
        max_harvest_factor: inputs.map(&:allowed_harvest_factor).compact.max,
        max_untreated_buffer_aquatic: inputs.map(&:usage).compact.map(&:untreated_buffer_aquatic).compact.max,
        inputs: intervention.inputs.map do |input|
                  {
                    target_names: target_names,
                    working_zone: working_zone,
                    equipment: equipment,
                    product_name: product_name(input.product),
                    quantity: input.input_quantity_per_area.round_l,
                    allowed_entry_factor: input.allowed_entry_factor,
                    untreated_buffer_aquatic: input.usage&.untreated_buffer_aquatic,
                    allowed_harvest_factor: input.allowed_harvest_factor,
                    france_maid: input.usage&.france_maaid
                  }
                end
      }
    end

    def product_name(product)
      if product.tracking
        "#{product.tracking.name} - #{product.tracking.serial}"
      else
        product.variant.name
      end
    end

    def check_overlaps_nta(intervention)
      authorization_calculator = Interventions::Phytosanitary::InterventionInputAuthorizationCalculator.for_intervention(intervention)
      data = intervention.inputs.map { |input| authorization_calculator.authorization_state(input, intervention) }

      if data.any? { |subarray| subarray[1].include?(:working_zone_overlaps_nta.tl) }
        :y.tl
      else
        :n.tl
      end
    end

    def document_name
      template.nature.human_name.to_s
    end
  end
end
