class Telepac::V2015::CapLandParcelsExchanger < ActiveExchanger::Base

  def import
    # Unzip file
    dir = w.tmp_dir
    Zip::File.open(file) do |zile|
      zile.each do |entry|
        entry.extract(dir.join(entry.name))
      end
    end

    RGeo::Shapefile::Reader.open(dir.join("ilot.shp").to_s, srid: 2154) do |file|
      # Set number of shapes
      w.count = file.size

      # Find good variant
      land_parcel_cluster_variant = ProductNatureVariant.import_from_nomenclature(:land_parcel_cluster)
      # Import or update
      file.each do |record|
        attributes = {
          initial_born_at: Time.utc(1, 1, 1, 0, 0, 0),
          work_number: record.attributes['NUMERO'].to_s,
          variant_id: land_parcel_cluster_variant.id,
          name: LandParcelCluster.model_name.human + " " + record.attributes['NUMERO'].to_s,
          variety: "land_parcel_cluster",
          initial_owner: Entity.of_company,
          identification_number: record.attributes['PACAGE'].to_s + record.attributes['CAMPAGNE'].to_s + record.attributes['NUMERO'].to_s
        }

        if record.geometry
          # Find or create land_parcel_cluster
          # TODO: Use a find_by_shape_similarity to determine existence of the land parcel
          unless land_parcel_cluster = LandParcelCluster.find_by(attributes.slice(:work_number, :variety, :identification_number))
            land_parcel_cluster = LandParcelCluster.create!(attributes)
          end
          land_parcel_cluster.read!(:shape, record.geometry, at: land_parcel_cluster.initial_born_at)
          a = (land_parcel_cluster.shape_area.to_d / land_parcel_cluster_variant.net_surface_area.to_d(:square_meter))
          land_parcel_cluster.read!(:population, a, at: land_parcel_cluster.initial_born_at)
        # if record.geometry
        #   shapes[record.attributes['NUMERO'].to_s] = Charta::Geometry.new(record.geometry).transform(:WGS84).to_rgeo
        # end
        else
          w.warn "No geometry given for CAP land parcel (#{attributes.inspect})"
        end
        w.check_point
      end
    end
  end

end
