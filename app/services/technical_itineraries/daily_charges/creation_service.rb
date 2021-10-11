# frozen_string_literal: true

module TechnicalItineraries
  module DailyCharges
    class CreationService
      attr_reader :activity_production, :itinerary_templates,
                  :planting_template, :started_at, :net_surface_area,
                  :batch_number, :irregular_batch_id

      def initialize(activity_production)
        @activity_production = activity_production
        @itinerary_templates = init_itinerary_templates
        @planting_template = init_planting_template
        @started_at = init_started_at
      end

      def perform(sowing_start_date, net_surface_area, batch_number: nil, irregular_batch_id: nil)
        @net_surface_area = net_surface_area
        @batch_number = batch_number
        @irregular_batch_id = irregular_batch_id

        create_proposals_and_daily_charges(sowing_start_date)
      end

      private

        def init_itinerary_templates
          @activity_production
            .technical_itinerary
            .itinerary_templates
            .includes(:intervention_template)
        end

        def init_planting_template
          @itinerary_templates
            .select{ |itinerary_template| itinerary_template.intervention_template.planting? }
            .first
        end

        def init_started_at
          return @activity_production.started_on if @planting_template.nil?

          @activity_production.predicated_sowing_date || @activity_production.started_on
        end

        def create_proposals_and_daily_charges(sowing_start_date)
          first_template = find_first_template

          @itinerary_templates.each do |itinerary_template|
            started_date = started_template_date(itinerary_template, first_template, sowing_start_date)

            create_intervention_proposal(itinerary_template, started_date)
            create_products_daily_charges(itinerary_template, started_date)
          end
        end

        def find_first_template
          @itinerary_templates
            .order(:position)
            .first
        end

        def started_template_date(itinerary_template, first_template, started_at)
          if (@planting_template.nil? ||
              @activity_production.predicated_sowing_date.nil?) &&
              @irregular_batch_id.nil?
            additionnal_days = @itinerary_templates
                                 .where(position: (first_template.position)..(itinerary_template.position))
                                 .sum(:day_between_intervention)

            return started_at + additionnal_days
          end

          started_at + itinerary_template.day_compare_to_planting
        end

        def create_intervention_proposal(itinerary_template, started_date)
          intervention_proposal = itinerary_template
                                    .intervention_proposals
                                    .build(
                                      estimated_date: started_date,
                                      area: @net_surface_area,
                                      activity_production: @activity_production,
                                      batch_number: @batch_number,
                                      activity_production_irregular_batch_id: @irregular_batch_id
                                    )

          intervention_proposal.save
        end

        def create_products_daily_charges(itinerary_template, started_date)
          intervention_template = itinerary_template.intervention_template
          product_parameters = intervention_template.product_parameters

          product_parameters.each do |product_parameter|
            product_type = product_parameter.procedure['type']
            general_type = product_parameter.find_general_product_type

            quantity = intervention_template.quantity_of_parameter(product_parameter, @net_surface_area)

            if general_type == :doer
              quantity += ((intervention_template.preparation_time_hours || 0) + (intervention_template.preparation_time_minutes || 0) / 60.0) * product_parameter.quantity
            end

            duration = itinerary_template.duration

            if duration.present? && duration > 0 && !itinerary_template.dont_divide_duration
              quantity /= duration
              duration.times do |x|
                special_date = started_date + x.days
                create_daily_charge(product_parameter, product_type, quantity, special_date, general_type)
              end
            else
              create_daily_charge(product_parameter, product_type, quantity, started_date, general_type)
            end
          end
        end

        def create_daily_charge(product_parameter, product_type, quantity, date, general_type)
          daily_charge = product_parameter
                           .daily_charges
                           .build(reference_date: date,
                                  product_type: product_type,
                                  product_general_type: general_type,
                                  quantity: quantity,
                                  area: @net_surface_area,
                                  activity_production: @activity_production)

          daily_charge.save!
        end
    end
  end
end
