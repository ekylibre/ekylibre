# frozen_string_literal: true

module Ekylibre
  class PicturesExchanger < ActiveExchanger::Base
    category :settings
    vendor :ekylibre

    # Create or updates pictures
    def import
      # Unzip file
      dir = w.tmp_dir
      Ekylibre::SafeZip.extract_all(file, into: dir)

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
