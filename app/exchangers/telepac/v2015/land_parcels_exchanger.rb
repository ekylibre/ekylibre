module Telepac
  module V2015
    class LandParcelsExchanger < ActiveExchanger::Base
      def check
        # Unzip file
        dir = w.tmp_dir
        Zip::File.open(file) do |zile|
          zile.each do |entry|
            entry.extract(dir.join(entry.name))
          end
        end

        valid = true
        RGeo::Shapefile::Reader.open(dir.join('parcelle.shp').to_s, srid: 2154) do |file|
          # Set number of shapes
          w.count = file.size

          file.each do |record|
            # check cap_statement presence for the consider year
            harvest_year = record.attributes['CAMPAGNE'].to_s
            campaign = Campaign.of(harvest_year.to_i)
            w.info 'Campaign exist' if campaign

            pacage_number = record.attributes['PACAGE'].to_s

            ## find or create cap statement
            unless (cap_statement = CapStatement.find_by(campaign: campaign, pacage_number: pacage_number))
              w.info 'Cap statement will be created'
            end

            islet_number = record.attributes['NUMERO'].to_s
            # Find an existing islet or stop importing
            unless CapIslet.find_by(cap_statement: cap_statement, islet_number: islet_number)
              w.error "No way to find pacage #{pacage_number} - islet number #{islet_number}. You have to import islets first"
              valid = false
            end
          end
        end

        valid
      end

      def import
        # Unzip file
        dir = w.tmp_dir
        Zip::File.open(file) do |zile|
          zile.each do |entry|
            entry.extract(dir.join(entry.name))
          end
        end

        #############################################################################
        # Import landparcel_shapefile from TELEPAC From 2015
        # -- field_name
        # PACAGE
        # NUMERO_SI (land_parcel number)
        # NUMERO (land_parcel_cluster number id)
        # CAMPAGNE (campaign)
        # DPT_NUM (department zone number)
        # SURF_TOT (land_parcel_cluster area)
        # COMMUNE
        # TYPE (cf https://www3.telepac.agriculture.gouv.fr/telepac/pdf/tas/2015/Dossier-PAC-2015_notice_cultures-precisions.pdf)
        # CODE_VAR
        # NUMERO_PA
        # PROD_SEM
        # COMMERC
        # DEROB1
        # DEROB2
        # INTERRANG1
        # INTERRANG2
        # INTERRANG3
        # AGRIBIO
        # AIDEBIO
        # MARAICH
        # MAEC1_CODE
        # MAEC1CIBLE
        # MAEC2_CODE
        # MAEC2CIBLE
        # MAEC3_CODE
        # MAEC3CIBLE
        # AGROFOREST

        RGeo::Shapefile::Reader.open(dir.join('parcelle.shp').to_s, srid: 2154) do |file|
          # Set number of shapes
          w.count = file.num_records

          file.each do |record|
            # if record.index == 0
            # check cap_statement presence for the consider year
            harvest_year = record.attributes['CAMPAGNE'].to_s
            campaign = Campaign.of(harvest_year.to_i)

            pacage_number = record.attributes['PACAGE'].to_s

            cap_statement_attributes = {
              campaign: campaign,
              entity: Entity.of_company,
              exploitation_name: Entity.of_company.full_name,
              pacage_number: pacage_number,
              siret_number: Entity.of_company.siret_number
            }

            ## find or create cap statement
            unless (cap_statement = CapStatement.find_by(campaign: campaign, pacage_number: pacage_number))
              cap_statement = CapStatement.create!(cap_statement_attributes)
            end
            # end

            islet_number = record.attributes['NUMERO'].to_s

            # Find an existing islet or stop importing
            unless (cap_islet = CapIslet.find_by(cap_statement: cap_statement, islet_number: islet_number))
              w.error 'Import Islets first'
            end

            cap_land_parcel_attributes = {
              cap_islet: cap_islet,
              land_parcel_number: record.attributes['NUMERO_SI'].to_s,
              main_crop_code: record.attributes['TYPE'].to_s,
              main_crop_commercialisation: (record.attributes['COMMERC'].to_s == '1'),
              main_crop_precision: record.attributes['CODE_VAR'].to_s,
              main_crop_seed_production: (record.attributes['PROD_SEM'].to_s == '1'),
              shape: ::Charta.new_geometry(record.geometry).transform(:WGS84).to_rgeo
            }

            # Find or create a cap land parcel
            unless (cap_land_parcel = CapLandParcel.find_by(cap_land_parcel_attributes.slice(:land_parcel_number, :cap_islet)))
              cap_land_parcel = CapLandParcel.create!(cap_land_parcel_attributes)
            end

            # import into georeadings
            label = 'P' + '-' + cap_land_parcel.islet.cap_statement.pacage_number.to_s + '-' + cap_land_parcel.cap_islet.cap_statement.campaign.harvest_year.to_s + '-' + cap_land_parcel.islet_number.to_s + '-' + cap_land_parcel.land_parcel_number.to_s
            georeadings_attributes = {
              name: label,
              number: label,
              nature: :polygon,
              content: cap_land_parcel.shape
            }
            unless Georeading.find_by(georeadings_attributes.slice(:number))
              Georeading.create!(georeadings_attributes)
            end

            # Create activities if option true
            # if Preference.value(:create_activities_from_telepac, true)

            # TODO

            # end

            w.check_point
          end
        end

        true
      end
    end
  end
end
