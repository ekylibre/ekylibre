# frozen_string_literal: true

module ProcessToWine
  # Import a KML file (as FeatureCollection)
  # properties for each feature.
  class ActivityProductionsKmlExchanger < ActiveExchanger::Base
    category :plant_farming
    vendor :process_to_wine

    def check
      # check if file is a valid XML
      Nokogiri::XML(File.open(file), &:noblanks)

      true
    end

    def import
      @year = Time.zone.now.year
      @lexicon_production_nature = MasterCropProduction.find_by(reference_name: 'vine')
      # import and parse file
      doc = Nokogiri::XML(File.open(file)) do |config|
        config.strict.nonet.noblanks
      end

      # find or create vine activity for current campaign
      activities = Activity.where(family: 'vine_farming')
      if activities.any?
        @activity = activities.first
        @activity.budgets.find_or_create_by!(campaign: Campaign.of(@year))
      else
        @activity = create_vine_activity
      end

      # find each place and create production / land parcel and plant
      doc.css("Placemark").each do |place|
        id = nil
        name = nil
        shape = nil
        place.css("Data").each do |data|
          if data.attribute('name').value == 'id' && data.at_css("value").present?
            id = data.at_css("value").text
          end
          if data.attribute('name').value == 'label' && data.at_css("value").present?
            name = data.at_css("value").text
          end
          if data.attribute('name').value == 'coords' && data.at_css("value").present?
            geom = data.at_css("value").text
            shape = ::Charta.new_geometry(geom, 4326).transform(:WGS84)
          end
        end
        find_or_create_production(id, name, shape) if id && name && shape
      end
      true
    end

    private

      def create_vine_activity
        activity = Activity.create!(
          cultivation_variety: @lexicon_production_nature.specie,
          name: @lexicon_production_nature.translation.send(Preference[:language]),
          reference_name: @lexicon_production_nature.reference_name,
          production_system_name: "intensive_farming",
          support_variety: :land_parcel,
          family: @lexicon_production_nature.activity_family,
          nature: :main,
          production_cycle: :perennial,
          size_indicator: 'net_surface_area',
          size_unit: 'hectare',
          with_cultivation: true,
          with_supports: true,
          life_duration: @lexicon_production_nature.life_duration&.parts&.fetch(:years),
          start_state_of_production_year: 2,
          production_started_on: @lexicon_production_nature.started_on.change(year: 2000),
          production_stopped_on: @lexicon_production_nature.stopped_on.change(year: 2000),
          production_started_on_year: @lexicon_production_nature.started_on_year,
          production_stopped_on_year: @lexicon_production_nature.stopped_on_year
        )
      end

      def find_or_create_production(id, name, shape)
        existing_importing_ap = find_ap_by_provider(id)
        return existing_importing_ap.first if existing_importing_ap.any?

        cz = find_or_create_cz(id, name, shape)
        campaign = Campaign.find_or_create_by!(harvest_year: @year)
        productions = @activity.productions.of_campaign(campaign).support_shape_matching(shape, 0.02)
        if productions.any?
          activity_production = productions.first
        else
          activity_production = @activity.productions.new(campaign: campaign)
          activity_production.custom_name = name
          activity_production.support_shape = shape
          activity_production.support_nature = :cultivation
          activity_production.cultivable_zone = cz
          activity_production.usage = @lexicon_production_nature.usage
          activity_production.reference_name = @lexicon_production_nature.reference_name
          activity_production.started_on = @lexicon_production_nature.start_on(@year)
          activity_production.provider = provider_value(land_parcel_id: id)
          activity_production.save!
        end
        activity_production
      end

      def find_or_create_cz(id, name, shape)
        existing_importing_cz = find_cz_by_provider(id)
        return existing_importing_cz.first if existing_importing_cz.any?

        cap_land_parcel_inside_cultivable_zone = CultivableZone.shape_covering(shape, 0.05)
        unless cap_land_parcel_inside_cultivable_zone.any?
          # info << "Overlaps!\n"
          cap_land_parcel_inside_cultivable_zone = CultivableZone.shape_matching(shape, 0.10)
          cap_land_parcel_inside_cultivable_zone ||= CultivableZone.shape_intersecting(shape, 0.02)
        end

        if cap_land_parcel_inside_cultivable_zone.any?
          # info << "Found\n"
          cultivable_zone = cap_land_parcel_inside_cultivable_zone.first
        else
          cultivable_zone = CultivableZone.create!(name: name, work_number: id, shape: shape, provider: provider_value(land_parcel_id: id))
        end
      end

      # @param [String]
      # @return [CultivableZone]
      def find_cz_by_provider(id)
        CultivableZone.of_provider_name(self.class.vendor, provider_name).of_provider_data(:land_parcel_id, id)
      end

      # @param [String]
      # @return [ActivityProduction]
      def find_ap_by_provider(id)
        ActivityProduction.of_provider_name(self.class.vendor, provider_name).of_provider_data(:land_parcel_id, id)
      end

      # @return [Import]
      def import_resource
        @import_resource ||= Import.find(options[:import_id])
      end

      def provider_value(**data)
        { vendor: self.class.vendor, name: provider_name, id: import_resource.id, data: data }
      end

      def provider_name
        :activity_production
      end

  end
end
