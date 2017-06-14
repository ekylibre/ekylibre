require 'test_helper'

module Backend
  class LoansControllerTest < ActionController::TestCase
    test_restfully_all_actions

    test 'create without ongoing_at' do
      user = User.where(administrator: true).last
      sign_in(user)
      assert_no_difference 'Loan.count' do
        test = post(:create, loan: {
                      name: 'Test',
                      amount: 5000,
                      cash_id: Cash.last.id,
                      lender_id: Entity.last.id,
                      interest_percentage: 2,
                      insurance_percentage: 1,
                      insurance_repayment_method: 'to_repay',
                      repayment_method: 'constant_amount',
                      shift_method: 'immediate_payment',
                      started_on: nil,
                      repayment_period: 'month',
                      repayment_duration: 15,
                      shift_duration: 3,
                      loan_account_id: Account.last.id,
                      interest_account_id: Account.last.id,
                      insurance_account_id: '',
                      initial_releasing_amount: 0,
                      accountable_repayments_started_on: '',
                      use_bank_guarantee: 0,
                      bank_guarantee_amount: ''
                    })
      end
      assert_response(200)
    end
  end
end
