class AddProductionSystems < ActiveRecord::Migration
  def change
    add_column :activities, :production_system_reference_name, :string
    add_column :cultivable_zones, :production_system_reference_name, :string
  end
end
