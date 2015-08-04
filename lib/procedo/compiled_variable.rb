module Procedo
  class CompiledVariable
    attr_accessor :destinations, :handlers, :procedure, :actor, :variant

    def initialize(procedure)
      fail 'Invalid procedure' unless procedure.is_a?(Procedo::CompiledProcedure)
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

    def contents_count
      return @actor.containeds(at: now).count(&:available?) if @actor
      0
    end
  end
end
