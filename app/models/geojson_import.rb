require 'nokogiri'

class GeojsonImport
  attr_reader :shapes

  #TODO: handle a File object instead of calling IO read/write directly
  def initialize(params = {})
    @params = params.symbolize_keys
    @shapes = nil
  end

  def geojson_import_file
    @params[:file] || Hajimari.geojson_import_file
  end

  def save(data)
    File.write self.geojson_import_file, data
  end

  def valid?
    f = File.read(self.geojson_import_file)
    shapes = JSON.parse(f)
    ::Charta::GeoJSON.valid?(shapes)
  end

  def exist?
    File.exist?(self.geojson_import_file)
  end

  def shapes(options = {})

    options[:to] ||= ''

    f = File.read(self.geojson_import_file)

    # no filter needed for now, see capImport shape method for example
    @shapes = JSON.parse(f)

    if options[:to].equal? :json
      @shapes = @shapes.to_json
    elsif options[:to].equal? :string
      @shapes = @shapes.to_s
    end

  end


  def as_geojson
    #TODO: make it valid geojson object
    @shapes.to_json
  end

end