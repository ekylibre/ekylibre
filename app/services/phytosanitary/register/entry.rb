# frozen_string_literal: true

module Phytosanitary
  module Register
    Entry = Struct.new(
      :intervention_id,
      :intervention_number,
      :intervention_input_id,
      :intervention_target_id,

      :holder_siret,
      :beneficiary_siret,

      :product_name,
      :amm_number,
      :active_substances,

      :application_date,
      :application_started_at,
      :application_stopped_at,

      :dose_value,
      :dose_unit,

      :treated_area_value,
      :treated_area_unit,
      :treated_volume_value,
      :treated_volume_unit,

      :crop_name,
      :crop_variety,
      :organic_production,

      :location_geometry,
      :location_rpg_islet,
      :location_rpg_parcel,

      :phenological_bbch_stage,
      :seed_lot_number,
      :targeted_pest_name,
      :application_mode,

      :early_reentry,
      :early_reentry_ppe_description,
      :early_reentry_reason,

      :weather_condition_code,
      :weather_temperature,
      :weather_wind,
      :weather_humidity,

      keyword_init: true
    ) do
      def freeze
        location_geometry.freeze if location_geometry
        active_substances.freeze if active_substances
        super
      end
    end
  end
end
