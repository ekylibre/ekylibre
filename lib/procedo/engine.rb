# require 'procedo/engine/intervention'
# require 'procedo/engine/reassignable'

module Procedo
  module Engine
    class << self
      def new_intervention(parameters)
        Procedo::Engine::Intervention.new(parameters)
      end
    end
  end
end
