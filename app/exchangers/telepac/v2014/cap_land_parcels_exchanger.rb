class Telepac::V2014::CapLandParcelsExchanger < ActiveExchanger::Base
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

      # check cap_statement presence for the consider year
      harvest_year = file.first.attributes['CAMPAGNE'].to_s
      campaign = Campaign.find_or_create_by!(harvest_year: harvest_year)

      pacage_number = file.first.attributes['PACAGE'].to_s

      cap_statement_attributes = {
        campaign: campaign,
        entity: Entity.of_compagny,
        exploitation_name: Entity.of_compagny.full_name,
        pacage_number: pacage_number,
        siret_number: Entity.of_compagny.siret
        }

      ## find or create cap statement
      unless cap_statement = CapStatement.find_by(campaign: campaign, pacage_number: pacage_number)
        cap_statement = CapStatement.create!(cap_statement_attributes)
      end

      # Import 2015 islet
      file.each do |record|
        islet_attributes = {
          cap_statement: cap_statement,
          islet_number: record.attributes['NUMERO'].to_s,
          town_number: record.attributes['COMMUNE'].to_s,
          shape: record.geometry
        }

        # find or create islet according to cap statement
        unless cap_islet = CapIslet.find_by(islet_attributes.slice(:islet_number, :cap_statement))
          cap_islet = CapIslet.create!(islet_attributes)
        end
        w.check_point
      end
    end
  end
end