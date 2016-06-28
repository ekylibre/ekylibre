module Ekylibre
  # Import a list of cultivable zone from georeadings
  # Prefer ekylibre/cultivable_zones_json to import directly cultivable zones
  # REMOVEME This exchanger is not very useful in standalone mode
  class CultivableZonesExchanger < ActiveExchanger::Base
    # Create or updates cultivable zones
    def import
      rows = CSV.read(file, headers: true).delete_if { |r| r[0].blank? }
      w.count = rows.size

      rows.each do |row|
        r = {
          name: row[0].to_s,
          nature: (row[1].blank? ? nil : row[1].to_sym),
          code: (row[2].blank? ? nil : row[2].to_s),
          georeading_number: (row[3].blank? ? nil : row[3].to_s)
          # members: row[4].blank? ? [] : row[4].to_s.strip.split(/[[:space:]]*\,[[:space:]]*/)
        }.to_struct

        georeading = Georeading.find_by(number: r.georeading_number)
        raise "Cannot find georeading: #{r.georeading_number}" unless georeading
        zone = CultivableZone.find_or_initialize_by(work_number: r.code)
        zone.name = r.name
        zone.shape = georeading.content
        zone.save!
        w.check_point
      end
    end
  end
end
