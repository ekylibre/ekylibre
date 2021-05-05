class EditPlantingCampaign < ActiveRecord::Migration
  def up

    execute <<-SQL
      update cvi_cadastral_plants
      set planting_campaign = NULL
      where planting_campaign = '' or planting_campaign = '9999'
    SQL

    execute <<-SQL
      update cvi_land_parcels
      set planting_campaign = NULL
      where planting_campaign = '' or planting_campaign = '9999'
    SQL

  end
  
  def down
    #null
  end
end
