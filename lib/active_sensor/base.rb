module ActiveSensor
  class Base
    mattr_accessor :list do
      []
    end

    class << self
      def register(_vendor, _model, _options = {})
        fail :not_implemented
      end

      def register_many(path)
        return unless Pathname(path).exist?
        sensors = YAML.load_file(path)
        sensors.deep_symbolize_keys!

        options = {}
        # Only one vendor key
        options[:vendor] = sensors.keys.first

        sensors.fetch(options[:vendor], {}).try(:keys).each do |model|
          options[:model] = model
          options[:label] = sensors[options[:vendor]][model].fetch(:label)
          options[:description] = sensors[options[:vendor]][model].try(:[], :description)
          options[:indicators] = sensors[options[:vendor]][model].try(:[], :indicators)

          unless image = sensors[options[:vendor]][model].try(:[], :image).nil?
            image = Pathname(path.dirname).join(image)
            options[:image_path] = image if image.exist?
          end

          if sensors[options[:vendor]][model].try(:[], :controller)
            options[:controller] = begin
                                     sensors[options[:vendor]][model].fetch(:controller).to_s.constantize
                                   rescue
                                     nil
                                   end
          else
            fail "No controller set for #{options[:vendor]}:#{options[:model]}"
          end

          fail "Equipment #{options[:vendor]}:#{options[:model]} already exists" unless ActiveSensor::Equipment.find(options[:vendor], options[:model]).blank?
          list << ActiveSensor::Equipment.new(options)
        end
      end
    end
  end
end
