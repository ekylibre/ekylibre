module Charta
  # Represents a Geometry with SRID
  class GeoJSON
    attr_reader :srid

    def initialize(data, srid = :WGS84)
      srid ||= :WGS84
      @json = (data.is_a?(Hash) ? data : JSON.parse(data))
      lsrid = @json.try(:[], 'crs').try(:[], 'properties').try(:[], 'name') || srid
      @srid = ::Charta.find_srid(lsrid)
    end

    def flatten
      self.class.flatten(@json)
    end

    def geom
      Charta.new_geometry(to_ewkt)
    end

    def to_ewkt
      "SRID=#{@srid};" + self.class.object_to_ewkt(@json)
    end

    def valid?
      to_ewkt
      true
    rescue
      false
    end

    class << self
      # Test is given data is a valid GeoJSON
      def valid?(data, srid = :WGS84)
        new(data, srid).valid?
      rescue
        false
      end

      def flatten(hash)
        flattened =
          if hash['type'] == 'FeatureCollection'
            flatten_feature_collection(hash)
          elsif hash['type'] == 'Feature'
            flatten_feature(hash)
          else
            flatten_geometry(hash)
          end
        new(flattened)
      end

      def flatten_feature_collection(hash)
        hash.except('features').merge('features' => hash['features'].map { |f| flatten_feature(f) })
      end

      def flatten_feature(hash)
        hash.except('geometry').merge('geometry' => flatten_geometry(hash['geometry']))
      end

      def flatten_geometry(hash)
        coordinates = hash['coordinates']
        flattened =
          case hash['type']
          when 'Point' then
            flatten_position(coordinates)
          when 'MultiPoint', 'LineString'
            coordinates.map { |p| flatten_position(p) }
          when 'MultiLineString', 'Polygon'
            coordinates.map { |l| l.map { |p| flatten_position(p) } }
          when 'MultiPolygon'
            coordinates.map { |m| m.map { |l| l.map { |p| flatten_position(p) } } }
          when 'GeometryCollection' then
            return hash.except('geometries').merge('geometries' => hash['geometries'].map { |g| flatten_geometry(g) })
          else
            raise StandardError, "Cannot handle: #{hash['type']}"
          end

        hash.except('coordinates').merge('coordinates' => flattened)
      end

      def flatten_position(position)
        position[0..1]
      end

      def object_to_ewkt(hash)
        send("#{hash['type'].underscore}_to_ewkt", hash)
      end

      def feature_collection_to_ewkt(hash)
        return 'GEOMETRYCOLLECTION EMPTY' if hash['features'].blank?
        'GEOMETRYCOLLECTION(' + hash['features'].collect do |feature|
          object_to_ewkt(feature)
        end.join(', ') + ')'
      end
      alias geometry_collection_to_ewkt feature_collection_to_ewkt

      def feature_to_ewkt(hash)
        object_to_ewkt(hash['geometry'])
      end

      def point_to_ewkt(hash)
        return 'POINT EMPTY' if hash['coordinates'].blank?
        'POINT(' + hash['coordinates'].join(' ') + ')'
      end

      def line_string_to_ewkt(hash)
        return 'LINESTRING EMPTY' if hash['coordinates'].blank?
        'LINESTRING(' + hash['coordinates'].collect do |point|
          point.join(' ')
        end.join(', ') + ')'
      end

      def polygon_to_ewkt(hash)
        return 'POLYGON EMPTY' if hash['coordinates'].blank?
        'POLYGON(' + hash['coordinates'].collect do |hole|
          '(' + hole.collect do |point|
            point.join(' ')
          end.join(', ') + ')'
        end.join(', ') + ')'
      end

      def multi_point_to_ewkt(hash)
        return 'MULTIPOINT EMPTY' if hash['coordinates'].blank?
        'MULTIPOINT(' + hash['coordinates'].collect do |point|
          '(' + point.join(' ') + ')'
        end.join(', ') + ')'
      end

      def multi_line_string_to_ewkt(hash)
        return 'MULTILINESTRING EMPTY' if hash['coordinates'].blank?
        'MULTILINESTRING(' + hash['coordinates'].collect do |line|
          '(' + line.collect do |point|
            point.join(' ')
          end.join(', ') + ')'
        end.join(', ') + ')'
      end

      def multi_polygon_to_ewkt(hash)
        return 'MULTIPOLYGON EMPTY' if hash['coordinates'].blank?
        'MULTIPOLYGON(' + hash['coordinates'].collect do |polygon|
          '(' + polygon.collect do |hole|
            '(' + hole.collect do |point|
              point.join(' ')
            end.join(', ') + ')'
          end.join(', ') + ')'
        end.join(', ') + ')'
      end
    end
  end
end
