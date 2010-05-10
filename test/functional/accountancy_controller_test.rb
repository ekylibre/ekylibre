require 'test_helper'

class AccountancyControllerTest < ActionController::TestCase
  fixtures :companies, :users
  test_all_actions :account_letter=>:update, :account_unletter=>:delete, :bank_account_statement_point=>:update, :journal_close=>:update, :journal_reopen=>:update, :financialyear_close=>:update, :journal_record_create=>:update, :except=>[:journal_entry_create]
end
