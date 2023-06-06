class AddNameColumnOnActivityProduction < ActiveRecord::Migration[5.0]
  def change
    add_column :activity_productions, :name, :string, index: true
    add_column :activity_productions, :cultivable_zone_rank_number, :integer, index: true
  end
end
