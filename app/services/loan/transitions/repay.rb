class Loan
  module Transitions
    class Repay < Transitionable::Transition
      event :repay
      from :ongoing
      to :repaid

      # @return [DateTime]
      attr_reader :repaid_at
      # @return [User]
      attr_reader :current_user

      def initialize(loan, repaid_at:, current_user:, **_options)
        super(loan)

        @repaid_at = loan.repaid_at || repaid_at
        @current_user = current_user
      end

      def transition
        resource.repaid_at = repaid_at
        resource.state = :repaid
        resource.save!
      end

      def can_run?
        super && resource.valid?
      end
    end
  end
end
