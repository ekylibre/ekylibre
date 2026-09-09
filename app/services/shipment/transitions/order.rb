# frozen_string_literal: true

class Shipment
  module Transitions
    class Order < Transitionable::Transition
      event :order
      from :draft
      to :ordered

      def transition
        resource.state = :ordered
        resource.save!
      end

      # Mirrors the `if: :any_items?` guard the state_machine event carried.
      def can_run?
        super && resource.any_items?
      end
    end
  end
end
