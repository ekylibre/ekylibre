# frozen_string_literal: true

class SaleOpportunity
  module Transitions
    class Qualify < Transitionable::Transition
      event :qualify
      # The state_machine event used `transition all => :qualification`, so every state
      # is a valid source, including the destination itself.
      from :prospecting, :qualification, :value_proposition, :price_quote, :negociation, :won, :lost
      to :qualification

      def transition
        resource.state = :qualification
        resource.save!
      end
    end
  end
end
