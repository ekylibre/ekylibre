module Charta
  # Represents a Geometry with SRID
  class KML
    attr_reader :srid

    def initialize(data, srid = :WGS84)
      @kml = if data.is_a? Nokogiri::XML::Document
               data.root.to_xml
             elsif data.is_a?(Nokogiri::XML::NodeSet) || data.is_a?(Nokogiri::XML::Element)
               data.to_xml
             else
               data
             end
      sanitize!
      @srid = Charta.find_srid(srid)
    end

    def to_ewkt
      Charta.select_value("SELECT ST_AsEWKT(ST_GeomFromKML('#{@kml}'))")
    end

    def sanitize!
      xml = Nokogiri::XML(@kml) do |config|
        config.options = Nokogiri::XML::ParseOptions::NOBLANKS
      end

      coordinates = xml.css('coordinates')

      coordinates.each do |coord|
        coordArray = coord.content.split /\r\n|\n| /
        coordArray.collect!{|c|c.split ','}.collect!{|dimension| [dimension.first, dimension.second, '0']}
        coord.content = coordArray.collect{|coord| coord.join(',')}.join(' ')

      end
      @kml = xml.to_xml

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
