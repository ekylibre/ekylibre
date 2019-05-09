require 'test_helper'
module Backend
  class FinancialYearClosurePreparationsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures

    test 'the user in charge of a financial year closure is the only one who can keep adding entries for this period' do
      FinancialYear.delete_all
      financial_year = create(:financial_year, started_on: Date.today.beginning_of_year, stopped_on: Date.today.end_of_year)

      sign_in User.first
      post :create, financial_year_id: financial_year.id, redirect: backend_financial_years_path

      assert_equal FinancialYear.first.closer, User.first
      assert_equal FinancialYear.first.state, 'closure_in_preparation'

      assert create(:journal_entry, :with_items, printed_on: Date.today, creator: User.first)
      assert_raises ActiveRecord::RecordInvalid do
        create(:journal_entry, :with_items, printed_on: Date.today, creator: User.second)
      end

      delete :destroy, financial_year_id: financial_year.id, redirect: backend_financial_years_path

      assert_nil FinancialYear.first.closer
      assert_equal FinancialYear.first.state, 'opened'

      assert create(:journal_entry, :with_items, printed_on: Date.today, creator: User.first)
      assert create(:journal_entry, :with_items, printed_on: Date.today, creator: User.second)
    end
  end
end
