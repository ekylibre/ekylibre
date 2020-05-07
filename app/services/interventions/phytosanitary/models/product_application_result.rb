module Interventions
  module Phytosanitary
    module Models
      class ProductApplicationResult
        # @var [Hash{Product => Array<Models::ProductApplicationVote>}] votes
        attr_reader :votes

        def initialize(votes = {})
          @votes = votes
        end

        # @param [Product] product
        # @return [Array<String>]
        def product_messages(product)
          product_grouped_messages(product).values.flatten
        end

        # @param [Product] product
        # @return [Hash{Symbol => Array<String>}]
        def product_grouped_messages(product)
          @votes
            .fetch(product, [])
            .group_by(&:field)
            .transform_values { |v| v.map(&:message).compact }
        end

        # @param [Product] product
        # @return [Symbol]
        def product_vote(product)
          @votes
            .fetch(product, [])
            .reduce(:allowed) { |acc, v| Models::ProductApplicationVote.vote_reducer(acc, v.vote) }
        end

        # @param [Array<Result>] others
        # @return [ProductApplicationResult]
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
        # @option [Symbol, nil] on
        def vote_forbidden(product, message = nil, on: nil)
          add_vote(product, status: :forbidden, message: message, on: on)
        end

        # @param [Product] product
        def vote_unknown(product)
          add_vote(product, status: :unknown)
        end

        # @param [Product] product
        # @option [Symbol] status
        # @option [String] message
        # @option [Symbol, nil] on
        def add_vote(product, status:, message: nil, on: nil)
          vote = Models::ProductApplicationVote.new(status, message, on || :product)

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
