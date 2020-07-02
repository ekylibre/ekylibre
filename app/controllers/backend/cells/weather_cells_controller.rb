module Backend
  module Cells
    class WeatherCellsController < Backend::Cells::BaseController
      def show
        openweathermap_api_key = Identifier.find_by(nature: :openweathermap_api_key)
        weather_client = OpenWeatherMapClient.from_identifier openweathermap_api_key

        coordinates = if params[:centroid]
          params[:centroid]
        else
          geom_centroid = CultivableZone.geom_union_centroid(:shape)
          geom_centroid.present? ? [geom_centroid.y, geom_centroid.x] : nil
        end

        # We use the 5days forecast free from openwheathermap
        if coordinates.present?
          json = weather_client.fetch_forecast(coordinates)

          @forecast = json.fmap { |j| build_forecast j }.or_nil
        end
      rescue Net::OpenTimeout => e
        @forecast = nil
        logger.warn "Net::OpenTimeout: Cannot open service OpenWeatherMap in time (#{e.message})"
      rescue Net::ReadTimeout => e
        @forecast = nil
        logger.warn "Net::ReadTimeout: Cannot read service OpenWeatherMap in time (#{e.message})"
      end

      private

        def build_forecast(json)
          forecast = json.deep_symbolize_keys

          if forecast[:cod] == '200'
            forecast[:list] = forecast[:list].collect do |day|
              day = day.deep_symbolize_keys

              {
                at: Time.zone.at(day[:dt]),
                temperatures: %i[temp temp_min temp_max].reduce({}) do |hash, key|
                  { **hash, key => day[:main].fetch(key, 0).in_kelvin }
                end,
                # pressure: day.fetch(:main, {})[:pressure].in_hectopascal,
                humidity: day.fetch(:main, {}).fetch(:humidity, 0).in_percent,
                wind_speed: day.fetch(:wind, {}).fetch(:speed, 0).in_meter_per_second,
                wind_direction: day.fetch(:wind, {}).fetch(:deg, 0).in_degree,
                pluviometry: day.fetch(:rain, {}).fetch(:'3h', 0).in_millimeter,
                # clouds: day.fetch(:clouds, {}).fetch(:all, 0).in_percent,
                # weather: day[:weather]
              }
            end
          end

          forecast
        end
    end
  end
end
