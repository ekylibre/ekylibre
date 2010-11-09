require 'test_helper'

class FinancesControllerTest < ActionController::TestCase
  test_all_actions(
                   :deposit_create=>{:mode_id=>1}, 
                   :incoming_payment_mode_reflect=>:delete,
                   :incoming_payment_use_create=>{:expense_type=>"sales_order", :expense_id=>1},
                   :outgoing_payment_use_create=>{:expense_id=>1}
                   )
end
