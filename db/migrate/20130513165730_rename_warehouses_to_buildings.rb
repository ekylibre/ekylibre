class RenameWarehousesToBuildings < ActiveRecord::Migration

  def up
    #TODO adapter la méthode pour renommer les clefs polymorphiques et les colonnes type et vérifier les customs fields.
    #rename_table :warehouses, :buildings
  end

  def down
    #rename_table :buildings, :warehouses
  end

end
