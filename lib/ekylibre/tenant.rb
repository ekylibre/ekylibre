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
