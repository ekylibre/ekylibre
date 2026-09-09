# frozen_string_literal: true

class TaxDeclaration
  module Transitions
    class Propose < Transitionable::Transition
      event :propose
      from :draft
      to :validated

      def transition
        resource.state = :validated
        resource.save!
      end

      # Mirrors the `if: :has_content?` guard the state_machine event carried.
      def can_run?
        super && resource.has_content?
      end
    end
  end
end
