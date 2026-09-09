# frozen_string_literal: true

class TaxDeclaration
  module Transitions
    class Confirm < Transitionable::Transition
      event :confirm
      from :validated
      to :sent

      def transition
        resource.state = :sent
        resource.save!
      end

      # Mirrors the `if: :has_content?` guard the state_machine event carried.
      def can_run?
        super && resource.has_content?
      end
    end
  end
end
