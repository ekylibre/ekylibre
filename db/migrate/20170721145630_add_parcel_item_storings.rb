class AddParcelItemStorings < ActiveRecord::Migration
  def change
    create_table :parcel_item_storings do |t|
      t.references :parcel_item, null: false, index: true
      t.references :storage, null: false, index: true
      t.integer :quantity
      t.stamps
    end
  end
end
