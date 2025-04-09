class AddEasementCapacity < ActiveRecord::Migration[5.2]
  def change
    add_column :products, :with_easement_capacity, :boolean, null: false, default: false
    add_column :products, :easement_capacity_variety, :string
  end
end


