class AddBankAccountHolderNameToCashes < ActiveRecord::Migration
  def change
    add_column :cashes, :bank_account_holder_name, :string
  end
end
