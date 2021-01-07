class AddTransactionNatureToBankStatementItems < ActiveRecord::Migration[4.2]
  def change
    add_column :bank_statement_items, :transaction_nature, :string
  end
end
