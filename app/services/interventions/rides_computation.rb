# frozen_string_literal: true

module Interventions
  # Transform crop groups id into intervention target parameters
  class RidesComputation
    DEFAULT_TOOL_WIDTH = 3.5

    def initialize(ride_ids, procedure_name)
      @ride_ids = ride_ids
      @procedure_name = procedure_name
    end

    def existing_rides
      @rides = Ride.where(id: @ride_ids, state: :unaffected, nature: :work).reorder(:started_at)
    end

    def options
      options = { targets_attributes: [],
        group_parameters_attributes: [],
        labellings_attributes: [] }

      return options if target_parameter.nil?
      return options if existing_rides.blank?

      @all_rides_crumbs = Crumb.where(ride_id: existing_rides.pluck(:id))
      @samsys_tool_width = existing_rides.first.provider[:data]["machine_equipment_tool_width"] || DEFAULT_TOOL_WIDTH

      if matching_targets.any?
        line_buffer_working_zone = rides_crumbs_line_with_buffer(all_rides_crumbs, samsys_tool_width)
        target_options = matching_targets.map {|target| { reference_name: target_parameter.name, product_id: target.id, working_zone: compute_geometry_collection(target, line_buffer_working_zone) }}

        if  target_parameter_group_name.present?
          options[:group_parameters_attributes] = target_options.map{ |target| { reference_name:  target_parameter_group_name, targets_attributes: [target] }}
        else
          options[:targets_attributes] = target_options
        end
      end

      options
    end

    private

      def target_parameter
        procedure = Procedo::Procedure.find(@procedure_name)
        return nil if procedure.nil?

        procedure.parameters_of_type(:target, true).first
      end

      def matching_targets
        started_at = existing_rides.first.started_at
        line_buffer_working_zone = rides_crumbs_line_with_buffer(@all_rides_crumbs, @samsys_tool_width)
        select_type_of_area(target_parameter.name).at(started_at).shape_intersecting(line_buffer_working_zone)
      end

      def select_type_of_area(target_parameter)
        case target_parameter
        when :land_parcel then LandParcel
        when :plant       then Plant
        when :cultivation then LandParcel
        else nil
        end
      end

      def rides_crumbs_line_with_buffer(all_rides_crumbs, samsys_tool_width)
        line = ::Charta.make_line(all_rides_crumbs.order(:read_at).map(&:geolocation))
        line.to_rgeo.buffer(samsys_tool_width)
      end

      def target_parameter_group_name
        if target_parameter.group.name != :root_
          target_parameter.group.name
        else
          ""
        end
      end

      def compute_geometry_collection(area, line_buffer_working_zone)
        computed_working_zones = Charta.new_geometry(area.shape.intersection(line_buffer_working_zone))
        if computed_working_zones.instance_of?(Charta::Polygon)
          computed_working_zones.to_json_feature
        else
          computed_working_zones.to_json_feature_collection
        end
      end

  end
end
