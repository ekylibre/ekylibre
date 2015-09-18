module OpenWeatherMap
  class VirtualController < ActiveSensor::Controller
    has_parameter :latitude
    has_parameter :longitude
    has_parameter :api_key, required: false

    def retrieve(parameters, _options = {})
      latitude = parameters[:latitude].to_f
      longitude = parameters[:longitude].to_f
      http = Net::HTTP.new('api.openweathermap.org')
      http.open_timeout = 3
      http.read_timeout = 3
      response = http.get("/data/2.5/weather?lat=#{latitude}&lon=#{longitude}&units=metric")
      json = JSON.load(response.body).deep_symbolize_keys

      values = {}
      values[:temperature] = json[:main][:temp].to_f.in_celsius
      values[:atmospheric_pressure] = json[:main][:pressure].to_f.in_hectopascal
      values[:hygrometry] = json[:main][:humidity].to_f.in_percent
      values[:wind_speed] = json[:wind][:speed].to_f.in_meter_per_second
      values[:wind_direction] = json[:wind][:deg].to_f.in_degree

      report = {
        sampled_at: Time.at(json[:dt]),
        sampling_temporal_mode: 'instant',
        geolocation: Charta::Geometry.point(latitude, longitude),
        values: values,
        status: :ok
      }

      report
    end
  end
end
