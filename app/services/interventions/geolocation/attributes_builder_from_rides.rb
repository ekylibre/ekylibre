# frozen_string_literal: true

module Interventions
  module Geolocation
    # Build intervention target attributes (including computed working zone) from rides
    class AttributesBuilderFromRides
      DEFAULT_TOOL_WIDTH = 3.5

      def self.call(*args)
        new(*args).call
      end

      def initialize(ride_ids:, procedure_name:, target_class: nil)
        @ride_ids = ride_ids
        @procedure_name = procedure_name
        @target_class = target_class
      end

      def call
        options = {
          targets_attributes: [],
          group_parameters_attributes: [],
          ride_ids: existing_rides.pluck(:id)
        }

        return options if target_parameter.nil?
        return options if existing_rides.blank?

        if matching_targets.any?
          target_options = matching_targets.map {|target| { reference_name: target_parameter.name, product_id: target.id, working_zone: compute_target_working_zone(target.shape) }}
          options[:working_periods_attributes] = [{
            started_at: started_at,
            stopped_at: stopped_at
          }]

          if  target_parameter_group_name.present?
            options[:group_parameters_attributes] = target_options.map{ |target| { reference_name:  target_parameter_group_name, targets_attributes: [target] }}
          else
            options[:targets_attributes] = target_options
          end
        end

        options
      end

      private
        attr_reader :ride_ids

        def working_zone
          crumbs = Crumb.where(ride_id: existing_rides.pluck(:id))
          line = ::Charta.make_line(crumbs.order(:read_at).pluck(:geolocation))
          line.buffer(tool_width)
        end

        def existing_rides
          @existing_rides ||= Ride.joins(:equipment).with_state(:unaffected).where(id: @ride_ids, nature: :work).reorder(:started_at)
        end

        def started_at
          existing_rides.first.started_at
        end

        def stopped_at
          existing_rides.last.stopped_at
        end

        def ride_main_equipment
          existing_rides.first.equipment
        end

        def tool_width
          if (width = ride_main_equipment.get(:application_width).in(:meter).to_f).zero?
            DEFAULT_TOOL_WIDTH
          else
            width
          end
        end

        def target_parameter
          procedure = Procedo::Procedure.find(@procedure_name)
          return nil if procedure.nil?

          procedure.parameters_of_type(:target, true).first
        end

        def matching_targets
          @matching_targets ||= target_class.at(started_at).shape_intersecting(working_zone)
        end

        def target_class
          return @target_class if @target_class.present?

          case target_parameter.name
          when :land_parcel then LandParcel
          when :plant       then Plant
          when :cultivation then LandParcel
          else nil
          end
        end

        def target_parameter_group_name
          if target_parameter.group.name != :root_
            target_parameter.group.name
          else
            ""
          end
        end

        def compute_target_working_zone(target_shape)
          computed_working_zones = Charta.new_geometry(target_shape.intersection(working_zone))
          if computed_working_zones.instance_of?(Charta::Polygon)
            computed_working_zones.to_json_feature.with_indifferent_access
          else
            computed_working_zones.to_json_feature_collection.with_indifferent_access
          end
        end

    end
  end
end
