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
      if clusters['type'] == 'FeatureCollection'
        clusters['features'].each do |feature|
          properties = feature['properties']
          shape = ::Charta.from_geojson(feature)
          # check if current cluster cover or overlap an existing cultivable zone
          shape_inside_cultivable_zone = CultivableZone.shape_covering(shape, 0.02)
          unless shape_inside_cultivable_zone.any?
            shape_inside_cultivable_zone = CultivableZone.shape_matching(shape, 0.02)
          end
          if shape_inside_cultivable_zone.any?
            cultivable_zone = shape_inside_cultivable_zone.first
            cultivable_zone.name = properties['name'] if properties['name']
            cultivable_zone.save!
          else
            CultivableZone.create!(properties.slice('name', 'work_number').merge(shape: shape))
          end
        end
      else
        raise ActiveExchanger::NotWellFormedFileError, 'File seems to be JSON but not GeoJSON.'
      end
    end
  end
end
