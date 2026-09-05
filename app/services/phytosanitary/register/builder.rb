# frozen_string_literal: true

module Phytosanitary
  module Register
    class Builder
      def self.call(**args)
        new(**args).call
      end

      def initialize(campaign:, from: nil, to: nil)
        @campaign = campaign
        @from = from
        @to = to
      end

      def call
        Payload.new(
          holder_siret: holder&.siret_number,
          holder_name: holder&.full_name,
          campaign_name: @campaign&.name,
          period_from: period_from,
          period_to: period_to,
          generated_at: Time.zone.now,
          entries: build_entries
        )
      end

      private

        def holder
          @holder ||= Entity.of_company
        end

        def period_from
          return @from if @from
          return nil unless @campaign&.harvest_year

          Time.zone.local(@campaign.harvest_year, 1, 1)
        end

        def period_to
          return @to if @to
          return nil unless @campaign&.harvest_year

          Time.zone.local(@campaign.harvest_year, 12, 31).end_of_day
        end

        def fetch_interventions
          scope = Intervention.where(procedure_name: Intervention::PHYTO_PROCEDURE_NAMES)
                              .where.not(state: :rejected)
          scope = scope.joins(:campaigns).where(campaigns: { id: @campaign.id }) if @campaign
          scope = scope.where('started_at >= ?', period_from) if period_from
          scope = scope.where('started_at <= ?', period_to) if period_to
          scope.includes(
            :working_periods,
            inputs: %i[product variant],
            targets: { product: { activity_production: %i[activity cap_land_parcel] } }
          )
        end

        def build_entries
          entries = []
          fetch_interventions.find_each do |intervention|
            inputs = intervention.inputs.select(&:product_id).to_a
            targets = intervention.targets.select(&:product_id).to_a
            next if inputs.empty? || targets.empty?

            inputs.each do |input|
              targets.each do |target|
                entries << build_entry(intervention, input, target)
              end
            end
          end
          entries
        end

        def build_entry(intervention, input, target)
          activity_production = target.product&.activity_production
          cap = activity_production&.cap_land_parcel
          working_period = first_intervention_period(intervention)
          weather = intervention.weather_conditions || {}

          Entry.new(
            intervention_id: intervention.id,
            intervention_number: intervention.number,
            intervention_input_id: input.id,
            intervention_target_id: target.id,

            holder_siret: holder&.siret_number,
            beneficiary_siret: intervention.beneficiary_siret,

            product_name: input.product&.name || input.variant&.name,
            amm_number: amm_number_for(input),
            active_substances: active_substances_for(input),

            application_date: intervention.started_at&.to_date,
            application_started_at: working_period&.started_at,
            application_stopped_at: working_period&.stopped_at,

            dose_value: input.quantity_value,
            dose_unit: input.quantity_unit_name,

            treated_area_value: target.working_zone_area_value,
            treated_area_unit: 'hectare',
            treated_volume_value: nil,
            treated_volume_unit: nil,

            crop_name: activity_production&.activity&.name || target.product&.name,
            crop_variety: target.product&.variety,
            organic_production: activity_production&.activity&.organic_farming? == true,

            location_geometry: target.working_zone,
            location_rpg_islet: cap&.islet_number,
            location_rpg_parcel: cap&.land_parcel_number,

            phenological_bbch_stage: target.phenological_bbch_stage,
            seed_lot_number: input.batch_number,
            targeted_pest_name: targeted_pest_for(input),
            application_mode: input.application_mode,

            early_reentry: intervention.early_reentry,
            early_reentry_ppe_description: intervention.early_reentry_ppe_description,
            early_reentry_reason: intervention.early_reentry_reason,

            weather_condition_code: weather['weather_condition_code'],
            weather_temperature: weather['temperature'],
            weather_wind: weather['wind'],
            weather_humidity: weather['humidity']
          ).freeze
        end

        def first_intervention_period(intervention)
          intervention.working_periods
                      .select { |wp| wp.nature.nil? || wp.nature == 'intervention' }
                      .min_by(&:started_at) || intervention.working_periods.min_by(&:started_at)
        end

        # AMM resolved from snapshot first, falls back to live lexicon lookup.
        def amm_number_for(input)
          input.reference_data&.dig('usage', 'france_maaid') ||
            input.reference_data&.dig('product', 'france_maaid') ||
            input.variant&.france_maaid
        end

        # Active substances are for treated seeds. Pulled from variant if present.
        # Returns a comma-separated string of active compound names, or nil.
        def active_substances_for(input)
          phyto = input.variant&.france_maaid && RegisteredPhytosanitaryProduct.find_by(france_maaid: input.variant.france_maaid)
          phyto&.active_compounds
        end

        # Targeted pest is NOT in LoggedPhytosanitaryUsage::ATTRIBUTES, so live resolution
        # via the lexicon usage row. Returns nil if usage no longer in lexicon.
        def targeted_pest_for(input)
          input.usage&.target_name_label_fra
        end
    end
  end
end
