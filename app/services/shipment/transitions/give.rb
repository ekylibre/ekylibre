# frozen_string_literal: true

class Shipment
  module Transitions
    class Give < Transitionable::Transition
      event :give
      from :draft, :ordered, :in_preparation, :prepared
      to :given

      def transition
        resource.state = :given
        resource.save!
      end

      # Mirrors the `if: :giveable?` guard the state_machine event carried.
      def can_run?
        super && resource.giveable?
      end
    end
  end
end
