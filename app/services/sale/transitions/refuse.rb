# frozen_string_literal: true

class Sale
  module Transitions
    class Refuse < Transitionable::Transition
      event :refuse
      from :estimate
      to :refused

      def transition
        resource.state = :refused
        resource.save!
      end

      # Mirrors the `if: :has_content?` guard the state_machine event carried.
      def can_run?
        super && resource.has_content?
      end
    end
  end
end
