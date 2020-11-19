class RecreateUniqueIndexForSalesNumber < ActiveRecord::Migration
  def change
    remove_index :sales, :number
    add_index :sales, :number, unique: true
  end
end
