class AddEuidToSensorsTable < ActiveRecord::Migration
  def change
    add_column :sensors, :euid, :string
  end
end
