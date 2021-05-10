class RenameIncomingHarvestsToWineIncomingHarvests < ActiveRecord::Migration[4.2]
  def change
    rename_table :incoming_harvests, :wine_incoming_harvests
    rename_table :incoming_harvest_inputs, :wine_incoming_harvest_inputs
    rename_table :incoming_harvest_plants, :wine_incoming_harvest_plants
    rename_table :incoming_harvest_storages, :wine_incoming_harvest_storages

    reversible do |change|
      change.up do
        remove_index :wine_incoming_harvest_inputs, :incoming_harvest_id
        remove_index :wine_incoming_harvest_plants, :incoming_harvest_id
        remove_index :wine_incoming_harvest_storages, :incoming_harvest_id
      end

      change.down do
        add_index :wine_incoming_harvest_inputs, :incoming_harvest_id
        add_index :wine_incoming_harvest_plants, :incoming_harvest_id
        add_index :wine_incoming_harvest_storages, :incoming_harvest_id
      end
    end

    rename_column :wine_incoming_harvest_inputs, :incoming_harvest_id, :wine_incoming_harvest_id
    rename_column :wine_incoming_harvest_plants, :incoming_harvest_id, :wine_incoming_harvest_id
    rename_column :wine_incoming_harvest_storages, :incoming_harvest_id, :wine_incoming_harvest_id

    # We have to take care of index name max length
    add_index :wine_incoming_harvest_inputs, :wine_incoming_harvest_id, name: 'idx_wine_incoming_harvest_inputs_incoming_harvests'
    add_index :wine_incoming_harvest_plants, :wine_incoming_harvest_id, name: 'idx_wine_incoming_harvest_plants_incoming_harvests'
    add_index :wine_incoming_harvest_storages, :wine_incoming_harvest_id, name: 'idx_wine_incoming_harvest_storages_incoming_harvests'
  end
end
