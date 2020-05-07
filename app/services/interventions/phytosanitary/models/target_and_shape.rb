module Interventions
  module Phytosanitary
    module Models
      class TargetAndShape

        class << self

          # @param [Intervention] intervention
          # @return [Array<TargetAndShape>]
          def from_intervention(intervention)
            intervention.targets.map do |target|
              new(target.product, target.working_zone)
            end
          end
        end

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