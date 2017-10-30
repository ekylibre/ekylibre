class FixMatterInitialPopulation < ActiveRecord::Migration
  def change
    reversible do |d|
      d.up do
        execute 'UPDATE products SET initial_population = 0 WHERE initial_population IS NULL'
      end
    end
  end
end
