module Charta
  # Represents a Geometry with SRID
  class KML
    attr_reader :srid

    TAGS = %w[Point LineString Polygon MultiGeometry].freeze

    def initialize(data, srid = :WGS84)
      @kml = if data.is_a? String

               Nokogiri::XML(data.to_s.squish) do |config|
                 config.options = Nokogiri::XML::ParseOptions::NOBLANKS
               end

             else
               # Nokogiri::XML::Document expected
               data
             end
      @srid = Charta.find_srid(srid)
    end

    def to_ewkt
      "SRID=#{@srid};" + self.class.document_to_ewkt(@kml)
    end

    def valid?
      to_ewkt
      true
    rescue
      false
    end

    class << self
      # Test is given data is a valid KML
      def valid?(data, srid = :WGS84)
        new(data, srid).valid?
      rescue
        false
      end

      def object_to_ewkt(fragment)
        send("#{fragment.name.snakecase}_to_ewkt", fragment)
      end

      def document_to_ewkt(kml)
        return 'GEOMETRYCOLLECTION EMPTY' if kml.css('Document').blank?
        'GEOMETRYCOLLECTION(' + kml.css('Placemark').collect do |placemark|
          TAGS.collect do |tag|
            next if placemark.css(tag).empty?
            placemark.css(tag).collect do |fragment|
              object_to_ewkt(fragment)
            end.compact.join(', ')
          end.compact.join(', ')
        end.compact.join(', ') + ')'
      end
      alias geometry_collection_to_ewkt document_to_ewkt

      def feature_to_ewkt(kml)
        object_to_ewkt(kml)
      end

      def point_to_ewkt(kml)
        return 'POINT EMPTY' if kml.css('coordinates').blank?
        'POINT(' + kml.css('coordinates').collect { |coords| coords.content.split ',' }.flatten.join(' ') + ')'
      end

      def line_string_to_ewkt(kml)
        return 'LINESTRING EMPTY' if kml.css('coordinates').blank?

        'LINESTRING(' + kml.css('coordinates').collect { |coords| coords.content.split(/\r\n|\n| /) }.flatten.reject(&:empty?).collect { |c| c.split ',' }.collect { |dimension| %(#{dimension.first} #{dimension.second}) }.join(', ') + ')'
      end

      def polygon_to_ewkt(kml)
        return 'POLYGON EMPTY' if kml.css('coordinates').blank?

        'POLYGON(' + %w[outerBoundaryIs innerBoundaryIs].collect do |boundary|
          next if kml.css(boundary).empty?

          kml.css(boundary).collect do |hole|
            '(' + hole.css('coordinates').collect { |coords| coords.content.split(/\r\n|\n| /) }.flatten.reject(&:empty?).collect { |c| c.split ',' }.collect { |dimension| %(#{dimension.first} #{dimension.second}) }.join(', ') + ')'
          end.join(', ')
        end.compact.join(', ') + ')'
      end

      def multigeometry_to_ewkt(_kml)
        raise :not_implemented
      end
    end
  end
end
