class CreateRideSetEquipment < ActiveRecord::Migration[5.2]
  def change
    create_table :ride_set_equipments do |t|
      t.references :ride_set, foreign_key: true
      t.references :product, foreign_key: true
      t.string :nature
      t.jsonb :provider
      t.stamps
    end
  end
end
