module Backend
  module Cells
    class WeatherCellsBaseController < Backend::Cells::BaseController

      protected

        def api_weather_data
          openweathermap_api_key = Identifier.find_by(nature: :openweathermap_api_key)
          weather_client = OpenWeatherMapClient.from_identifier(openweathermap_api_key, current_user)

          coordinates = if params[:centroid]
                          params[:centroid]
                        else
                          geom_centroid = CultivableZone.geom_union_centroid(:shape)
                          geom_centroid.present? ? [geom_centroid.y, geom_centroid.x] : nil
                        end
          # We use the 5days forecast free from openwheathermap
          weather_client.fetch_forecast(coordinates)
        end

        def build_hourly_forecast(json)
          forecast = json.deep_symbolize_keys

          forecast[:list] = forecast[:list].collect do |data|
            data = data.deep_symbolize_keys

            {
                at: Time.zone.at(data[:dt]),
                temperatures: data.fetch(:main, {})[:temp].in_celsius,
                pressure: data.fetch(:main, {}).fetch(:pressure, 0).in_hectopascal,
                humidity: data.fetch(:main, {}).fetch(:humidity, 0).in_percent,
                wind_speed: data.fetch(:wind, {}).fetch(:speed, 0).in_meter_per_second,
                wind_direction: data.fetch(:wind, {}).fetch(:deg, 0).in_degree,
                pluviometry: data.fetch(:rain, {}).fetch(:'3h', 0).in_millimeter,
                snow: data.fetch(:snow, {}).fetch(:'1h', 0).in_millimeter,
                clouds: data.fetch(:clouds, {}).fetch(:all, 0).in_percent,
                weather_main: data.fetch(:weather).first.fetch(:main),
                weather_description: data.fetch(:weather).first.fetch(:description),
                icon: data.fetch(:weather).first.fetch(:icon),
            }
          end

          forecast
        end

        def build_current_weather(json)
          build_hourly_forecast(json)
        end

        def build_daily_forecast(json)
          build_hourly_forecast(json)
        end

    end
  end
end
