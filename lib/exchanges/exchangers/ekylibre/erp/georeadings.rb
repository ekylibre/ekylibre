Exchanges.add_importer :ekylibre_erp_georeadings do |file, w|

  # Unzip file
  dir = w.tmp_dir
  Zip::File.open(file) do |zile|
    zile.each do |entry|
      entry.extract(dir.join(entry.name))
    end
  end

  mimetype = File.read(dir.join('mimetype')).to_s.strip
  nature = mimetype.split(".").last

  RGeo::Shapefile::Reader.open(dir.join("georeading.shp").to_s, srid: 4326) do |file|
    # Set number of shapes
    w.count = file.size

    file.each do |record|
      if record.geometry
        attributes = {
          name: record.attributes['name'] || record.attributes['number'],
          number: record.attributes['number'],
          nature: nature
        }
        unless georeading = Georeading.find_by(attributes.slice(:number))
          georeading = Georeading.new(attributes)
        end
        georeading.content = record.geometry
        georeading.save!
      end
      w.check_point
    end
  end


end
