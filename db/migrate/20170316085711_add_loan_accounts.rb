class AddLoanAccounts < ActiveRecord::Migration
  def change
    add_column :loans, :loan_account_id, :integer
    add_column :loans, :interest_account_id, :integer
    add_column :loans, :insurance_account_id, :integer
    add_column :loans, :bank_guarantee_account_id, :integer
  end
end
