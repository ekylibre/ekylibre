class AddCodesToCultivableZones < ActiveRecord::Migration
  def change
    add_column :cultivable_zones, :codes, :jsonb
  end
end
