# coding: utf-8
module Ekylibre
  class CrumbsExchanger < ActiveExchanger::Base
      def import

      # Unzip files
      dir = w.tmp_dir
      Zip::File.open(file) do |zile|
        zile.each do |entry|
          entry.extract(dir.join(entry.name))
        end
      end
  
       # 1 - CHECK INTRANTS AND VARIABLES
       #production = Production.where(name: "Carotte").first       
       #support = production.supports.where(storage: cultivable_zone).first
       #intrant = Product.find_by_work_number("SEM_CAROTTE_NANT_2014")
       #input_population = 0.89
       started_at = "2016-01-27 09:43"
       duration = 19.0 * 60
       #target_variant = ProductNatureVariant.find_by_variety('daucus')
       #plants_count = 85695
       # actors
       cultivable_zone = CultivableZone.find_by_work_number("ZC052")
       land_parcel = LandParcel.find_by(work_number: "TRAC_38")
       tractor = Equipment.find_by(work_number: "TRAC_38")
       soil_tool = Equipment.find_by(work_number: "TNAR")
       user = User.where(email: "julien.larrere@groupe-larrere.com").first
       worker = Worker.find_by(work_number: "JNLE")
       
       georeading = Georeading.find_by(number: "P01")
       geom = Charta::Geometry.new(georeading.content)
       geom.srid = 2154
       geom = geom.transform(4326)
  
       # 2 - CREATE A PROVISIONNAL superficial_plowing INTERVENTION
        intervention = nil
        if support && intrant
          Ekylibre::FirstRun::Booker.production = support.production
          # Chemical weed
          intervention = Ekylibre::FirstRun::Booker.force(:superficial_plowing, Time.zone.local(2016,1,27,9,43), (duration / 3600), support: support) do |i|
            i.add_cast(reference_name: 'plow',         actor: soil_tool)
            i.add_cast(reference_name: 'driver',       actor: worker)
            i.add_cast(reference_name: 'tractor',      actor: tractor)
            i.add_cast(reference_name: 'land_parcel',  actor: land_parcel)
          end
        end
  
        # 3 - COLLECT REAL INTERVENTION TRIP
        # populate crumbs
        # shape file with attributes for sowing
        path = dir.join('trip_simulation.shp')
  
        RGeo::Shapefile::Reader.open(path.to_s, srid: 4326) do |file|
          file.each do |record|
                next if record.nil?
                metadata = record.attributes['metadata'].blank? ? {} : record.attributes['metadata'].to_s.strip.split(/[[:space:]]*\;[[:space:]]*/).collect { |i| i.split(/[[:space:]]*\:[[:space:]]*/) }.inject({}) do |h, i|
                  h[i.first.strip.downcase.to_s] = i.second.to_s
                  h
                end
  
                Crumb.create!(accuracy: 1,
                              geolocation: record.geometry,
                              metadata: metadata,
                              nature: record.attributes['nature'].to_sym,
                              read_at: Time.parse(started_at) + (60 * record.attributes['id'].to_i),
                              user_id: user.id,
                              device_uid: record.attributes['device_uid'] || 'demo:123854',
                              intervention_cast: intervention.casts.find_by(reference_name: 'sower')
                             )
              end
            end
  
  
      # 4 - COLLECT REAL CONSUMPTION DURING INTERVENTION TRIP
      csv_file = dir.join('data_consumption.csv')
      rows = CSV.read(csv_file, headers: true, col_sep: ',')
      w.count = rows.size
      start = Time.parse(started_at)
      rows.each do |row|
        r = {
          id: row[0].to_i,
          time: row[1].to_i,
          value: row[2].to_d,
        }.to_struct
  
        tractor.read!(:fuel_consumption, r.value.in(:liter_per_hour), at: start + r.time)
  
        end
  
    end
  end
end
