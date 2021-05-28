class RemoveLandParcelRootstockTable < ActiveRecord::Migration[5.0]
  def change
    drop_table :land_parcel_rootstocks do |t|
      t.decimal :percentage, default: 1.0
      t.string :rootstock_id
      t.references :land_parcel, polymorphic: true, index: false

      t.timestamps null: false
    end
  end
end
