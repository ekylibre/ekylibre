module Interventions
  module Phytosanitary
    module Models
      class ProductApplicationVote
        class << self
          def vote_reducer(first, second)
            if first == :forbidden || second == :forbidden
              :forbidden
            elsif first == :unknown || second == :unknown
              :unknown
            else
              :allowed
            end
          end
        end

        attr_reader :message, :vote, :field

        def initialize(vote, message, field)
          @vote = vote
          @message = message
          @field = field
        end
      end
    end
  end
end