module Ekylibre
  module FirstRun
    class Counter
      attr_reader :count

      class CountExceeded < StandardError
      end

      def initialize(maximum = 0, &block)
        @count = 0
        @maximum = maximum
        @block = block if block_given?
      end

      def check_point(increment = 1)
        @count += increment
        @block.call(@count, increment) if @block
        raise CountExceeded if @maximum > 0 && @count >= @maximum
      end
    end
  end
end
