class FixMistakesOnGeometryProductReadings < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute "UPDATE product_readings SET indicator_datatype = 'multi_polygon' WHERE indicator_datatype = 'geometry'"
      end
    end
  end
end
