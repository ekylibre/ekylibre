class RemoveAmountsFromParcelItems < ActiveRecord::Migration[4.2]
  def change
    remove_column :parcel_items, :unit_pretax_amount
    remove_column :parcel_items, :pretax_amount
  end
end
