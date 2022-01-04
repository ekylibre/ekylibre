module Backend
  module Cells
    class WeatherCellsController < Backend::Cells::WeatherCellsBaseController
      def show
        json = api_weather_data
        @forecast = json.fmap { |j| build_hourly_forecast j }.or_nil
        rescue Net::OpenTimeout => e
          @forecast = nil
          logger.warn "Net::OpenTimeout: Cannot open service OpenWeatherMap in time (#{e.message})"
        rescue Net::ReadTimeout => e
          @forecast = nil
          logger.warn "Net::ReadTimeout: Cannot read service OpenWeatherMap in time (#{e.message})"
      end
    end
  end
end
