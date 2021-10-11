class AddEuidToSensorsTable < ActiveRecord::Migration[4.2]
  def change
    add_column :sensors, :euid, :string
  end
end
