class ChangeCviCadastralPlants < ActiveRecord::Migration[4.2]
  def change
    rename_column :cvi_cadastral_plants, :campaign, :planting_campaign
    remove_column :cvi_cadastral_plants, :insee_number, :string
    remove_column :cvi_cadastral_plants, :locality, :string
    remove_column :cvi_cadastral_plants, :commune, :string
  end
end
