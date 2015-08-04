module Calculus
  module ManureManagementPlan
    class Method
      def initialize(options = {})
        @options        = options
        @variety        = options[:variety]
        @support        = options[:support]
        @opened_at      = options[:opened_at]
        @usage          = options[:production_usage]
        @soil_nature    = options[:soil_nature]
        @cultivation    = options[:cultivation]
        @expected_yield = options[:expected_yield] || 0.0.in_kilogram_per_square_meter
      end

      delegate :activity, to: :production

      delegate :campaign, to: :production

      def production
        @support.production
      end

      def soil_natures
        @soil_natures ||= (@options[:soil_nature] ? @options[:soil_nature].self_and_parents : [:undefined])
      end

      # Returns matching crop set for the given variety
      def crop_sets
        return [] unless @variety
        @crop_sets ||= Nomen::CropSets.list.select do |i|
          i.varieties.detect do |v|
            @variety <= v
          end
        end
        @crop_sets
      end

      def estimate_expected_yield
        fail NotImplemented
      end

      def compute
        fail NotImplemented
      end
    end
  end
end
