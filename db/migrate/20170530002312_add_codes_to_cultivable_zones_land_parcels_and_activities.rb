class AddCodesToCultivableZonesLandParcelsAndActivities < ActiveRecord::Migration
  def change
    add_column :cultivable_zones, :codes, :jsonb
    add_column :products, :codes, :jsonb
    add_column :activities, :codes, :jsonb
  end
end
