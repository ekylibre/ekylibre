# frozen_string_literal: true

module Interventions
  module Phytosanitary
    module Models
      class TargetZone
        class << self
          # @param [Intervention] intervention
          # @return [Array<TargetZone>]
          def from_intervention(intervention)
            intervention.targets.map do |target|
              new(target.product, target.working_zone || target.product_shape, target.working_area)
            end
          end

          # @param [Hash{String => Hash{String => String}}] targets_data
          #     Each value has two keys:
          #       'id' A Product id that is expected to be a Planr or LandParcel
          #       'shape' A GeoJSON String
          # @return [Array<TargetZone>]
          def from_targets_data(targets_data)
            targets_data.flat_map do |data|
              target = [Plant, LandParcel].map { |model| model.find_by(id: data[:id]) }.compact.first
              shape = Charta::new_geometry(data[:shape])
              working_zone_area_value = Measure.new(data[:working_zone_area_value]&.to_f || 0, :hectare).in(:square_meter)

              if target.present?
                [::Interventions::Phytosanitary::Models::TargetZone.new(target, shape, working_zone_area_value)]
              else
                []
              end
            end
          end
        end

        attr_reader :target, :shape, :area

        # @param [LandParcel, Plant] target
        # @param [Charta::Geometry] shape
        # @param [Measure] area in square meter
        def initialize(target, shape, area)
          @target = target
          @shape = shape
          @area = area
        end
      end
    end
  end
end
