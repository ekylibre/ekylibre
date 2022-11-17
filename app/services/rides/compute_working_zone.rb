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
      line = ::Charta.make_line(ordered_crumbs.pluck(:geolocation))
      line.to_rgeo.buffer( tool_width / 2)
    end

    private
      attr_reader :rides

      def tool_width
        width = begin
                  rides.first.equipment.width&.to_f
                rescue NoMethodError => e
                  DEFAULT_TOOL_WIDTH
                end
        width.zero? ? DEFAULT_TOOL_WIDTH : width
      end

      def ordered_crumbs
        Crumb.where(ride_id: rides.pluck(:id)).order(:read_at)
      end

  end
end
