require 'nokogiri'

class GeojsonImport
  attr_reader :shapes
  attr_writer :xml

  # TODO: handle a File object instead of calling IO read/write directly
  def initialize(params = {})
    @params = params.symbolize_keys
    @shapes = nil
  end

  def valid?
    shapes = JSON.parse(@xml)
    ::Charta::GeoJSON.valid?(shapes)
  end

  def shapes(options = {})
    options[:to] ||= ''

    @shapes = JSON.parse(@xml)

    if options[:to].equal? :json
      @shapes = @shapes.to_json
    elsif options[:to].equal? :string
      @shapes = @shapes.to_s
    end
  end

  def as_geojson
    @shapes.to_json
  end
end
