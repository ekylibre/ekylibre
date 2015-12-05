module Charta
  # Represent a Geometry with contains only polygons
  class Polygon < Geometry
    def exterior_ring
      @exterior_ring ||= LineString.new(select_value("SELECT ST_AsEWKT(ST_ExteriorRing(#{geom}))"))
    end
  end
end
