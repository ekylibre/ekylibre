# -*- coding: utf-8 -*-
demo :land_parcels do

  Ekylibre::fixturize :telepac_shape_file_import do |w|
    #############################################################################
    # Import shapefile


    land_parcel_group_variant = ProductNature.import_from_nomenclature(:land_parcel_cluster).default_variant

    RGeo::Shapefile::Reader.open(Rails.root.join("test", "fixtures", "files", "ilot_017005218.shp").to_s, :srid => 2154) do |file|
      # puts "File contains #{file.num_records} records."
      file.each do |record|
        land_parcel_cluster = LandParcelCluster.create!(:variant_id => land_parcel_group_variant.id,
                                                        :name => "ilôt "+record.attributes['NUMERO'].to_s,
                                                        :work_number => record.attributes['NUMERO'].to_s,
                                                        :variety => "land_parcel_cluster",
                                                        :born_at => Date.civil(record.attributes['CAMPAGNE'], 1, 1),
                                                        :owner_id => Entity.of_company.id,
                                                        :identification_number => record.attributes['PACAGE'].to_s + record.attributes['CAMPAGNE'].to_s + record.attributes['NUMERO'].to_s)
        land_parcel_cluster.is_measured!(:shape, record.geometry, :at => Date.civil(record.attributes['CAMPAGNE'], 1, 1))
        ind_area = land_parcel_cluster.shape_area
        land_parcel_cluster.is_measured!(:net_surface_area, ind_area.in_square_meter.convert(:hectare), :at => Date.civil(record.attributes['CAMPAGNE'], 1, 1))
        # puts "Record number #{record.index}:"
        # puts "  Geometry: #{record.geometry.as_text}"
        # puts "  Attributes: #{record.attributes.inspect}"
        w.check_point
      end
    end


  end

  Ekylibre::fixturize :calc_sheet_file_import do |w|
    # Import land_parcel from Calc Sheet

    land_parcel_group_nature_variant = ProductNature.import_from_nomenclature(:cultivable_land_parcel).default_variant
    land_parcel_nature_variant = ProductNature.import_from_nomenclature(:land_parcel).default_variant

    # Load file
    file = Rails.root.join("test", "fixtures", "files", "land_parcel_017005218.csv")
    CSV.foreach(file, :encoding => "UTF-8", :col_sep => ",", :headers => true, :quote_char => "'") do |row|
      r = OpenStruct.new(:ilot_work_number => row[0],
                         :campaign => row[1],
                         :land_parcel_group_work_number => row[2],
                         :land_parcel_group_name => row[3].capitalize,
                         :land_parcel_work_number => row[4],
                         :land_parcel_name => row[5].capitalize,
                         :land_parcel_area => row[6].to_d,
                         :land_parcel_group_shape => row[7],
                         :land_parcel_shape => row[8],
                         :land_parcel_plant_name => row[9],
                         :land_parcel_plant_variety => row[10]
                         )

      if land_parcel_cluster = LandParcelCluster.find_by_work_number(r.ilot_work_number)
        cultural_land_parcel = CultivableLandParcel.find_by_work_number(r.land_parcel_group_work_number)
        cultural_land_parcel ||= CultivableLandParcel.create!(:variant_id => land_parcel_group_nature_variant.id,
                                                              :name => r.land_parcel_group_name,
                                                              :work_number => r.land_parcel_group_work_number,
                                                              :variety => "cultivable_land_parcel",
                                                              :born_at => Time.now,
                                                              :owner_id => Entity.of_company.id,
                                                              :identification_number => r.land_parcel_group_work_number)
        if r.land_parcel_group_shape
          cultural_land_parcel.is_measured!(:shape, r.land_parcel_group_shape, :at => Time.now)
          ind_area = cultural_land_parcel.shape_area
          cultural_land_parcel.is_measured!(:net_surface_area, ind_area.in_square_meter.convert(:hectare), :at => Time.now)
        end

        land_parcel = LandParcel.find_by_work_number(r.land_parcel_work_number)
        land_parcel ||= LandParcel.create!(:variant_id => land_parcel_nature_variant.id,
                                           :name => r.land_parcel_name,
                                           :work_number => r.land_parcel_work_number,
                                           :variety => "land_parcel",
                                           :born_at => Time.now,
                                           :owner_id => Entity.of_company.id,
                                           :identification_number => r.land_parcel_work_number)
        if r.land_parcel_shape
          land_parcel.is_measured!(:shape, r.land_parcel_shape, :at => Time.now)
          ind_area = land_parcel.shape_area
          land_parcel.is_measured!(:net_surface_area, ind_area.in_square_meter.convert(:hectare), :at => Time.now)
        end

        land_parcel_cluster.add(land_parcel)
        cultural_land_parcel.add(land_parcel)

      end

      # puts "Record number #{record.index}:"
      # puts "  Geometry: #{record.geometry.as_text}"
      # puts "  Attributes: #{record.attributes.inspect}"
      w.check_point
      #break if LandParcelGroup.count >= max
    end
  end

end
