# frozen_string_literal: true

module Procedo
  class ProcedureRegistry
    # @return [Hash<String, Symbol => Procedure>]
    attr_reader :procedures
    # @return [Array<ProcedureLoader>]
    attr_reader :loaders

    def initialize
      @procedures = HashWithIndifferentAccess.new
      @loaders = []
    end

    # @param [ProcedureLoader] loader
    def register_loader(loader)
      @loaders << loader
    end

    def load
      loaders.flat_map(&:load).each do |procedure|
        @procedures[procedure.name] = procedure
      end
    end
  end
end
