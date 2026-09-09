# frozen_string_literal: true

class ActivityProduction
  module Transitions
    class Reopen < Transitionable::Transition
      event :reopen
      from :closed, :aborted
      to :opened

      def transition
        resource.state = :opened
        resource.save!
      end
    end
  end
end
