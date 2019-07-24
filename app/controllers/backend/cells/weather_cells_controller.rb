module Backend
  module Cells
    class WeatherCellsController < Backend::Cells::BaseController
      def show
        @forecast = nil
        openweathermap_api_key = Identifier.find_by(nature: :openweathermap_api_key)

        coordinates = params[:centroid]

        # We try to get weather from cultivable zones
        coordinates ||= CultivableZone.geom_union(:shape).centroid

        # We use the 5days forecast free from openwheathermap
        if coordinates.present? && openweathermap_api_key
          http = Net::HTTP.new('api.openweathermap.org')
          http.open_timeout = 3
          http.read_timeout = 3
          res = http.get("/data/2.5/forecast?lat=#{coordinates.first}&lon=#{coordinates.second}&mode=json&APPID=#{openweathermap_api_key.value}")

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
                  temperatures: %i[temp temp_min temp_max].each_with_object({}) do |key, hash|
                    hash[key] = (day[:main][key] || 0).in_kelvin
                    hash
                  end,
                  pressure: day[:main][:pressure].in_hectopascal,
                  humidity: (day[:main][:humidity] || 0).in_percent,
                  wind_speed: (day[:wind][:speed] || 0).in_meter_per_second,
                  wind_direction: (day[:wind][:deg] || 0).in_degree,
                  #rain: (day[:rain] || 0).in_millimeter,
                  clouds: (day[:clouds][:all] || 0).in_percent,
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
