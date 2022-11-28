# frozen_string_literal: true

module Printers
  class PhytosanitaryRegisterPrinter < PrinterBase
    IMPLANTATION_PROCEDURE_NAMES = %w[sowing sowing_without_plant_output sowing_with_spraying mechanical_planting].freeze
    HARVESTING_PROCEDURE_NAMES = %w[straw_bunching harvesting direct_silage].freeze
    SPRAYING_PROCEDURE_NAMES = %w[all_in_one_sowing all_in_one_planting chemical_mechanical_weeding spraying sowing_with_spraying spraying
                                  vine_chemical_weeding vine_spraying_without_fertilizing vine_leaves_fertilizing_with_spraying
                                  vine_spraying_with_fertilizing].freeze
    PHYTOSANITARY_PRODUCT = %w[Variants::Article::PlantMedicineArticle].freeze
    PLANT_FAMILY_ACTIVITIES = %w[plant_farming vine_farming].freeze

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
        @activity = activity
        @activity_production = ActivityProduction.of_activity(@activity).of_activity_families(PLANT_FAMILY_ACTIVITIES).of_campaign(@campaign)
      else
        @campaign = campaign
        @activity_production = ActivityProduction.of_activity_families(PLANT_FAMILY_ACTIVITIES).of_campaign(@campaign)
      end
    end

    def key
      if @activity.present?
        self.class.build_key campaign: @campaign, activity: @activity_production
      else
        self.class.build_key campaign: @campaign
      end
    end

    def document_name
      if @activity.present?
        "#{template.nature.human_name} - #{@activity.name} - #{@campaign.name}"
      else
        "#{template.nature.human_name} - #{@campaign.name}"
      end
    end

    def select_intervention(production, filters)
      intervention = production.interventions.of_campaign(@campaign).select{|intervention| filters.include? intervention.procedure_name}.uniq
    end

    def select_input(intervention)
      input = intervention.inputs.select{|input| input.reference_name=="plant_medicine"}
    end

    def select_variety(production)
      varieties = production.products.select{|product| product.type == "Plant"}
      varieties = varieties.pluck(:specie_variety, :reading_cache)
      varieties.map do |variety|
        if variety[0]["specie_variety_name"].present? && variety[1]["net_surface_area"].present?
          {
            name: variety[0]["specie_variety_name"],
            surface: variety[1]["net_surface_area"].round_l
          }
        end
      end.compact
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
        :at_date.tl(date: max_date)
      else
        :from_to_date.tl(from: min_date, to: max_date)
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

    def total_area_production(intervention, production_id)
      target = intervention.targets.select{|target| production_id == target.product.activity_production_id}
      target.inject(0){|sum, tar| sum + worked_area(tar).to_d}.in_hectare.round_l
    end

    def total_area_intervention(intervention)
      if intervention.working_area.zero?
        intervention.targets.inject(0){|sum, tar| sum + worked_area(tar).to_d}.in_hectare
      else
        intervention.working_area.in_hectare
      end
    end

    def production_nature(production)
      if (nature = production.production_nature).present?
        nature.translation.fra
      elsif (nature = production.activity.production_nature).present?
        nature.translation.fra
      else
        "-"
      end
    end

    def ephy_product_name(input)
      if (ephy_product = RegisteredPhytosanitaryProduct.find_by_reference_name(input.variant&.reference_name)).present?
        ephy_product.name
      else
        input.variant.name
      end
    end

    def input_unit(input, base = false)
      o_unit = if base
                 Onoma::Unit.find(input.input_quantity_per_area.base_unit)
               else
                 Onoma::Unit.find(input.quantity_unit_name)
               end
      if o_unit
        o_unit.symbol
      else
        input.product.unit_name
      end
    end

    def input_rate(input, intervention)
      if input.input_quantity_per_area.repartition_unit.present? || total_area_intervention(intervention).zero?
        input.input_quantity_per_area.round_l
      else
        "#{(input.quantity_value / total_area_intervention(intervention).to_d).round(2)} #{input_unit(input)}/ha"
      end
    end

    def input_usage(input)
      if (usage = RegisteredPhytosanitaryUsage.find_by_id(input&.usage_id)).present?
        usage.target_name_label_fra
      else
        "-"
      end
    end

    def select_description(intervention)
      if intervention.description.present?
        intervention.description
      else
        "-"
      end
    end

    def select_num_pac(production)
      if production.cap_land_parcel.present?
        production.cap_land_parcel.islet_number
      else
        "-"
      end
    end

    def compute_dataset
      productions = @activity_production.map do |production|
        {
          name: production.name,
          surface: production.net_surface_area.in_hectare.round_l,
          cultivable_zone: production.cultivable_zone&.name,
          pac_islet: select_num_pac(production),
          activity: production.activity.name,
          period: compare_date(production.started_on.to_date.l, production.stopped_on.to_date.l),
          specie: production_nature(production),
          variety: select_variety(production),
          sowing_period: period_intervention(production, IMPLANTATION_PROCEDURE_NAMES),
          harvest_period: period_intervention(production, HARVESTING_PROCEDURE_NAMES),
          intervention: select_intervention(production, SPRAYING_PROCEDURE_NAMES).map do |intervention|
            if select_input(intervention).any?
              {
                name: "#{intervention.procedure_name.l} n°#{intervention.number}",
                start: "#{intervention.started_at.to_date.l}\n#{intervention.started_at.l(format: '%Hh%M')}",
                stop: "#{intervention.stopped_at.to_date.l}\n#{intervention.stopped_at.l(format: '%Hh%M')}",
                working_zone: total_area_production(intervention, production.id),
                description: select_description(intervention),
                inputs: select_input(intervention).map do |input|
                  {
                    input_name: ephy_product_name(input),
                    input_quantity: input_rate(input, intervention),
                    input_usage: input_usage(input)
                  }
                end
              }
            end
          end.compact
        }
      end
      {
        productions: productions,
        empty_register: productions.empty? ? [{}] : [],
        company: Entity.of_company
      }
    end

    def generate(r)
      dataset = compute_dataset

      # Header
      r.add_field 'DOCUMENT_NAME', document_name

      # Productions
      r.add_section('Section-production', dataset.fetch(:productions)) do |s|
        s.add_field(:production_name)  { |production| production[:name] }
        s.add_field(:production_surface_area)  { |production| production[:surface] }
        s.add_field(:pac_islet)  { |production| production[:pac_islet] }
        s.add_field(:cultivable_zone)  { |production| production[:cultivable_zone] }
        s.add_field(:activity)  { |production| production[:activity] }
        s.add_field(:production_period)  { |production| production[:period] }
        s.add_field(:production_nature)  { |production| production[:specie] }
        s.add_table('Table-varieties', :variety) do |t|
          t.add_field(:variety_name) { |variety| variety[:name] }
          t.add_field(:variety_surface) { |variety| variety[:surface] }
        end
        s.add_field(:sowing_period)  { |production| production[:sowing_period] }
        s.add_field(:harvest_period)  { |production| production[:harvest_period] }
        s.add_table('Table-intervention', :intervention) do |tt|
          tt.add_field(:intervention_name)  { |intervention| intervention[:name] }
          tt.add_field(:intervention_start)  { |intervention| intervention[:start] }
          tt.add_field(:intervention_stop)  { |intervention| intervention[:stop] }
          tt.add_field(:working_zone)  { |intervention| intervention[:working_zone] }
          tt.add_field(:description)  { |intervention| intervention[:description] }
          tt.add_table('Table-input', :inputs) do |t_input|
            t_input.add_field(:input_name)  { |input| input[:input_name] }
            t_input.add_field(:input_quantity)  { |input| input[:input_quantity] }
            t_input.add_field(:input_usage)  { |input| input[:input_usage] }
          end
        end
      end

      # Footer
      r.add_field(:company_name, dataset.fetch(:company).name)
      r.add_field(:company_address, dataset.fetch(:company).mails.where(by_default: true).first.coordinate)
      r.add_field(:company_siret, dataset.fetch(:company).siret_number)
      r.add_field(:printed_at, Time.zone.now.l(format: '%d/%m/%Y %T'))
      r.add_section(:Section_no_production, dataset.fetch(:empty_register)) do |msg|
        msg
      end
    end
  end
end
