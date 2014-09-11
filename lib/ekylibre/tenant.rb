module Ekylibre

  class TenantError < StandardError
  end

  class Tenant

    class << self

      # Tests existence of a tenant
      def exist?(name)
        list.include?(name)
      end

      # Returns the current tenant
      def current
        unless name = Apartment::Tenant.current
          raise TenantError, "No current tenant"
        end
        return name
      end

      # Returns the private directory of the current tenant
      def private_directory
        Ekylibre.root.join("private", Tenant.current)
      end

      # Create a new tenant
      def create(name)
        name = name.to_s
        if exist?(name)
          raise TenantError, "Already existing tenant"
        end
        Apartment::Tenant.create(name)
        @list << name
        write
      end

      # Drop tenant
      def drop(name)
        name = name.to_s
        unless exist?(name)
          raise TenantError, "Unexistent tenant: #{name}"
        end
        Apartment::Tenant.drop(name)
        @list.delete(name)
        write
      end


      def switch(name)
        Apartment::Tenant.switch(name)
      end
      alias :current= :switch

      def switch_default!
        if list.empty?
          raise TenantError, "No default tenant"
        else
          Apartment::Tenant.switch(list.first)
        end
      end

      def clear!
        if File.exist?(config_file)
          FileUtils.rm(config_file)
        end
      end

      def list
        unless @list
          @list = (File.exist?(config_file) ? YAML.load_file(config_file) : [])
        end
        return @list
      end


      def build_aggregated_schema!(name = "__all__")
        build_aggregated_views_schema!(name)
      end

      def build_aggregated_views_schema!(name)
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

      private

      def config_file
        Rails.root.join("config", "tenants.yml")
      end

      def write
        File.write(config_file, @list.sort.to_yaml)
      end

    end

  end

end
