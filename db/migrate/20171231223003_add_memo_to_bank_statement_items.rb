class AddMemoToBankStatementItems < ActiveRecord::Migration
  def change
    add_column :bank_statement_items, :memo, :string
  end
end
