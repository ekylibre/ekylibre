# frozen_string_literal: true

class Contract
  module Transitions
    class Negociate < Transitionable::Transition
      event :negociate
      # The state_machine event used `transition all => :negociation`, so every state
      # is a valid source, including the destination itself.
      from :prospecting, :price_quote, :negociation, :won, :lost
      to :negociation

      def transition
        resource.state = :negociation
        resource.save!
      end
    end
  end
end
