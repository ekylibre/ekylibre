# frozen_string_literal: true

class Delivery
  module Transitions
    class Finish < Transitionable::Transition
      event :finish
      from :in_preparation, :prepared, :started
      to :finished

      def transition
        resource.state = :finished
        resource.save!
      end

      # Mirrors the `if: :all_parcels_prepared?` guard the state_machine event carried.
      def can_run?
        super && resource.all_parcels_prepared?
      end
    end
  end
end
