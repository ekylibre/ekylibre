# frozen_string_literal: true

class Delivery
  module Transitions
    class Order < Transitionable::Transition
      event :order
      from :draft
      to :ordered

      def transition
        resource.state = :ordered
        resource.save!
      end
    end
  end
end
