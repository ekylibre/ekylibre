class AddProductionNatureToActivity < ActiveRecord::Migration
  def change
    add_column :activities, :production_nature_id, :integer
  end
end
