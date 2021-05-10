class ChangeLocationForeignKeyColumn < ActiveRecord::Migration
  def up
    rename_column :locations, :insee_number, :registered_postal_zone_id
  end

  def down
    rename_column :locations, :registered_postal_zone_id, :insee_number
  end
end
