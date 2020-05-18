module Ekylibre
  # Zones exchanger accepts CSV files with given columns:
  #  - Name
  #  - Nature: from product_nature_variants nomenclature
  #  - Code (or working number): used to identify zone
  #  - Group code: Not used
  #  - Place code: Code of container if any
  #  - Description
  # Zones can be: building, settlement,
  class ZonesExchanger < ActiveExchanger::Base
    # Create or updates zones
    def import
      born_at = Time.new(1995, 1, 1, 10, 0, 0, '+00:00')

      rows = CSV.read(file, headers: true).delete_if { |r| r[0].blank? }
      w.count = rows.size

      rows.each do |row|
        r = {
          name: row[0].to_s,
          nature: (row[1].blank? ? :settlement : row[1].to_sym),
          code: (row[2].blank? ? nil : row[2].to_s),
          group_code: (row[3].blank? ? nil : row[3].to_s),
          place_code: (row[4].blank? ? nil : row[4].to_s),
          description: (row[5].blank? ? nil : row[5].to_s)
        }.to_struct

        zone = Product.find_by(work_number: r.code)
        unless zone
          zone_variant = ProductNatureVariant.import_from_nomenclature(r.nature)
          zone_variant ||= ProductNatureVariant.import_from_lexicon(r.nature)
          unless zone_variant
            raise InvalidDataError, "Invalid nature of zone: #{r.nature}"
          end
          zone = r.nature.to_s.camelcase.constantize.new(variant: zone_variant, work_number: r.code)
        end

        zone.name = r.name
        zone.initial_born_at ||= born_at
        zone.initial_owner ||= Entity.of_company
        zone.initial_container ||= Product.find_by(work_number: r.place_code)
        zone.description ||= r.description

        zone.save!

        # Adds georeading
        georeading = Georeading.find_by(number: r.code)
        if georeading
          zone.read!(:shape, georeading.content, at: zone.initial_born_at, force: true)
          zone.read!(:net_surface_area, georeading.content_area, at: zone.initial_born_at, force: true)
        end

        w.check_point
      end
    end
  end
end
