require 'test_helper'

class AccountancyControllerTest < ActionController::TestCase
  fixtures :companies, :users
  test_all_actions(:account_mark=>:update, 
                   :account_unmark=>:delete, 
                   :bank_statement_point=>:update, 
                   :journal_close=>:update, 
                   :journal_reopen=>:update, 
                   :financial_year_close=>:update, 
                   :journal_entry_create=>:update, 
                   :except=>[:journal_entry_line_create, :accounts_load])
end
