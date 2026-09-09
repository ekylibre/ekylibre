# frozen_string_literal: true

class Contract
  module Transitions
    class Win < Transitionable::Transition
      event :win
      # The state_machine event used `transition all => :won`, so every state
      # is a valid source, including the destination itself.
      from :prospecting, :price_quote, :negociation, :won, :lost
      to :won

      def transition
        resource.state = :won
        resource.save!
      end
    end
  end
end
