class ChangeTheoreticalWorkingSpeedDatatype < ActiveRecord::Migration[4.2]
  def change
    %w[product_nature_variant_readings product_readings].each do |table|
      execute <<-SQL
        UPDATE #{table} AS t
        SET indicator_datatype = 'measure',
            absolute_measure_value_value = t.decimal_value,
            measure_value_value = t.decimal_value,
            decimal_value = NULL,
            absolute_measure_value_unit = 'hectare_per_hour',
            measure_value_unit = 'hectare_per_hour'
        WHERE indicator_name = 'theoretical_working_speed'
          AND indicator_datatype = 'decimal';
      SQL
    end
  end
end
