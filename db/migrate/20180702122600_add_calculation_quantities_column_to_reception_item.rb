class AddCalculationQuantitiesColumnToReceptionItem < ActiveRecord::Migration
  def change
    add_column :parcel_item_storings, :conditionning_quantity, :integer
    add_column :parcel_item_storings, :conditionning, :integer
  end
end
