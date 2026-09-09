# frozen_string_literal: true

class Shipment
  module Transitions
    class Check < Transitionable::Transition
      event :check
      from :draft, :ordered, :in_preparation
      to :prepared

      def transition
        resource.state = :prepared
        resource.save!
      end

      # Mirrors the `if: :all_items_prepared?` guard the state_machine event carried.
      def can_run?
        super && resource.all_items_prepared?
      end
    end
  end
end
