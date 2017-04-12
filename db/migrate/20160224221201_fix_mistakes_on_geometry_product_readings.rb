class FixMistakesOnGeometryProductReadings < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        %w[analysis_items product_readings intervention_parameter_readings product_nature_variant_readings].each do |table|
          execute "UPDATE #{table} SET indicator_datatype = 'multi_polygon' WHERE indicator_datatype = 'geometry'"
        end
      end
    end
  end
end
