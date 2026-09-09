# frozen_string_literal: true

class SaleOpportunity
  module Transitions
    class Win < Transitionable::Transition
      event :win
      # The state_machine event used `transition all => :won`, so every state
      # is a valid source, including the destination itself.
      from :prospecting, :qualification, :value_proposition, :price_quote, :negociation, :won, :lost
      to :won

      def transition
        resource.state = :won
        resource.save!
      end
    end
  end
end
