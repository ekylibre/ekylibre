class UpdateProductionSupports < ActiveRecord::Migration
  def change
    add_column :production_supports, :nature, :string
    add_column :production_supports, :production_usage, :string
    execute "UPDATE production_supports SET nature = 'main'"
    execute "UPDATE production_supports SET production_usage = 'grain'"
    change_column_null :production_supports, :nature, false
    change_column_null :production_supports, :production_usage, false
  end
end
