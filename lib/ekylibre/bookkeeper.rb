module Ekylibre
  class Bookkeeper
    attr_reader :resource, :recorder

    def initialize(recorder)
      @resource = recorder.resource
      @recorder = recorder
    end

    private

      def journal_entry(*args, &block)
        recorder.journal_entry(*args, &block)
      end

    def method_missing(method_name, *args, &block)
      super unless resource.respond_to? method_name
      resource.send(method_name, *args, &block)
    end

    def respond_to_missing?(method_name)
      resource.respond_to? method_name
    end
  end
end
