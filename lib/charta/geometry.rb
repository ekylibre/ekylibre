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

    def to_rgeo
      @ewkt
    end

    def geom
      "ST_MakeValid(ST_GeomFromEWKT('#{@ewkt}'))"
    end

    def srid
      return select_value("SELECT ST_SRID(#{self.geom})").to_i
    end

    def to_text
      return select_value("SELECT ST_AsText(#{self.geom})")
    end

    def to_geojson
      return JSON.parse(select_value("SELECT ST_AsGeoJSON(#{self.geom})"))
    end

    def centroid
      return select_row("SELECT ST_Y(ST_Centroid(#{self.geom})), ST_X(ST_Centroid(#{self.geom}))").map(&:to_f)
    end

    def transform(srid)
      return self.class.new(select_value("SELECT ST_AsEWKT(ST_Transform(#{self.geom}, #{find_srid(srid)}))"))
    end

    def merge!(other_geometry)
      @ewkt = self.merge(other_geometry).ewkt
    end

    def merge(other_geometry)
      other = self.class.new(other_geometry).transform(self.srid)
      self.class.new(select_value("SELECT ST_AsEWKT(ST_Union(#{self.geom}, #{other.geom}))"))
    end

    def bounding_box
      values = select_row("SELECT " + [:YMin, :XMin, :YMax, :XMax].collect do |v|
                               "ST_#{v}(#{self.geom})"
                             end.join(", ")).map(&:to_f)
      return [values[0..1], values[2..3]]
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
          systems.items[name_or_srid].srid
        else
          systems.where(srid: name_or_srid).first.srid
        end
      end

    end

  end
end
