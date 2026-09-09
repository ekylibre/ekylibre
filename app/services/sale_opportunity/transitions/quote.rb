# frozen_string_literal: true

class SaleOpportunity
  module Transitions
    class Quote < Transitionable::Transition
      event :quote
      # The state_machine event used `transition all => :price_quote`, so every state
      # is a valid source, including the destination itself.
      from :prospecting, :qualification, :value_proposition, :price_quote, :negociation, :won, :lost
      to :price_quote

      def transition
        resource.state = :price_quote
        resource.save!
      end
    end
  end
end
