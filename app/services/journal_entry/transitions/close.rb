# frozen_string_literal: true

class JournalEntry
  module Transitions
    class Close < Transitionable::Transition
      event :close
      from :draft, :confirmed
      to :closed

      def transition
        resource.state = :closed
        resource.save!
      end

      def can_run?
        super && resource.balanced?
      end
    end
  end
end
