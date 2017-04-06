module OpenWeatherMap
  autoload :VirtualController, 'open_weather_map/virtual_controller'
end

ActiveSensor::Equipment.register(:openweathermap, :virtual_station, controller: 'OpenWeatherMap::VirtualController', indicators: %i[temperature atmospheric_pressure relative_humidity wind_speed wind_direction])
