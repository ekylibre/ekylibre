# -*- coding: utf-8 -*-
load_data :land_parcels do |loader|

  path = loader.path("ilot_017005218.shp")
  if path.exist?
    loader.count :telepac_shape_file_import do |w|
      #############################################################################
      # Import shapefile


      land_parcel_group_variant = ProductNatureVariant.import_from_nomenclature(:land_parcel_cluster)

      RGeo::Shapefile::Reader.open(path.to_s, :srid => 2154) do |file|
        # puts "File contains #{file.num_records} records."
        file.each do |record|
          born_at = Time.new(record.attributes['CAMPAGNE'], 1, 1)
          land_parcel_cluster = LandParcelCluster.create!(:variant_id => land_parcel_group_variant.id,
                                                          :name => LandParcel.model_name.human(locale: Preference[:language]) + " " + record.attributes['NUMERO'].to_s,
                                                          :work_number => record.attributes['NUMERO'].to_s,
                                                          :variety => "land_parcel_cluster",
                                                          :born_at => born_at,
                                                          :initial_owner => Entity.of_company,
                                                          :identification_number => record.attributes['PACAGE'].to_s + record.attributes['CAMPAGNE'].to_s + record.attributes['NUMERO'].to_s)
          land_parcel_cluster.is_measured!(:shape, record.geometry, at: born_at)
          ind_area = land_parcel_cluster.shape_area
          land_parcel_cluster.is_measured!(:population, ind_area.in_hectare, at: born_at)

          # puts "Record number #{record.index}:"
          # puts "  Geometry: #{record.geometry.as_text}"
          # puts "  Attributes: #{record.attributes.inspect}"
          w.check_point
        end
      end
    end

  end

  path = loader.path("land_parcel_017005218.csv")
  if path.exist?
    loader.count :land_parcel_import do |w|
      # Import land_parcel from Calc Sheet

      land_parcel_nature_variant = ProductNatureVariant.import_from_nomenclature(:land_parcel)

      # Load file
      CSV.foreach(path, :encoding => "UTF-8", :col_sep => ",", :headers => true, :quote_char => "'") do |row|
        r = OpenStruct.new(:ilot_work_number => row[0],
                           :campaign => row[1],
                           :land_parcel_work_number => row[2],
                           :land_parcel_name => row[3].capitalize,
                           :land_parcel_area => row[4].blank? ? nil : row[4].to_d,
                           :land_parcel_shape => row[5],
                           :land_parcel_variant_nomen => row[6].blank? ? nil : row[6].to_sym,
                           :land_parcel_available_water_capacity => row[7].blank? ? nil : row[7].to_d,
                           born_at: Time.new(1995, 1, 1, 10, 0, 0, "+00:00")
                           )

        if land_parcel_cluster = LandParcelCluster.find_by_work_number(r.ilot_work_number)

          land_parcel_variant = ProductNatureVariant.import_from_nomenclature(r.land_parcel_variant_nomen)
          land_parcel_variant ||= land_parcel_nature_variant
          land_parcel = LandParcel.find_by_work_number(r.land_parcel_work_number)
          land_parcel ||= LandParcel.create!(:variant => land_parcel_variant,
                                             :name => r.land_parcel_name,
                                             born_at: r.born_at,
                                             :work_number => r.land_parcel_work_number,
                                             :initial_owner => Entity.of_company,
                                             :identification_number => r.land_parcel_work_number)
          # add shape and population indicator
          if r.land_parcel_shape
            land_parcel.is_measured!(:shape, r.land_parcel_shape, at: r.born_at)
            ind_area = land_parcel.shape_area
            land_parcel.is_measured!(:population, (ind_area / 10000).round(3), at: r.born_at)
          elsif r.land_parcel_area
            land_parcel.is_measured!(:population, r.land_parcel_area, at: r.born_at)
          end

          # add available_water_capacity indicator
          if r.land_parcel_available_water_capacity
            land_parcel.is_measured!(:available_water_capacity_per_area, r.land_parcel_available_water_capacity.in_liter_per_square_meter, at: r.born_at)
          end

          # add land_parcel in land_parcel_cluster group
          land_parcel_cluster.add(land_parcel)

        end

        w.check_point
      end
    end
  end



  path = loader.path("cultivable_zone_land_parcel.csv")
  if path.exist?
    loader.count :cultivable_zone_import do |w|
      # Import land_parcel from Calc Sheet

      cultivable_zone_variant = ProductNatureVariant.import_from_nomenclature(:cultivable_zone)

      # Load file
      CSV.foreach(path, :encoding => "UTF-8", :col_sep => ",", :headers => true, :quote_char => "'") do |row|
        r = OpenStruct.new(:cultivable_zone_work_number => row[0],
                           :cultivable_zone_name => row[1],
                           :cultivable_zone_area => row[2].blank? ? nil : row[2].to_d,
                           :land_parcel_work_number => row[3],
                           :land_parcel_name => row[4].capitalize,
                           :land_parcel_member_area => row[5].blank? ? nil : row[5].to_d,
                           :cultivable_zone_shape => row[6].blank? ? nil : row[6],
                           :land_parcel_member_shape => row[7].blank? ? nil : row[7],
                           born_at: Time.new(1995, 1, 1, 10, 0, 0, "+00:00")
                           )

        cultivable_zone = CultivableZone.find_by_work_number(r.zone_cultural_work_number)
        cultivable_zone ||= CultivableZone.create!(:variant_id => cultivable_zone_variant.id,
                                                   :name => r.cultivable_zone_name,
                                                   :work_number => r.cultivable_zone_work_number,
                                                   born_at: r.born_at,
                                                   :variety => "cultivable_zone",
                                                   :initial_owner => Entity.of_company,
                                                   :identification_number => r.cultivable_zone_work_number)

        if r.cultivable_zone_shape
          cultivable_zone.is_measured!(:shape, r.cultivable_zone_shape, at: r.born_at)
          ind_area = cultivable_zone.shape_area
          area = (ind_area / 10000).round(2)
          cultivable_zone.is_measured!(:population, area, at: r.born_at)
        elsif r.cultivable_zone_area
          cultivable_zone.is_measured!(:population, r.cultivable_zone_area, at: r.born_at)
        end


        if land_parcel = LandParcel.find_by_work_number(r.land_parcel_work_number) || nil
          cultivable_zone_membership = CultivableZoneMembership.where(group: cultivable_zone, member: land_parcel).first
          cultivable_zone_membership ||= CultivableZoneMembership.create!(:group => cultivable_zone,
                                                                          :member => land_parcel,
                                                                          :shape => r.land_parcel_member_shape,
                                                                          :population => r.land_parcel_member_area
                                                                          )
        end

        w.check_point
      end
    end
  end

end
