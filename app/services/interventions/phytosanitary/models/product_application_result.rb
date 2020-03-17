module Interventions
  module Phytosanitary
    module Models
      class ProductApplicationResult
        attr_reader :messages

        def initialize(result = 'allowed', messages = {})
          @result = result
          @messages = messages
        end

        def allowed?
          @result == 'allowed'
        end

        def forbidden?
          @result == 'forbidden'
        end

        # @param [Array<Result>] others
        # @return [Result]
        def merge_all(*others)
          others.reduce(self) { |acc, other| acc.merge(other) }
        end

        # @param [ProductApplicationResult] other
        # @return [ProductApplicationResult]
        def merge(other)
          ProductApplicationResult.new(nil, messages.deep_merge(other.messages) { |_key, messages, other_messages| messages + other_messages })
        end

        # @param [Product] product
        # @param [String] message
        def add_message(product, message)
          #TODO add message at the correct place
          if messages.key?(product)
            messages[product] << message
          else
            messages[product] = [message]
          end
        end
      end
    end
  end
end
