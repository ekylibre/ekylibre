require 'apartment'
require 'ekylibre/schema'
require 'shellwords'

module Ekylibre
  class TenantError < StandardError; end
  class ForbiddenImport < StandardError; end

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
          raise TenantError.new('No current tenant')
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
        raise TenantError.new('Already existing tenant') if exist?(name)

        add(name)
        Apartment::Tenant.create(name)
        # byebug
      end

      # Adds a tenant in config. No schema are created.
      def add(name)
        list << name unless list.include?(name)
        write
        # byebug
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
        raise TenantError.new("Unexistent tenant: #{name}") unless exist?(name)

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
        return if old == new

        check!(old)
        raise TenantError.new("Unexistent tenant: #{old}") unless Apartment.connection.schema_exists?(old)
        raise TenantError.new("Tenant already exists: #{new}") if Apartment.connection.schema_exists?(new)

        ActiveRecord::Base.connection.execute("ALTER SCHEMA #{old.to_s.inspect} RENAME TO #{new.to_s.inspect};")
        if private_directory(old).exist?
          FileUtils.rm_rf(private_directory(new))
          FileUtils.mv(private_directory(old), private_directory(new))
        end
        @list[env].delete(old.to_s)
        @list[env] << new.to_s
        write
      end

      # Dump database and files data to a zip archive with specific places
      # This archive is database independent
      def dump(name, options = {})
        raise "Tenant doesn't exist: #{name}" unless exist?(name)

        verbose = !options[:verbose].is_a?(FalseClass)
        start = Time.current
        dump_v3(name, options)
        duration = Time.current - start
        puts "Done! (#{duration.round(2)}s)".yellow if verbose
      end

      # Restore an archive
      def restore(archive_file, options = {})
        code = options[:tenant] || Time.zone.now.to_i.to_s(36) + rand(999_999_999).to_s(36)
        verbose = !options[:verbose].is_a?(FalseClass)

        archive_path = Rails.root.join('tmp', 'archives', "#{code}-restore")
        FileUtils.rm_rf(archive_path)
        FileUtils.mkdir_p(archive_path)

        puts "Decompressing #{archive_file.basename} to #{archive_path.basename}...".yellow if verbose

        system "unzip -d #{archive_path} #{archive_file} > /dev/null"

        puts 'Checking archive...'.yellow if verbose
        if !archive_path.join('manifest.yml').exist?
          raise 'Cannot not handle this archive'
        else
          manifest = YAML.load_file(archive_path.join('manifest.yml')).symbolize_keys
          # Bugfix
          if manifest[:tenant] == 'Ekylibre::Tenant'
            Dir.chdir(archive_path) do
              f = Dir.glob('*.sql').first
              manifest[:tenant] = f.gsub('.sql', '') if f
            end
          end
          unless name = options[:tenant] || manifest[:tenant]
            raise 'No given name for the tenant'
          end

          format_version = manifest[:format_version].to_s
          if format_version == '3'
            restore_v3(archive_path, name, options.merge(dump_file: archive_path.join("#{manifest[:tenant]}.sql")))
          elsif ['2.0', '2'].include? format_version
            restore_v2(archive_path, name, options)
          else
            raise "Cannot handle this version of archive: #{format_version.inspect}"
          end
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
          raise TenantError.new('No default tenant')
        else
          switch!(list.first)
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

      def filter_list!
        filtered_list = list.select do |tenant|
          begin
            Ekylibre::Tenant.switch(tenant) { true }
          rescue Apartment::TenantNotFound
            nil
          end
        end
        @list[env] = filtered_list
        write
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
          Ekylibre::Tenant.switch! tenant
          migration_version = ActiveRecord::Migrator.current_version

          next if migration_version.nonzero?

          tenants << { name: tenant, version: migration_version }
        end

        tenants
      end

      def correct_tenants_with_migration_problem!
        tenants = list_tenants_with_migration_problem

        tenants.each do |tenant|
          Ekylibre::Tenant.switch! tenant[:name]

          connection = ActiveRecord::Base.connection
          connection.execute('INSERT INTO schema_migrations SELECT * FROM public.schema_migrations')

          puts (tenant[:name] + ' : done').yellow
        end

        load!

        puts 'Task done'.blue
      end

      def list_tenant_with_table_not_exist(table_name)
        tenants = []

        list.each do |tenant|
          Ekylibre::Tenant.switch! tenant

          connection = ActiveRecord::Base.connection
          result = connection.execute(
            "SELECT EXISTS(
              SELECT 1
              FROM information_schema.tables
              WHERE table_schema = current_schema()
              AND table_name = '#{table_name}'
            )"
          ).to_a

          next if result.first.value?('t')

          migration_version = ActiveRecord::Migrator.current_version
          tenants << { name: tenant, migration_version: migration_version }
        end

        tenants
      end

      def remove_last_migration_and_migrate!(tenant_name)
        Ekylibre::Tenant.switch! tenant_name

        ActiveRecord::Base.connection.execute(
          "DELETE FROM schema_migrations
           WHERE version IN (
              SELECT version
              FROM schema_migrations
              ORDER BY version DESC
              LIMIT 1
          )"
        )

        ActiveRecord::Migrator.migrate 'db/migrate'

        load!
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
          file = config_file
          # byebug
          semaphore.synchronize do
            FileUtils.mkdir_p(file.dirname)

            # byebug

            temp = File.open(file, 'w')
            temp.write @list.to_yaml
            temp.flush
            temp.close

            # byebug
            # File.write(config_file, @list.to_yaml)
          end
        end

        def semaphore
          @@semaphore ||= Mutex.new
        end

        def dump_v2(name, options = {})
          dump_archive(name, options) { |opt| dump_tables_v2(opt[:tables_path]) }
        end

        def restore_v2(archive_path, name, options = {})
          restore_dump(archive_path, name, options) do |data_options|
            data_options = data_options.dup
            tenant_name = data_options.delete(:tenant_name)
            Fixturing.restore(tenant_name, **data_options)
          end
        end

        def dump_v3(name, options = {})
          dump_archive(name, options) { |opt| dump_tables_v3(opt) }
        end

        def restore_v3(archive_path, name, options = {})
          restore_dump(archive_path, name, options) do |opt|
            tenant_name = opt[:tenant_name]
            restore_tables_v3(opt)
            Fixturing.migrate(tenant_name, origin: opt[:version])
          end
        end

        def dump_archive(name, options = {})
          destination_path = options.delete(:path) || Rails.root.join('tmp', 'archives')
          switch(name) do
            archive_file = destination_path.join("#{name}.zip")
            archive_path = destination_path.join("#{name}-dump")
            tables_path = archive_path.join('tables')
            files_path = archive_path.join('files')

            FileUtils.rm_rf(archive_path)
            FileUtils.mkdir_p(archive_path)

            dump_options = options.merge(archive_path: archive_path,
                                         tenant_name: name,
                                         tables_path: tables_path)
            version = yield(dump_options)

            dump_files(files_path)
            dump_mimetype(archive_path)
            dump_manifest(archive_path, version, name, options)

            FileUtils.rm_rf(archive_file)
            zip_up(archive_path, into: archive_file)
            FileUtils.rm_rf(archive_path)
          end
        end

        def restore_dump(archive_path, name, options = {})
          start = Time.current

          tables_path = archive_path.join('tables')
          files_path = archive_path.join('files')

          manifest = YAML.load_file(archive_path.join('manifest.yml')).symbolize_keys

          database_version = manifest[:database_version].to_i
          if database_version > ActiveRecord::Migrator.last_migration.version
            raise 'Too recent archive'
          end

          verbose = !options[:verbose].is_a?(FalseClass)
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
            restore_options = options.merge(
              tenant_name: name,
              version: database_version,
              path: tables_path,
              verbose: verbose
            )
            yield(restore_options)
            puts 'Restored!'.yellow if verbose
          end

          duration = Time.current - start
          puts "Done! (#{duration.round(2)}s)".yellow if verbose
        end

        def dump_mimetype(archive_path)
          File.open(archive_path.join('mimetype'), 'wb') do |f|
            f.write 'application/vnd.ekylibre.tenant.archive'
          end
        end

        def dump_manifest(archive_path, version, name, options = {})
          File.open(archive_path.join('manifest.yml'), 'wb') do |f|
            options.update(
              tenant: name,
              format_version: 3,
              database_version: version,
              creation_at: Time.zone.now,
              created_with: "Ekylibre #{Ekylibre::VERSION}".strip
            )
            f.write options.stringify_keys.to_yaml
          end
        end

        def dump_files(files_path)
          return unless private_directory.exist?

          FileUtils.mkdir_p(files_path.dirname)
          FileUtils.cp_r(private_directory.to_s, files_path.to_s)
        end

        def dump_tables_v2(options)
          tables_path = options[:tables_path]
          FileUtils.mkdir_p(tables_path)
          Fixturing.extract(path: tables_path)
        end

        def dump_tables_v3(options)
          path = options[:archive_path]
          tenant = options[:tenant_name]
          Dir.chdir path do
            sh("pg_dump -n #{tenant} -x -O --dbname=#{db_url} > #{tenant}.sql")
            sh("sed -i'' -e '/^CREATE SCHEMA/d' #{tenant}.sql")
            sh("sed -i'' -e '/^SET search_path = /d' #{tenant}.sql")
          end
          ActiveRecord::Migrator.current_version
        end

        def restore_tables_v3(options)
          path = options[:path]
          tenant_name = options[:tenant_name]

          # DROP/CREATE
          sh("echo 'SET client_min_messages TO WARNING; DROP SCHEMA IF EXISTS \"#{tenant_name}\" CASCADE; SET client_min_messages TO NOTICE;' | psql --dbname=#{db_url}")
          sh("echo 'CREATE SCHEMA \"#{tenant_name}\";' | psql --dbname=#{db_url}")

          # Prepend SET search_path to sql
          sh("echo 'SET search_path = \"#{tenant_name}\", postgis, lexicon, pg_catalog;' | cat - #{Shellwords.escape(options[:dump_file].to_s)} | psql --dbname=#{db_url}")
        end

        def sh(command)
          system(command)
        end

        def db_url
          user     = db_config['username']
          host     = db_config['host']
          port     = db_config['port'] || '5432'
          dbname   = db_config['database']
          password = db_config['password']
          Shellwords.escape("postgresql://#{user}:#{password}@#{host}:#{port}/#{dbname}")
        end

        def db_config
          Rails.application.config.database_configuration[Rails.env.to_s]
        end

        def zip_up(archive_path, into:)
          Zip::File.open(into, Zip::File::CREATE) do |zile|
            Dir.chdir archive_path do
              Dir.glob('**/*').each do |path|
                zile.add(path, archive_path.join(path))
              end
            end
          end
        end
    end
  end
end
