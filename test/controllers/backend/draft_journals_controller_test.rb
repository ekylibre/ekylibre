require 'test_helper'
module Backend
  class DraftJournalsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions show: :index, confirm: :post_and_redirect, except: %i[confirm_all list list_journal_entry_items]

    test 'confirm all draft journal entries' do
      get :show, params: {}
      assert_response :success
      post :confirm_all, params: { from: FinancialYear.first_of_all.started_on.strftime('%Y-%m-%d'), to: Date.today.strftime('%Y-%m-%d') }
      assert_equal 0, JournalEntry.where(state: :draft).count
      assert_redirected_to backend_draft_journal_path
    end

    test "confirm all don't validate exchanged entries" do
      empty_db
      fy = create(:financial_year, year: 2021)
      printed_on_dates = %w[2021-01-09 2021-01-11 2021-01-14 2021-01-16 2021-01-25]
      printed_on_dates.each do |date|
        create(:journal_entry, :with_items, printed_on: date)
      end
      exchande = create(:financial_year_exchange, :opened, financial_year: fy, started_on: '2021-01-10', stopped_on: '2021-01-20')
      post :confirm_all, params: { from: '2021-01-05'.to_date, to: '2021-01-28'.to_date }
      assert_equal 3, JournalEntry.where(state: :draft).count
      assert_redirected_to backend_draft_journal_path
    end

    private def empty_db
      FinancialYear.delete_all
      FinancialYearExchange.delete_all
      Notification.delete_all
      OutgoingPayment.delete_all
      Regularization.delete_all
      Payslip.delete_all
      JournalEntryItem.delete_all
      JournalEntry.delete_all
    end
  end
end
