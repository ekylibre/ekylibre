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

          forecast[:list] = forecast[:hourly].collect do |data|
            data = data.deep_symbolize_keys

            {
                at: Time.zone.at(data[:dt]),
                temperatures: data.fetch(:temp, 0).in_celsius,
                # pressure: data.fetch(:main, {})[:pressure].in_hectopascal,
                humidity: data.fetch(:humidity, 0).in_percent,
                wind_speed: data.fetch(:wind_speed, 0).in_meter_per_second,
                wind_direction: data.fetch(:wind_deg, 0).in_degree,
                pluviometry: data.fetch(:rain, {}).fetch(:'1h', 0).in_millimeter,
                snow: data.fetch(:snow, {}).fetch(:'1h', 0).in_millimeter,
                clouds: data.fetch(:clouds, 0).in_percent,
                weather_main: data.fetch(:weather).first.fetch(:main),
                weather_description: data.fetch(:weather).first.fetch(:description),
                icon: data.fetch(:weather).first.fetch(:icon),
            }
          end

          forecast
        end

        def build_current_weather(json)
          forecast = json.deep_symbolize_keys

          data = forecast[:current]

          forecast[:list] =
            {
                at: Time.zone.at(data[:dt]),
                sunrise: Time.zone.at(data[:sunrise]),
                sunset: Time.zone.at(data[:sunset]),
                temperatures: data.fetch(:temp, 0).in_celsius,
                temp_feels_like: data.fetch(:feels_like, 0).in_celsius,
                pressure: data.fetch(:pressure, 0).in_hectopascal,
                humidity: data.fetch(:humidity, 0).in_percent,
                dew_point: data.fetch(:dew_point, 0).in_celsius,
                uvi: data.fetch(:uvi, 0).in_celsius,
                wind_speed: data.fetch(:wind_speed, 0).in_meter_per_second,
                wind_direction: data.fetch(:wind_deg, 0).in_degree,
                pluviometry: data.fetch(:rain, {}).fetch(:'1h', 0).in_millimeter,
                snow: data.fetch(:snow, {}).fetch(:'1h', 0).in_millimeter,
                clouds: data.fetch(:clouds, 0).in_percent,
                visibility: data.fetch(:visibility, 0).in_meter,
                weather_main: data.fetch(:weather).first.fetch(:main),
                weather_description: data.fetch(:weather).first.fetch(:description),
                icon: data.fetch(:weather).first.fetch(:icon),
            }

          forecast
        end

        def build_daily_forecast(json)
          forecast = json.deep_symbolize_keys

          forecast[:list] = forecast[:daily].collect do |data|
            data = data.deep_symbolize_keys

            {
                at: Time.zone.at(data[:dt]),
                sunrise: Time.zone.at(data[:sunrise]),
                sunset: Time.zone.at(data[:sunset]),
                min_temp: data.fetch(:temp, {})[:min].in_celsius,
                max_temp: data.fetch(:temp, {})[:min].in_celsius,
                pressure: data.fetch(:pressure, 0).in_hectopascal,
                humidity: data.fetch(:humidity, 0).in_percent,
                dew_point: data.fetch(:dew_point, 0).in_celsius,
                uvi: data.fetch(:uvi, 0).in_celsius,
                wind_speed: data.fetch(:wind_speed, 0).in_meter_per_second,
                wind_direction: data.fetch(:wind_deg, 0).in_degree,
                pluviometry: data.fetch(:rain, 0).in_millimeter,
                probability: data.fetch(:pop, 0),
                snow: data.fetch(:snow, 0).in_millimeter,
                clouds: data.fetch(:clouds, 0).in_percent,
                weather_main: data.fetch(:weather).first.fetch(:main),
                weather_description: data.fetch(:weather).first.fetch(:description),
                icon: data.fetch(:weather).first.fetch(:icon),
            }
          end

          forecast
        end

    end
  end
end
