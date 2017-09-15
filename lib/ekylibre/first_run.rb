require 'zip'

module Ekylibre
  module FirstRun
    autoload :Counter, 'ekylibre/first_run/counter'
    autoload :Booker,  'ekylibre/first_run/booker'
    autoload :Base,    'ekylibre/first_run/base'
    autoload :Faker,   'ekylibre/first_run/faker'
    autoload :Folder,  'ekylibre/first_run/folder'

    class << self
      # Launch a first-run with tenant creation
      # Name of tenant is found with option :name or with path or folder options if missing
      def launch!(options = {})
        if options[:path]
          options[:name] ||= File.basename(options[:path]).to_s
        else
          options[:folder] ||= options[:name]
          options[:folder] ||= 'demo' if Ekylibre::FirstRun.path.join('demo').exist?
          options[:folder] ||= 'default' if Ekylibre::FirstRun.path.join('default').exist?
          options[:name] ||= options[:folder]
        end
        launch(options)
      end

      # Only run first-run in current tenant
      # Options are:
      #  - path:   Full path of the first run folder
      #  - folder: Name of the folder expected to be in db/first_runs
      #  - name:   Name of the tenant to create. No tenant created if no name.
      #  - max:    Max iteration per counter
      #  - mode:   (hard|nil)
      #  - verbose
      def launch(options = {})
        if options[:path] && options[:folder]
          raise ArgumentError, ':path and :folder options are incompatible'
        end
        name = options.delete(:name)
        if path = options.delete(:path)
          path = Pathname.new(path)
        elsif options[:folder]
          path = Ekylibre::FirstRun.path.join(options.delete(:folder))
        else
          raise ArgumentError, 'Need at least :path or :folder option'
        end
        manifest = YAML.load_file(path.join('manifest.yml'))
        sentence = 'Launch first run'
        sentence << " in tenant #{name}" if name
        sentence << " from #{path.relative_path_from(Rails.root)}"
        max = options[:max].to_i
        sentence << (max > 0 ? " with max of #{max}" : ' without max')
        sentence << (options[:hard] ? ' without global transaction' : ' inside global transaction')
        sentence << '.'
        Rails.logger.info sentence
        puts sentence.yellow if options[:verbose]
        secure_tenant(name) do
          if manifest['version'] == 2
            Folder.new(path, options).run
          else
            Base.new(path, options).run
          end
        end
      end

      # Returns the default path where first_runs data are expected
      def path
        Rails.root.join('db', 'first_runs')
      end

      # Wrap code in a tenant creation transaction if wanted
      def secure_tenant(name = nil)
        if name
          begin
            Ekylibre::Tenant.check!(name)
            Ekylibre::Tenant.create(name) unless Ekylibre::Tenant.exist?(name)
            Ekylibre::Tenant.switch(name) do
              yield
            end
          ensure
            Ekylibre::Tenant.check!(name)
          end
        else
          yield
        end
      end
    end
  end
end
