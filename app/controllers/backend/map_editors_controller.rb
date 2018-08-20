module Backend
  class MapEditorsController < Backend::BaseController
    def upload
      file_parsed = false
      geometries = {}

      uploaded = params[:import_file]
      if uploaded.present?
        format = params[:importer_format]
        geometries = import_shapes(uploaded, format)
      end

      if geometries.is_a?(Hash) && geometries.key?(:error)
        flash.now[:alert] = geometries[:error].tl
      end

      respond_to do |format|
        format.json { render json: { alert: flash.alert } } unless flash.now[:alert].nil?
        format.json { render json: geometries.to_json }
      end
    end

    protected

    def import_shapes(file, format)
      geometry = file.read
      feature = nil
      geojson_features = nil
      srid = nil
      geojson_features_collection = ::Charta.empty_geometry.to_json_object

      begin
        case format.to_s
        when 'gml'
          geojson_features_collection = ::Charta.from_gml(geometry, nil, false).to_json_object(true) if ::Charta::GML.valid?(geometry)

        when 'kml'
          geojson_features_collection = Charta.from_kml(geometry, false).to_json_object(true) if ::Charta::KML.valid?(geometry)

        when 'geojson'
          geo = (begin
                   geometry.is_a?(Hash) ? geometry : JSON.parse(geometry)
                 rescue
                   {}
                 end) || {}
          srid = geo.try(:[], 'crs').try(:[], 'properties').try(:[], 'name')

          if ::Charta::GeoJSON.valid?(geometry, srid)
            geojson = (geometry.is_a?(Hash) ? geometry : JSON.parse(geometry)) || {}

            single_feature = [geojson] if geojson.key? 'feature'

            single_geometry = [geojson] if geojson.key? 'coordinates'

            if geojson.key?('features') || single_feature.is_a?(Array) || single_geometry.is_a?(Array)
              geoarray = geojson.try(:[], 'features') || single_feature || single_geometry
              if geoarray.is_a?(Array) && geoarray.count > 0
                geojson_features = geoarray.collect do |feature|
                  geofeature = nil
                  gfeature = {}

                  single_geometry ? gfeature['geometry'] = feature : gfeature = feature

                  if gfeature.key? 'geometry'
                    if ::Charta::GeoJSON.valid?(gfeature['geometry'])
                      geofeature = {
                        type: 'Feature',
                        properties: {
                          internal_id: (Time.now.to_i.to_s + Time.now.usec.to_s),
                          name: gfeature.try(:[], 'properties').try(:[], 'name'),
                          id: gfeature.try(:[], 'properties').try(:[], 'id'),
                          removable: true
                        }.reject { |_, v| v.nil? },
                        geometry: Charta.from_geojson(gfeature['geometry'], srid).transform(:WGS84).to_json_object
                      }.reject { |_, v| v.nil? }
                    end
                  end
                  geofeature
                end

              end
            end
          end

          unless geojson_features.nil?
            geojson_features_collection = {
              type: 'FeatureCollection',
              features: geojson_features
            }
          end

        else
          return { error: 'invalid_format' }
        end
      rescue
        return { error: 'invalid_file' }
      end

      if geojson_features_collection == ::Charta.empty_geometry.to_json_object
        return { error: 'invalid_file' }
      end

      geojson_features_collection
    end
  end
end
