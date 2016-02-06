module Charta
  # Represent a Geometry with contains only polygons
  class LineString < Geometry
    def each_point(&block)
      if block.arity == 1
        points.each(&block)
      elsif block.arity == 2
        points.each_with_index(&block)
      else
        raise 'Cannot browse each point without parameter'
      end
    end

    def points
      @points ||= select_values("SELECT ST_AsEWKT(ST_PointN(#{geom}, generate_series(1, ST_NPoints(#{geom}))))").map do |point|
        Point.new(point)
      end || []
    end
  end
end
