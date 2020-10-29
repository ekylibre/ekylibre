module Ekylibre
  class PicturesExchanger < ActiveExchanger::Base
    # Create or updates pictures
    def import
      # Unzip file
      dir = w.tmp_dir
      Zip::File.open(file) do |zile|
        zile.each do |entry|
          file = dir.join(entry.name)
          FileUtils.mkdir_p(file.dirname)
          entry.extract(file)
        end
      end

      mimetype = File.read(dir.join('mimetype')).to_s.strip
      nature = mimetype.split('.').last

      identifier = File.read(dir.join('identifier')).to_s.strip.to_sym

      klass = nil
      if nature == 'products'
        klass = Product
      else
        raise "Unknown picture type: #{mimetype.inspect}"
      end

      Dir.chdir(dir.join('pictures')) do
        Dir.glob('*') do |picture|
          path = Pathname.new(picture)
          extn = path.extname
          id = File.basename(picture, extn)
          if record = klass.find_by(identifier => id)
            f = File.open(picture)
            record.picture = f
            record.save!
          end
        end
      end

      true
    end
  end
end
