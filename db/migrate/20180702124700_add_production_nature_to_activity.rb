class AddProductionNatureToActivity < ActiveRecord::Migration[4.2]
  def change
    add_column :activities, :production_nature_id, :integer
  end
end
