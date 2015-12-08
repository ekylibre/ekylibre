# FIXME: What is a Zone? Need doc
module Ekylibre
  class ZonesExchanger < ActiveExchanger::Base
    # Create or updates zones
    def import
      born_at = Time.new(1995, 1, 1, 10, 0, 0, '+00:00')
      default_place = LandParcel.first
      land_parcel_variant = ProductNatureVariant.import_from_nomenclature(:land_parcel)
      LandParcel.create!(
        variant_id: land_parcel_variant.id,
        work_number: 'LP00',
        name: 'LandParcel',
        initial_born_at: Time.new(1995, 1, 1, 10, 0, 0, '+00:00'),
        initial_owner: Entity.of_company,
        default_storage: nil
      )

      rows = CSV.read(file, headers: true).delete_if { |r| r[0].blank? }
      w.count = rows.size

      rows.each do |row|
        r = {
          name: row[0].to_s,
          nature: (row[1].blank? ? nil : row[1].to_sym),
          code: (row[2].blank? ? nil : row[2].to_s),
          group_code: (row[3].blank? ? nil : row[3].to_s),
          place_code: (row[4].blank? ? nil : row[4].to_s),
          description: (row[5].blank? ? nil : row[5].to_s)
        }.to_struct

        if Product.where(work_number: r.code).empty? && r.nature
          unless zone_variant = ProductNatureVariant.find_by(reference_name: r.nature)
            zone_variant = ProductNatureVariant.import_from_nomenclature(r.nature)
          end
          zone = zone_variant.matching_model.create!(variant: zone_variant, work_number: r.code,
                                                     name: r.name,
                                                     initial_born_at: born_at,
                                                     initial_owner: Entity.of_company,
                                                     initial_container: Product.find_by_work_number(r.place_code))
        end

        if zone
          if georeading = Georeading.find_by(number: r.code)
            zone.read!(:shape, georeading.content, at: born_at, force: true)
            zone.read!(:net_surface_area, georeading.to_geom.area, at: born_at, force: true)
          end
        end

        w.check_point
      end
    end
  end
end
