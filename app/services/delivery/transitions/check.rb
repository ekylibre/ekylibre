# frozen_string_literal: true

class Delivery
  module Transitions
    class Check < Transitionable::Transition
      event :check
      from :in_preparation
      to :prepared

      def transition
        resource.state = :prepared
        resource.save!
      end

      # Mirrors the `if: :all_parcels_almost_prepared?` guard the state_machine event carried.
      def can_run?
        super && resource.all_parcels_almost_prepared?
      end
    end
  end
end
