module Charta
  # Represent a Geometry with contains only polygons
  class MultiPolygon < GeometryCollection
    def each_polygon(&block)
      if block.arity == 1
        polygons.each(&block)
      elsif block.arity == 2
        polygons.each_with_index do |polygon, index|
          yield polygon, index + 1
        end
      else
        raise 'Cannot browse each polygon without parameter'
      end
    end

    # Extract polygons ordered by 'PointOnSurface' position
    def polygons
      @polygons ||= select_values("SELECT ST_AsEWKT(geom) FROM (SELECT ST_GeometryN(#{geom}, generate_series(1, ST_NumGeometries(#{geom}))) AS geom) AS polygons ORDER BY ST_X(ST_PointOnSurface(geom)), ST_Y(ST_PointOnSurface(geom))").map do |polygon|
        Polygon.new(polygon)
      end || []
    end
  end
end
