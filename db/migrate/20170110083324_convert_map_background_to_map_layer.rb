class ConvertMapBackgroundToMapLayer < ActiveRecord::Migration
  MAP_OVERLAYS = [
    { name: 'OpenWeatherMap Clouds',
      reference_name: 'open_weather_map.clouds',
      url: 'http://{s}.tile.openweathermap.org/map/clouds/{z}/{x}/{y}.png',
      attribution: 'Weather from <a href="http://openweathermap.org/" alt="World Map and worldwide Weather Forecast online">OpenWeatherMap</a>',
      max_zoom: 18,
      opacity: 50 },
    { name: 'OpenWeatherMap Clouds classic',
      reference_name: 'open_weather_map.clouds_classic',
      url: 'http://{s}.tile.openweathermap.org/map/clouds_cls/{z}/{x}/{y}.png',
      attribution: 'Weather from <a href="http://openweathermap.org/" alt="World Map and worldwide Weather Forecast online">OpenWeatherMap</a>',
      max_zoom: 18,
      opacity: 50 },
    { name: 'OpenWeatherMap Precipitation',
      reference_name: 'open_weather_map.precipitation',
      url: 'http://{s}.tile.openweathermap.org/map/precipitation/{z}/{x}/{y}.png',
      attribution: 'Weather from <a href="http://openweathermap.org/" alt="World Map and worldwide Weather Forecast online">OpenWeatherMap</a>',
      max_zoom: 18,
      opacity: 50 },
    { name: 'OpenWeatherMap Precipitation classic',
      reference_name: 'open_weather_map.precipitation_classic',
      url: 'http://{s}.tile.openweathermap.org/map/precipitation_cls/{z}/{x}/{y}.png',
      attribution: 'Weather from <a href="http://openweathermap.org/" alt="World Map and worldwide Weather Forecast online">OpenWeatherMap</a>',
      max_zoom: 18,
      opacity: 50 },
    { name: 'OpenWeatherMap Rain',
      reference_name: 'open_weather_map.rain',
      url: 'http://{s}.tile.openweathermap.org/map/rain/{z}/{x}/{y}.png',
      attribution: 'Weather from <a href="http://openweathermap.org/" alt="World Map and worldwide Weather Forecast online">OpenWeatherMap</a>',
      max_zoom: 18,
      opacity: 50 },
    { name: 'OpenWeatherMap Rain classic',
      reference_name: 'open_weather_map.rain_classic',
      url: 'http://{s}.tile.openweathermap.org/map/rain_cls/{z}/{x}/{y}.png',
      attribution: 'Weather from <a href="http://openweathermap.org/" alt="World Map and worldwide Weather Forecast online">OpenWeatherMap</a>',
      max_zoom: 18,
      opacity: 50 },
    { name: 'OpenWeatherMap Pressure',
      reference_name: 'open_weather_map.pressure',
      url: 'http://{s}.tile.openweathermap.org/map/pressure/{z}/{x}/{y}.png',
      attribution: 'Weather from <a href="http://openweathermap.org/" alt="World Map and worldwide Weather Forecast online">OpenWeatherMap</a>',
      max_zoom: 18,
      opacity: 50 },
    { name: 'OpenWeatherMap Pressure contour',
      reference_name: 'open_weather_map.pressure_contour',
      url: 'http://{s}.tile.openweathermap.org/map/pressure_cntr/{z}/{x}/{y}.png',
      attribution: 'Weather from <a href="http://openweathermap.org/" alt="World Map and worldwide Weather Forecast online">OpenWeatherMap</a>',
      max_zoom: 18,
      opacity: 50 },
    { name: 'OpenWeatherMap Wind',
      reference_name: 'open_weather_map.wind',
      url: 'http://{s}.tile.openweathermap.org/map/wind/{z}/{x}/{y}.png',
      attribution: 'Weather from <a href="http://openweathermap.org/" alt="World Map and worldwide Weather Forecast online">OpenWeatherMap</a>',
      max_zoom: 18,
      opacity: 50 },
    { name: 'OpenWeatherMap Temperature',
      reference_name: 'open_weather_map.temperature',
      url: 'http://{s}.tile.openweathermap.org/map/temp/{z}/{x}/{y}.png',
      attribution: 'Weather from <a href="http://openweathermap.org/" alt="World Map and worldwide Weather Forecast online">OpenWeatherMap</a>',
      max_zoom: 18,
      opacity: 50 },
    { name: 'OpenWeatherMap Snow',
      reference_name: 'open_weather_map.snow',
      url: 'http://{s}.tile.openweathermap.org/map/snow/{z}/{x}/{y}.png',
      attribution: 'Weather from <a href="http://openweathermap.org/" alt="World Map and worldwide Weather Forecast online">OpenWeatherMap</a>',
      max_zoom: 18,
      opacity: 50 }
  ].freeze

  def change
    rename_table :map_backgrounds, :map_layers
    add_column :map_layers, :nature, :string
    add_column :map_layers, :position, :integer
    add_column :map_layers, :opacity, :integer

    reversible do |r|
      r.up do
        execute <<-SQL
          UPDATE map_layers SET nature='background'
        SQL

        reference_names = select_values("SELECT reference_name FROM map_layers WHERE nature='overlay'").uniq
        MAP_OVERLAYS.each do |overlay|
          next if reference_names.include?(overlay[:reference_name])
          execute 'INSERT INTO map_layers (' + overlay.keys.join(', ') +
                  ', created_at, updated_at, nature, managed) SELECT ' +
                  overlay.values.map { |v| quote(v) }.join(', ') +
                  ', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, \'overlay\', true;'
        end
      end

      r.down do
        execute <<-SQL
          DELETE FROM map_layers WHERE nature='overlay'
        SQL
      end
    end
  end
end
