# -*- coding: utf-8 -*-
class Backend::Cells::WeatherCellsController < Backend::CellsController

  def show
    if zone = (params[:id] ? CultivableZone.find_by(id: params[:id]) : CultivableZone.first)
      if reading = zone.reading(:shape)
        coordinates = Charta::Geometry.new(reading.geometry_value).centroid
        begin
          @forecast = JSON.load(open("http://api.openweathermap.org/data/2.5/forecast/daily?lat=#{coordinates.first}&lon=#{coordinates.second}&cnt=14&mode=json")).deep_symbolize_keys
          @forecast[:list] = @forecast[:list].collect do |day|
            day.deep_symbolize_keys!
            {
              at: Time.at(day[:dt]),
              temperatures: [:day, :night, :min, :max, :eve, :morn].inject({}) do |hash, key|
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
        end
      end
    end
  rescue Exception => e
    # Nothing
    @forecast = nil
    logger.warn e.message
  end

end
