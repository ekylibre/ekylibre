class FixMatterInitialPopulation < ActiveRecord::Migration
  def change
    execute "UPDATE products SET initial_population = 0 WHERE initial_population is null"
  end
end
