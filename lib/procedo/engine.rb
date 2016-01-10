# require 'procedo/engine/intervention'

module Procedo
  module Engine
    class << self
      def new_intervention(parameters)
        Procedo::Engine::Intervention.new(parameters)
      end
    end
  end
end
