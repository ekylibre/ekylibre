module Backend
  module Visualizations
    class RidesVisualizationsController < Backend::VisualizationsController
      respond_to :json

      def show
        ride = Ride.find(params[:ride_id])
        ride_map = RideMap.new(ride, view_context)

        config = view_context.configure_visualization do |v|
          options = { fill_opacity: 0.2, fill_color: '#3171A9', color: '#FFFFFF', weight: 3 }
          ride_map.parcels_near_ride.each do |parcel|
            v.serie parcel[:name], [parcel]
            v.simple parcel[:name], parcel[:name], options
          end
          v.serie :ride, ride_map.linestring
          v.polyline :ride, :ride
          v.serie :data_start_end, ride_map.start_end_crumbs
          v.points :startend, :data_start_end, colors: ['#7fbf7f', '#ff7f7f']
          if ride_map.pause_crumbs.any?
            v.serie :pause, ride_map.pause_crumbs
            v.pause_group :pause.tl, :pause
          end
        end

        respond_with config
      end
    end
  end
end
