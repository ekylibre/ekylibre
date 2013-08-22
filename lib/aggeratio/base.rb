module Aggeratio
  class Base

    attr_reader :name, :parameters, :root, :aggregator

    def initialize(aggregator)
      @aggregator = aggregator
      @name = @aggregator.attr("name")
      @parameters = @aggregator.children[0].children.collect do |element|
        Parameter.import(element)
      end
      @root = @aggregator.children[1]
    end

    def class_name
      name.camelcase
    end

    def build
      raise NotImplementedEror.new
    end

    def parameter_initialization
      code = ""
      for parameter in parameters
        code << "#{parameter.name} = @#{parameter.name}\n"
      end
      return code
    end

    def normalize_name(name)
      name = name.attr('name') unless name.is_a?(String)
      name.to_s.strip.gsub('_', '-')
    end

    def value_of(element)
      value = (element.has_attribute?("value") ? element.attr("value") : element.has_attribute?("name") ? element.attr("name") : "inspect")
      value = element.attr("of") + "." + value if element.has_attribute?("of")
      return value
    end


    def human_value_of(element)
      value = value_of(element)
      type = (element.has_attribute?("type") ? element.attr("type").to_s : :string).to_s.gsub('-', '_').to_sym
      human_value = if type == :date or type == :datetime or type == :measure
                      value + ".l"
                    else
                      value
                    end
      return human_value
    end


    def human_name_of(element)
      name = element.attr('value').to_s.downcase # unless name.is_a?(String)
      name = element.attr('name') unless name.match(/^\w+$/)
      name = name.to_s.strip.gsub('-', '_')
      return "'labels.#{name}'.t(:default => [:'attributes.#{name}', '#{name.to_s.humanize}'])"
    end

  end
end
