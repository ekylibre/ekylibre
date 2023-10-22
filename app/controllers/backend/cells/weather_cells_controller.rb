module Backend
  module Cells
    class WeatherCellsController < Backend::Cells::WeatherCellsBaseController
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
      end
    end
  end
end
