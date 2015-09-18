module ActiveSensor
  class Connection
    attr_accessor :equipment, :controller, :parameters

    def initialize(equipment, parameters = {})
      @equipment = equipment
      if equipment.controller
        @controller = equipment.controller.new
        @parameters = {}.with_indifferent_access
        equipment.parameters.each do |name, parameter|
          @parameters[name] = parameter.normalize!(parameters[name.to_s])
        end
      end
    end

    def retrieve(options = {})
      unless controller
        return { status: :error, message: "No controller given for #{equipment.unique_name}" }
      end
      # begin
      res = @controller.retrieve(parameters, options)
      # rescue StandardError => e
      #  res = {status: :controller_error, message: e.message}
      # end

      # # Check response is valid
      # if res.is_a?(Hash) && res.present?
      #   res = check(res)
      # end
      # # check!(res)

      res
    end

    def check(result)
      fail 'Timestamp missing' if result.slice(:time).empty?
      fail 'Geolocation missing' if result.slice(:geolocation).empty?
      if result[:geolocation].is_a? Array
        # [lat, lon] array
        result[:geolocation] = Charta::Geometry.new("POINT(#{result[:geolocation]})", 4326)
      elsif result[:geolocation].is_a?(Hash) && lat = result[:geolocation].try(:[], :lat) and lon = result[:geolocation].try(:[], :lon)
        # {lat:, lon:} hash
        result[:geolocation] = Charta::Geometry.new("POINT(#{lat} #{lon})", 4326)
      else
        fail 'Geolocation is invalid'
      end
      # # Indicators
      # result.except(:time, :geolocation, :sampling_temporal_mode).each do |k, _|
      #   fail "#{k} is not a valid indicator" unless Nomen::Indicator.find(k)
      # end
      result
    end
  end
end
