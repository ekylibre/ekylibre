require 'test_helper'
class Backend::GeneralLedgersControllerTest < ActionController::TestCase
  test_restfully_all_actions show: :index, list_journal_entry_items: :list
end
