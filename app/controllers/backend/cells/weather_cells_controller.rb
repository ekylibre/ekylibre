module Backend
  module Cells
    class WeatherCellsController < Backend::Cells::BaseController
      def show
        @forecast = nil
        openweathermap_api_key = Identifier.find_by(nature: :openweathermap_api_key)
        zone = (params[:id] ? CultivableZone.find_by(id: params[:id]) : CultivableZone.first)
        if zone && openweathermap_api_key
          coordinates = Charta.new_geometry(zone.shape).centroid
          http = Net::HTTP.new('api.openweathermap.org')
          http.open_timeout = 3
          http.read_timeout = 3
          res = http.get("/data/2.5/forecast/daily?lat=#{coordinates.first}&lon=#{coordinates.second}&cnt=14&mode=json&APPID=#{openweathermap_api_key.value}")

          json = begin
                   JSON.parse(res.body)
                 rescue
                   nil
                 end
          unless json.nil?
            @forecast = json.deep_symbolize_keys
            if @forecast[:cod] == '200'
              @forecast[:list] = @forecast[:list].collect do |day|
                day.deep_symbolize_keys!
                {
                  at: Time.zone.at(day[:dt]),
                  temperatures: [:day, :night, :min, :max, :eve, :morn].each_with_object({}) do |key, hash|
                    hash[key] = (day[:temp][key] || 0).in_kelvin
                    hash
                  end,
                  pressure: day[:pressure].in_hectopascal,
                  humidity: (day[:humidity] || 0).in_percent,
                  wind_speed: (day[:speed] || 0).in_meter_per_second,
                  wind_direction: (day[:deg] || 0).in_degree,
                  rain: (day[:rain] || 0).in_millimeter,
                  clouds: (day[:rain] || 0).in_percent,
                  # weather: day[:weather]
                }
              end
            else
              @forecast = nil
            end
          end
        elsif !openweathermap_api_key
          @forecast = nil
          logger.warn 'Missing OpenWeatherMap api key in identifiers)'
        end
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
