# frozen_string_literal: true

class Sale
  module Transitions
    class Propose < Transitionable::Transition
      event :propose
      from :draft, :refused
      to :estimate

      def transition
        resource.state = :estimate
        resource.save!
      end

      # The state_machine block guarded only the draft source
      # (`transition draft: :estimate, if: :has_content?`); refused -> estimate
      # was unguarded.
      def can_run?
        super && (resource.state.to_sym != :draft || resource.has_content?)
      end
    end
  end
end
