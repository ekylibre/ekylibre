# frozen_string_literal: true

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
        @build_name = NamingFormats::LandParcels::BuildNamingService.new(activity_production: @activity_production).perform
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
    end
  end
end
