module ActionIntegration
  class Parameter
    def initialize(name, &default_value)
      @name = name.to_s
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
