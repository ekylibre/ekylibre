require 'apartment'
require 'ekylibre/schema'

module Ekylibre

  class TenantError < StandardError
  end

  class Tenant

    AGGREGATION_NAME = "__all__"

    class << self

      # Tests existence of a tenant
      def exist?(name)
        list.include?(name)
      end


      # Tests existence of a tenant in DB
      # and removes it if not exist
      def check!(name, options = {})
        if list.include?(name)
          unless Apartment.connection.schema_exists? name
            drop(name, options)
          end
        end
      end

      # Returns the current tenant
      def current
        unless name = Apartment::Tenant.current
          raise TenantError, "No current tenant"
        end
        return name
      end

      # Returns the private directory of the current tenant
      # If tenant name given, it returns its private_directory
      def private_directory(name = nil)
        Ekylibre.root.join("private", name || current)
      end

      # Create a new tenant with tables and co
      def create(name)
        name = name.to_s
        check!(name)
        if exist?(name)
          raise TenantError, "Already existing tenant"
        end
        Apartment::Tenant.create(name)
        add(name)
      end

      # Adds a tenant in config. No schema are created.
      def add(name)
        unless list.include?(name)
          list << name
        end
        write
      end

      # Add a tenant in config without creating it
      # Nothing is done if already exist
      def setup!(name, options = {})
        check!(name, options)
        unless exist?(name)
          create(name)
        end
        switch!(name)
      end

      # Drop tenant
      def drop(name, options = {})
        name = name.to_s
        unless exist?(name)
          raise TenantError, "Unexistent tenant: #{name}"
        end
        if Apartment.connection.schema_exists? name
          Apartment::Tenant.drop(name)
        end
        unless options[:keep_files]
          FileUtils.rm_rf private_directory(name)
        end
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
        unless exist?(old)
          raise TenantError, "Unexistent tenant: #{name}"
        end
        ActiveRecord::Base.connection.execute("ALTER SCHEMA #{old.to_s.inspect} RENAME TO #{new.to_s.inspect};")
        @list[env].delete(old.to_s)
        @list[env] << new.to_s
      end

      # Change current tenant
      def switch(name, &block)
        raise "Need block to use Ekylibre::Tenant.switch" unless block_given?
        Apartment::Tenant.switch(name, &block)
      end

      def switch!(name)
        Apartment::Tenant.switch!(name)
      end

      alias :current= :switch!

      def switch_default!
        if list.empty?
          raise TenantError, "No default tenant"
        else
          Apartment::Tenant.switch!(list.first)
        end
      end

      # Browse all tenant to make actions on it
      def switch_each(&block)
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
        unless @list
          @list = (File.exist?(config_file) ? YAML.load_file(config_file) : {})
          @list ||= {}
        end
        @list[env] ||= []
        return @list[env]
      end

      def drop_aggregation_schema!
        ActiveRecord::Base.connection.execute("CREATE SCHEMA IF NOT EXISTS #{AGGREGATION_NAME};")
      end

      def create_aggregation_schema!
        create_aggregation_views_schema!
      end

      def create_aggregation_views_schema!
        if list.empty?
          raise "No tenant to build an aggregation schema"
        end
        name = AGGREGATION_NAME
        connection = ActiveRecord::Base.connection
        connection.execute("CREATE SCHEMA IF NOT EXISTS #{name};")
        for table in Ekylibre::Schema.tables.keys
          connection.execute "DROP VIEW IF EXISTS #{name}.#{table}"
          columns = Ekylibre::Schema.columns(table)
          queries = list.collect do |tenant|
            "SELECT '#{tenant}' AS tenant_name, " + columns.collect{|c| c[:name] }.join(", ") + " FROM #{tenant}.#{table}"
          end
          query = "CREATE VIEW #{name}.#{table} AS " + queries.join(" UNION ALL ")
          connection.execute(query)
        end
      end

      def reset_search_path!
        ActiveRecord::Base.connection.schema_search_path = Ekylibre::Application.config.database_configuration[::Rails.env]["schema_search_path"]
      end

      private

      def config_file
        Rails.root.join("config", "tenants.yml")
      end

      # Return the env
      def env
        Rails.env.to_s
      end

      def write
        FileUtils.mkdir_p(config_file.dirname)
        File.write(config_file, @list.to_yaml)
      end

    end

  end

end
