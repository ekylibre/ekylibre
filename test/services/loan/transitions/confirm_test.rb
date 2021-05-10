require 'test_helper'

class Loan
  module Transitions
    class ConfirmTest < Ekylibre::Testing::ApplicationTestCase
      setup do
        @financial_year = create(:financial_year, year: 2019)
        @user = create(:user)
      end

      test 'should not allow to confirm Loan if state is not draft' do
        %w[ongoing repaid].each do |state|
          mock = MiniTest::Mock.new
          mock.expect(:state, state)
          mock.expect(:ongoing_at, nil)

          t = new_transition_for(mock, Date.new(2019, 3, 13), @user)

          assert_not t.can_run?, "Should not be able to confirm a Loan with state #{state}"
          assert_mock mock
        end
      end

      test 'should not allow to confirm an invalid loan' do
        mock = Minitest::Mock.new
        mock.expect(:state, :draft)
        mock.expect(:valid?, false)
        mock.expect(:ongoing_at, nil)

        t = new_transition_for(mock, Date.new(2019, 3, 13), @user)

        assert_not t.can_run?, "Should not be able to confirm an invalid loan"
        assert_mock mock
      end

      test 'should confirm a Loan if the given ongoing_at date is during an opened FinancialYear' do
        mock = Minitest::Mock.new
        mock.expect(:state, :draft)
        mock.expect(:valid?, true)
        mock.expect(:ongoing_at, nil)
        mock.expect(:initial_releasing_amount, true)

        t = new_transition_for(mock, Date.new(2019, 5, 1), @user)

        assert t.can_run?
        assert_mock mock
      end

      test 'should confirm a loan if ongoing_date is during a financial_year prepared for closure AND fy updater is current_user' do
        mock = Minitest::Mock.new
        mock.expect(:state, :draft)
        mock.expect(:valid?, true)
        mock.expect(:ongoing_at, nil)
        mock.expect(:initial_releasing_amount, true)

        @financial_year.update!(state: 'closure_in_preparation', updater: @user)

        t = new_transition_for(mock, Date.new(2019, 5, 1), @user)

        assert t.can_run?
        assert_mock mock
      end

      fy_supported_states = %w[opened closure_in_preparation]
      fy_unsupported_states = FinancialYear.state.values - fy_supported_states
      fy_unsupported_states.each do |state|
        test "should not confirm a loan if financial year is #{state}" do
          mock = Minitest::Mock.new
          mock.expect(:state, :draft)
          mock.expect(:valid?, true)
          mock.expect(:ongoing_at, nil)
          mock.expect(:initial_releasing_amount, true)

          @financial_year.update!(state: state)

          t = new_transition_for(mock, Date.new(2019, 5, 1), @user)

          assert_not t.can_run?
          assert_mock mock
        end

        test "should confirm a loan on unsupported fy state (#{state}) when initial_releasing_amount is false" do
          mock = Minitest::Mock.new
          mock.expect(:state, :draft)
          mock.expect(:valid?, true)
          mock.expect(:ongoing_at, nil)
          mock.expect(:initial_releasing_amount, false)

          @financial_year.update_columns(state: state)

          t = new_transition_for(mock, Date.new(2019, 5, 1), @user)

          assert t.can_run?
          assert_mock mock
        end
      end

      def new_transition_for(loan, ongoing_at, current_user)
        Loan::Transitions::Confirm.new(loan, ongoing_at: ongoing_at, current_user: current_user)
      end
    end
  end
end
