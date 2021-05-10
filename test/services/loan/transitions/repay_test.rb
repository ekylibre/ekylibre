require 'test_helper'

class Loan
  module Transitions
    class RepayTest < Ekylibre::Testing::ApplicationTestCase
      setup do
        @financial_year = create(:financial_year, year: 2019)
        @user = create(:user)
      end

      test 'should not allow to repay Loan if state is not ongoing' do
        %w[draft repaid].each do |state|
          mock = MiniTest::Mock.new
          mock.expect(:state, state)
          mock.expect(:repaid_at, nil)

          transition = new_transition_for(mock, Date.new(2019, 3, 13), @user)

          assert_not transition.can_run?, "Should not be able to repay a Loan with state #{state}"
          assert_mock mock
        end
      end

      test 'should not allow to repay an invalid loan' do
        mock = Minitest::Mock.new
        mock.expect :state, :ongoing
        mock.expect :valid?, false
        mock.expect :repaid_at, nil

        t = new_transition_for(mock, Date.new(2019, 3, 13), @user)

        assert_not t.can_run?, "Should not be able to repay an invalid loan"
        assert_mock mock
      end

      def new_transition_for(loan, repaid_at, current_user)
        Loan::Transitions::Repay.new(loan, repaid_at: repaid_at, current_user: current_user)
      end
    end
  end
end
