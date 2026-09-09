# frozen_string_literal: true

class Sale
  module Transitions
    class Confirm < Transitionable::Transition
      event :confirm
      from :estimate
      to :order

      def transition
        resource.state = :order
        resource.save!
      end

      # Mirrors the `if: :has_content?` guard the state_machine event carried.
      def can_run?
        super && resource.has_content?
      end
    end
  end
end
