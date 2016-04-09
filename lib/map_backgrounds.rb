module MapBackgrounds
  class Layer
    mattr_accessor :items do
      []
    end
    attr_reader :name
    attr_reader :label
    attr_reader :url
    attr_reader :enabled
    attr_reader :attribution

    def initialize(name, url, enabled, attribution, provider)
      @name = name
      @url = url || provider.url
      @enabled = enabled.nil? ? false : enabled
      @attribution = attribution || provider.attribution
      @provider = provider
    end

    def label
      @name == :default ? @provider.label : "#{@provider.label}.#{@name.to_s.camelize}"
    end

    def provider_name
      @provider.name
    end

    class << self
      # Load backgrounds from config_path parameter (if any) or from config/map_backgrounds.yml
      def load(path=nil)
        config_path = path || Rails.root.join('config', 'map_backgrounds.yml')
        fail 'No valid config file found for MapBackgrounds::Layer' unless Pathname(config_path).exist?
        layers = YAML.load_file(config_path).deep_symbolize_keys
        layers.each do |provider, attributes|
          provider = ::MapBackgrounds::Provider.new(provider, attributes[:url], attributes[:options])

          # A layer can be represented by a variant or by the provider itself
          if attributes.key?(:variants) and attributes[:variants].is_a? Hash
            attributes[:variants].each do |k, v|
              items << ::MapBackgrounds::Layer.new(k, v.try(:[], :url), v.try(:[], :enabled), v.try(:[], :attribution), provider)
            end
          else
            items << ::MapBackgrounds::Layer.new(:default, provider.url, provider.enabled, provider.attribution, provider)
          end
        end
      end

      def providers
        items.collect(&:provider_name).uniq
      end

      def find(provider, layer_name)
        return nil unless provider && layer_name
        items.detect do |layer|
          layer.provider_name == provider.to_sym && layer.name == layer_name.to_sym
        end
      end
    end
  end
  class Provider
    attr_reader :name, :url, :options

    def initialize(name, url, options={})
      @name=name
      @url=url
      @options=options
    end

    def label
      name.to_s.camelize
    end

    def attribution
      @options.try(:[], :attribution)
    end

    def enabled
      @options.try(:[], :enabled)
    end
  end
end

MapBackgrounds::Layer.load