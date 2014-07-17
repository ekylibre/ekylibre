module Ekylibre
  module FirstRun

    class Counter
      attr_reader :count

      def initialize(max = -1)
        @count = 0
        @max = max
      end

      def check_point(increment = 1)
        @count += increment
        print "." if (@count - increment).to_i != @count.to_i
        if @max > 0
          raise CountExceeded if @count >= @max
        end
      end
    end

  end
end
