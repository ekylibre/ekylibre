module Charta
  # Represents a Geometry with SRID
  class GeoJSON
    
    def initialize(data, srid = nil)
      @json = (data.is_a?(Hash) ? data : JSON.parse(data))
      @srid = srid
    end

    def to_ewkt
      "SRID=#{@srid};" + self.class.object_to_ewkt(@json)
    end

    class << self

      def object_to_ewkt(hash)
        send("#{hash['type'].underscore}_to_ewkt", hash)
      end

      def feature_collection_to_ewkt(hash)
        return "GEOMETRYCOLLECTION(" + hash['features'].collect do |feature|
          object_to_ewkt(feature)
        end.join(", ") + ")"
      end

      def feature_to_ewkt(hash)
        return object_to_ewkt(hash['geometry'])
      end

      def point_to_ewkt(hash)
        return "POINT(" + hash['coordinates'].join(" ") + ")"
      end

      def line_string_to_ewkt(hash)
        return "LINESTRING(" + hash['coordinates'].collect do |point|
          point.join(" ")
        end.join(", ") + ")"
      end

      def polygon_to_ewkt(hash)
        return "POLYGON(" + hash['coordinates'].collect do |hole|
          "(" + hole.collect do |point|
            point.join(" ")
          end.join(", ") + ")"
        end.join(", ") + ")"
      end

      def multi_point_to_ewkt(hash)
        return "MULTIPOINT(" + hash['coordinates'].collect do |point|
          "(" + point.join(" ") + ")"
        end.join(", ") + ")"
      end

      def multi_line_string_to_ewkt(hash)
        return "MULTILINESTRING(" + hash['coordinates'].collect do |line|
          "(" + hole.collect do |point|
            point.join(" ")
          end.join(", ") + ")"
        end.join(", ") + ")"
      end

      def multi_polygon_to_ewkt(hash)
        return "MULTIPOLYGON(" + hash['coordinates'].collect do |polygon|
          "(" + polygon.collect do |hole|
            "(" + hole.collect do |point|
              point.join(" ")
            end.join(", ") + ")"
          end.join(", ") + ")"
        end.join(", ") + ")"
      end



    end

  end
end
