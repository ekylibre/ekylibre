module Ekylibre
  module FirstRun
    class Folder

      VERSION = 2

      attr_reader :path, :version, :imports, :preferences, :defaults

      def initialize(path)
        @path = path
        manifest = YAML.load_file(path.join('manifest.yml')).deep_symbolize_keys
        @version = manifest[:version]
        unless @version == VERSION
          fail "Incompatible first-run folder: #{@version.inspect}." +
               "Need v#{VERSION} first-run API."
        end
        @imports = manifest[:imports] || {}
        @preferences = manifest[:preferences] || {}
        @defaults = manifest[:defaults] || {}
      end

      def imports_dir
        @path.join('imports')
      end

      def run
        load_preferences
        load_defaults
        load_imports
      end

      # Load global preferences of the instance
      def load_preferences
        @preferences.each do |key, value|
          if Preference.references[key]
            Preference.set!(key, value)
          else
            self.warn
          end
        end
      end

      # Load default data of models with default data
      def load_defaults
        Sequence.load_defaults
        Account.load_defaults
        DocumentTemplate.load_defaults
        Tax.load_defaults
        Journal.load_defaults
      end

      # Load all of given imports
      def load_imports

      end

      protected

      def warn(message)
        Rails.logger.warn(message)
      end



    end
  end
end
