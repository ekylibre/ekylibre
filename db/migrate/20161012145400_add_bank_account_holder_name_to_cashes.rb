class AddBankAccountHolderNameToCashes < ActiveRecord::Migration[4.2]
  def change
    add_column :cashes, :bank_account_holder_name, :string
  end
end
