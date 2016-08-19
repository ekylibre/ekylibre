module ActionCaller
  # Response object that includes the DSL methods.
  class Response
    attr_reader :code

    def initialize(net_response)
      @code = net_response.code
    end

    def success
      yield if @code.first == '2'
    end

    def redirect
      yield if @code.first == '3'
    end

    def error(error_code: nil)
      return unless %w(4 5).include?(@code.first)
      yield if block_given?
      error_code
    end
  end
end
