class Backend::MapEditorController < Backend::BaseController
  def import_shapes(file, format)
    geometries = nil
    case format
    when 'gml'
      import = GmlImport.new
      import.xml = file.read

      if import.valid?
        import.shapes
        geometries = import.as_geojson
      end
    when 'kml'
      import = KmlImport.new
      import.xml = file.read

      if import.valid?
        import.shapes
        geometries = import.as_geojson
        # geometries = import.as_wrapped_kml
      end
    when 'geojson'
      import = GeojsonImport.new
      import.xml file.read

      if import.valid?
        import.shapes(to: :json)
        geometries = import.as_geojson
      end
    end
    geometries
  end

  def upload
    file_parsed = false
    @import_geojson = {}

    if remotipart_submitted?
      uploaded = params[:import_file]
      unless uploaded.blank?
        format = params[:importer_format]
        geometries = import_shapes(uploaded, format)

        @import_geojson = geometries.to_json unless geometries.nil?

        file_parsed = true unless @import_geojson.blank?
      end
    end

    respond_to do |format|
      format.json { render json: @import_geojson }
    end
  end
end
