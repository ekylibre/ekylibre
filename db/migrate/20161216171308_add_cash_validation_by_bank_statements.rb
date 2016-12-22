class AddCashValidationByBankStatements < ActiveRecord::Migration
  def change
    add_column :cashes, :suspend_until_reconciliation, :boolean, null: false, default: false
    add_reference :cashes, :suspense_account, index: true
    add_reference :bank_statements, :journal_entry, index: true
    add_column :bank_statements, :accounted_at, :datetime
    rename_column :cashes, :account_id, :main_account_id
  end
end
