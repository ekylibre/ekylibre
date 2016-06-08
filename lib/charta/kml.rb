module Charta
  # Represents a Geometry with SRID
  class KML
    attr_reader :srid

    def initialize(data, srid = :WGS84)
      @kml = if data.is_a? String

                Nokogiri::XML(data.to_s.squish) do |config|
                  config.options = Nokogiri::XML::ParseOptions::NOBLANKS
                end

             else
               # Nokogiri::XML::Document expected
               data
             end
      sanitize!
      @srid = Charta.find_srid(srid)
    end

    def to_ewkt
      Charta.select_value("SELECT ST_AsEWKT(ST_GeomFromKML('#{@kml.css('Polygon').to_xml}'))")
    end

    def sanitize!
      return nil unless @kml.is_a? Nokogiri::XML::Document

      shapes = @kml.css('Polygon')

      shapes.css('coordinates').each do |coord|
        coordArray = coord.content.split /\r\n|\n| /
        coordArray.collect! { |c| c.split ',' }.collect! { |dimension| [dimension.first, dimension.second, '0'] }
        coord.content = coordArray.collect { |coord| coord.join(',') }.join(' ')
      end
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
    end
  end
end
