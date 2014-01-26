# -*- coding: utf-8 -*-
load_data :land_parcels do |loader|

  path = loader.path("ilot.shp")
  if path.exist?
    loader.count :telepac_shape_file_import do |w|
      #############################################################################
      # Import shapefile


      land_parcel_group_variant = ProductNatureVariant.import_from_nomenclature(:land_parcel_cluster)

      RGeo::Shapefile::Reader.open(path.to_s, :srid => 2154) do |file|
        # puts "File contains #{file.num_records} records."
        file.each do |record|
          born_at = Time.new(1, 1, 2)
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

  path = loader.path("parcelle.shp")
  if path.exist?
    loader.count :telepac_landparcel_shape_file_import do |w|
      #############################################################################
      # Import landparcel_shapefile from TELEPAC
      # -- field_name
      # PACAGE
      # NUMERO_SI (land_parcel number)
      # NUMERO (land_parcel_cluster number id)
      # CAMPAGNE (campaign)
      # DPT_NUM (department zone number)
      # SURF_TOT (land_parcel_cluster area)
      # COMMUNE
      # TYPE (cf http://www.maine-et-loire.gouv.fr/IMG/pdf/Dossier-PAC-2013_notice_cultures-varietes.pdf)
      # CODE_VAR
      # SURF_DECL (land_parcel area)
      # TYPE_PARC
      # AGRI_BIO
      # ANNEE_ENGM

      land_parcel_variant = ProductNatureVariant.import_from_nomenclature(:clay_limestone_land_parcel)
      cultivable_zone_variant = ProductNatureVariant.import_from_nomenclature(:cultivable_zone)

      RGeo::Shapefile::Reader.open(path.to_s, :srid => 2154) do |file|
        # puts "File contains #{file.num_records} records."
        file.each do |record|
          born_at = Time.new(1, 1, 2)

          # create a land parcel for each entries
          #
          land_parcel = LandParcel.create!(:variant_id => land_parcel_variant.id,
                                                          :name => LandParcel.model_name.human(locale: Preference[:language]) + " " + record.attributes['NUMERO'].to_s + "-" + record.attributes['NUMERO_SI'].to_s,
                                                          :work_number => "P" + record.attributes['NUMERO'].to_s + "-" + record.attributes['NUMERO_SI'].to_s,
                                                          :variety => "clay_limestone_soil",
                                                          :born_at => born_at,
                                                          :initial_owner => Entity.of_company,
                                                          :identification_number => record.attributes['PACAGE'].to_s + record.attributes['CAMPAGNE'].to_s + record.attributes['NUMERO'].to_s + record.attributes['NUMERO_SI'].to_s)

          land_parcel.is_measured!(:shape, record.geometry, at: born_at)
          ind_area = land_parcel.shape_area
          land_parcel.is_measured!(:population, ind_area.in_hectare, at: born_at)

          # create a cultivable zone for each entries
          #
          cultivable_zone = CultivableZone.create!(:variant_id => cultivable_zone_variant.id,
                                                          :name => CultivableZone.model_name.human(locale: Preference[:language]) + " " + record.attributes['NUMERO'].to_s,
                                                          :work_number => "ZC" + record.attributes['NUMERO'].to_s + "-" + record.attributes['NUMERO_SI'].to_s,
                                                          :variety => "cultivable_zone",
                                                          :born_at => born_at,
                                                          :initial_owner => Entity.of_company,
                                                          :identification_number => record.attributes['PACAGE'].to_s + record.attributes['CAMPAGNE'].to_s + record.attributes['NUMERO'].to_s + record.attributes['NUMERO_SI'].to_s)

          cultivable_zone.is_measured!(:shape, record.geometry, at: born_at)
          ind_area = cultivable_zone.shape_area
          cultivable_zone.is_measured!(:population, ind_area.in_hectare, at: born_at)

          # link a land parcel to a land parcel cluster
          land_parcel_cluster = LandParcelCluster.find_by_work_number(record.attributes['NUMERO'].to_s)
          land_parcel_cluster.add(land_parcel) if land_parcel_cluster

          # link cultivable zone and land parcel for each entries
          #
          cultivable_zone_membership = CultivableZoneMembership.where(group: cultivable_zone, member: land_parcel).first
          cultivable_zone_membership ||= CultivableZoneMembership.create!(:group => cultivable_zone,
                                                                          :member => land_parcel,
                                                                          :shape => record.geometry,
                                                                          :population => record.attributes['SURF_DECL'].to_d
                                                                          )

          # create a campaign if not exist
          campaign = Campaign.find_by(harvest_year: record.attributes['CAMPAGNE'].to_i)
          campaign ||= Campaign.create!(harvest_year: record.attributes['CAMPAGNE'].to_i, closed: false)

          # create an activity if not exist
          item = Nomen::ProductionNatures.where(telepac_crop_code: record.attributes['TYPE'].to_s).first
          activity_family_item = Nomen::ActivityFamilies[item.activity] if item
          activity   = Activity.find_by(family: activity_family_item.name)
          activity ||= Activity.create!(:nature => :main, :family => activity_family_item.name, :name => item.human_name)

          # create a production if not exist
          product_nature_variant_sup = ProductNatureVariant.import_from_nomenclature(item.variant_support.to_s)
          product_support = cultivable_zone || nil
          if product_nature_variant_sup and !product_support.nil?
            # find a production corresponding to campaign , activity and product_nature
            pro = Production.where(:campaign_id => campaign.id, :activity_id => activity.id, :variant_id => product_nature_variant_sup.id).first
            # or create it
            pro ||= activity.productions.create!(:variant_id => product_nature_variant_sup.id, :campaign_id => campaign.id, :static_support => true)
            # create a support for this production
            support = pro.supports.create!(:storage_id => product_support.id)
          elsif !product_nature_variant_sup.nil?
            pro = Production.where(:variant_id => product_nature_variant_sup.id, :campaign_id => campaign.id, :activity_id => activity.id).first
            pro ||= activity.productions.create!(:variant_id => product_nature_variant_sup.id, :campaign_id => campaign.id)
          end

          w.check_point
        end
      end
    end

  end

  path = loader.path("land_parcel.csv")
  if path.exist?
    loader.count :land_parcel_import do |w|
      # Import land_parcel from Calc Sheet

      land_parcel_nature_variant = ProductNatureVariant.import_from_nomenclature(:clay_limestone_land_parcel)

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
