module Interventions
  module Phytosanitary
    module Models
      class ProductApplicationResult
        attr_reader :votes

        def initialize(votes = {})
          @votes = votes
        end

        def product_messages(product)
          @votes
            .fetch(product, [])
            .map(&:message)
            .compact
        end

        def product_vote(product)
          @votes
            .fetch(product, [])
            .reduce(:allowed) { |acc, v| Models::ProductApplicationVote.vote_reducer(acc, v.vote) }
        end

        # @param [Array<Result>] others
        # @return [Result]
        def merge_all(*others)
          others.reduce(self) { |acc, other| acc.merge(other) }
        end

        # @param [ProductApplicationResult] other
        # @return [ProductApplicationResult]
        def merge(other)
          ProductApplicationResult.new(votes.deep_merge(other.votes) { |_key, votes, other_votes| votes + other_votes })
        end

        # @param [Product] product
        # @param [String] message
        def vote_forbidden(product, message = nil)
          add_vote(product, status: :forbidden, message: message)
        end

        # @param [Product] product
        def vote_unknown(product)
          add_vote(product, status: :unknown)
        end

        # @param [Product] product
        # @option [Symbol] status
        # @option [String] message
        def add_vote(product, status:, message: nil)
          vote = Models::ProductApplicationVote.new(status, message)

          if votes.key?(product)
            votes[product] << vote
          else
            votes[product] = [vote]
          end
        end
      end
    end
  end
end
