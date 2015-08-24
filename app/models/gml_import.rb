require 'nokogiri'

class GmlImport
  attr_reader :shapes
  attr_writer :xml

  def initialize(params = {})
    @params = params.symbolize_keys
    @shapes = nil
  end

  def valid?
    self.shapes
    geometries = self.as_geojson || {}

    !geometries.empty?
  end

  def sanitize(xml)

    xml.to_s.squish
  end

  def shapes(options = {})

    options[:to] ||= ''

    f = sanitize @xml

    doc = Nokogiri::XML(f) do |config|
      config.options = Nokogiri::XML::ParseOptions::NOBLANKS
    end

    @shapes = doc.root

    if options[:to].equal? :xml
      @shapes = @shapes.to_xml
    elsif options[:to].equal? :string
      @shapes = @shapes.to_s
    else
      @shapes
    end

  end


  def as_geojson

    geojson_features_collection = {}
    geojson_features = []

    if @shapes.is_a? Nokogiri::XML::Node

      geojson_features << featurize(@shapes)

    elsif @shapes.is_a? Nokogiri::XML::NodeSet

      @shapes.each do |node|

        geojson_features << featurize(node)

      end

    end

    geojson_features_collection = {
        type: 'FeatureCollection',
        features: geojson_features
    }

    geojson_features_collection

  end

  private
  def featurize(node)
    if node.element? and node.xpath('.//gml:Polygon')
      geojson_feature = {}

      geometry = node.xpath('.//gml:Polygon')
      geometry.first['srsName'] = 'EPSG:2154'

      if ::Charta::GML.valid?(geometry)

        #properties
        id = Digest::MD5.hexdigest(Time.now.to_i.to_s+Time.now.usec.to_s)

        geojson_feature = {
            type: 'Feature',
            properties: {
                internal_id: id
            }.reject{ |_, v| v.nil? },
            geometry: ::Charta::Geometry.new(geometry.to_xml, nil, 'gml').transform(:WGS84).to_geojson
        }.reject{ |_, v| v.nil? }

        return geojson_feature
      else
        return false
      end
    end
  end

end