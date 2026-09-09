# frozen_string_literal: true

class Payslip
  module Transitions
    class Invoice < Transitionable::Transition
      event :invoice
      from :draft
      to :invoice

      def transition
        resource.state = :invoice
        resource.save!
      end
    end
  end
end
