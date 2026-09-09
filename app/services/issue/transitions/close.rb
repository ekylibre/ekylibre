# frozen_string_literal: true

class Issue
  module Transitions
    class Close < Transitionable::Transition
      event :close
      from :opened
      to :closed

      def transition
        resource.state = :closed
        resource.save!
      end
    end
  end
end
