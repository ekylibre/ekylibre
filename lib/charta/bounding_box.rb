module Charta
  class BoundingBox
    attr_reader :y_min, :x_min, :y_max, :x_max

    def initialize(y_min, x_min, y_max, x_max)
      @y_min = y_min
      @x_min = x_min
      @y_max = y_max
      @x_max = x_max
    end

    def width
      @x_max - @x_min
    end

    def height
      @y_max - @y_min
    end

    def svg_view_box
      [x_min, -y_max, width, height]
    end

    def to_a
      [[@y_min, @x_min], [@y_max, @x_max]]
    end
  end
end
