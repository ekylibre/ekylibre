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
          fail ArgumentError, ':path and :folder options are incompatible'
        end
        name = options.delete(:name)
        if path = options.delete(:path)
          path = Pathname.new(path)
        elsif options[:folder]
          path = Ekylibre::FirstRun.path.join(options.delete(:folder))
        else
          fail ArgumentError, 'Need at least :path or :folder option'
        end
        base = Base.new(path, options)
        secure_tenant(name) do
          sentence = 'Launch first run'
          sentence << " in tenant #{name}" if name
          sentence << " from #{base.path.relative_path_from(Rails.root)}"
          # sentence << " in #{base.mode} mode"
          sentence << (base.max > 0 ? " with max of #{base.max}" : ' without max')
          sentence << (base.hard? ? ' without global transaction' : ' inside global transaction')
          sentence << '.'
          Rails.logger.info sentence
          puts sentence.yellow if base.verbose
          call_loaders(base)
        end
      end

      # Returns the default path where first_runs data are expected
      def path
        Rails.root.join('db', 'first_runs')
      end

      # Adds a loader
      def add_loader(name, &block)
        @loaders ||= {}
        @loaders[name.to_sym] = block
      end

      # Returns loaders names
      def loaders
        (@loaders ? @loaders.keys : [])
      end

      def executed_preference
        Preference.get!("first_run.executed", false, :boolean)
      end


      # Execute all loaders for a given base
      def call_loaders(base)
        @loaders ||= []
        secure_transaction(!base.hard?) do
          preference = executed_preference
          loaders.each do |loader|
            call_loader(loader, base)
          end
          preference.value = true
          preference.save!
        end
      end

      # Execute given loader for a given base
      def call_loader(loader, base)
        unless base.is_a?(Ekylibre::FirstRun::Base)
          fail 'Invalid first run. Need a Ekylibre::FirstRun::Base'
        end
        ::I18n.locale = Preference[:language]
        ActiveRecord::Base.transaction do
          preference = Preference.get!("first_run.executed_loaders.#{loader}", false, :boolean)
          if base.force || !preference.value
            @loaders[loader].call(base)
            preference.value = true
            preference.save!
          else
            puts 'Skip'.yellow + " #{loader} loader"
          end
        end
      end

      # Wrap code in a tenant creation transaction if wanted
      def secure_tenant(name = nil, &_block)
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

      # Wrap code in a transaction if wanted
      def secure_transaction(with_transaction = true, &block)
        (with_transaction ? ActiveRecord::Base.transaction(&block) : yield)
      end
    end
  end
end

# Add loaders
require 'ekylibre/first_run/loaders'
