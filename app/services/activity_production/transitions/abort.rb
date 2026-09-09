# frozen_string_literal: true

class ActivityProduction
  module Transitions
    class Abort < Transitionable::Transition
      event :abort
      from :opened
      to :aborted

      def transition
        resource.state = :aborted
        resource.save!
      end
    end
  end
end
