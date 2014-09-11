# -*- coding: utf-8 -*-
Ekylibre::FirstRun.add_loader :buildings do |first_run|

  # create base land parcel
  land_parcel_variant = ProductNatureVariant.import_from_nomenclature(:land_parcel)
  LandParcel.create!(:variant_id => land_parcel_variant.id, :work_number => "LP00",
                     :name => "Parcelle par défault", :initial_born_at => Time.new(1995, 1, 1, 10, 0, 0, "+00:00"), :initial_owner => Entity.of_company, :default_storage => nil)

  path = first_run.path("alamano", "zones.csv")
  if path.exist?
    # Zones, BuildingDivisions...
    born_at = Time.new(1995, 1, 1, 10, 0, 0, "+00:00")
    default_place = LandParcel.first
    first_run.count :zone_groups do |w|
      CSV.foreach(path, headers: true) do |row|
        r = OpenStruct.new(name: row[0].to_s,
                           nature: (row[1].blank? ? nil : row[1].to_sym),
                           code: (row[2].blank? ? nil : row[2].to_s),
                           group_code: (row[3].blank? ? nil : row[3].to_s),
                           place_code: (row[4].blank? ? nil : row[4].to_s),
                           description: (row[5].blank? ? nil : row[5].to_s)
                           )

        if Product.where(work_number: r.code).empty? and r.nature
          unless zone_variant = ProductNatureVariant.find_by(reference_name: r.nature)
            zone_variant = ProductNatureVariant.import_from_nomenclature(r.nature)
          end
          zone_variant.matching_model.create!(variant: zone_variant, work_number: r.code,
                                              name: r.name,
                                              initial_born_at: born_at,
                                              initial_owner: Entity.of_company,
                                              initial_container: Product.find_by_work_number(r.place_code))
        end
        w.check_point
      end
    end
  end

  path = first_run.path("alamano", "zones", "zones.shp")
  if path.exist?
    first_run.count :zones_shapes do |w|
      #############################################################################
      born_at = Time.new(1995, 1, 1, 10, 0, 0, "+00:00")
      RGeo::Shapefile::Reader.open(path.to_s, :srid => 4326) do |file|
        # puts "File contains #{file.num_records} records."
        file.each do |record|
          if zone = Product.find_by_work_number(record.attributes['work_numbe'])
            zone.read!(:shape, record.geometry, at: born_at, force: true)
            zone.read!(:net_surface_area, zone.shape_area, at: born_at, force: true)
          end
          w.check_point
        end
      end
    end
  end

end
