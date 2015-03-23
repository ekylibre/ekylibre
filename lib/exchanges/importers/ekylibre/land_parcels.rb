Exchanges.add_importer :ekylibre_land_parcels do |file, w|
  # Set count of rows
  rows = CSV.read(file, headers: true)
  w.count = rows.size

  born_at = Time.utc(1900, 1, 1, 0, 0, 0)

  rows.each do |row|
    r = OpenStruct.new(name: row[0].to_s,
                       nature: (row[1].blank? ? nil : row[1].to_sym),
                       code: (row[2].blank? ? nil : row[2].to_s),
                       shape_number: (row[3].blank? ? nil : row[3].to_s),
                       land_parcel_cluster_code: (row[4].blank? ? nil : row[4].to_s),
                       place_code: (row[5].blank? ? nil : row[5].to_s),
                       soil_nature: (row[6].blank? ? nil : row[6].to_s),
                       available_water_capacity: (row[7].blank? ? nil : row[7].to_d),
                       soil_depth: (row[8].blank? ? nil : row[8].to_d)
                       )

    zone = nil

    # If landparcel already exist update it
    if zone = LandParcel.find_by(work_number: r.code)
      zone.update_attributes(name: r.name)
      zone.save!
      # else if landparcel shape already exist in georeadding then create it with shape
    elsif georeading = Georeading.find_by(number: r.shape_number)
      zone_variant = ProductNatureVariant.import_from_nomenclature(r.nature)
      pmodel = zone_variant.nature.matching_model
      zone = pmodel.create!(:variant_id => zone_variant.id, :work_number => r.code,
                            :name => r.name, :initial_born_at => born_at, :initial_owner => Entity.of_company, initial_shape: georeading.content)
    end

    if zone
      if container = Product.find_by_work_number(r.place_code)
        zone.update_attributes(initial_container: container)
        zone.save!
      end
      # link a land parcel to a land parcel cluster
      if land_parcel_cluster = LandParcelCluster.find_by(work_number: r.land_parcel_cluster_code) and zone.clusters_work_number == nil
        ProductMembership.create!(member: zone, group: land_parcel_cluster, started_at: born_at, nature: :interior)
      end
      if r.soil_nature
        zone.read!(:soil_nature, r.soil_nature, at: born_at, force: true)
      end
      if r.soil_depth
        zone.read!(:soil_depth, r.soil_depth.in_centimeter, at: born_at, force: true)
      end
      if r.available_water_capacity_per_area
        zone.read!(:available_water_capacity_per_area, r.available_water_capacity_per_area.in_liter_per_square_meter, at: born_at, force: true)
      end
    end
    w.check_point
  end

end
