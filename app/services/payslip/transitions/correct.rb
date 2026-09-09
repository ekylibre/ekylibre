# frozen_string_literal: true

class Payslip
  module Transitions
    class Correct < Transitionable::Transition
      event :correct
      from :invoice
      to :draft

      def transition
        resource.state = :draft
        resource.save!
      end

      # The payslip can only go back to draft while its journal entry is still
      # a draft itself — mirrors the `if: :has_no_entry?` guard the
      # state_machine event carried.
      def can_run?
        super && resource.has_no_entry?
      end
    end
  end
end
