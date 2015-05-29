require 'test_helper'
class Backend::DraftJournalsControllerTest < ActionController::TestCase
  test_restfully_all_actions show: :index, confirm: :post_and_redirect, list_journal_entry_items: :list
end
