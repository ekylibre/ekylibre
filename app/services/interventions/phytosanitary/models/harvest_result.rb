module Interventions
  module Phytosanitary
    module Models
      class HarvestResult
        attr_reader :possible, :period

        # @param [Boolean] possible
        # @param [Period] period
        def initialize(possible, period = nil)
          @possible = possible
          @period = period
        end

        def period_duration
          period.duration
        end

        def next_possible_date
          if period.duration == 8.hours
            period.end_date - 2.hours
          else
            period.end_date
          end
        end
      end
    end
  end
end
