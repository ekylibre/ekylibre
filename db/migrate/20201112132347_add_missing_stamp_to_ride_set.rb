class AddMissingStampToRideSet < ActiveRecord::Migration[4.2]
  def change
    add_reference :ride_sets, :creator, index: true
    add_reference :ride_sets, :updater, index: true
    add_column :ride_sets, :lock_version, :integer, null: false, default: 0
    add_reference :rides, :creator, index: true
    add_reference :rides, :updater, index: true
    add_column :rides, :lock_version, :integer, null: false, default: 0
  end
end