module Charta
  # Represent a Point
  class Point < Geometry
    def x
      coordinates(:x)
    end
    alias longitude x

    def y
      coordinates(:y)
    end
    alias latitude y

    protected

    # Computes X,Y in one time and store it
    def coordinates(axis)
      unless @coordinates
        coord = select_row("SELECT ST_X(#{geom}), ST_Y(#{geom})")
        @coordinates = { x: coord[0].to_d, y: coord[1].to_d }
      end
      @coordinates[axis]
    end
  end
end
