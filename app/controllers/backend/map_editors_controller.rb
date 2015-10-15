class Backend::MapEditorsController < Backend::BaseController
  def upload
    file_parsed = false
    geometries = {}

    uploaded = params[:import_file]
    unless uploaded.blank?
      format = params[:importer_format]
      geometries = import_shapes(uploaded, format)
    end

    respond_to do |format|
      format.json { render json: geometries.to_json }
    end
  end

  protected

  def import_shapes(file, format)
    case format
    when 'gml'
      import = Charta::GmlImport.new(file.read)
    when 'kml'
      import = Charta::KmlImport.new(file.read)
    when 'geojson'
      import = Charta::GeojsonImport.new(file.read)
    else
      fail 'Invalid format'
    end
    geometries = nil
    if import.valid?
      import.shapes
      geometries = import.as_geojson
    end
    geometries
  end
end
