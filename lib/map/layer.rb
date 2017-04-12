module Map
  class Layer
    mattr_accessor :items do
      []
    end
    attr_reader :name
    attr_reader :url
    attr_reader :enabled
    attr_reader :by_default
    attr_reader :type
    attr_reader :options

    def initialize(name, url, enabled, by_default, type, options, provider)
      @name = name
      @url = url || provider.url
      @enabled = enabled.nil? ? false : enabled
      @by_default = by_default.nil? ? false : by_default
      @type = type || provider.type
      @provider = provider
      @options = options || provider.options
      @options[:attribution] ||= provider.options[:attribution]
      @options[:subdomains] ||= provider.options[:subdomains]
    end

    def label
      @name == :default ? @provider.label : "#{@provider.label} #{@name.to_s.split('_').join(' ').camelize}"
    end

    def reference_name
      @reference_name ||= "#{@provider.name}.#{@name}"
    end

    def provider_name
      @provider.name
    end

    class << self
      delegate :each, :count, :size, :select, :detect, to: :items

      # Load layers from config_path parameter (if any) or from config/map_layers.yml
      def load(path = nil)
        config_path = path || Rails.root.join('config', 'map_layers.yml')
        raise 'No valid config file found for Map::Layer' unless Pathname(config_path).exist?
        layers = YAML.load_file(config_path).deep_symbolize_keys
        layers.each do |provider, attributes|
          provider = ::Map::Provider.new(provider, attributes.try(:[], :url), attributes.try(:[], :enabled), attributes.try(:[], :by_default), attributes.try(:[], :type), attributes.try(:[], :options))

          # A layer can be represented by a variant or by the provider itself
          if attributes.key?(:variants) && attributes[:variants].is_a?(Hash)
            attributes[:variants].each do |k, v|
              items << ::Map::Layer.new(k, v.try(:[], :url), v.try(:[], :enabled), v.try(:[], :by_default), v.try(:[], :type), v.try(:[], :options), provider)
            end
          else
            items << ::Map::Layer.new(:default, provider.url, provider.enabled, provider.by_default, provider.type, provider.options, provider)
          end
        end
      end

      def providers
        items.collect(&:provider_name).uniq
      end

      def find(reference_name)
        return nil unless reference_name
        detect do |layer|
          layer.reference_name == reference_name
        end
      end

      def find_each(&block)
        each(&block)
      end

      def of_type(type = :background)
        select do |layer|
          layer.type.to_sym == type.to_sym
        end
      end
    end
  end
end
