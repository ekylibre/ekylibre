module Procedo

  class CompiledVariable
    attr_accessor :destinations, :handlers, :procedure, :actor, :variant

    def initialize(procedure)
      raise "Invalid procedure" unless procedure.is_a?(Procedo::CompiledProcedure)
      @procedure = procedure
      @destinations = {}.with_indifferent_access
      @handlers = {}.with_indifferent_access
      @actor = nil
      @variant = nil
    end

    def now
      @procedure.now!
    end

    def actor_id
      (@actor ? @actor.id : nil)
    end

    def variant_id
      (@variant ? @variant.id : nil)
    end

  end

end
