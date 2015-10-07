module Procedo
  class CompiledProcedure
    # Returns the moment of the execution of the intervention
    def now!
      @__started_at__
    end

    # Checks "updater path"
    def updater?(*args)
      args.each_with_index do |arg, index|
        return false if arg != @__updater__[index]
      end
      true
    end

    @@list = {}.with_indifferent_access

    class << self
      def [](name)
        @@list[name]
      end

      def []=(name, compiled)
        unless compiled < self
          fail ArgumentError, "Invalid value. #{self.name} expected, got #{self.class.name}."
        end
        @@list[name] = compiled
      end
    end
  end
end
