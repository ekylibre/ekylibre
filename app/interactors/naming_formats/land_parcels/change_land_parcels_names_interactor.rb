module NamingFormats
  module LandParcels
    class ChangeLandParcelsNamesInteractor
      def self.call
        interactor = new
        interactor.run
        interactor
      end

      attr_reader :error

      def initialize
        @error = []
      end

      def run
        change_land_parcels_name
      rescue StandardError => exception
        fail!(exception.message)
      end

      def success?
        @error.empty?
      end

      def fail?
        @error.any?
      end

      private

      def fail!(error)
        @error << error
      end

      def change_land_parcels_name
        LandParcel.all.each do |land_parcel|
          interactor = NamingFormats::LandParcels::BuildActivityProductionNameInteractor
                       .call(activity_production: land_parcel.activity_production)

          land_parcel.update_attribute(:name, interactor.build_name) if interactor.success?
          fail!(interactor.error) if interactor.fail?
        end
      end
    end
  end
end
