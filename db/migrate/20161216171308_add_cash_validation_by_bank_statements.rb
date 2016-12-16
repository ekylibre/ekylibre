class AddCashValidationByBankStatements < ActiveRecord::Migration
  def change
    add_column :cashes, :validate_payments_with_bank_statements, :boolean, null: false, default: false
    add_reference :cashes, :validation_suspense_account, index: true
    add_reference :bank_statements, :journal_entry, index: true
    add_column :bank_statements, :accounted_at, :datetime
  end
end
