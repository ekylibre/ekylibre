require 'nokogiri'

class GeojsonImport
  # TODO: handle a File object instead of calling IO read/write directly
  def initialize(data)
    @shapes = nil
    @xml = data
  end

  def valid?
    shapes = JSON.parse(@xml)
    ::Charta::GeoJSON.valid?(shapes)
  end

  def shapes(options = {})
    options[:to] ||= :json

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
