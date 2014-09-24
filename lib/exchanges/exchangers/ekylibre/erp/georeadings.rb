Exchanges.add_importer :ekylibre_erp_georeadings do |file, w|

  # Unzip file
  dir = w.tmp_dir
  Zip::File.open(file) do |zile|
    zile.each do |entry|
      entry.extract(dir.join(entry.name))
    end
  end


  RGeo::Shapefile::Reader.open(dir.join("cultivable_zones.shp").to_s, srid: 4326) do |file|
    # Set number of shapes
    w.count = file.size

    file.each do |record|
      if record.geometry
        attributes = {
          name: record.attributes['name'] || record.attributes['number'],
          number: record.attributes['number'],
          nature: record.attributes['type'] || record.attributes['nature'] || 'polygon',
          content: record.geometry
        }
        puts attributes.inspect.red
        unless georeading = Georeading.find_by(attributes.slice(:number))
          georeading = Georeading.create(attributes)
        end
        georeading.inspect.yellow
      end
      w.check_point
    end
  end


end
