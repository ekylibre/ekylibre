# frozen_string_literal: true

class JournalEntry
  module Transitions
    class Confirm < Transitionable::Transition
      event :confirm
      from :draft
      to :confirmed

      def transition
        # Replaces the `before_transition to: :confirmed` callback the
        # state_machine block carried.
        resource.validated_at = Time.zone.now
        resource.state = :confirmed
        resource.save!
      end

      def can_run?
        super && resource.balanced?
      end
    end
  end
end
