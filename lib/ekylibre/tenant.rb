require 'apartment'
require 'ekylibre/schema'

module Ekylibre
  class TenantError < StandardError
  end

  class Tenant
    AGGREGATION_NAME = '__all__'.freeze

    class << self
      # Tests existence of a tenant
      def exist?(name)
        list.include?(name)
      end

      # Tests existence of a tenant in DB
      # and removes it if not exist
      def check!(name, options = {})
        if list.include?(name)
          drop(name, options) unless Apartment.connection.schema_exists? name
        end
      end

      # Returns the current tenant
      def current
        unless name = Apartment::Tenant.current
          raise TenantError, 'No current tenant'
        end
        name
      end

      def host
        "#{current}.#{ENV['HOST_DOMAIN_NAME'] || 'example.org'}"
      end

      # Returns the private directory of the current tenant
      # If tenant name given, it returns its private_directory
      def private_directory(name = nil)
        Ekylibre.root.join('private', name || current)
      end

      # Create a new tenant with tables and co
      def create(name)
        name = name.to_s
        check!(name)
        raise TenantError, 'Already existing tenant' if exist?(name)
        Apartment::Tenant.create(name)
        add(name)
      end

      # Adds a tenant in config. No schema are created.
      def add(name)
        list << name unless list.include?(name)
        write
      end

      # Add a tenant in config without creating it
      # Nothing is done if already exist
      def setup!(name, options = {})
        check!(name, options)
        create(name) unless exist?(name)
        switch!(name)
      end

      # Drop tenant
      def drop(name, options = {})
        name = name.to_s
        raise TenantError, "Unexistent tenant: #{name}" unless exist?(name)
        Apartment::Tenant.drop(name) if Apartment.connection.schema_exists? name
        FileUtils.rm_rf private_directory(name) unless options[:keep_files]
        @list[env].delete(name)
        write
      end

      # Migrate tenant to wanted version
      def migrate(name, options = {})
        switch(name) do
          ActiveRecord::Migrator.migrate(ActiveRecord::Migrator.migrations_paths, options[:to])
        end
      end

      def rename(old, new)
        check!(old)
        raise TenantError, "Unexistent tenant: #{name}" unless exist?(old)
        ActiveRecord::Base.connection.execute("ALTER SCHEMA #{old.to_s.inspect} RENAME TO #{new.to_s.inspect};")
        @list[env].delete(old.to_s)
        @list[env] << new.to_s
      end

      # Dump database and files data to a zip archive with specific places
      # This archive is database independent
      def dump(name, options = {})
        destination_path = options.delete(:path) || Rails.root.join('tmp', 'archives')
        switch(name) do
          archive_file = destination_path.join("#{name}.zip")
          archive_path = destination_path.join("#{name}-dump")
          tables_path = archive_path.join('tables')
          files_path = archive_path.join('files')

          FileUtils.rm_rf(archive_path)

          FileUtils.mkdir_p(tables_path)
          version = Fixturing.extract(path: tables_path)

          if private_directory.exist?
            FileUtils.mkdir_p(files_path.dirname)
            FileUtils.cp_r(private_directory.to_s, files_path.to_s)
          end

          File.open(archive_path.join('mimetype'), 'wb') do |f|
            f.write 'application/vnd.ekylibre.tenant.archive'
          end

          File.open(archive_path.join('manifest.yml'), 'wb') do |f|
            options.update(
              tenant: name,
              format_version: '2.0',
              database_version: version,
              creation_at: Time.zone.now,
              created_with: "Ekylibre #{Ekylibre::VERSION}"
            )
            f.write options.stringify_keys.to_yaml
          end

          FileUtils.rm_rf(archive_file)
          Zip::File.open(archive_file, Zip::File::CREATE) do |zile|
            Dir.chdir archive_path do
              Dir.glob('**/*').each do |path|
                zile.add(path, archive_path.join(path))
              end
            end
          end

          FileUtils.rm_rf(archive_path)
        end
      end

      # Restore an archive
      def restore(archive_file, options = {})
        code = options[:tenant] || Time.zone.now.to_i.to_s(36) + rand(999_999_999).to_s(36)
        verbose = !options[:verbose].is_a?(FalseClass)

        archive_path = Rails.root.join('tmp', 'archives', "#{code}-restore")
        tables_path = archive_path.join('tables')
        files_path = archive_path.join('files')

        FileUtils.rm_rf(archive_path)
        FileUtils.mkdir_p(archive_path)

        puts "Decompressing #{archive_file.basename} to #{archive_path.basename}...".yellow if verbose
        Zip::File.open(archive_file.to_s) do |zile|
          zile.each do |entry|
            entry.extract(archive_path.join(entry.name))
          end
        end

        puts 'Checking archive...'.yellow if verbose
        raise 'Invalid archive' unless archive_path.join('manifest.yml').exist?

        manifest = YAML.load_file(archive_path.join('manifest.yml')).symbolize_keys
        format_version = manifest[:format_version]
        unless format_version == '2.0'
          raise "Cannot handle this version of archive: #{format_version}"
        end

        unless name = options[:tenant] || manifest[:tenant]
          raise 'No given name for the tenant'
        end

        database_version = manifest[:database_version].to_i
        if database_version > ActiveRecord::Migrator.last_version
          raise 'Too recent archive'
        end

        puts "Resetting tenant #{name}...".yellow if verbose
        drop(name) if exist?(name)
        create(name)

        switch(name) do
          if files_path.exist?
            puts 'Restoring files...'.yellow if verbose
            FileUtils.rm_rf private_directory
            FileUtils.mv files_path, private_directory
          else
            puts 'No files to restore'.yellow if verbose
          end

          puts 'Restoring database and migrating...'.yellow if verbose
          Fixturing.restore(name, version: database_version, path: tables_path, verbose: verbose)
          puts 'Done!'.yellow if verbose
        end

        FileUtils.rm_rf(archive_path)
      end

      # Change current tenant
      def switch(name, &block)
        raise 'Need block to use Ekylibre::Tenant.switch' unless block_given?
        Apartment::Tenant.switch(name, &block)
      end

      def switch!(name)
        Apartment::Tenant.switch!(name)
      end

      alias current= switch!

      def switch_default!
        if list.empty?
          raise TenantError, 'No default tenant'
        else
          Apartment::Tenant.switch!(list.first)
        end
      end

      # Browse all tenant to make actions on it
      def switch_each(&_block)
        list.each do |tenant|
          switch(tenant) do
            yield tenant
          end
        end
      end

      def clear!
        list unless @list
        @list[env] = []
        write
      end

      def list
        load! unless @list
        @list[env] ||= []
        @list[env]
      end

      def load!
        @list = (File.exist?(config_file) ? YAML.load_file(config_file) : {})
        @list ||= {}
      end

      def drop_aggregation_schema!
        ActiveRecord::Base.connection.execute("CREATE SCHEMA IF NOT EXISTS #{AGGREGATION_NAME};")
      end

      def create_aggregation_schema!
        create_aggregation_views_schema!
      end

      def create_aggregation_views_schema!
        raise 'No tenant to build an aggregation schema' if list.empty?
        name = AGGREGATION_NAME
        connection = ActiveRecord::Base.connection
        connection.execute("CREATE SCHEMA IF NOT EXISTS #{name};")
        Ekylibre::Schema.tables.keys.each do |table|
          connection.execute "DROP VIEW IF EXISTS #{name}.#{table}"
          columns = Ekylibre::Schema.columns(table)
          queries = list.collect do |tenant|
            "SELECT '#{tenant}' AS tenant_name, " + columns.collect { |c| c[:name] }.join(', ') + " FROM #{tenant}.#{table}"
          end
          query = "CREATE VIEW #{name}.#{table} AS " + queries.join(' UNION ALL ')
          connection.execute(query)
        end
      end

      def reset_search_path!
        ActiveRecord::Base.connection.schema_search_path = Ekylibre::Application.config.database_configuration[::Rails.env]['schema_search_path']
      end

      def list_tenants_with_migration_problem

        tenants = []

        list.each do |tenant|

          Ekylibre::Tenant::switch! tenant
          migration_version = ActiveRecord::Migrator.current_version

          next if migration_version != 0

          tenants << { name: tenant, version: migration_version }
        end

        tenants
      end

      def correct_tenants_with_migration_problem!

        tenants = list_tenants_with_migration_problem

        tenants.each do |tenant|

          Ekylibre::Tenant::switch! tenant[:name]

          connection = ActiveRecord::Base.connection
          connection.execute("INSERT INTO schema_migrations SELECT * FROM public.schema_migrations")

          puts (tenant[:name] + " : done").yellow
        end

        puts 'Task done'.blue
      end

      private

      def config_file
        Rails.root.join('config', 'tenants.yml')
      end

      # Return the env
      def env
        Rails.env.to_s
      end

      def write
        semaphore.synchronize do
          FileUtils.mkdir_p(config_file.dirname)
          File.write(config_file, @list.to_yaml)
        end
      end

      def semaphore
        @@semaphore ||= Mutex.new
      end
    end
  end
end
