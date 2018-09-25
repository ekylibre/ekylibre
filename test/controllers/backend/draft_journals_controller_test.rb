require 'test_helper'
module Backend
  class DraftJournalsControllerTest < ActionController::TestCase
    test_restfully_all_actions show: :index, confirm: :post_and_redirect, list_journal_entry_items: :list, except: %i[confirm_all list]

    test 'confirm all draft journal entries' do
      get :show
      assert_response :success
      post :confirm_all, redirection: backend_journals_path
      assert_equal 0, JournalEntry.where(state: :draft).count
      assert_redirected_to backend_journals_path
    end
  end
end
