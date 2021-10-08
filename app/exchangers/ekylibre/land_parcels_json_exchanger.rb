# frozen_string_literal: true

module Ekylibre
  # Import a GeoJSON file (as FeatureCollection) with `name` and `number`
  # properties for each feature.
  class LandParcelsJsonExchanger < ActiveExchanger::Base
    category :plant_farming
    vendor :ekylibre

    # def check
    #   valid = true
    #   clusters = JSON.parse(file.read).deep_symbolize_keys
    #   unless clusters[:type] == 'FeatureCollection'
    #     w.error 'Invalid format'
    #     valid = false
    #   end
    #   valid
    # end

    def import
      clusters = JSON.parse(file.read)
      ensure_clusters_valid_geojson(clusters)
      clusters['features'].each do |feature|
        shape = ::Charta.from_geojson(feature)
        properties = feature['properties']
        next unless properties["activity_id"]

        activity = Activity.where("(codes ->> 'hajimari_id') = ?", properties["activity_id"]).first
        current_year = Time.zone.now.year
        current_year += 1 if Time.zone.now >= Time.new(Time.zone.now.year, 10, 1)
        campaign = Campaign.of(current_year)

        activity.budgets.find_or_create_by!(campaign: campaign)

        cultivable_zone = find_cultivable_zone(shape).first
        attributes = { cultivable_zone: cultivable_zone, support_shape: shape }
        attributes[:campaign_id] = campaign.id if activity.annual?

        activity.productions.create!(
          ActivityProductions::DefaultAttributesValueBuilder.new(activity, campaign).build.merge(attributes)
        )
      end
    end

    private

      def ensure_clusters_valid_geojson(clusters)
        raise ActiveExchanger::NotWellFormedFileError.new('File seems to be JSON but not GeoJSON.') if clusters['type'] != 'FeatureCollection'
      end

      def find_cultivable_zone(shape)
        # check if current cluster cover or overlap an existing cultivable zone
        shapes_over_zone = CultivableZone.shape_covering(shape, 0.02)
        return shapes_over_zone if shapes_over_zone.any?

        CultivableZone.shape_matching(shape, 0.02)
      end
  end
end
