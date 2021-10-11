require 'test_helper'
module Backend
  class DraftJournalsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions show: :index, confirm: :post_and_redirect, except: %i[confirm list list_journal_entry_items fec_compliance_errors confirmation_modal]

    test 'confirm all draft journal entries' do
      get :show, params: {}
      assert_response :success
      post :confirm, params: { from: FinancialYear.first_of_all.started_on.strftime('%Y-%m-%d'), to: Date.today.strftime('%Y-%m-%d') }
      assert_equal 0, JournalEntry.where(state: :draft).count
      assert_redirected_to backend_draft_journal_path
    end
  end
end
