# frozen_string_literal: true

module Printers
  class TechnicalItineraryPrinter < PrinterBase
    # for currency and avatar path methods
    include ApplicationHelper
    include NomenHelper

    class << self
      # TODO: move this elsewhere when refactoring the Document Management System
      def build_key(campaign:, technical_itinerary_ids: nil)
        if technical_itinerary_ids.present? && technical_itinerary_ids.count == 1
          "#{TechnicalItinerary.where(id: technical_itinerary_ids).first.name} - #{campaign.name}"
        else
          campaign.name
        end
      end
    end

    # options[:technical_itinerary_ids], Array of id (integer)
    # options[:campaign] , Campaign Object
    def initialize(*_args, template:, **options)
      super(template: template)
      @campaign = options[:campaign]
      @technical_itineraries = TechnicalItinerary.where(id: options[:technical_itinerary_ids]) if options[:technical_itinerary_ids]
    end

    # Generate document name
    def document_name
      if @technical_itineraries && @technical_itineraries.count == 1
        "#{template.nature.human_name} : #{@technical_itineraries.first.name} #{@campaign.name}"
      else
        "#{template.nature.human_name} : #{@campaign.name}"
      end
    end

    # Create document key
    def key
      self.class.build_key(campaign: @campaign)
    end

    def compute_dataset
      if @technical_itineraries
        technical_itineraries = @technical_itineraries.reorder(:name)
      end
      activities_dataset = technical_itineraries.map do |ti|
        { image: Rails.root.join("app/assets/images/#{activity_avatar_path(ti.activity)}"),
          name: ti.name,
          duration: ti.human_duration,
          average_yield: ti.average_yield,
          doer_global_wl: ti.human_parameter_workload(:doers),
          tool_global_wl: ti.human_parameter_workload(:tools),
          global_workload: ti.human_global_workload,
          total_cost: ti.total_cost,
          items: ti.itinerary_templates.reorder(:position).map do |it|
            {
              position: it.position,
              day_since_start: it.day_since_start,
              human_day_between_intervention: it.human_day_between_intervention,
              human_day_compare_to_planting: it.human_day_compare_to_planting,
              name: it.intervention_template.name,
              preparation_time: it.intervention_template.preparation_time,
              human_workflow: it.intervention_template.human_workflow,
              repetition: it.repetition,
              frequency: it.frequency,
              total_cost: it.intervention_template.total_cost,
              human_time_per_hectare: it.intervention_template.human_time_per_hectare,
              parameters: it.intervention_template.product_parameters.map do |pp|
                {
                  image_pp: Rails.root.join("app/assets/images/interventions/#{pp.find_general_product_type}.png"),
                  nature: pp.find_general_product_type&.tl,
                  name: pp.product_nature_variant.name,
                  quantity: pp.quantity_with_unit,
                  usage_cost: pp.cost_amount_computation.catalog_usage.tl,
                  unit_cost: pp.cost_amount_computation.unit_amount.to_d,
                  currency: pp.cost_amount_computation&.catalog_item&.currency,
                  unit_unity: pp.cost_amount_computation.unit.symbol
                }
              end
            }
          end }
      end.compact
      activities_dataset
    end

    def generate(r)
      company = Entity.of_company
      currency = Onoma::Currency.find(Preference[:currency]).symbol
      dataset = compute_dataset
      r.add_field 'CAMPAIGN_NAME', @campaign.name
      r.add_field 'PRINTED_AT', Time.now.strftime("%d/%m/%y")
      r.add_field 'COMPANY_NAME', company.name
      r.add_field 'COMPANY_ADDRESS', company.mails.where(by_default: true).first.coordinate
      r.add_field 'COMPANY_SIRET', company.siret_number
      r.add_field 'FILENAME', document_name
      r.add_section(:section_ti, dataset) do |s|
        s.add_image(:img_act) { |ti| ti[:image]}
        s.add_field(:ti_name) { |ti| ti[:name]}
        s.add_field(:duration) { |ti| ti[:duration]}
        s.add_field(:av_yield) { |ti| ti[:average_yield]}
        s.add_field(:total_cost) { |ti| ti[:total_cost]}
        s.add_field(:doer_global_wl) { |ti| ti[:doer_global_wl]}
        s.add_field(:tool_global_wl) { |ti| ti[:tool_global_wl]}
        s.add_field(:global_workload) { |ti| ti[:global_workload]}
        s.add_section(:section_procedure, :items) do |sp|
          sp.add_field(:position) { |spi| spi[:position]}
          sp.add_field(:name) { |spi| spi[:name]}
          sp.add_field(:curr) { currency }
          sp.add_field(:d_b_i) { |spi| spi[:human_day_between_intervention]}
          sp.add_field(:d_s_s) { |spi| spi[:day_since_start]}
          sp.add_field(:d_c_p) { |spi| spi[:human_day_compare_to_planting]}
          sp.add_field(:human_workflow) { |spi| spi[:human_workflow]}
          sp.add_field(:preparation_time) { |spi| spi[:preparation_time]}
          sp.add_field(:total_pro_cost) { |spi| spi[:total_cost]}
          sp.add_table(:table_parameters, :parameters) do |ts|
            ts.add_image(:img_pp) { |i| i[:image_pp]}
            ts.add_field(:nature) { |i| i[:nature]}
            ts.add_field(:name) { |i| i[:name]}
            ts.add_field(:quantity) { |i| i[:quantity]}
            ts.add_field(:usage_cost) { |i| i[:usage_cost]}
            ts.add_field(:unit_cost) { |i| i[:unit_cost]}
            ts.add_field(:cur) { |i| i[:currency]}
            ts.add_field(:unit) { |i| i[:unit_unity]}
          end
        end
      end
    end

  end
end
