module Charta
  # Represent a Geometry with contains other geometries
  class GeometryCollection < Geometry
    def initialize(ewkt, flatten = true, options = [])
      super(ewkt)
      @options = options
      homogenize! if flatten
    end

    # Homogenize data if it's a GeometryCollection
    def homogenize!
      @ewkt = select_value("SELECT ST_AsEWKT(ST_Multi(ST_CollectionHomogenize(#{geom})))")
    end

    def self.empty(srid = nil)
      srid = Charta.find_srid(srid.blank? ? :WGS84 : srid)
      new("SRID=#{srid};GEOMETRYCOLLECTION EMPTY")
    end
  end
end
