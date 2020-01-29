module Telepac
  module V2014
    class CapLandParcelsExchanger < ActiveExchanger::Base
      self.deprecated = true

      def import
        # Unzip file
        dir = w.tmp_dir
        Zip::File.open(file) do |zile|
          zile.each do |entry|
            entry.extract(dir.join(entry.name))
          end
        end

        RGeo::Shapefile::Reader.open(dir.join('ilot.shp').to_s, srid: 2154) do |file|
          # Set number of shapes
          w.count = file.size

          # Import 2015 islet
          file.each do |record|
            # if record.index == 0
            # check cap_statement presence for the consider year
            harvest_year = record.attributes['CAMPAGNE'].to_s
            campaign = Campaign.of(harvest_year)

            pacage_number = record.attributes['PACAGE'].to_s

            company = Entity.of_company
            siret_number = company.siret_number
            siret_number = '000000000000018' if siret_number.blank?
            cap_statement_attributes = {
              campaign: campaign,
              declarant: company,
              farm_name: company ? company.full_name : 'No declarant',
              pacage_number: pacage_number,
              siret_number: siret_number
            }
            ## find or create cap statement
            cap_statement = ::CapStatement.find_or_initialize_by(campaign: campaign, pacage_number: pacage_number)
            cap_statement.attributes = cap_statement_attributes
            cap_statement.save!
            # end

            islet_attributes = {
              cap_statement: cap_statement,
              islet_number: record.attributes['NUMERO'].to_s,
              town_number: record.attributes['COMMUNE'].to_s,
              shape: ::Charta.new_geometry(record.geometry).transform(:WGS84).to_rgeo
            }

            # find or create islet according to cap statement
            cap_islet = ::CapIslet.find_or_initialize_by(islet_attributes.slice(:islet_number, :cap_statement))
            cap_islet.attributes = islet_attributes
            cap_islet.save!

            # import into georeadings
            label = 'I' + '-' + cap_islet.cap_statement.pacage_number.to_s + '-' + cap_islet.cap_statement.campaign.harvest_year.to_s + '-' + cap_islet.islet_number.to_s
            georeadings_attributes = {
              name: label,
              number: label,
              nature: :polygon,
              content: cap_islet.shape
            }
            unless ::Georeading.find_by(georeadings_attributes.slice(:number))
              ::Georeading.create!(georeadings_attributes)
            end

            w.check_point
          end
        end

        true
      end
    end
  end
end
