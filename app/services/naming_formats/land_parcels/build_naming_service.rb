module NamingFormats
  module LandParcels
    class BuildNamingService
      attr_reader :compute_name, :cultivable_zone, :activity, :campaign, :season

      def initialize(cultivable_zone: nil, activity: nil, campaign: nil, season: nil)
        @compute_name = []
        @cultivable_zone = cultivable_zone
        @activity = activity
        @campaign = campaign
        @season = season
      end

      def perform(field_values: [])
        field_values.each do |field_value|
          add_cultivable_zone(field_value) if field_value =~ /cultivable_zone/

          call_if_equal(field_value, :activity, method(:add_activity))
          call_if_equal(field_value, :campaign, method(:add_campaign))
          call_if_equal(field_value, :season, method(:add_season))
          call_if_equal(field_value, :production_mode, method(:add_production_system))
        end

        @compute_name.join(' ')
      end

      private

      def add_cultivable_zone(field_value)
        return if @cultivable_zone.nil?

        if field_value.to_sym == :cultivable_zone_name
          @compute_name << @cultivable_zone.name
        end

        if field_value.to_sym == :cultivable_zone_code
          @compute_name << @cultivable_zone.work_number
        end
      end

      def add_activity
        return if @activity.nil?

        @compute_name << @activity.name
      end

      def add_campaign
        return if @campaign.nil? || @campaign.name.blank?

        @compute_name << @campaign.name
      end

      def add_season
        return if @season.nil? || @season.name.blank?

        @compute_name << @season.name
      end

      def add_production_system
        return if @activity.nil? || @activity.production_system_name.blank?

        @compute_name << @activity.human_production_system_name
      end

      def call_if_equal(field_value, format_field_name, method_callback)
        method_callback.call if field_value.to_sym == format_field_name
      end
    end
  end
end
