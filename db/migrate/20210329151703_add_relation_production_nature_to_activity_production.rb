class AddRelationProductionNatureToActivityProduction < ActiveRecord::Migration[5.0]
  def change
    add_column :activity_productions, :production_nature_id, :integer
  end
end
