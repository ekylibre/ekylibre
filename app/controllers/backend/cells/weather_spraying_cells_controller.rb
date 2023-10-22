module Backend
  module Cells
    class WeatherSprayingCellsController < Backend::Cells::WeatherCellsBaseController

      def show
        response = api_weather_data

        if response && response["cod"] != "200"
          @forecast = nil
          @error = response["message"]
        elsif response
          @forecast = build_hourly_forecast(response)
          @error = nil
        else
          @forecast = nil
          @error = nil
        end

        if @forecast
          @date = @forecast[:list].collect{|d| [d[:at].l(format: "%d/%m"), d[:at].l(format: "%HH")]}
          @weather = @forecast[:list].collect{|d| [d[:icon], d[:weather_description]]}
          @temperatures = @forecast[:list].collect{|d| "#{d[:temperatures].to_f(:celsius).round(1)} °C"}
          @humidity = @forecast[:list].collect{|d| "#{d[:humidity].to_f(:percent).round(1)} %"}
          @wind_speed = @forecast[:list].collect{|d| "#{d[:wind_speed].to_f(:kilometer_per_hour).round(1)} km/h"}
          @pluviometry = @forecast[:list].collect{|d| "#{d[:pluviometry].to_f(:millimeter).round(1)} mm"}
          @condition = @forecast[:list].collect{|d| spraying_weather_condition(d[:temperatures], d[:humidity], d[:wind_speed], d[:pluviometry]) }
        end
      end

      protected

        def spraying_weather_condition(temperatures, humidity, wind_speed, pluviometry)
          condition = {}
          temperatures = temperatures.to_f(:celsius)
          humidity = humidity.to_f(:percent)
          wind_speed = wind_speed.to_f(:meter_per_second)
          pluviometry = pluviometry.to_f(:millimeter)

          if wind_speed
            if wind_speed <= 2
              condition['wind_speed'] = 'go'
            elsif wind_speed > 2 && wind_speed < 5
              condition['wind_speed'] = 'caution'
            else
              condition['wind_speed'] = 'stop'
            end
          end

          if humidity
            if humidity >= 75 && humidity <= 95
              condition['humidity'] = 'go'
            elsif (humidity > 50 && humidity < 75) || (humidity > 95 && humidity < 99)
              condition['humidity'] = 'caution'
            else
              condition['humidity'] = 'stop'
            end
          end

          if temperatures
            if temperatures >= 5 && temperatures <=25
              condition['temperatures'] = 'go'
            elsif (temperatures > 25 && temperatures < 30) || (temperatures > 0 && temperatures < 5)
              condition['temperatures'] = 'caution'
            else
              condition['temperatures'] = 'stop'
            end
          end

          if pluviometry
            if pluviometry <= 0.1
              condition['pluviometry'] = 'go'
            elsif pluviometry > 0.1 && pluviometry <= 0.3
              condition['pluviometry'] = 'caution'
            else
              condition['pluviometry'] = 'stop'
            end
          end

          if condition.value?('stop')
            'stop'
          elsif condition.value?('caution')
            'caution'
          else
            'go'
          end
        end
    end
  end
end
