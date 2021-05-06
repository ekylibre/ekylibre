class CreateRides < ActiveRecord::Migration[4.2]
  def change
    create_table :rides do |t|
      t.string :number
      t.datetime :started_at
      t.datetime :stopped_at
      t.integer :sleep_count
      t.string :equipment_name
      t.jsonb :provider
      t.string :state
      t.references :product, index: true, foreign_key: true

      t.timestamps null: false
    end

    add_column :rides, :duration, :interval, default: nil
    add_column :rides, :sleep_duration, :interval, default: nil
    add_column :rides, :distance_km, :float
    add_column :rides, :area_without_overlap, :float
    add_column :rides, :area_with_overlap, :float
    add_column :rides, :area_smart, :float
    add_column :rides, :gasoline, :float
    add_column :rides, :nature, :string
  end
end
