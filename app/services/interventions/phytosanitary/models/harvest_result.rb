module Interventions
  module Phytosanitary
    module Models
      class HarvestResult
        attr_reader :possible, :next_possible_date

        # @param [Boolean] possible
        # @param [Date|nil] next_possible_date
        def initialize(possible, next_possible_date = nil)
          @possible = possible
          @next_possible_date = next_possible_date
        end
      end
    end
  end
end