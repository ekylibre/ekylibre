module Calculus
  module NitrogenInputs

    class Method
      attr_reader :zone

      def initialize(zone, options = {})
        @zone = zone
        @options = options
        @crop_yield = @options.delete(:crop_yield)
        @crop_yield = @crop_yield[:value].to_d.in(@crop_yield[:unit]) rescue nil
      end

      def apply!
        raise NotImplementedError
      end

      def crop_yield
        raise NotImplementedError
      end

    end

  end
end
