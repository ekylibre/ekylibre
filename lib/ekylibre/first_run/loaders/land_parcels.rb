Ekylibre::FirstRun.add_loader :land_parcels do |first_run|

  first_run.import_archive(:telepac_v2014_cap_land_parcels, "ilot.zip", "ilot.shp", "ilot.dbf", "ilot.shx", in: "telepac")

  first_run.import_archive(:telepac_v2014_land_parcels, "parcelle.zip", "parcelle.shp", "parcelle.dbf", "parcelle.shx", in: "telepac")

  first_run.import_archive(:telepac_v2015_land_parcels, "parcelle.zip", "parcelle.shp", "parcelle.dbf", "parcelle.shx", in: "telepac/2015")
  first_run.import_archive(:telepac_v2015_cap_land_parcels, "ilot.zip", "ilot.shp", "ilot.dbf", "ilot.shx", in: "telepac/2015")

  # TODO removes zones which means nothing...
  {equipments: :polygon, cultivable_zones: :polygon, geolocations: :point, building_divisions: :polygon, buildings: :polygon, roads: :linestring, hedges: :linestring, water: :polygon, zones: :polygon}.each do |name, nature|
    dir = first_run.path.join("alamano", "georeadings")
    next unless dir.join("#{name}.shp").exist?

    puts "WARNING: You should rename zones.shp to building_divisions.shp".red if name == :zones

    mimefile = dir.join("#{name}.mimetype")
    File.write(mimefile, "application/vnd.ekylibre.georeading.#{nature}")

    first_run.import_archive(:ekylibre_georeadings, "#{name}.zip", "mimetype" => "#{name}.mimetype", "georeading.shp" => "#{name}.shp", "georeading.dbf" => "#{name}.dbf", "georeading.shx" => "#{name}.shx", in: "alamano/georeadings", prevent: false)

    FileUtils.rm_rf(mimefile)
  end

  first_run.import_file(:ekylibre_land_parcels, "alamano/land_parcels.csv")

  first_run.import_file(:ekylibre_cultivable_zones, "alamano/cultivable_zones.csv")

  first_run.import_file(:ekylibre_plants, "alamano/plants.csv")

  # VINITECA vines
  first_run.import_archive(:viniteca_plant_zones, "vines.zip", "plant.shp", "plant.dbf", "plant.shx", "plant.prj", "varieties_transcode.csv", "certifications_transcode.csv", "cultivable_zones_transcode.csv",  in: "viniteca")

  # UNICOQUE orchards
  first_run.import_archive(:unicoque_plant_zones, "plantation.zip", "plantation.shp", "plantation.dbf", "plantation.shx", "plantation.prj", "varieties_transcode.csv", in: "unicoque/plantation")

end
