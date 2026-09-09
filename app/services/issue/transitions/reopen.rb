# frozen_string_literal: true

class Issue
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
