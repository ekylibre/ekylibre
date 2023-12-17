# frozen_string_literal: true

module Isagri
  module Geofolia
    class InterventionsExchanger < ActiveExchanger::Base
      category :plant_farming
      vendor :isagri

      def import
        # Unzip file (Action.Json / Field.Json)
        dir = w.tmp_dir
        Zip::File.open(file) do |zile|
          zile.each do |entry|
            entry.extract(dir.join(entry.name))
          end
        end

        # parse file
        data_file = File.read(dir.join("Field.Json").to_s)

        begin
          clusters = JSON.parse(data_file, quirks_mode: true)
          # import field
          puts clusters.inspect.green
          clusters['Fields'].each do |field|
            puts field['HarvestYear'].inspect.red
            puts field['Id'].inspect.green
          end
        rescue JSON::JSONError, ArgumentError => e
          puts e.to_s.inspect.red
        end
        true
      end

      protected

        # @return [Import]
        def import_resource
          @import_resource ||= Import.find(options[:import_id])
        end

        def provider_value(**data)
          { vendor: self.class.vendor, name: provider_name, id: import_resource.id, data: data }
        end

        def provider_name
          :geofolia_interventions
        end

    end
  end
end
