module Ekylibre
  # Import a GeoJSON file (as FeatureCollection) with `name` and `number`
  # properties for each feature.
  class CultivableZonesJsonExchanger < ActiveExchanger::Base
    # def check
    #   valid = true
    #   clusters = JSON.parse(file.read).deep_symbolize_keys
    #   unless clusters[:type] == 'FeatureCollection'
    #     w.error 'Invalid format'
    #     valid = false
    #   end
    #   valid
    # end

    def import
      clusters = JSON.parse(file.read)
      ensure_clusters_valid_geojson(clusters)
      clusters['features'].each do |feature|
        shape = ::Charta.from_geojson(feature)
        properties = feature['properties']
        attributes = properties.slice('work_number')
                               .merge(shape: shape)

        cultivable_zone = zones_overlapping(shape).first ||
                          CultivableZone.new(attributes)

        cultivable_zone.name = properties['name'] if properties['name']
        cultivable_zone.save!
      end
    end

    private

    def ensure_clusters_valid_geojson(clusters)
      raise ActiveExchanger::NotWellFormedFileError, 'File seems to be JSON but not GeoJSON.' if clusters['type'] != 'FeatureCollection'
    end

    def zones_overlapping(shape)
      # check if current cluster cover or overlap an existing cultivable zone
      shapes_over_zone = CultivableZone.shape_covering(shape, 0.02)
      return shapes_over_zone if shapes_over_zone.any?
      CultivableZone.shape_matching(shape, 0.02)
    end
  end
end
