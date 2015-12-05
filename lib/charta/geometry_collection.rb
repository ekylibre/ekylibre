module Charta
  # Represent a Geometry with contains other geometries
  class GeometryCollection < Geometry
    def initialize(ewkt)
      super(ewkt)
      homogenize!
    end

    # Homogenize data if it's a GeometryCollection
    def homogenize!
      @ewkt = select_value("SELECT ST_AsEWKT(ST_Multi(ST_CollectionHomogenize(#{geom})))")
    end

    def self.empty(srid = :WGS84)
      srid = Charta.find_srid(srid)
      new("SRID=#{srid};GEOMETRYCOLLECTION EMPTY")
    end
  end
end
