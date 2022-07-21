class AddCviCultivableZoneRefToCviCadastralPlant < ActiveRecord::Migration[4.2]
  def change
    add_reference :cvi_cadastral_plants, :cvi_cultivable_zone, index: true, foreign_key: true
  end
end
