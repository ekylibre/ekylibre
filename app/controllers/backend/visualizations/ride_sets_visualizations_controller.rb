module Backend
  module Visualizations
    class RideSetsVisualizationsController < Backend::VisualizationsController
      respond_to :json

      def show
        ride_set = RideSet.find(params[:ride_set_id])
        ride_set_map = RideSetMap.new(ride_set, view_context)

        config = view_context.configure_visualization do |v|
          options = { fill_opacity: 0.2, fill_color: '#3171A9', color: '#FFFFFF', weight: 3 }
          ride_set_map.parcels_near_rides.each do |parcel|
            v.serie parcel[:name], [parcel]
            v.simple parcel[:name], parcel[:name], options
          end

          ride_set_map.rides.reverse.each do |ride|
            options = { color: ride.colors, center: ride_set.shape_centroid, ride_set: true }
            v.serie ride.name, ride.linestring
            v.polyline ride.name, ride.name, options
          end
        end

        respond_with config
      end
    end
  end
end
