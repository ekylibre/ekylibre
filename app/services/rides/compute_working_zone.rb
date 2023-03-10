# frozen_string_literal: true

module Rides
  DEFAULT_TOOL_WIDTH = 3.5

  class ComputeWorkingZone
    def self.call(*args)
      new(*args).call
    end

    def initialize(rides:)
      @rides = rides

    end

    def call
      points = if ordered_crumbs.any?
                 ordered_crumbs.pluck(:geolocation)
               else
                 points_from_rides_shapes
               end
      line = ::Charta.make_line(points).to_rgeo
      line.buffer( tool_width / 2 )
    end

    private
      attr_reader :rides

      def tool_width
        width = begin
                  rides.first.ride_set.products.map{ |product| product.get(:application_width).to_f }.compact.max || DEFAULT_TOOL_WIDTH
                rescue NoMethodError => e
                  DEFAULT_TOOL_WIDTH
                end
        width.zero? ? DEFAULT_TOOL_WIDTH : width
      end

      def ordered_crumbs
        Crumb.where(ride_id: rides.pluck(:id)).order(:read_at)
      end

      def points_from_rides_shapes
        rides.order(:started_at).flat_map { |ride| ride.shape.points }
      end

  end
end
