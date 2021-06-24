# frozen_string_literal: true

class Loan
  module Transitions
    class Confirm < Transitionable::Transition
      event :confirm
      from :draft
      to :ongoing

      # @return [DateTime]
      attr_reader :ongoing_at
      # @return [User]
      attr_reader :current_user

      def initialize(loan, ongoing_at:, current_user:, **_options)
        super(loan)

        @ongoing_at = loan.ongoing_at || ongoing_at
        @current_user = current_user
      end

      def transition
        resource.ongoing_at = @ongoing_at
        resource.state = :ongoing
        resource.save!
      end

      def can_run?
        financial_year = FinancialYear.at(ongoing_at)

        if super && resource.valid?
          !resource.initial_releasing_amount || (financial_year.opened? || (financial_year.closure_in_preparation? && financial_year.updater == current_user))
        else
          false
        end
      end
    end
  end
end
