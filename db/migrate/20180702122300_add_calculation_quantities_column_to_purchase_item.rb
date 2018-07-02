class AddCalculationQuantitiesColumnToPurchaseItem < ActiveRecord::Migration
  def change
    add_column :purchase_items, :conditionning_quantity, :integer
    add_column :purchase_items, :conditionning, :integer
  end
end
