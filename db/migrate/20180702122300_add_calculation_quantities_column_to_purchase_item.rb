class AddCalculationQuantitiesColumnToPurchaseItem < ActiveRecord::Migration[4.2]
  def change
    add_column :purchase_items, :conditionning_quantity, :integer
    add_column :purchase_items, :conditionning, :integer
  end
end
