# frozen_string_literal: true

class SaleOpportunity
  module Transitions
    class Evaluate < Transitionable::Transition
      event :evaluate
      # The state_machine event used `transition all => :value_proposition`, so every state
      # is a valid source, including the destination itself.
      from :prospecting, :qualification, :value_proposition, :price_quote, :negociation, :won, :lost
      to :value_proposition

      def transition
        resource.state = :value_proposition
        resource.save!
      end
    end
  end
end
