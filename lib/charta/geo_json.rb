module Charta
  # Represents a Geometry with SRID
  class GeoJSON
    attr_reader :srid

    def initialize(data, srid = :WGS84)
      @json = (data.is_a?(Hash) ? data : JSON.parse(data))
      @srid = Geometry.find_srid(srid)
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

      def object_to_ewkt(hash)
        send("#{hash['type'].underscore}_to_ewkt", hash)
      end

      def feature_collection_to_ewkt(hash)
        return 'GEOMETRYCOLLECTION EMPTY' if hash['features'].blank?
        'GEOMETRYCOLLECTION(' + hash['features'].collect do |feature|
          object_to_ewkt(feature)
        end.join(', ') + ')'
      end

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
