# frozen_string_literal: true

class Sale
  module Transitions
    class Correct < Transitionable::Transition
      event :correct
      from :estimate, :refused, :order
      to :draft

      def transition
        resource.state = :draft
        resource.save!
      end

    end
  end
end
