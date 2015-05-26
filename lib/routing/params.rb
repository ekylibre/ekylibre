module Routes

  class ParamsConstraint

    def initialize(params = {})
      @params = params.stringify_keys
    end

    def matches?(request)
      return !@params.detect do |key, value|
        value != request.query_parameters[key] and value != request.request_parameters[key]
      end
    end

  end

end

module ActionDispatch::Routing

  class Mapper

    def params(*args)
      Routes::ParamsConstraint.new(*args)
    end

  end

end
