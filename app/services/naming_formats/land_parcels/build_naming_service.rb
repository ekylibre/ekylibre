# frozen_string_literal: true

module NamingFormats
  module LandParcels
    class BuildNamingService
      attr_reader :compute_name, :activity_production

      def initialize(activity_production: nil, field_values: nil)
        @activity_production = activity_production
        @compute_name = []
        @cultivable_zone = @activity_production.cultivable_zone
        @activity = @activity_production.activity
        @campaign = @activity_production.campaign if @activity_production.campaign
        @season = @activity_production.season if @activity_production.season
        @free_field = @activity_production.custom_name if @activity_production.custom_name
        @activity_rank_number = @activity_production.rank_number
        @cultivable_zone_rank_number = @activity_production.cultivable_zone_rank_number
        if NamingFormatLandParcel.any?
          @field_values = field_values || NamingFormatLandParcel.last.fields.map(&:field_name)
        else
          NamingFormatLandParcel.load_defaults
          @field_values = field_values || NamingFormatLandParcel.last.fields.map(&:field_name)
        end
      end

      def perform
        @field_values.each do |field_value|
          add_cultivable_zone(field_value) if field_value =~ /cultivable_zone/

          call_if_equal(field_value, :activity, method(:add_activity))
          call_if_equal(field_value, :activity_rank_number, method(:add_activity_rank_number))
          call_if_equal(field_value, :cultivable_zone_rank_number, method(:add_cultivable_zone_rank_number))
          add_campaign(field_value) if field_value =~ /campaign/
          call_if_equal(field_value, :season, method(:add_season))
          call_if_equal(field_value, :production_mode, method(:add_production_system))
          call_if_equal(field_value, :free_field, method(:add_free_field))
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

        def add_activity_rank_number
          return if @activity_rank_number.nil?

          @compute_name << @activity_rank_number
        end

        def add_cultivable_zone_rank_number
          return if @cultivable_zone_rank_number.nil?

          @compute_name << @cultivable_zone_rank_number
        end

        def add_campaign(field_value)
          return if @campaign.nil? || @campaign.name.blank?

          if field_value.to_sym == :campaign
            @compute_name << @campaign.name
          end

          if field_value.to_sym == :campaign_short_year
            return if @campaign.harvest_year.nil?

            @compute_name << @campaign.harvest_year.to_s[2..4]
          end
        end

        def add_season
          return if @season.nil? || @season.name.blank?

          @compute_name << @season.name
        end

        def add_production_system
          return if @activity.nil? || @activity.production_system_name.blank?

          @compute_name << @activity.human_production_system_name
        end

        def add_free_field
          return if @free_field.blank?

          @compute_name << @free_field
        end

        def call_if_equal(field_value, format_field_name, method_callback)
          method_callback.call if field_value.to_sym == format_field_name
        end
    end
  end
end
