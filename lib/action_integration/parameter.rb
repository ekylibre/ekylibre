module ActionIntegration
  class Parameter
    attr_reader :hidden, :readonly

    def initialize(name, options, &default_value)
      @name = name.to_s
      @hidden = options[:hidden]
      @readonly = options[:readonly]
      @default_value = default_value
    end

    def to_s
      @name
    end

    def default_value
      return nil if @default_value.blank?

      @default_value.call
    end
  end
end
