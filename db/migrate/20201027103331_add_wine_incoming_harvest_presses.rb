class AddWineIncomingHarvestPresses < ActiveRecord::Migration[4.2]
  def change
    create_table :wine_incoming_harvest_presses do |t|
      t.references :wine_incoming_harvest, index: true, null: false, foreign_key: true
      t.references :press, index: true, null: true
      t.decimal :quantity_value, precision: 19, scale: 4, null: false
      t.string :quantity_unit, null: false
      t.time :pressing_started_at
      t.string :pressing_schedule
      t.stamps
    end

    add_foreign_key :wine_incoming_harvest_presses, :products, column: :press_id
  end
end
