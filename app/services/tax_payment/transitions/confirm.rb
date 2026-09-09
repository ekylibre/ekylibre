# frozen_string_literal: true

class TaxPayment
  module Transitions
    class Confirm < Transitionable::Transition
      event :confirm
      from :draft
      to :validated

      def transition
        resource.state = :validated
        resource.save!
      end
    end
  end
end
