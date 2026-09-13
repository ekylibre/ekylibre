# frozen_string_literal: true

module Phytosanitary
  module Register
    # Curated subset of OpenWeatherMap condition codes
    # (https://openweathermap.org/api/weather-conditions). Codes match the
    # numeric values used by their REST API and are stored as strings in
    # interventions.weather_conditions JSONB (key: weather_condition_code).
    module WeatherConditions
      # [code, i18n_key]. Resolved to [label, code] at OPTIONS call time so
      # locale changes are picked up per request.
      CODE_KEYS = [
        # Group 8xx: Clear / Clouds
        %w[800 weather_clear_sky],
        %w[801 weather_few_clouds],
        %w[802 weather_scattered_clouds],
        %w[803 weather_broken_clouds],
        %w[804 weather_overcast],
        # Group 7xx: Atmosphere
        %w[701 weather_mist],
        %w[721 weather_haze],
        %w[741 weather_fog],
        %w[781 weather_tornado],
        # Group 6xx: Snow
        %w[600 weather_light_snow],
        %w[601 weather_snow],
        %w[602 weather_heavy_snow],
        # Group 5xx: Rain
        %w[500 weather_light_rain],
        %w[501 weather_moderate_rain],
        %w[502 weather_heavy_rain],
        %w[511 weather_freezing_rain],
        # Group 3xx: Drizzle
        %w[300 weather_light_drizzle],
        %w[301 weather_drizzle],
        # Group 2xx: Thunderstorm
        %w[200 weather_thunderstorm_light_rain],
        %w[201 weather_thunderstorm_rain],
        %w[211 weather_thunderstorm]
      ].freeze

      def self.options
        CODE_KEYS.map { |code, key| [key.to_sym.tl, code] }
      end
    end
  end
end
