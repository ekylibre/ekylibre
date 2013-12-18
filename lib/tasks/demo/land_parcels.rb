# -*- coding: utf-8 -*-
demo :land_parcels do

  Ekylibre::fixturize :telepac_shape_file_import do |w|
    #############################################################################
    # Import shapefile


    land_parcel_group_variant = ProductNatureVariant.import_from_nomenclature(:land_parcel_cluster)

    RGeo::Shapefile::Reader.open(Rails.root.join("test", "fixtures", "files", "ilot_017005218.shp").to_s, :srid => 2154) do |file|
      # puts "File contains #{file.num_records} records."
      file.each do |record|
        land_parcel_cluster = LandParcelCluster.create!(:variant_id => land_parcel_group_variant.id,
                                                        :name => LandParcel.model_name.human(locale: Preference[:language]) + " " + record.attributes['NUMERO'].to_s,
                                                        :work_number => record.attributes['NUMERO'].to_s,
                                                        :variety => "land_parcel_cluster",
                                                        :born_at => Date.civil(record.attributes['CAMPAGNE'], 1, 1),
                                                        :initial_owner => Entity.of_company,
                                                        :identification_number => record.attributes['PACAGE'].to_s + record.attributes['CAMPAGNE'].to_s + record.attributes['NUMERO'].to_s)
        land_parcel_cluster.is_measured!(:shape, record.geometry, :at => Date.civil(record.attributes['CAMPAGNE'], 1, 1))
        ind_area = land_parcel_cluster.shape_area
        land_parcel_cluster.is_measured!(:population, ind_area.in_square_meter.convert(:hectare), :at => Date.civil(record.attributes['CAMPAGNE'], 1, 1))


        # puts "Record number #{record.index}:"
        # puts "  Geometry: #{record.geometry.as_text}"
        # puts "  Attributes: #{record.attributes.inspect}"
        w.check_point
      end
    end


  end

  Ekylibre::fixturize :land_parcel_import do |w|
    # Import land_parcel from Calc Sheet

    land_parcel_nature_variant = ProductNatureVariant.import_from_nomenclature(:land_parcel)

    # Load file
    file = Rails.root.join("test", "fixtures", "files", "land_parcel_017005218.csv")
    CSV.foreach(file, :encoding => "UTF-8", :col_sep => ",", :headers => true, :quote_char => "'") do |row|
      r = OpenStruct.new(:ilot_work_number => row[0],
                         :campaign => row[1],
                         :land_parcel_work_number => row[2],
                         :land_parcel_name => row[3].capitalize,
                         :land_parcel_area => row[4].blank? ? nil : row[4].to_d,
                         :land_parcel_shape => row[5],
                         :land_parcel_variant_nomen => row[6].blank? ? nil : row[6].to_sym,
                         :land_parcel_available_water_capacity => row[7].blank? ? nil : row[7].to_d
                         )

      if land_parcel_cluster = LandParcelCluster.find_by_work_number(r.ilot_work_number)

        land_parcel_variant = ProductNatureVariant.import_from_nomenclature(r.land_parcel_variant_nomen)
        land_parcel_variant ||= land_parcel_nature_variant
        land_parcel = LandParcel.find_by_work_number(r.land_parcel_work_number)
        land_parcel ||= LandParcel.create!(:variant => land_parcel_variant,
                                           :name => r.land_parcel_name,
                                           :born_at => Time.now,
                                           :work_number => r.land_parcel_work_number,
                                           :initial_owner => Entity.of_company,
                                           :identification_number => r.land_parcel_work_number)
        # add shape and population indicator
        if r.land_parcel_shape
          land_parcel.is_measured!(:shape, r.land_parcel_shape, :at => Time.now)
          ind_area = land_parcel.shape_area
          land_parcel.is_measured!(:population, (ind_area / 10000).round(3), :at => Time.now)
        elsif r.land_parcel_area
          land_parcel.is_measured!(:population, r.land_parcel_area, :at => Time.now)
        end

        # add available_water_capacity indicator
        if r.land_parcel_available_water_capacity
          land_parcel.is_measured!(:available_water_capacity, r.land_parcel_available_water_capacity.in_liter_per_square_meter, :at => Time.now)
        end

        # add land_parcel in land_parcel_cluster group
        land_parcel_cluster.add(land_parcel)

      end

      # puts "Record number #{record.index}:"
      # puts "  Geometry: #{record.geometry.as_text}"
      # puts "  Attributes: #{record.attributes.inspect}"
      w.check_point
      #break if LandParcelGroup.count >= max
    end
  end

  Ekylibre::fixturize :cultivable_zone_import do |w|
    # Import land_parcel from Calc Sheet

   cultivable_zone_variant = ProductNatureVariant.import_from_nomenclature(:cultivable_zone)

    # Load file
    file = Rails.root.join("test", "fixtures", "files", "cultivable_zone_land_parcel.csv")
    CSV.foreach(file, :encoding => "UTF-8", :col_sep => ",", :headers => true, :quote_char => "'") do |row|
      r = OpenStruct.new(:cultivable_zone_work_number => row[0],
                         :cultivable_zone_name => row[1],
                         :cultivable_zone_area => row[2].blank? ? nil : row[2].to_d,
                         :land_parcel_work_number => row[3],
                         :land_parcel_name => row[4].capitalize,
                         :land_parcel_member_area => row[5].blank? ? nil : row[5].to_d,
                         :cultivable_zone_shape => row[6].blank? ? nil : row[6],
                         :land_parcel_member_shape => row[7].blank? ? nil : row[7]
                         )

        cultivable_zone = CultivableZone.find_by_work_number(r.zone_cultural_work_number)
        cultivable_zone ||= CultivableZone.create!(:variant_id => cultivable_zone_variant.id,
                                                              :name => r.cultivable_zone_name,
                                                              :work_number => r.cultivable_zone_work_number,
                                                              :born_at => Time.now,
                                                              :variety => "cultivable_zone",
                                                              :initial_owner => Entity.of_company,
                                                              :identification_number => r.cultivable_zone_work_number)

      if r.cultivable_zone_shape
        cultivable_zone.is_measured!(:shape, r.cultivable_zone_shape, :at => Time.now)
        ind_area = cultivable_zone.shape_area
        area = (ind_area / 10000).round(2)
        cultivable_zone.is_measured!(:population, area, :at => Time.now)
      elsif r.cultivable_zone_area
        cultivable_zone.is_measured!(:population, r.cultivable_zone_area, :at => Time.now)
      end


      land_parcel = LandParcel.find_by_work_number(r.land_parcel_work_number) || nil

      if land_parcel
        cultivable_zone_membership = CultivableZoneMembership.where(group: cultivable_zone, member: land_parcel).first
        cultivable_zone_membership ||= CultivableZoneMembership.create!(:group => cultivable_zone,
                                                                        :member => land_parcel,
                                                                        :shape => r.land_parcel_member_shape,
                                                                        :population => r.land_parcel_member_area
                                                                        )
      end

      # puts "  Attributes: #{record.attributes.inspect}"
      w.check_point
      #break if LandParcelGroup.count >= max
    end
  end

end
