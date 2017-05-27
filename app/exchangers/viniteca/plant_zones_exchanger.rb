# Create or updates entities
module Viniteca
  class PlantZonesExchanger < ActiveExchanger::Base
    def import
      # Unzip files
      dir = w.tmp_dir
      Zip::File.open(file) do |zile|
        zile.each do |entry|
          entry.extract(dir.join(entry.name))
        end
      end

      # Import and transcode variety
      varieties_transcode = {}.with_indifferent_access
      csv_variety_file = dir.join('varieties_transcode.csv')
      if csv_variety_file.exist?
        CSV.foreach(csv_variety_file, headers: true) do |row|
          varieties_transcode[row[0]] = row[1].to_sym
        end
      end

      certifications_transcode = {}.with_indifferent_access
      path = dir.join('certifications_transcode.csv')
      if path.exist?
        CSV.foreach(path, headers: true) do |row|
          certifications_transcode[row[0]] = row[1].to_sym
        end
      end

      cultivable_zones_transcode = {}.with_indifferent_access
      path = dir.join('cultivable_zones_transcode.csv')
      if path.exist?
        CSV.foreach(path, headers: true) do |row|
          cultivable_zones_transcode[row[0]] = row[1].to_s
        end
      end

      RGeo::Shapefile::Reader.open(dir.join('plant.shp').to_s, srid: 4326) do |file|
        # Set number of shapes
        w.count = file.size
        # Import or update

        file.each do |record|
          # build variable for transcode
          record_variety = record.attributes['CEPAGE'].to_s.downcase + ' ' + record.attributes['COULEUR_PA'].to_s.downcase
          # find or import variant
          if variety = varieties_transcode[record_variety]
            # vine_crop_variant = ProductNatureVariant.find_or_import!(variety)
            # else
            vine_crop_variant = ProductNatureVariant.find_or_import!(:vitis_vinifera)
          end

          initial_born_at = (record.attributes['DATE_CREAT'].blank? ? born_at : record.attributes['DATE_CREAT'].to_datetime)

          zc_work_number = cultivable_zones_transcode[record.attributes['NOM_PIECE']]
          # create plant
          plant = Plant.create!(
            variant_id: vine_crop_variant.first.id,
            name: record.attributes['CEPAGE'].to_s + ' (' + record.attributes['PORTE_GREF'].to_s + ') - [' + record.attributes['N_PARCELLE'].to_s + '_' + record.attributes['NOM_PIECE'].to_s + ']',
            work_number: 'PLANT_' + record.attributes['N_PARCELLE'].to_s + '_' + record.attributes['NOM_PIECE'].to_s,
            variety: variety,
            initial_born_at: initial_born_at,
            initial_owner: Entity.of_company,
            default_storage: CultivableZone.find_by(work_number: zc_work_number) || CultivableZone.first,
            identification_number: record.attributes['N_PARCELLE'].to_s
          )

          # shape and population
          plant.read!(:shape, record.geometry, at: initial_born_at)
          plant.read!(:population, record.attributes['SURFACE_RE'].to_d, at: initial_born_at) if record.attributes['SURFACE_RE']

          # vine indicators
          # plant_life_state, woodstock_variety, certification, plants_count, rows_interval, plants_interval
          if record.attributes['CODE_AOC'].present?
            code_aoc = record.attributes['CODE_AOC'].to_s.downcase
            plant.read!(:certification, certifications_transcode[code_aoc], at: initial_born_at) if code_aoc
          end

          if record.attributes['PORTE_GREF'].present?
            porte_greffe = record.attributes['PORTE_GREF'].to_s.downcase
            plant.read!(:woodstock_variety, varieties_transcode[porte_greffe], at: initial_born_at) if porte_greffe
          end

          if record.attributes['ECARTEMENT']
            plant.read!(:rows_interval, record.attributes['ECARTEMENT'].to_d.in_meter, at: initial_born_at)
          end

          if record.attributes['ECARTEMEN0']
            plant.read!(:plants_interval, record.attributes['ECARTEMEN0'].to_d.in_meter, at: initial_born_at)
          end

          w.check_point
        end
      end
    end
  end
end
