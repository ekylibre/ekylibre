module Aggeratio
  class Parameter
    TYPES = [:record_list, :record, :string, :decimal, :integer]
    attr_reader :name, :type, :default, :class_name

    def initialize(element)
      @type = element.attr("type").to_s.gsub('-', '_').to_sym
      raise ArgumentError.new("Type is unknown: #{@type.inspect}") unless TYPES.include?(@type)
      @name = element.attr("name").to_s
      raise ArgumentError.new("Default value must be given for #{@name}") unless element.has_attribute?("default")
      @default = element.attr("default").to_s
      @class_name = element.attr("of").to_s.camelcase
    end

  end
end
