class AddCultivableZoneColumns < ActiveRecord::Migration[4.2]
  def change
    add_column :cultivable_zones, :soil_nature, :string
    add_reference :cultivable_zones, :owner, index: true
    add_reference :cultivable_zones, :farmer, index: true
  end
end
