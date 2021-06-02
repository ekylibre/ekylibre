class ChangeCviCultivableZone < ActiveRecord::Migration
  def change
    remove_column :cvi_cultivable_zones, :communes, :string
    remove_column :cvi_cultivable_zones, :cadastral_references, :string
    remove_column :cvi_cultivable_zones, :formatted_declared_area, :string
    remove_column :cvi_cultivable_zones, :formatted_calculated_area, :string
  end
end
