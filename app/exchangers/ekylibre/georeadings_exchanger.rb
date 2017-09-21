module Ekylibre
  class GeoreadingsExchanger < ActiveExchanger::Base
    def import
      # Unzip file
      dir = w.tmp_dir
      Zip::File.open(file) do |zile|
        zile.each do |entry|
          entry.extract(dir.join(entry.name))
        end
      end

      mimetype = File.read(dir.join('mimetype')).to_s.strip
      nature = mimetype.split('.').last

      RGeo::Shapefile::Reader.open(dir.join('georeading.shp').to_s) do |file|
        # Set number of shapes
        w.count = file.size

        file.each do |record|
          # puts record.attributes['number'].inspect.red
          if record.geometry
            name = if record.attributes['name'].present?
                     # TODO: find how to fix non UTF-8 name
                     # puts record.attributes['name'].inspect.red
                     record.attributes['name'].mb_chars.downcase.capitalize
                   else
                     record.attributes['number'].to_s.upcase
                   end
            attributes = {
              name: name,
              number: record.attributes['number'].to_s.upcase,
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
  end
end
