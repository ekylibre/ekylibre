# frozen_string_literal: true

module Procedo
  class ProcedureLoader
    # @return [Pathname]
    attr_reader :root

    # @param [Pathname] root
    def initialize(root:)
      @root = root
    end

    # @return [Array<Procedure>]
    def load
      Dir.glob(root.join('*.xml')).flat_map do |path|
        Procedo::XML.parse(path)
      end
    end
  end
end
