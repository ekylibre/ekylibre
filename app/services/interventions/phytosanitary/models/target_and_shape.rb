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

          # @param [Hash{String => Hash{String => String}}] targets_data
          #     Each value has two keys: 
          #       'id' A Product id that is expected to be a Planr or LandParcel
          #       'shape' A GeoJSON String
          # @return [Array<TargetAndShape>]
          def from_targets_data(targets_data)
            targets_data.flat_map do |data|
              target = [Plant, LandParcel].map { |model| model.find_by(id: data[:id]) }.compact.first
              shape = Charta::new_geometry(data[:shape])
  
              if target.present?
                [::Interventions::Phytosanitary::Models::TargetAndShape.new(target, shape)]
              else
                []
              end
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