module Telepac
  module V2014
    class LandParcelsExchanger < ActiveExchanger::Base
      self.deprecated = true

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
            campaign = Campaign.of(harvest_year)
            w.info 'Campaign exist' if campaign

            pacage_number = record.attributes['PACAGE'].to_s

            cap_statement_attributes = {
              campaign: campaign,
              declarant: Entity.of_company,
              farm_name: Entity.of_company.full_name,
              pacage_number: pacage_number,
              siret_number: Entity.of_company.siret_number
            }

            ## find or create cap statement
            unless (cap_statement = CapStatement.find_by(campaign: campaign, pacage_number: pacage_number))
              w.info 'Cap statement will be created'
            end

            islet_number = record.attributes['NUMERO'].to_s
            # Find an existing islet or stop importing
            unless (cap_islet = CapIslet.find_by(cap_statement: cap_statement, islet_number: islet_number))
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
        # Import landparcel_shapefile from TELEPAC
        # -- field_name
        # PACAGE
        # NUMERO_SI (land_parcel number)
        # NUMERO (land_parcel_cluster number id)
        # CAMPAGNE (campaign)
        # DPT_NUM (department zone number)
        # SURF_TOT (land_parcel_cluster area)
        # COMMUNE
        # TYPE (cf http://www.maine-et-loire.gouv.fr/IMG/pdf/Dossier-PAC-2013_notice_cultures-varietes.pdf)
        # CODE_VAR
        # SURF_DECL (land_parcel area)
        # TYPE_PARC
        # AGRI_BIO
        # ANNEE_ENGM

        RGeo::Shapefile::Reader.open(dir.join('parcelle.shp').to_s, srid: 2154) do |file|
          # Set number of shapes
          w.count = file.num_records

          file.each do |record|
            # check cap_statement presence for the consider year
            harvest_year = record.attributes['CAMPAGNE'].to_s
            campaign = Campaign.of(harvest_year)

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

            islet_number = record.attributes['NUMERO'].to_s

            # Find an existing islet or stop importing
            unless (cap_islet = CapIslet.find_by(cap_statement: cap_statement, islet_number: islet_number))
              w.error 'Import Islets first'
            end

            cap_land_parcel_attributes = {
              cap_islet: cap_islet,
              land_parcel_number: record.attributes['NUMERO_SI'].to_s,
              main_crop_code: record.attributes['TYPE'].to_s,
              main_crop_commercialisation:  false,
              main_crop_precision: record.attributes['CODE_VAR'].to_s,
              main_crop_seed_production: false,
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
            unless (georeading = Georeading.find_by(georeadings_attributes.slice(:number)))
              georeading = Georeading.create!(georeadings_attributes)
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
