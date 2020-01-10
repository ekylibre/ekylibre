module NamingFormats
  module LandParcels
    class BuildActivityProductionNameInteractor
      def self.call(activity_production: nil)
        interactor = new(activity_production)
        interactor.run
        interactor
      end

      attr_reader :build_name, :activity_production, :error

      def initialize(activity_production)
        @activity_production = activity_production
      end

      def run
        @build_name = NamingFormats::LandParcels::BuildNamingService
                      .new(cultivable_zone: @activity_production.cultivable_zone,
                           activity: @activity_production.activity,
                           campaign: @activity_production.campaign,
                           season: @activity_production.season)
                      .perform(field_values: naming_format_fields_names)

        rank_number = :rank.t(number: @activity_production.rank_number)
        @build_name.concat(" #{rank_number}")
      rescue StandardError => exception
        fail!(exception.message)
      end

      def success?
        @error.nil?
      end

      def fail?
        !@error.nil?
      end

      private

      def fail!(error)
        @error = error
      end

      def naming_format_fields_names
        NamingFormatLandParcel.last.fields.map(&:field_name)
      end
    end
  end
end
