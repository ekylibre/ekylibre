# frozen_string_literal: true

class SaleOpportunity
  module Transitions
    class Lose < Transitionable::Transition
      event :lose
      # The state_machine event used `transition all => :lost`, so every state
      # is a valid source, including the destination itself.
      from :prospecting, :qualification, :value_proposition, :price_quote, :negociation, :won, :lost
      to :lost

      def transition
        resource.state = :lost
        resource.save!
      end
    end
  end
end
