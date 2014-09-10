module Ekylibre

  class Tenant

    class << self

      def exist?(name)
        list.include?(name)
      end

      def create(name)
        name = name.to_s
        if exist?(name)
          raise StandardError, "Already existing tenant"
        end
        Apartment::Tenant.create(name)
        @list << name
        write
      end

      def drop(name)
        name = name.to_s
        unless exist?(name)
          raise StandardError, "Unexistent tenant: #{name}"
        end
        Apartment::Tenant.drop(name)
        @list.delete(name)
        write
      end

      def switch(name)
        Apartment::Tenant.switch(name)
      end

      def switch_default!
        if list.empty?
          raise StandardError, "No default tenant"
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
