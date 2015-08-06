class Unicoque::PlantZonesExchanger < ActiveExchanger::Base
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

    RGeo::Shapefile::Reader.open(dir.join('plantation.shp').to_s, srid: 2154) do |file|
      # Set number of shapes
      w.count = file.size
      # Import or update

      file.each do |record|
        attributes = {
          name: record.attributes['BLOC_2'].to_s + ' - [' + (record.attributes['LIEUDIT'].blank? ? record.attributes['COMMUNE'].to_s : record.attributes['LIEUDIT'].to_s.capitalize!) + ']',
          bloc: record.attributes['BLOC'].to_s,
          rows_interval: (record.attributes['ENTRERANG'].blank? ? nil : record.attributes['ENTRERANG'].to_d),
          plants_interval: (record.attributes['SURRANG'].blank? ? nil : record.attributes['SURRANG'].to_d),
          plants_population: (record.attributes['NBREPIEDST'].blank? ? nil : record.attributes['NBREPIEDST'].to_d),
          surface_area: (record.attributes['SURFACE_NE'].blank? ? nil : record.attributes['SURFACE_NE'].to_d),
          measured_at: (record.attributes['AG_DATE'].blank? ? nil : (record.attributes['AG_DATE'].tr('/', '-')).to_datetime),
          born_at: (record.attributes['PREMIERE_F'].blank? ? nil : (record.attributes['PREMIERE_F'].to_s + '-01-01 00:00').to_datetime),
          variety: (record.attributes['CODE_VARIE'].blank? ? nil : varieties_transcode[record.attributes['CODE_VARIE'].to_s]),
          reference_variant: (record.attributes['ESPCE'].to_s == '21' ? :hazel_crop : :walnut_crop)
        }

        # Find or import from variant reference_nameclature the correct ProductNatureVariant
        variant = ProductNatureVariant.find_or_import!(attributes[:variety]).first || ProductNatureVariant.import_from_nomenclature(attributes[:reference_variant])
        pmodel = variant.nature.matching_model

        # Create the plant
        plant = pmodel.create!(variant_id: variant.id, work_number: 'PLANT_' + attributes[:bloc],
                               name: attributes[:name], initial_born_at: attributes[:born_at], initial_owner: Entity.of_company, variety: attributes[:variety] # , :initial_container => container
                              )

        plant.read!(:population, attributes[:surface_area], at: attributes[:measured_at]) if attributes[:surface_area]
        plant.read!(:rows_interval, attributes[:rows_interval].in_meter, at: attributes[:measured_at]) if attributes[:rows_interval]
        plant.read!(:plants_interval, attributes[:plants_interval].in_meter, at: attributes[:measured_at]) if attributes[:plants_interval]
        # Build density
        plant.read!(:plants_count, (attributes[:plants_population] / attributes[:surface_area]).to_i, at: attributes[:measured_at]) if attributes[:plants_population] && attributes[:surface_area]

        if record.geometry
          plant.read!(:shape, record.geometry, at: attributes[:born_at], force: true)
          plant_shape = Charta::Geometry.new(record.geometry).transform(:WGS84)
          if product_around = plant_shape.actors_matching(nature: CultivableZone).first
            plant.initial_container = product_around
            plant.save!
          end
        end

        w.check_point
      end
    end
  end
end
