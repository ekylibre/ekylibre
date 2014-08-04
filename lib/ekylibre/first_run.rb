require 'zip'

module Ekylibre
  module FirstRun

    COUNTER_MAX = -1

    LAST_LOADER_PREFERENCE = "first_run.last_loader"

    LOADERS = [:base, :general_ledger, :entities, :land_parcels, :buildings, :equipments, :products, :animals, :productions, :analyses, :sales, :deliveries, :demo_interventions, :interventions, :guides]

    class CountExceeded < StandardError
    end

    autoload :Counter,  'ekylibre/first_run/counter'
    autoload :Booker,   'ekylibre/first_run/booker'
    autoload :Loader,   'ekylibre/first_run/loader'
    autoload :Manifest, 'ekylibre/first_run/manifest'

    class << self

      # Check if hard mode is required
      def hard?
        ENV["MODE"].to_s.downcase == "hard" or Rails.env.production?
      end

      # Transaction for first run
      def transaction(options = {}, &block)
        if hard?
          puts "No transaction".red unless options[:quiet]
          yield
        else
          ActiveRecord::Base.transaction(&block)
        end
      end

      # Get the last completed loader from preferences
      def last_loader
        if preference = Preference.find_by(name: Ekylibre::FirstRun::LAST_LOADER_PREFERENCE)
          return preference.value
        end
        return nil
      end
      
      # Set the last loader in preferences for next run
      def last_loader=(value)
        unless preference = Preference.find_by(name: Ekylibre::FirstRun::LAST_LOADER_PREFERENCE)
          preference = Preference.new(name: Ekylibre::FirstRun::LAST_LOADER_PREFERENCE, nature: :string)
        end
        preference.value = value
        preference.save!
      end
      
    end

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

      def path
        Rails.root.join("db", "first_runs")
      end

      def build(path)
        spec = YAML.load_file(path).deep_symbolize_keys

        puts spec.inspect

        # files = {}
        manifest = Manifest.new

        # General
        manifest[:locale] = spec[:locale] || I18n.default_locale
        manifest[:country] = spec[:country] || "fr"
        manifest[:currency] = spec[:currency] || "EUR"

        # Entity
        if spec[:entity]
          spect[:entity] = {name: spec[:entity].to_s} unless spec[:entity].is_a?(Hash)
          manifest[:entity] = spec[:entity]
          unless spec[:entity][:picture]
            manifest.store(:entity, :picture, Rails.root.join("app", "assets", "images", "icon", "store.png"))
          end
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
          details[:password] ||= User.give_password(8, :normal)
          manifest[:users][email] = details
        end

        # Imports
        manifest[:imports] = {}
        for import, parameters in IMPORTS
          if spec[:imports][import]
            manifest[:imports][import] = {}
            for param, type in parameters
              if type == :file
                manifest.add_file(:imports, import, param, path.dirname.join(spec[:imports][import][param]))
                manifest[:imports, import, param] = path.dirname.join(spec[:imports][import][param])

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

        manifest.build(path.realpath.parent.join(path.basename(path.extname).to_s + ".fra"))
      end

      def check(file)
      end

      def seed(file)

      end

    end

  end
end
