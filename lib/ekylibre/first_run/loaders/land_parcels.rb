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



  # load transcoding files

  varieties_transcode = {}.with_indifferent_access

  certifications_transcode = {}.with_indifferent_access

  cultivable_zones_transcode = {}.with_indifferent_access

  # For Viniteca sofware

  path = first_run.path("viniteca", "varieties_transcode.csv")
  if path.exist?
    CSV.foreach(path, headers: true) do |row|
      varieties_transcode[row[0]] = row[1].to_sym
    end
  end

  path = first_run.path("viniteca", "certifications_transcode.csv")
  if path.exist?
    CSV.foreach(path, headers: true) do |row|
      certifications_transcode[row[0]] = row[1].to_sym
    end
  end

  path = first_run.path("viniteca", "cultivable_zones_transcode.csv")
  if path.exist?
    CSV.foreach(path, headers: true) do |row|
      cultivable_zones_transcode[row[0]] = row[1].to_s
    end
  end

  # load data files from Viniteca software

  path = first_run.path("viniteca", "plant.shp")
  if path.exist?
    first_run.count :plant_shapes do |w|
      #############################################################################
      # File structuration
      # INFO Take care of 10 characters truncature because of RGEO
      # -- field_name
      # N_PARCELLE (work_number of plant)
      # CEPAGE (variety of plant) to transcode with nomenclature
      # COULEUR_PAR (color of the vine variety) to transcode
      # SURFACE_REE (population of plant)
      # DATE_CREATI (born_at of plant)
      # CODE_AOC (certification of plant)
      born_at = Time.new(1980, 1, 1, 10, 0, 0, "+00:00")

      RGeo::Shapefile::Reader.open(path.to_s, :srid => 4326) do |shape_file|
        # puts "File contains #{file.num_records} records."
        shape_file.each do |record|

          # puts "  Attributes: #{record.attributes.inspect}"
          # build variable for transcode
          record_variety = record.attributes['CEPAGE'].to_s.downcase + ' ' + record.attributes['COULEUR_PA'].to_s.downcase
          # find or import variant
          # puts record_variety
          # puts varieties_transcode[record_variety]
          if variety = varieties_transcode[record_variety]
            #vine_crop_variant = ProductNatureVariant.find_or_import!(variety)
          #else
            vine_crop_variant = ProductNatureVariant.find_or_import!(:vitis_vinifera)
          end

          initial_born_at = (record.attributes['DATE_CREAT'].blank? ? born_at : record.attributes['DATE_CREAT'].to_datetime)

          zc_work_number = cultivable_zones_transcode[record.attributes['NOM_PIECE']]
          # create plant
          plant = Plant.create!(:variant_id => vine_crop_variant.first.id,
                  :name =>  record.attributes['CEPAGE'].to_s + " (" + record.attributes['PORTE_GREF'].to_s + ") - [" + record.attributes['N_PARCELLE'].to_s + "_" + record.attributes['NOM_PIECE'].to_s + "]",
                  :work_number => "PLANT_" + record.attributes['N_PARCELLE'].to_s + "_" + record.attributes['NOM_PIECE'].to_s,
                  :variety => variety,
                  :initial_born_at => initial_born_at,
                  :initial_owner => Entity.of_company,
                  :default_storage => CultivableZone.find_by_work_number(zc_work_number) || CultivableZone.first,
                  :identification_number => record.attributes['N_PARCELLE'].to_s )

          # shape and population
          plant.read!(:shape, record.geometry, at: initial_born_at)
          plant.read!(:population, record.attributes['SURFACE_RE'].to_d, at: initial_born_at) if record.attributes['SURFACE_RE']

          # vine indicators
          # plant_life_state, woodstock_variety, certification, plants_count, rows_interval, plants_interval
          #puts varieties_transcode[record.attributes['PORTE_GREF'].to_s.downcase!]
          if !record.attributes['CODE_AOC'].blank?
            code_aoc = record.attributes['CODE_AOC'].to_s.downcase
            plant.read!(:certification, certifications_transcode[code_aoc], at: initial_born_at) if code_aoc
          end
          #puts varieties_transcode[record.attributes['PORTE_GREF'].to_s.downcase!]
          if !record.attributes['PORTE_GREF'].blank?
            porte_greffe = record.attributes['PORTE_GREF'].to_s.downcase
            plant.read!(:woodstock_variety, varieties_transcode[porte_greffe], at: initial_born_at) if porte_greffe
          end
          #puts record.attributes['ECARTEMENT'].inspect
          if record.attributes['ECARTEMENT']
            plant.read!(:rows_interval, record.attributes['ECARTEMENT'].to_d.in_meter, at: initial_born_at)
          end
          #puts record.attributes['ECARTEMEN0'].inspect
          if record.attributes['ECARTEMEN0']
            plant.read!(:plants_interval, record.attributes['ECARTEMEN0'].to_d.in_meter, at: initial_born_at)
          end

          w.check_point
        end
      end
    end
  end

  # For Unicoque data

  path = first_run.path("unicoque", "varieties_transcode.csv")
  if path.exist?
    CSV.foreach(path, headers: true) do |row|
      varieties_transcode[row[0]] = row[1].to_sym
    end
  end

   # orchard shape


  path = first_run.path("unicoque", "plantation", "plantation.shp")
  if path.exist?
    first_run.count :cultivable_zones_shapes do |w|
      #############################################################################
      RGeo::Shapefile::Reader.open(path.to_s, :srid => 2154) do |file|
        # puts "File contains #{file.num_records} records."
        file.each do |record|
          if record.geometry
            shapes[record.attributes['BLOC']] = Charta::Geometry.new(record.geometry).transform(:WGS84).to_rgeo
          end
          w.check_point
        end
      end
    end
  end

  # orchard inventory

  path = first_run.path("unicoque", "inventaire_verger.csv")
  if path.exist?
    first_run.count :unicoque_orchard do |w|
      CSV.foreach(path, headers: true, col_sep: ";") do |row|
        next if row[0].blank?
        r = OpenStruct.new(name: row[34].to_s + " - [" + row[19].to_s.capitalize! + "]",
                           bloc: row[32].to_s,
                           # cultivable_zone_code: (row[3].blank? ? nil : row[3].to_s),
                           rows_interval: (row[9].blank? ? nil : row[9].gsub(",",".").to_d),
                           plants_interval: (row[10].blank? ? nil : row[10].gsub(",",".").to_d),
                           plants_population: (row[11].blank? ? nil : row[11].to_d),
                           surface_area: (row[12].blank? ? nil : row[12].gsub(",",".").to_d),
                           measured_at: (row[1].blank? ? nil : (row[1].to_s + "-01-01 00:00").to_datetime),
                           born_at: (row[13].blank? ? nil : (row[13].to_s + "-01-01 00:00").to_datetime),
                           variety: (row[7].blank? ? nil : varieties_transcode[row[7].to_s]),
                           reference_variant: (row[35].to_s == '21' ? :hazel_crop : :walnut_crop )
                           )
        # find or import from variant reference_nameclature the correct ProductNatureVariant
        variant = ProductNatureVariant.find_or_import!(r.variety).first || ProductNatureVariant.import_from_nomenclature(r.reference_variant)
        pmodel = variant.nature.matching_model

        # create the plant
        plant = pmodel.create!(:variant_id => variant.id, :work_number => "PLANT_" + r.bloc,
                                 :name => r.name, :initial_born_at => r.born_at, :initial_owner => Entity.of_company, :variety => r.variety#, :initial_container => container
                                 )

        # create indicators linked to plant
        if geometry = shapes[r.bloc]
          plant.read!(:shape, geometry, at: r.born_at, force: true)
        end
        plant.read!(:population, r.surface_area, at: r.measured_at) if r.surface_area
        plant.read!(:rows_interval, r.rows_interval.in_meter, at: r.measured_at) if r.rows_interval
        plant.read!(:plants_interval, r.plants_interval.in_meter, at: r.measured_at) if r.plants_interval
        # build density
        plant.read!(:plants_count, (r.plants_population / r.surface_area).to_i, at: r.measured_at) if (r.plants_population and r.surface_area)

        if plant.shape
          plant_shape = Charta::Geometry.new(plant.shape)
          if product_around = plant_shape.actors_matching(nature: CultivableZone).first
            plant.initial_container = product_around
            plant.save!
          end
        end

        w.check_point
      end
    end

  end

end
