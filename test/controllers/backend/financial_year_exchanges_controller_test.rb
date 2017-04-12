require 'test_helper'
module Backend
  class FinancialYearExchangesControllerTest < ActionController::TestCase
    test_restfully_all_actions except: %i[journal_entries_export journal_entries_import notify_accountant close]
    # TODO: Write tests for #journal_entries_export, #journal_entries_import, #notify_accountant, #close
  end
end
