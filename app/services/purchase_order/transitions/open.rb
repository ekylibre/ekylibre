# frozen_string_literal: true

class PurchaseOrder
  module Transitions
    class Open < Transitionable::Transition
      event :open
      # The state_machine event used `transition all => :opened`, so every
      # state is a valid source — including :opened itself.
      from :opened, :closed
      to :opened

      def transition
        resource.state = :opened
        resource.save!
      end
    end
  end
end
