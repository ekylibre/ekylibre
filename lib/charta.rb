# Gathers geomatic calculations
# Completes RGeo
require 'charta/geometry'
require 'charta/geometry_collection'
require 'charta/point'
require 'charta/line_string'
require 'charta/polygon'
require 'charta/multi_polygon'
require 'charta/bounding_box'
require 'charta/geo_json'

module Charta
  class << self
    def new_geometry(coordinates, srs = nil, format = nil)
      geom_ewkt = nil
      if coordinates.blank?
        geom_ewkt = empty_geometry(srs).to_ewkt
      elsif coordinates.is_a?(self.class)
        geom_ewkt = coordinates.ewkt
      elsif coordinates.is_a?(Hash) || (coordinates.is_a?(String) && ::Charta::GeoJSON.valid?(coordinates)) # GeoJSON
        srid = srs ? find_srid(srs) : :WGS84
        geom_ewkt = select_value("SELECT ST_AsEWKT(ST_GeomFromEWKT('#{::Charta::GeoJSON.new(coordinates, srid).to_ewkt}'))")
      elsif coordinates.is_a?(String)
        if coordinates =~ /\A[A-F0-9]+\z/ # WKB
          if srs && srid = find_srid(srs)
            geom_ewkt = select_value("SELECT ST_AsEWKT(ST_GeomFromText(E'\\\\x#{coordinates}', #{srid}))")
          else
            geom_ewkt = select_value("SELECT ST_AsEWKT(ST_GeomFromEWKB(E'\\\\x#{coordinates}'))")
          end
        elsif format == 'gml' && ::Charta::GML.valid?(coordinates)
          # required format 'cause kml geometries return empty instead of failing
          geom_ewkt = ::Charta::GML.new(coordinates, srid).to_ewkt
        elsif format == 'kml' && ::Charta::KML.valid?(coordinates)
          geom_ewkt = ::Charta::KML.new(coordinates, srid).to_ewkt
        else # WKT expected
          if srs && srid = find_srid(srs)
            geom_ewkt = select_value("SELECT ST_AsEWKT(ST_GeomFromText('#{coordinates}', #{srid}))")
          else
            geom_ewkt = select_value("SELECT ST_AsEWKT(ST_GeomFromEWKT('#{coordinates}'))")
          end
        end
      else
        geom_ewkt = select_value("SELECT ST_AsEWKT(ST_GeomFromText('#{coordinates.as_text}', #{coordinates.srid}))")
      end
      if geom_ewkt.blank?
        fail ArgumentError, "Invalid data: coordinates=#{coordinates.inspect}, srid=#{srid.inspect}"
      end
      type = select_value("SELECT GeometryType(ST_GeomFromEWKT('#{geom_ewkt}'))").to_s.strip
      geom = case type
             when 'POINT' then
               Point.new(geom_ewkt)
             when 'LINESTRING' then
               LineString.new(geom_ewkt)
             when 'POLYGON' then
               Polygon.new(geom_ewkt)
             when 'MULTIPOLYGON' then
               MultiPolygon.new(geom_ewkt)
             when 'GEOMETRYCOLLECTION' then
               GeometryCollection.new(geom_ewkt)
             else
               Geometry.new(geom_ewkt)
             end
      geom
    end

    def new_point(lat, lon, srid = 4326)
      Point.new("SRID=#{srid};POINT(#{lon} #{lat})")
    end

    def empty_geometry(srid = :WGS84)
      GeometryCollection.empty(srid)
    end

    # Execute a query
    def select_value(query)
      ActiveRecord::Base.connection.select_value(query)
    end

    def select_values(query)
      ActiveRecord::Base.connection.select_values(query)
    end

    # Execute a query
    def select_row(query)
      ActiveRecord::Base.connection.select_rows(query).first
    end

    # Link to the nomenclature
    def systems
      Nomen::SpatialReferenceSystem
    end

    # Check and returns the SRID matching with srname or SRID.
    def find_srid(srname_or_srid)
      if srname_or_srid.is_a?(Symbol) || srname_or_srid.is_a?(String)
        item = systems.items[srname_or_srid]
      else
        item = systems.find_by(srid: srname_or_srid)
      end
      (item ? item.srid : nil)
    end

    def clean_for_active_record(value, options = {})
      return nil if value.blank?
      if value.is_a?(String) && value =~ /\A\{.*\}\z/
        value = from_geojson(value)
      else
        value = new_geometry(value)
      end
      value.convert_to(options[:type]).to_rgeo
    end

    def from(format, data)
      unless respond_to?("from_#{format}")
        fail "Unknown format: #{format.inspect}"
      end
      send("from_#{format}", data)
    end

    def from_gml(data, srid = nil)
      new_geometry(::Charta::GML.new(data, srid).to_ewkt)
    end

    def from_kml(data)
      new_geometry(::Charta::KML.new(data).to_ewkt)
    end

    def from_geojson(data)
      new_geometry(::Charta::GeoJSON.new(data).to_ewkt)
    end
  end
end
