# -*- coding: utf-8 -*-
class Backend::Cells::MeteoCellsController < Backend::CellsController

  def show
    if datum = CultivableZone.first.indicator_datum(:shape)
      wkt = datum.class.connection.select_value("SELECT ST_AsText(ST_Transform(ST_Centroid(ST_SetSRID(geometry_value, 2154)), 4326)) FROM #{datum.class.table_name} WHERE id = #{datum.id}")
      factory = RGeo::Geographic.spherical_factory
      coordinates = factory.parse_wkt(wkt)
      @forecast = JSON.load(open("http://api.openweathermap.org/data/2.5/forecast/daily?lat=#{coordinates.latitude}&lon=#{coordinates.longitude}&cnt=14&mode=json")).deep_symbolize_keys
      puts @forecast.inspect
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
      puts @forecast.inspect
    end
  end

end
