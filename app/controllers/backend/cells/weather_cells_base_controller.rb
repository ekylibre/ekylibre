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

        def historical_weather_data(campaign, started_at, stopped_at)
          h = {}
          h[:data] = nil
          h[:error] = nil
          if !started_at.present? || !stopped_at.present?
            if campaign.present?
              started_at = Date.new(campaign.harvest_year, 1, 1)
              stopped_at = Date.new(campaign.harvest_year, 12, 31)
            else
              h[:error] = :missing_dates_for_weather.tl
              return h
            end
          end
          station_id = Preference[:weather_public_station]
          unless station_id.present?
            h[:error] = :missing_weather_public_station_in_preferences.tl
            return h
          end
          dataset = RegisteredHourlyWeather.for_station_id(station_id).between(started_at, stopped_at).reorder(:started_at)
          unless dataset.any?
            h[:error] = :missing_weather_public_data_in_lexicon.tl
            return h
          end
          h[:data] = dataset
          h
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

        def build_historical_forecast(dataset, period = :monthly)
          forecast = []
          if period == :weekly
            group = dataset.group_by { |item| item.started_at.beginning_of_week.to_date }
            group.each do |month, items|
              forecast << {
                at: month.l(format: "%d/%m/%Y"),
                humidity: (items.map(&:humidity).compact.sum / items.count).to_f.round(2),
                pluviometry: items.map(&:rain).compact.sum.to_f.round(2),
                max_wind_speed: (items.map(&:max_wind_speed).compact.sum / items.count).to_f.round(2),
                min_temperature: (items.map(&:min_temp).compact.sum / items.count).to_f.round(2),
                max_temperature: (items.map(&:max_temp).compact.sum / items.count).to_f.round(2),
                degree_day: items.map(&:average_temp_for_degree_day).compact.sum.round(2)
              }
            end
          elsif period == :daily
            group = dataset.group_by { |item| item.started_at.beginning_of_day.to_date }
            group.each do |month, items|
              forecast << {
                at: month.l(format: "%d/%m/%Y"),
                humidity: (items.map(&:humidity).compact.sum / items.count).to_f.round(2),
                pluviometry: items.map(&:rain).compact.sum.to_f.round(2),
                max_wind_speed: (items.map(&:max_wind_speed).compact.sum / items.count).to_f.round(2),
                min_temperature: (items.map(&:min_temp).compact.sum / items.count).to_f.round(2),
                max_temperature: (items.map(&:max_temp).compact.sum / items.count).to_f.round(2),
                degree_day: items.map(&:average_temp_for_degree_day).compact.sum.round(2)
              }
            end
          elsif period == :monthly
            group = dataset.group_by { |item| item.started_at.beginning_of_month.to_date }
            group.each do |month, items|
              forecast << {
                at: month.l(format: "%m/%Y"),
                humidity: (items.map(&:humidity).compact.sum / items.count).to_f.round(2),
                pluviometry: items.map(&:rain).compact.sum.to_f.round(2),
                max_wind_speed: (items.map(&:max_wind_speed).compact.sum / items.count).to_f.round(2),
                min_temperature: (items.map(&:min_temp).compact.sum / items.count).to_f.round(2),
                max_temperature: (items.map(&:max_temp).compact.sum / items.count).to_f.round(2),
                degree_day: items.map(&:average_temp_for_degree_day).compact.sum.round(2)
              }
            end
          elsif period == :hourly
            dataset.reorder(:started_at).each do |item|
              forecast << {
                at: item.started_at.l(format: "%d/%m/%Y %HH"),
                humidity: item.humidity.to_f.round(2),
                pluviometry: item.rain.to_f.round(2),
                max_wind_speed: item.max_wind_speed.to_f.round(2),
                min_temperature: item.min_temp.to_f.round(2),
                max_temperature: item.max_temp.to_f.round(2),
                degree_day: item.average_temp_for_degree_day.round(2)
              }
            end
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
