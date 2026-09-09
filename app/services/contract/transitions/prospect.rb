# frozen_string_literal: true

class Contract
  module Transitions
    class Prospect < Transitionable::Transition
      event :prospect
      # The state_machine event used `transition all => :prospecting`, so every state
      # is a valid source, including the destination itself.
      from :prospecting, :price_quote, :negociation, :won, :lost
      to :prospecting

      def transition
        resource.state = :prospecting
        resource.save!
      end
    end
  end
end
