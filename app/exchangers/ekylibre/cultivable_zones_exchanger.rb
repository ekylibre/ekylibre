class Ekylibre::CultivableZonesExchanger < ActiveExchanger::Base

  # Create or updates cultivable zones
  def import
    rows = CSV.read(file, headers: true).delete_if{|r| r[0].blank?}
    w.count = rows.size

    born_at = Time.utc(1900, 1, 1, 0, 0, 0)

    rows.each do |row|
      r = {
        name: row[0].to_s,
        nature: (row[1].blank? ? nil : row[1].to_sym),
        code: (row[2].blank? ? nil : row[2].to_s),
        georeading_number: (row[3].blank? ? nil : row[3].to_s)
        # members: row[4].blank? ? [] : row[4].to_s.strip.split(/[[:space:]]*\,[[:space:]]*/)
      }.to_struct

      if zone = CultivableZone.find_by_work_number(r.code)
        zone.update_attributes(name: r.name)
        zone.save!
      else
        zone_variant = ProductNatureVariant.import_from_nomenclature(r.nature)
        attributes = {
          variant_id: zone_variant.id,
          work_number: r.code,
          name: r.name,
          initial_born_at: born_at,
          initial_owner: Entity.of_company
        }
        zone = zone_variant.matching_model.create!(attributes)
      end
      if georeading = Georeading.find_by(number: r.georeading_number)
        zone.read!(:shape, georeading.content, at: zone.initial_born_at, force: true)
        a = (zone.shape_area.to_d / zone.variant.net_surface_area.to_d(:square_meter))
        zone.read!(:population, a.to_s.to_f, at: zone.initial_born_at, force: true)
        # zone.read!(:net_surface_area, zone.shape_area, at: zone.born_at)
      end

      # link cultivable zone and land parcel for each entries
      if zone.shape
        zone_shape = Charta::Geometry.new(zone.shape).transform(:WGS84)
        if products_around = zone_shape.actors_matching(nature: LandParcel)
          for land_parcel in products_around
            if land_parcel.shape
              attributes = {
                group_id: zone.id,
                member_id: land_parcel.id,
                shape: land_parcel.shape,
                population: (land_parcel.shape_area.to_d / land_parcel.variant.net_surface_area.to_d(:square_meter))
              }
              unless CultivableZoneMembership.find_by(attributes.slice(:group_id, :member_id))
                CultivableZoneMembership.create!(attributes)
              end
            end
          end
        end
      end


      # # Add available_water_capacity indicator
      # if r.land_parcel_available_water_capacity
      #   land_parcel.read!(:available_water_capacity_per_area, r.land_parcel_available_water_capacity.in_liter_per_square_meter, at: r.born_at)
      # end

      # # Add land_parcel in land_parcel_cluster group
      # land_parcel.memberships.create!(group: land_parcel_cluster, started_at: born_at, nature: :interior)

      w.check_point
    end
  end

end
