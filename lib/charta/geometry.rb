module Charta
  # Represents a Geometry with SRID
  class Geometry

    attr_reader :ewkt

    def initialize(coordinates, srid = nil)
      if coordinates.is_a?(self.class)
        @ewkt = coordinates.ewkt
      elsif coordinates.is_a?(String)
        if coordinates =~ /\A[A-F0-9]+\z/ # WKB
          if srid
            @ewkt = select_value("SELECT ST_AsEWKT(ST_GeomFromText(E'\\\\x#{coordinates}', #{srid}))")
          else
            @ewkt = select_value("SELECT ST_AsEWKT(ST_GeomFromEWKB(E'\\\\x#{coordinates}'))")
          end
        else # WKT expected
          if srid
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
      "ST_GeomFromEWKT('#{@ewkt}')"
    end

    def select_value(query)
      self.class.select_value(query)
    end

    class << self

      # Link to the nomenclature
      def systems
        Nomen::SpatialReferenceSystems
      end

      # Converts coordinates of a Geometry into the reference of the given SRID
      def transform(geometry, srid)
        geometry = new(geometry)
        return new(select_value("SELECT ST_Transform(#{geometry.geom}, #{find_srid(srid)})"))
      end

      # Execute a query
      def select_value(query)
        ActiveRecord::Base.connection.select_value(query)
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
