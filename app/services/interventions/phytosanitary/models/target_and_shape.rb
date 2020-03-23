module Interventions
  module Phytosanitary
    module Models
      class TargetAndShape
        attr_reader :target, :shape

        # @param [LandParcel, Plant] target
        # @param [Charta::Geometry] shape
        def initialize(target, shape)
          @target = target
          @shape = shape
        end
      end
    end
  end
end