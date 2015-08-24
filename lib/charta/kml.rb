module Charta
  # Represents a Geometry with SRID
  class KML
    attr_reader :srid

    def initialize(data, srid = :WGS84)
      if data.is_a? Nokogiri::XML::Document
        @kml = data.root.to_xml
      elsif data.is_a?(Nokogiri::XML::NodeSet) || data.is_a?(Nokogiri::XML::Element)
        @kml = data.to_xml
      else
        @kml = data
      end
      @srid = Geometry.find_srid(srid)
    end

    def to_ewkt
      ::Charta::Geometry.select_value("SELECT ST_AsEWKT(ST_GeomFromKML('#{@kml}'))")
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
