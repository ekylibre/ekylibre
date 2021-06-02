class CreateLandParcelRootstocks < ActiveRecord::Migration[4.2]
  def change
    create_table :land_parcel_rootstocks do |t|
      t.decimal :percentage, default: 1.0
      t.string :rootstock_id
      t.references :land_parcel, polymorphic: true

      t.timestamps null: false
    end

    reversible do |dir|
      dir.down { execute('DROP VIEW IF EXISTS formatted_cvi_land_parcels') }
    end
  end
end
