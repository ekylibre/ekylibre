# frozen_string_literal: true

module Isagri
  module Geofolia
    class LandParcelsExchanger < ActiveExchanger::Base
      category :plant_farming
      vendor :isagri

      def import
        # Unzip file
        dir = w.tmp_dir
        path_to_get = nil
        Zip::File.open(file) do |zile|
          zile.each do |entry|
            path_to_get = entry.name.split('.').first
            entry.extract(dir.join(entry.name))
          end
        end

        RGeo::Shapefile::Reader.open(dir.join("#{path_to_get}.shp").to_s, srid: 2154) do |file|
          # Set number of shapes
          w.count = file.size

          file.each do |record|
            if record.geometry

              # build attrs
              cz_name = record.attributes['NOM_PARCEL']
              work_number = record.attributes['COD_PARCEL'].to_s
              cz_work_number = record.attributes['NUM_ILOT'].to_s + '_' + work_number
              uuid = record.attributes['GUID_PARC']
              insee_code = record.attributes['CODE_INSEE']
              net_surface_area = record.attributes['SURFACE'].to_d.in(:hectare)
              campaign_harvest_year = record.attributes['CAMPAGNE'].to_i
              shape = Charta.new_geometry(record.geometry).transform(:WGS84)
              activity_name = record.attributes['CP_CULTU']
              activity_edi_code = record.attributes['CP_CODCULT']
              variety = record.attributes['VARIETE']
              sowed_on = Date.parse(record.attributes['DATE_SEMIS'].to_s) if record.attributes['DATE_SEMIS'].present?
              harvested_on = Date.parse(record.attributes['DATE_RECOL'].to_s) if record.attributes['DATE_RECOL'].present?

              attrs = {
                uuid: uuid,
                cz_name: cz_name,
                cz_work_number: cz_work_number,
                campaign: Campaign.of(campaign_harvest_year),
                activity_name: activity_name,
                activity_edi_code: activity_edi_code[0, 3],
                number: work_number,
                net_surface_area: net_surface_area,
                shape: shape
              }

              # find or create cultivable zone
              cultivable_zone = find_cultivable_zone(shape).first
              cultivable_zone ||= create_cz_from_attrs(attrs)

              # find or create activity
              activity = find_or_create_activity(attrs)

              # find or create activity_production
              if activity.present? && cultivable_zone.present?
                production = find_or_create_activity_production(attrs, cultivable_zone, activity)
              else
                w.info 'No activity found'
              end
            end

            w.check_point
          end
        end

        true
      end

      def find_or_create_activity_production(attrs, cultivable_zone, activity)
        ap = ActivityProduction.of_provider_name(self.class.vendor, provider_name)
                   .of_provider_data(:uuid, attrs[:uuid])
        if ap.any?
          ap.first
        else
          attributes = { cultivable_zone: cultivable_zone, support_shape: attrs[:shape] }
          attributes[:campaign_id] = attrs[:campaign].id if activity.annual?
          attributes[:provider] = provider_value(uuid: attrs[:uuid])
          ap = activity.productions.create!(
            ActivityProductions::DefaultAttributesValueBuilder.new(activity, attrs[:campaign]).build.merge(attributes)
          )
        end
      end

      def find_or_create_activity(attrs)
        return nil if attrs[:activity_edi_code] == '000'

        lexicon_production_nature = MasterProduction.where(agroedi_crop_code: attrs[:activity_edi_code]).first

        unless lexicon_production_nature.present?
          lexicon_production_nature = MasterProduction.find_by(reference_name: 'crop_production')
        end

        # find annual or perennial activity
        if lexicon_production_nature.life_duration.present? && lexicon_production_nature.life_duration.parts[:years].to_d > 1.0
          production_cycle = :perennial
        else
          production_cycle = :annual
        end

        family_found = Activity.find_best_family(lexicon_production_nature.specie)

        attributes = {
          cultivation_variety: lexicon_production_nature.specie,
          name: attrs[:activity_name],
          reference_name: lexicon_production_nature.reference_name,
          production_system_name: "intensive_farming",
          support_variety: :land_parcel,
        }

        activity = Activity.find_by(attributes)
        activity ||= Activity.find_by(name: attributes[:name])

        if activity.nil?
          attributes.update(
            family: family_found.name,
            nature: :main,
            production_cycle: production_cycle,
            size_indicator: 'net_surface_area',
            size_unit: 'hectare',
            with_cultivation: true,
            with_supports: true,
            life_duration: lexicon_production_nature.life_duration&.parts&.fetch(:years),
            start_state_of_production_year: production_cycle == :perennial ? 2 : nil,
            production_started_on: lexicon_production_nature.started_on.change(year: 2000),
            production_stopped_on: lexicon_production_nature.stopped_on.change(year: 2000),
            production_started_on_year: lexicon_production_nature.started_on_year,
            production_stopped_on_year: lexicon_production_nature.stopped_on_year
          )

          activity = Activity.create!(attributes)
        end
        activity.budgets.find_or_create_by!(campaign: attrs[:campaign])
        activity
      end

      def find_cultivable_zone(shape)
        # check if current cluster cover or overlap an existing cultivable zone
        shapes_over_zone = CultivableZone.shape_covering(shape, 0.02)
        return shapes_over_zone if shapes_over_zone.any?

        CultivableZone.shape_matching(shape, 0.02)
      end

      def create_cz_from_attrs(attrs)
        cz = CultivableZone.find_by(uuid: attrs[:uuid])
        cz ||= CultivableZone.create!(
          name: attrs[:cz_name],
          uuid: attrs[:uuid],
          work_number: attrs[:cz_work_number],
          shape: attrs[:shape],
          provider: provider_value(uuid: attrs[:uuid])
        )
        cz
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
          :geofolia_land_parcels
        end

    end
  end
end
