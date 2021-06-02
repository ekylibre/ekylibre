class CreateRideSets < ActiveRecord::Migration[4.2]
  def change
    create_table :ride_sets do |t|
      t.datetime :started_at
      t.datetime :stopped_at
      t.integer :road
      t.string :nature
      t.integer :sleep_count
      t.jsonb :provider

      t.timestamps null: false
    end
    
    add_column :ride_sets, :number, :string
    add_column :ride_sets, :duration, :interval, default: nil
    add_column :ride_sets, :sleep_duration, :interval, default: nil
    add_column :ride_sets, :area_without_overlap, :float
    add_column :ride_sets, :area_with_overlap, :float
    add_column :ride_sets, :area_smart, :float
    add_column :ride_sets, :gasoline, :float
  end
end
