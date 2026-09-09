# frozen_string_literal: true

class Delivery
  module Transitions
    class Prepare < Transitionable::Transition
      event :prepare
      from :ordered
      to :in_preparation

      def transition
        resource.state = :in_preparation
        resource.save!
      end
    end
  end
end
