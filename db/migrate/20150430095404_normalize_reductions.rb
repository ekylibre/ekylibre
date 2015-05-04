class NormalizeReductions < ActiveRecord::Migration
  def change
    remove_column :sale_items, :reduced_unit_amount,        :decimal, precision: 19, scale: 4, null: false, default: 0.0
    remove_column :sale_items, :reduced_unit_pretax_amount, :decimal, precision: 19, scale: 4, null: false, default: 0.0
    remove_column :sales, :prereduction_amount,        :decimal, precision: 19, scale: 4, null: false, default: 0.0
    remove_column :sales, :prereduction_pretax_amount, :decimal, precision: 19, scale: 4, null: false, default: 0.0
    remove_column :sales, :reduction_percentage,       :decimal, precision: 19, scale: 4, null: false, default: 0.0
    add_column :purchase_items, :reduction_percentage, :decimal, precision: 19, scale: 4, null: false, default: 0.0
  end
end
