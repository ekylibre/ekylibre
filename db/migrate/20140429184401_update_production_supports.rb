class UpdateProductionSupports < ActiveRecord::Migration
  def change
    add_column :production_supports, :nature, :string
    execute "UPDATE production_supports SET nature = 'main'"
  end
end
