# frozen_string_literal: true

class Shipment
  module Transitions
    class Prepare < Transitionable::Transition
      event :prepare
      from :draft, :ordered
      to :in_preparation

      def transition
        resource.state = :in_preparation
        resource.save!
      end

      # Mirrors the `if: :any_items?` guard the state_machine event carried.
      def can_run?
        super && resource.any_items?
      end
    end
  end
end
