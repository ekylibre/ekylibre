require 'zip'

module Ekylibre
  class FirstRun

    IMPORTS = {
      telepac: {
        shapes: :file,
        shapes_index: :file,
        database: :file,
        projection: :file
      },
      istea: {
        general_ledger: :file
      }
    }

    class MissingData < StandardError
    end

    MIME = "application/vnd.ekylibre.first-run.archive"

    # Register FRA format unless is already set
    Mime::Type.register(MIME, :fra) unless defined? Mime::FRA

    class << self

      def build(path)
        spec = YAML.load_file(path).deep_symbolize_keys

        puts spec.inspect

        files = {}
        manifest = {}

        # Entity
        if spec[:entity]
          spect[:entity] = {name: spec[:entity].to_s} unless spec[:entity].is_a?(Hash)
          manifest[:entity] = spec[:entity]
        else
          raise MissingData, "Need entity data."
        end

        # Users
        unless spec[:users]
          spec[:users] = {'admin@ekylibre.org' => {
              first_name: 'Admin',
              last_name: 'EKYLIBRE',
              password: '12345678'
            }
          }
        end
        manifest[:users] = {}
        for email, details in spec[:users]
          manifest[:users][email] = details
        end

        # Imports
        manifest[:imports] = {}
        for import, parameters in IMPORTS
          if spec[:imports][import]
            manifest[:imports][import] = {}
            for param, type in parameters
              if type == :file
                doc = path.dirname.join(spec[:imports][import][param])
                name = "#{param}#{doc.extname}"
                files["imports/#{import}/#{name}"] = doc
                manifest[:imports][import][param] = name
              else
                manifest[:imports][import][param] = spec[:imports][import][param]
              end
            end
          end
        end
        manifest.delete(:imports) if manifest[:imports].empty?

        file = path.realpath.parent.join(path.basename(path.extname).to_s + ".fra")
        Zip::OutputStream.open(file) do |zile|
          zile.put_next_entry('mimetype', nil, nil, Zip::Entry::STORED)
          zile << Mime::FRA

          zile.put_next_entry('manifest.yml')
          zile << manifest.deep_stringify_keys.to_yaml

          for dest, src in files
            zile.put_next_entry(dest)
            zile << File.read(src)
          end
        end

      end

      def check(file)
      end

      def seed(file)

      end

    end

  end
end
