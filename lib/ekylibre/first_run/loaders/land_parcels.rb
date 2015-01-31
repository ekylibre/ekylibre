# -*- coding: utf-8 -*-
Ekylibre::FirstRun.add_loader :land_parcels do |first_run|

  shapes = {}.with_indifferent_access

  file = first_run.check_archive("ilot.zip", "ilot.shp", "ilot.dbf", "ilot.shx", in: "telepac")
  if file.exist?
    first_run.import(:telepac_cap_land_parcels, file)
  end

  file = first_run.check_archive("parcelle.zip", "parcelle.shp", "parcelle.dbf", "parcelle.shx", in: "telepac")
  if file.exist?
    first_run.import(:telepac_land_parcels, file)
  end

  # TODO: Removes zones level, zones and initial_geolocations
  for level in [:georeadings, :zones]
    for name, nature in {equipments: :polygon, cultivable_zones: :polygon, geolocations: :point, initial_geolocations: :point, building_divisions: :polygon, buildings: :polygon, zones: :polygon, roads: :linestring, hedges: :linestring, water: :polygon}
      dir = first_run.path.join("alamano/#{level}")
      if dir.join("#{name}.shp").exist?

        mimefile = dir.join("#{name}.mimetype")
        File.write(mimefile, "application/vnd.ekylibre.georeading.#{nature}")

        file = first_run.check_archive("#{name}.zip", "mimetype" => "#{name}.mimetype", "georeading.shp" => "#{name}.shp", "georeading.shp" => "#{name}.shp", "georeading.dbf" => "#{name}.dbf", "georeading.shx" => "#{name}.shx", in: "alamano/#{level}") # , "georeading.prj" => "#{name}.prj"

        FileUtils.rm_rf(mimefile)

        if file.exist?
          first_run.import(:ekylibre_georeadings, file)
        end
      end
    end
  end

  path = first_run.path("alamano", "land_parcels.csv")
  if path.exist?
    first_run.import(:ekylibre_land_parcels, path)
  end

  path = first_run.path("alamano", "cultivable_zones.csv")
  if path.exist?
    first_run.import(:ekylibre_cultivable_zones, path)
  end

  # TODO: Remove this file. Use plants instead.
  path = first_run.path("alamano", "cultivations.csv")
  if path.exist?
    first_run.import(:ekylibre_plants, path)
  end

  path = first_run.path("alamano", "plants.csv")
  if path.exist?
    first_run.import(:ekylibre_plants, path)
  end

  # VINITECA vines
  file = first_run.check_archive("vines.zip", "plant.shp", "plant.dbf", "plant.shx", "plant.prj", "varieties_transcode.csv", "certifications_transcode.csv", "cultivable_zones_transcode.csv",  in: "viniteca")
  if file.exist?
    first_run.import(:viniteca_plant_zones, file)
  end


  # UNICOQUE orchards
  file = first_run.check_archive("plantation.zip", "plantation.shp", "plantation.dbf", "plantation.shx", "plantation.prj", "varieties_transcode.csv", in: "unicoque/plantation")
  if file.exist?
    first_run.import(:unicoque_plant_zones, file)
  end

end
