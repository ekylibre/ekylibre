class AddStartingYearForActivityProduction < ActiveRecord::Migration[5.0]
  def change
    add_column :activity_productions, :starting_year, :integer
  end
end
