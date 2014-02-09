# -*- coding: utf-8 -*-
load_data :buildings do |loader|

  # create base land parcel
  land_parcel_variant = ProductNatureVariant.import_from_nomenclature(:land_parcel)
  LandParcel.create!(:variant_id => land_parcel_variant.id, :work_number => "LP00",
                                 :name => "Parcelle par défault", :initial_born_at => Time.new(1995, 1, 1, 10, 0, 0, "+00:00"), :initial_owner => Entity.of_company, :default_storage => nil)

  path = loader.path("zones.csv")
  if path.exist?
    born_at = Time.new(1995, 1, 1, 10, 0, 0, "+00:00")
    default_place = LandParcel.first
    loader.count :zone_groups do |w|
      CSV.foreach(path, headers: true) do |row|
        r = OpenStruct.new(name: row[0].to_s,
                           nature: (row[1].blank? ? nil : row[1].to_sym),
                           code: (row[2].blank? ? nil : row[2].to_s),
                           group_code: (row[3].blank? ? nil : row[3].to_s),
                           place_code: (row[4].blank? ? nil : row[4].to_s),
                           description: (row[5].blank? ? nil : row[5].to_s)
                          )

        unless zone = Product.find_by_work_number(r.code)
          zone_variant = ProductNatureVariant.find_by(:reference_name => r.nature) || ProductNatureVariant.import_from_nomenclature(r.nature)
          pmodel = zone_variant.nature.matching_model
          zone = pmodel.create!(:variant_id => zone_variant.id, :work_number => r.code,
                                 :name => r.name, :initial_born_at => born_at, :initial_owner => Entity.of_company)

            if container = Product.find_by_work_number(r.place_code)
              # container.add(zone, born_at)
              zone.update_attributes(initial_container: container)
              zone.save!
            end
        end
        w.check_point
     end
   end
  end

  path = loader.path("zones.shp")
  if path.exist?
    loader.count :zones_shapes do |w|
      #############################################################################
      born_at = Time.new(1995, 1, 1, 10, 0, 0, "+00:00")
      RGeo::Shapefile::Reader.open(path.to_s, :srid => 4326) do |file|
        # puts "File contains #{file.num_records} records."
        file.each do |record|
          if zone = Product.find_by_work_number(record.attributes['WORK_NUMBE'])
            zone.read!(:shape, record.geometry, at: born_at, force: true)
            zone.read!(:net_surface_area, zone.shape_area, at: born_at)
          end
          w.check_point
        end
      end
    end
  end

end
