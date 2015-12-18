require 'test_helper'
module Backend
  class GeneralLedgersControllerTest < ActionController::TestCase
    test_restfully_all_actions show: :index, list_journal_entry_items: :list
  end
end
