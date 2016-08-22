module ActionCaller
  # Base for any ActionCaller
  class Base
    extend Protocols

    attr_reader :call

    include_protocol ActionCaller::Protocols::HTML
    include_protocol ActionCaller::Protocols::JSON
    include_protocol ActionCaller::Protocols::Savon

    def initialize(call)
      # Call object to which we'll delegate the http requests making up
      # the api calls
      @call = call
    end

    def self.calls(*called_methods)
      # Each method in the "calls" parameters corresponds to a Call to an API
      # therefore for each of them we define a class method that will initialize
      # a Call object which will actually call the method.
      called_methods.each do |method|
        singleton_class.instance_exec(method) do
          define_method(method) do |*args|
            ::Call.new(
              source: self,
              method: method,
              args:   args
            )
          end
        end
      end
    end
  end
end
