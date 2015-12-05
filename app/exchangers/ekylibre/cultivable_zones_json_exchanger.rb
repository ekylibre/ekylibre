class Ekylibre::CultivableZonesJsonExchanger < ActiveExchanger::Base
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
        CultivableZone.create!(properties.slice('name', 'work_number').merge(shape: shape))
      end
    else
      fail ActiveExchanger::NotWellFormedFileError, 'File seems to be JSON but not GeoJSON.'
    end
  end
end
