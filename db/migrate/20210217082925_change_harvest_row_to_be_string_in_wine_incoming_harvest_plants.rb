class ChangeHarvestRowToBeStringInWineIncomingHarvestPlants < ActiveRecord::Migration[4.2]
  def up
    change_column :wine_incoming_harvest_plants, :rows_harvested, :string
  end

  def down
    change_column :wine_incoming_harvest_plants, :rows_harvested, 'integer USING CAST(rows_harvested AS integer)'
  end
end
