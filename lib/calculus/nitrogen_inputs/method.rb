module Calculus
  module NitrogenInputs

    class Method
      attr_reader :zone, :crop_yield

      def initialize(zone, options = {})
        @zone = zone
        @options = options
      end

      def apply!
        set_crop_yield!
        calculate!
      end

      def set_crop_yield!
        raise NotImplementedError
      end

      def calculate!
        raise NotImplementedError
      end

    end

  end
end
