module Ekylibre
  class BuildingsJsonExchanger < ActiveExchanger::Base
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
          variant = ProductNatureVariant.import_from_nomenclature(:building)
          building = Building.create!(properties.slice('name').merge(initial_shape: shape, variant: variant))
          divisions = properties['divisions']
          next unless divisions && divisions.any?
          divisions['features'].each do |division|
            properties = division['properties']
            shape = ::Charta.from_geojson(division)
            variant = ProductNatureVariant.import_from_nomenclature(:building_division)
            BuildingDivision.create!(properties.slice('name').merge(initial_shape: shape, variant: variant, initial_owner: Entity.of_company))
            # FIXME: We lose level (storey) and building information on division recording
          end
        end
      else
        raise ActiveExchanger::NotWellFormedFileError, 'File seems to be JSON but not GeoJSON.'
      end
    end
  end
end
