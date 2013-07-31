module Aggeratio
  class Base

    attr_reader :name, :parameters, :root, :aggregator

    def initialize(aggregator)
      @aggregator = aggregator
      @name = @aggregator.attr("name")
      @parameters = @aggregator.children[0].children.inject({}) do |hash, element|
        hash[element.attr('name').to_s] = Parameter.new(element)
        hash
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
      for parameter in @parameters.values
        code << "#{parameter.name} = @#{parameter.name}\n"
      end
      return code
    end

  end
end
