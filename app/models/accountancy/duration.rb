module Accountancy
  class Duration
    class << self
      def diff(start, stop)
        safe_diff *([start, stop].sort)
      end

      private

        def safe_diff(start, stop)
          return 0 if start == stop

          year_diff = stop.year - start.year
          months_diff = stop.month - start.month

          day1 = [30, start.day].min
          day2 = [30, stop.day].min
          day_diff = day2 - day1

          year_diff * 12 * 30 + months_diff * 30 + day_diff
        end

    end
  end
end
