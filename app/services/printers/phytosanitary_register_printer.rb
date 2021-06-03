# frozen_string_literal: true

module Printers
  class PhytosanitaryRegisterPrinter < PrinterBase
    IMPLANTATION_PROCEDURE_NAMES = %w[sowing sowing_without_plant_output sowing_with_spraying mechanical_planting].freeze
    HARVESTING_PROCEDURE_NAMES = %w[straw_bunching harvesting direct_silage].freeze
    SPRAYING_PROCEDURE_NAMES = %w[all_in_one_sowing chemical_mechanical_weeding spraying sowing_with_spraying spraying
                                  vine_chemical_weeding vine_spraying_without_fertilizing vine_leaves_fertilizing_with_spraying].freeze

    class << self
      # TODO: move this elsewhere when refactoring the Document Management System
      def build_key(campaign:, activity: nil)
        if activity.present?
          "#{activity.name} - #{campaign.name}"
        else
          campaign.name
        end
      end
    end

    def initialize(*_args, campaign:, activity: nil, template:, **_options)
      super(template: template)
      if activity.present?
        @campaign = campaign
        @activity_production = activity
      else
        @campaign = campaign
        @activity_production = ActivityProduction.of_campaign(@campaign)
      end
    end

    def key
      if activity.present?
        self.class.build_key campaign: @campaign, activity: @activity_production
      else
        self.class.build_key campaign: @campaign
      end
    end

    def select_intervention(activity, filters)
      activity.interventions.select{|intervention| filters.include? intervention.procedure_name}.uniq
    end

    def min_start_date(intervention)
      if intervention.present?
        intervention.map(&:started_at).max.strftime('%d/%m/%Y')
      else
        "-"
      end
    end

    def max_stop_date(intervention)
      if intervention.present?
        intervention.map(&:stopped_at).max.strftime('%d/%m/%Y')
      else
        "-"
      end
    end

    def compare_date(min_date, max_date)
      if min_date == max_date
        "Le #{max_date}"
      else
        "Du #{min_date}\nau #{max_date}"
      end
    end

    def period_intervention(activity, filters)
      select_int = select_intervention(activity, filters)
      min_date = min_start_date(select_int)
      max_date = max_stop_date(select_int)
      compare_date(min_date, max_date)
    end

    def worked_area(target)
      worked_area = if target.working_area.present?
        target.working_area
      else
        target.product.net_surface_area
      end
      worked_area.in_hectare.round(3)
    end

    def total_area(intervention,production_id)
      target = intervention.targets.select{|target| production_id == target.product.activity_production_id}
      target.inject(0){|sum, tar| sum + worked_area(tar).to_d}.in_hectare
    end

    def compute_dataset
      productions = @activity_production.map do |production|
        {
          name: production.name,
          surface: production.net_surface_area.in_hectare.round_l,
          cultivable_zone: production.cultivable_zone.name,
          activity: production.activity.name,
          started_at: production.started_on.to_date.l,
          stopped_at: production.stopped_on.to_date.l,
          specie: production.activity.production_nature,
          variety: None(),
          sowing_period: period_intervention(production, IMPLANTATION_PROCEDURE_NAMES),
          harvest_period: period_intervention(production, HARVESTING_PROCEDURE_NAMES),
          intervention: select_intervention(production, SPRAYING_PROCEDURE_NAMES).map do |intervention|
            {
              name: "#{intervention.procedure_name.l} n°#{intervention.number}",
              date: compare_date(intervention.started_at.to_date.l, intervention.stopped_at.to_date.l),
              period: "De #{intervention.started_at.strftime('%Hh%M')}\nà #{intervention.stopped_at.strftime('%Hh%M')}",
              working_zone: total_area(intervention,production.id),
              description: intervention.description
            }
          end
        }
      end
    end

    def generate(r)
      dataset = compute_dataset
      # Productions
      r.add_table('Tableau1', dataset) do |t|
        t.add_field(:production_name) { |production| production[:name] }
        t.add_field(:production_surface_area) { |production| production[:surface] }
        t.add_field(:started_on) { |production| production[:started_on] }
        t.add_field(:stopped_on) { |production| production[:stopped_on] }
        t.add_field(:cultivable_zone) { |production| production[:cultivable_zone] }
        t.add_field(:specie) { |production| production[:specie] }
      end
    end
  end
end
