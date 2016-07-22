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

# Charta aims to supply easy geom/geog tools
module Charta
  class << self
    def new_geometry(coordinates, srs = nil, format = nil, flatten_collection = true, options = {})
      geom_ewkt = nil
      if coordinates.blank?
        geom_ewkt = empty_geometry(srs).to_ewkt
      elsif coordinates.is_a?(::Charta::Geometry)
        geom_ewkt = coordinates.ewkt
      elsif coordinates.is_a?(Hash) || (coordinates.is_a?(String) && ::Charta::GeoJSON.valid?(coordinates)) # GeoJSON
        srid = srs ? find_srid(srs) : :WGS84
        geom_ewkt = select_value("SELECT ST_AsEWKT(ST_GeomFromEWKT('#{::Charta::GeoJSON.new(coordinates, srid).to_ewkt}'))")
      elsif coordinates.is_a?(String)
        geom_ewkt = if coordinates =~ /\A[A-F0-9]+\z/ # WKB
                      if srs && srid = find_srid(srs)
                        select_value("SELECT ST_AsEWKT(ST_GeomFromText(E'\\\\x#{coordinates}', #{srid}))")
                      else
                        select_value("SELECT ST_AsEWKT(ST_GeomFromEWKB(E'\\\\x#{coordinates}'))")
                      end
                    elsif format == 'gml' && ::Charta::GML.valid?(coordinates)
                      # required format 'cause kml geometries return empty instead of failing
                      ::Charta::GML.new(coordinates, srid).to_ewkt
                    elsif format == 'kml' && ::Charta::KML.valid?(coordinates)
                      ::Charta::KML.new(coordinates).to_ewkt
                    else # WKT expected
                      if srs && srid = find_srid(srs)
                        select_value("SELECT ST_AsEWKT(ST_GeomFromText('#{coordinates}', #{srid}))")
                      else
                        select_value("SELECT ST_AsEWKT(ST_GeomFromEWKT('#{coordinates}'))")
                      end
                    end
      else
        geom_ewkt = select_value("SELECT ST_AsEWKT(ST_GeomFromText('#{coordinates.as_text}', #{coordinates.srid}))")
      end
      if geom_ewkt.blank?
        raise ArgumentError, "Invalid data: coordinates=#{coordinates.inspect}, srid=#{srid.inspect}"
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
               MultiPolygon.new(geom_ewkt, flatten_collection, options)
             when 'GEOMETRYCOLLECTION' then
               GeometryCollection.new(geom_ewkt, flatten_collection, options)
             else
               Geometry.new(geom_ewkt)
             end

      geom
    end

    def new_point(lat, lon, srid = 4326)
      Point.new("SRID=#{srid};POINT(#{lon} #{lat})")
    end

    def make_line(points, options = {})
      options[:srid] ||= new_geometry(points.first).srid if points.any?
      options[:srid] ||= 4326
      list = points.map { |p| new_geometry(p).geom }
      new_geometry(select_value("SELECT ST_AsEWKT(ST_MakeLine(ARRAY[#{list.join(', ')}]))"))
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
      item = if srname_or_srid.is_a?(Symbol) || srname_or_srid.is_a?(String)
               if srname_or_srid =~ /\Aurn:ogc:def:crs:.*\z/
                 # first, find full-defined urn
                 found = systems.find_by(urn: srname_or_srid)

                 # or, match with authority reference
                 unless found
                   auth_ref = /\Aurn:ogc:def:crs:(.*)\z/.match(srname_or_srid)
                   if auth_ref.present?
                     srid = /\AEPSG::?(\d{4,5})\z/.match(auth_ref[1])
                     if srid.present?
                       found = systems.find_by(srid: srid[1].to_i)
                     end
                   end
                 end
                 found
               else
                 srid = /\AEPSG::?(\d{4,5})\z/.match(srname_or_srid)
                 if srid.present?
                   systems.find_by(srid: srid[1].to_i)
                 else
                   systems.items[srname_or_srid]
                 end
               end
             else
               systems.find_by(srid: srname_or_srid)
             end
      (item ? item.srid : nil)
    end

    def clean_for_active_record(value, options = {})
      return nil if value.blank?
      value = if value.is_a?(Hash) || (value.is_a?(String) && value =~ /\A\{.*\}\z/)
                from_geojson(value)
              else
                new_geometry(value)
              end
      value.flatten.convert_to(options[:type]).to_rgeo
    end

    def from(format, data)
      unless respond_to?("from_#{format}")
        raise "Unknown format: #{format.inspect}"
      end
      send("from_#{format}", data)
    end

    def from_gml(data, srid = nil, flatten_collection = false)
      new_geometry(::Charta::GML.new(data, srid).to_ewkt, nil, nil, flatten_collection)
    end

    def from_kml(data, flatten_collection = false)
      new_geometry(::Charta::KML.new(data).to_ewkt, nil, nil, flatten_collection)
    end

    def from_geojson(data, srid = nil)
      new_geometry(::Charta::GeoJSON.new(data, srid).to_ewkt)
    end

    def new_collection(geometries)
      geometries.is_a? Array and geometries.any? ? new_geometry(Charta.select_value("SELECT ST_AsEWKT(ST_Collect(ARRAY[#{geometries.collect { |geo| geo[:shape].geom }.join(',')}]))"), nil, nil, false, geometries) : Charta.empty_geometry
    end
  end
end
