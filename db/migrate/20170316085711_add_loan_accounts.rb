class AddLoanAccounts < ActiveRecord::Migration
  def change
    add_column :loans, :loan_account_id, :integer
    add_column :loans, :interest_account_id, :integer
    add_column :loans, :adi_account_id, :integer
    add_column :loans, :deposit_account_id, :integer
  end
end
