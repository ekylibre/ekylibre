class AddTransactionNatureToBankStatementItems < ActiveRecord::Migration
  def change
    add_column :bank_statement_items, :transaction_nature, :string
  end
end
