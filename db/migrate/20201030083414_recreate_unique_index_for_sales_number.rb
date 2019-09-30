class RecreateUniqueIndexForSalesNumber < ActiveRecord::Migration[4.2]
  def change
    remove_index :sales, :number
    add_index :sales, :number, unique: true
  end
end
