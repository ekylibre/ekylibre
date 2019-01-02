module GeoJSON
  class << self
    def parse(str)
      json = JSON.parse str
      return json if ::Charta::GeoJSON.valid? json
      nil
    end

    def feat_collection(*features)
      {'type' => "FeatureCollection", 'features' => features.flatten}
    end

    def feat(properties = {}, geometry = poly)
      {'type' => "Feature", 'properties' => properties.deep_stringify_keys, 'geometry' => geometry}
    end

    def poly(coordinates = [[[]]])
      {'type' => "Polygon", 'coordinates' => coordinates}
    end
  end
end