# frozen_string_literal: true

module Interventions
  # Transform crop groups id into intervention target parameters
  class RidesComputation
    DEFAULT_TOOL_WIDTH = 3.5

    def initialize(ride_ids)
      @ride_ids = ride_ids
    end

    def existing_rides
      @rides = Ride.where(id: @ride_ids, state: :unaffected, nature: :work).reorder(:started_at)
    end

    def options
      rides = @rides
      started_at = rides.first.started_at
      all_rides_crumbs = Crumb.where(ride_id: rides.pluck(:id))
      samsys_tool_width = rides.first.provider[:data]["machine_equipment_tool_width"] || DEFAULT_TOOL_WIDTH

      # create a crumbs rides line with samsys buffer
      line = ::Charta.make_line(all_rides_crumbs.order(:read_at).map(&:geolocation))
      line_buffer_working_zone = line.to_rgeo.buffer(samsys_tool_width)

      targets = []
      # Find land_parcels or plants intersecting rides_working_zone
      land_parcels = LandParcel.at(started_at).shape_intersecting(line_buffer_working_zone)
      land_parcels.each do |land_parcel|
        item = {}
        item[:product_id] = land_parcel.id
        item[:reference_name] = "cultivation"
        item[:working_zone] = compute_geometry_collection(land_parcel, line_buffer_working_zone)

        targets << item
      end
      targets
    end

    def compute_geometry_collection(land_parcel, line_buffer_working_zone)
      computed_working_zones = Charta.new_geometry(land_parcel.shape.intersection(line_buffer_working_zone))
      if computed_working_zones.instance_of?(Charta::Polygon)
        computed_working_zones.to_json_feature
      else
        computed_working_zones.to_json_feature_collection
      end
    end

  end
end
