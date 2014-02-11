module Charta
  # Represents a Geometry with SRID
  class Geometry

    attr_reader :ewkt

    def initialize(coordinates, srs = nil)
      if coordinates.is_a?(self.class)
        @ewkt = coordinates.ewkt
      elsif coordinates.is_a?(String)
        if coordinates =~ /\A[A-F0-9]+\z/ # WKB
          if srs and srid = find_srid(srs)
            @ewkt = select_value("SELECT ST_AsEWKT(ST_GeomFromText(E'\\\\x#{coordinates}', #{srid}))")
          else
            @ewkt = select_value("SELECT ST_AsEWKT(ST_GeomFromEWKB(E'\\\\x#{coordinates}'))")
          end
        elsif coordinates =~ /\A\{.*\}\z/ # GeoJSON
          srid = find_srid(srs)
          @ewkt = select_value("SELECT ST_AsEWKT(ST_SetSRID(ST_GeomFromGeoJSON('#{coordinates}'), #{srid}))")
        else # WKT expected
          if srs and srid = find_srid(srs)
            @ewkt = select_value("SELECT ST_AsEWKT(ST_GeomFromText('#{coordinates}', #{srid}))")
          else
            @ewkt = select_value("SELECT ST_AsEWKT(ST_GeomFromEWKT('#{coordinates}'))")
          end
        end
      else
        @ewkt = select_value("SELECT ST_AsEWKT(ST_GeomFromText('#{coordinates.as_text}', #{coordinates.srid}))")
      end
      if @ewkt.blank?
        raise ArgumentError, "Invalid data: coordinates=#{coordinates.inspect}, srid=#{srid.inspect}"
      end
    end

    def inspect
      "<Geometry(#{@ewkt})>"
    end

    def geom
      "ST_MakeValid(ST_GeomFromEWKT('#{@ewkt}'))"
    end

    def srid
      return select_value("SELECT ST_SRID(#{self.geom})").to_i
    end

    def to_rgeo
      @ewkt
    end

    def to_text
      return select_value("SELECT ST_AsText(#{self.geom})")
    end

    def to_ewkt
      return @ewkt
    end

    def to_binary
      return select_value("SELECT ST_AsEWKB(#{self.geom})")
    end

    def to_gml
      return select_value("SELECT ST_AsGML(#{self.geom})")
    end

    def to_kml
      return select_value("SELECT ST_AsKML(#{self.geom})")
    end

    def to_svg
      return select_value("SELECT ST_AsSVG(#{self.geom})")
    end

    def to_geojson
      return JSON.parse(select_value("SELECT ST_AsGeoJSON(#{self.geom})"))
    end

    # Returns area in square meter
    def area
      if srid = find_srid(Preference[:map_measure_srid])
        value = select_value("SELECT ST_Area(ST_Transform(#{self.geom}, #{srid}))")
      else
        value = select_value("SELECT ST_Area(#{self.geom}::geography)")
      end
      return (value.blank? ? 0.0 : value.to_d).in_square_meter
    end

    def centroid
      return select_row("SELECT ST_Y(ST_Centroid(#{self.geom})), ST_X(ST_Centroid(#{self.geom}))").map(&:to_f)
    end

    def point_on_surface
      return select_row("SELECT ST_Y(ST_PointOnSurface(#{self.geom})), ST_X(ST_PointOnSurface(#{self.geom}))").map(&:to_f)
    end

    def transform(srid)
      return self.class.new(select_value("SELECT ST_AsEWKT(ST_Transform(#{self.geom}, #{find_srid(srid)}))"))
    end

    # def merge!(other_geometry)
    #   @ewkt = self.merge(other_geometry).ewkt
    # end

    def merge(other_geometry)
      other = self.class.new(other_geometry).transform(self.srid)
      self.class.new(select_value("SELECT ST_AsEWKT(ST_Union(#{self.geom}, #{other.geom}))"))
    end

    def bounding_box
      if @y_min and @x_min and @y_max and @x_max
        values = [@y_min, @x_min, @y_max, @x_max]
      else
        values = select_row("SELECT " + [:YMin, :XMin, :YMax, :XMax].collect do |v|
                              "ST_#{v}(#{self.geom})"
                            end.join(", ")).map(&:to_f)
        [:y_min, :x_min, :y_max, :x_max].each_with_index do |val, index|
          self.instance_variable_set("@#{val}", values[index])
        end
      end
      return [values[0..1], values[2..3]]
    end

    def x_min
      @x_min ||= select_value("SELECT ST_XMin(#{self.geom})").to_i
    end

    def y_min
      @y_min ||= select_value("SELECT ST_YMin(#{self.geom})").to_i
    end

    def x_max
      @x_max ||= select_value("SELECT ST_XMax(#{self.geom})").to_i
    end

    def y_max
      @y_max ||= select_value("SELECT ST_YMax(#{self.geom})").to_i
    end






    def select_value(query)
      self.class.select_value(query)
    end

    def select_row(query)
      self.class.select_row(query)
    end

    def find_srid(name_or_srid)
      self.class.find_srid(name_or_srid)
    end



    class << self

      # Link to the nomenclature
      def systems
        Nomen::SpatialReferenceSystems
      end

      def empty(srid = :WGS84)
        new("GEOMETRYCOLLECTION EMPTY", srid)
      end

      # # Converts coordinates of a Geometry into the reference of the given SRID
      # def transform(geometry, srid)
      #   geometry = new(geometry)
      #   return new(select_value("SELECT ST_Transform(#{geometry.geom}, #{find_srid(srid)})"))
      # end

      # Execute a query
      def select_value(query)
        ActiveRecord::Base.connection.select_value(query)
      end

      # Execute a query
      def select_row(query)
        ActiveRecord::Base.connection.select_rows(query).first
      end

      # Check and returns the SRID matching with name or SRID.
      def find_srid(name_or_srid)
        if name_or_srid.is_a?(Symbol)
          item = systems.items[name_or_srid]
        else
          item = systems.where(srid: name_or_srid).first
        end
        return (item ? item.srid : nil)
      end

    end

  end
end
