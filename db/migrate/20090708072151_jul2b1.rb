class Jul2b1 < ActiveRecord::Migration
  def self.up
#     remove_index :accounts, :column=>[:number, :company_id]
    remove_index :accounts, :column=>[:alpha, :company_id]
    remove_index :users, :column=>[:name]
    add_index :users, [:name, :company_id], :unique=>true
#     remove_index :address_norms, :column=>[:name, :company_id]
#     remove_index :currencies, :column=>[:code, :company_id]
#     remove_index :delays, :column=>[:name, :company_id]
#     remove_index :departments, :column=>[:name, :company_id]
#     remove_index :entity_categories, :column=>[:code, :company_id]
#     remove_index :entities, :column=>[:code, :company_id]
  end

  def self.down
#     add_index :entities, [:code, :company_id]
#     add_index :entity_categories, [:code, :company_id]
#     add_index :departments, [:name, :company_id]
#     add_index :delays, [:name, :company_id]
#     add_index :currencies, [:code, :company_id]
#     add_index :address_norms, [:name, :company_id]
    remove_index :users, :column=>[:name, :company_id]
    add_index :users, [:name], :unique=>true
    add_index :accounts, [:alpha, :company_id]
#     add_index :accounts, [:number, :company_id]
  end
end
