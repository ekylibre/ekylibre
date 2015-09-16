module ActiveSensor
  class Connection
    attr_accessor :controller

    def initialize(*args)
      equipment = args.first
      parameters = args.extract_options!

      @controller = equipment.controller.constantize.new
      # load access parameters if any
      @controller.connect_sensor parameters unless parameters.blank?
    end

    def retrieve(options = {})
      # check method exist
      if @controller.respond_to? :retrieve
        res = @controller.retrieve options

        # Check response is valid.
        if res.is_a?(Hash) && res.present?

          fail 'Timestamp missing' if res.slice(:time).empty?

          fail 'Geolocation missing' if res.slice(:geolocation).empty?

          if res[:geolocation].is_a? Array
            # [lat, lon] array
            res[:geolocation] = Charta::Geometry.new("POINT( #{res[:geolocation]} )", 4326)

          elsif res[:geolocation].is_a?(Hash) && lat = res[:geolocation].try(:[], :lat) and lon = res[:geolocation].try(:[], :lon)
            # {lat:, lon:} hash
            res[:geolocation] = Charta::Geometry.new("POINT(#{lat} #{lon})", 4326)

          else
            fail 'Geolocation is invalid'
          end

          # Indicators
          res.except(:time, :geolocation, :sampling_temporal_mode).each { |k, _| fail "#{k} is not a valid indicator" if Nomen::Indicator.find(k).nil? }

        end
      else
        fail "No method found for get action in #{@controller.class.name}"
      end

      res
    end
  end
end
