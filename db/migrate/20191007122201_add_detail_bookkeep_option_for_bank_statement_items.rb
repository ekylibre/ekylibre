class AddDetailBookkeepOptionForBankStatementItems < ActiveRecord::Migration
  def change
    add_column :cashes, :enable_bookkeep_bank_item_details, :boolean, default: false
    add_column :bank_statement_items, :accounted_at, :datetime
    add_reference :bank_statement_items, :journal_entry, index: true
  end
end
