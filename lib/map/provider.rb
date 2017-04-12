module Map
  class Provider
    attr_reader :name, :url, :enabled, :by_default, :options, :type

    def initialize(name, url, enabled, by_default, type, options = {})
      @name = name
      @url = url
      @enabled = enabled
      @by_default = by_default
      @type = type
      @options = options
    end

    def label
      name.to_s.camelize
    end
  end
end
