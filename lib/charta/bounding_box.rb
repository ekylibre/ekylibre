module Charta

  class BoundingBox

    attr_reader :y_min, :x_min, :y_max, :x_max

    def initialize(y_min, x_min, y_max, x_max)
      @y_min, @x_min, @y_max, @x_max = y_min, x_min, y_max, x_max
      if @y_min > @y_max
        y = @y_min
        @y_min = @y_max
        @y_max = y
      end
      if @x_min > @x_max
        x = @x_min
        @x_min = @x_max
        @x_max = x
      end
    end

    def width
      @x_max - @x_min
    end

    def height
      @y_max - @y_min
    end

    def svg_view_box
      return [x_min, -y_max, width, height]
    end

    def to_a
      return [[@x_min, @y_min], [@x_max, @y_max]]
    end

  end

end
