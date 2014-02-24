module Procedo
  class CompiledProcedure

    attr_reader :now
    
    # def initialize(casting = {})
    #   cast(casting) if casting
    # end

    # def reverberate(updater, casting = nil)
    #   cast(casting) if casting
    #   updater = updater.split(':').map(&:to_sym) if updater.is_a?(String)
    #   @updates = {}
    #   send("update_other_from_#{updater.join('_')}")
    #   return @updates
    # end
      
    # # Register casting
    # def cast(casting)
    #   @casting = casting
    #   @now = Time.now
    # end

    @@list = {}.with_indifferent_access

    class << self

      def [](name)
        @@list[name]
      end

      def []=(name, compiled)
        unless compiled < self
          raise ArgumentError, "Invalid value. #{self.name} expected, got #{self.class.name}."
        end
        @@list[name] = compiled
      end

    end

  end
end
