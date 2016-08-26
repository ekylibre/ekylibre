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
          georeading_number: (row[3].blank? ? nil : row[3].to_s),
          soil_nature: (row[4].blank? ? nil : row[4].to_sym),
          owner_name: (row[5].blank? ? nil : row[5].to_s),
          farmer_name: (row[6].blank? ? nil : row[6].to_s)
        }.to_struct

        zone = CultivableZone.find_or_initialize_by(work_number: r.code)
        zone.name = r.name

        if r.soil_nature && soil_variety = Nomen::SoilNature[r.soil_nature]
          zone.soil_nature = r.soil_nature
        end

        # link the owner if exist
        if r.owner_name
          owner = Entity.find_by(last_name: r.owner_name.to_s)
          owner ||= Entity.find_by(full_name: r.owner_name.to_s)
          zone.owner = owner if owner
        end

        # link the farmer if exist
        if r.farmer_name
          farmer = Entity.find_by(last_name: r.farmer_name.to_s)
          zone.farmer = farmer if farmer
        end

        georeading = Georeading.find_by(number: r.georeading_number) ||
                     Georeading.find_by(name: r.georeading_number)
        if georeading
          zone.shape = georeading.content
        else
          zone.shape = Charta.new_geometry('MULTIPOLYGON(((0 0,0 1,1 1,1 0,0 0)))')
          Rails.logger.warn "Cannot find georeading: #{r.georeading_number}"
        end
        zone.save!
        w.check_point
      end
    end
  end
end
