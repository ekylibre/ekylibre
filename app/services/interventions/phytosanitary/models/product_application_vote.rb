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

        attr_reader :message, :vote

        def initialize(vote, message)
          @vote = vote
          @message = message
        end
      end
    end
  end
end