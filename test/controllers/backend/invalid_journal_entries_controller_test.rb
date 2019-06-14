require 'test_helper'
module Backend
  class InvalidJournalEntriesControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions except: %i[list delete_all]

    test 'delete all invalid journal entries' do
      get :index
      assert_response :success
      post :delete_all
      assert_equal 0, JournalEntry.where.not(balance: 0.0).count
      assert_redirected_to backend_journals_path
    end
  end
end
