module OpenWeatherMap
  autoload :VirtualController, 'open_weather_map/virtual_controller'
end

ActiveSensor::Equipment.register(:openweathermap, :virtual_station, controller: 'OpenWeatherMap::VirtualController', indicators: [:temperature, :atmospheric_pressure, :hygrometry, :wind_speed, :wind_direction])
