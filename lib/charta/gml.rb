module Charta
  # Represents a Geometry with SRID
  class GML
    attr_reader :srid

    def initialize(data, srid = :WGS84)
      if data.is_a? Nokogiri::XML::Document
        @gml = data.root.to_xml
      elsif data.is_a?(Nokogiri::XML::NodeSet) || data.is_a?(Nokogiri::XML::Element)
        @gml = data.to_xml
      else
        @gml = data
      end
      @srid = Charta.find_srid(srid)
    end

    def to_ewkt
      Charta.select_value("SELECT ST_AsEWKT(ST_GeomFromGML('#{@gml}'))")
    end

    def valid?
      to_ewkt
      true
    rescue
      false
    end

    class << self
      # Test is given data is a valid GML
      def valid?(data, srid = :WGS84)
        new(data, srid).valid?
      rescue
        false
      end
    end
  end
end
