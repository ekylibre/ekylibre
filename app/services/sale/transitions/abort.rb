# frozen_string_literal: true

class Sale
  module Transitions
    class Abort < Transitionable::Transition
      event :abort
      from :draft, :estimate
      to :aborted

      def transition
        resource.state = :aborted
        resource.save!
      end

    end
  end
end
