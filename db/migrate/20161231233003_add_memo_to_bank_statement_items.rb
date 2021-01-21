class AddMemoToBankStatementItems < ActiveRecord::Migration[4.2]
  def change
    add_column :bank_statement_items, :memo, :string
  end
end
