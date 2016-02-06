module ActiveSensor
  class Equipment
    mattr_accessor :list do
      []
    end

    class << self
      # Register an equipment in global base
      def register(vendor, model, options = {})
        # puts "Register #{vendor.to_s.yellow} #{model.to_s.green}"
        if ActiveSensor::Equipment.find(vendor, model)
          Rails.logger.warn "Equipment #{vendor}:#{model} already exists. Will be overriden"
          erase(vendor, model)
        end
        list << ActiveSensor::Equipment.new(vendor, model, options)
        true
      end

      # Register a YAML file of many equipment
      #   <vendor>:
      #     <model>:
      #       label: ...
      #       description: ...
      #       controller: ...
      #       indicators: ...
      def register_many(path, _options = {})
        raise "Cannot find #{path}" unless Pathname(path).exist?
        sensors = YAML.load_file(path).deep_symbolize_keys
        sensors.each do |vendor, models|
          models.each do |model, options|
            register(vendor, model, options)
          end
        end
      end

      # List all vendors
      def vendors
        list.collect(&:vendor).uniq
      end

      def equipments_of(vendor)
        list.select do |equipment|
          equipment.vendor == vendor.to_sym
        end
      end

      def erase(vendor, model)
        equipment = find(vendor, model)
        list.delete(equipment)
      end

      def find(vendor, model)
        return nil unless vendor && model
        list.detect do |equipment|
          equipment.vendor == vendor.to_sym && equipment.model == model.to_sym
        end
      end

      def find!(vendor, model)
        equipment = find(vendor, model)
        unless equipment
          raise EquipmentNotFound, "Cannot find vendor=#{vendor.inspect}, model=#{model.inspect}"
        end
        equipment
      end

      def connect(vendor, model, access_parameters = {})
        equipment = find!(vendor, model)
        equipment.connect(access_parameters)
      end
    end

    attr_reader :vendor
    attr_reader :model
    attr_reader :indicators
    attr_reader :image_path
    attr_reader :controller

    delegate :parameters, to: :controller

    # Initialize an equipment with given parameters
    def initialize(vendor, model, options = {})
      # options.symbolize_keys!
      @vendor = vendor.to_sym
      raise 'Need vendor' unless @vendor
      @model = model.to_sym
      raise 'Need model' unless @model
      if options[:indicators]
        @indicators = options[:indicators].collect do |i|
          raise "Invalid indicator: #{i.inspect}" unless Nomen::Indicator.find(i)
          i.to_sym
        end
      end
      store_translation(:label, options[:label])
      store_translation(:description, options[:description])
      if options[:image_path]
        path = Pathname.new(options[:image_path])
        raise "Cannot find image #{options[:image_path]}" unless path.exist?
        @image_path = path
      end
      @controller = options[:controller].constantize if options[:controller]
    end

    # Returns ActiveSensor::Connection  with permit to retrieve
    # data from sensor
    def connect(access_parameters = {})
      ActiveSensor::Connection.new(self, access_parameters)
    end

    def unique_name
      "#{@vendor}##{@model}"
    end

    # Returns i18nized label
    def label(options = {})
      translate(:label, options) || @model.to_s.humanize
    end

    # Returns i18nized description
    def description(options = {})
      translate(:description, options)
    end

    protected

    def store_translation(scope, value)
      if value.is_a?(String)
        value = { I18n.default_locale => value }
      elsif !value.is_a?(Hash)
        return false
        # fail "Cannot handle #{value.inspect} as translation for #{scope}"
      end
      @translations ||= {}.with_indifferent_access
      @translations.deep_merge!(scope => value)
    end

    def translate(scope, options = {})
      locale = options[:locale] || I18n.locale
      @translations ||= {}.with_indifferent_access
      text = @translations.try(:[], scope).try(:[], locale)
      unless text
        Rails.logger.warn "Missing translation for sensor #{@vendor}##{@model}: #{scope}"
      end
      text
    end
  end
end
