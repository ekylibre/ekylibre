# frozen_string_literal: true

class Sale
  module Transitions
    class Invoice < Transitionable::Transition
      event :invoice
      from :draft, :estimate, :order
      to :invoice

      def transition
        resource.state = :invoice
        resource.save!
      end

      # Mirrors the `if: :has_content?` guard the state_machine event carried.
      def can_run?
        super && resource.has_content?
      end
    end
  end
end
