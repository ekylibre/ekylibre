# frozen_string_literal: true

class Delivery
  module Transitions
    class Start < Transitionable::Transition
      event :start
      from :in_preparation, :prepared
      to :started

      def transition
        resource.state = :started
        resource.save!
      end

      # Mirrors the `if: :all_parcels_prepared?` guard the state_machine event carried.
      def can_run?
        super && resource.all_parcels_prepared?
      end
    end
  end
end
