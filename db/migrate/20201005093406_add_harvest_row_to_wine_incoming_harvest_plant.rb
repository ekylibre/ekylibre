class AddHarvestRowToWineIncomingHarvestPlant < ActiveRecord::Migration[4.2]
  def change
    add_column :wine_incoming_harvest_plants, :rows_harvested, :integer
  end
end
