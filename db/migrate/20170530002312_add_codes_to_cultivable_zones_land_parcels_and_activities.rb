class AddCodesToCultivableZonesLandParcelsAndActivities < ActiveRecord::Migration[4.2]
  def change
    add_column :cultivable_zones, :codes, :jsonb
    add_column :products, :codes, :jsonb
    add_column :activities, :codes, :jsonb
  end
end
