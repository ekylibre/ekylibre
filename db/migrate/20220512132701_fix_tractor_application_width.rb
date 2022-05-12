class FixTractorApplicationWidth < ActiveRecord::Migration[5.0]
  INDICATORS = {
    application_width: [2.0, 'meter'],
    ground_speed: [25.0, 'kilometer_per_hour'],
    hour_counter: [0.0, 'hour']
  }

  def up
    # add application_width indicators variable to tractor product nature
    execute <<~SQL
      UPDATE product_natures SET frozen_indicators_list = NULL,
      variable_indicators_list = 'fuel_consumption, geolocation, motor_power, hour_counter, ground_speed, application_width'
      WHERE variety = 'tractor'
    SQL

    # add indicators to existing tractors
    INDICATORS.each do |k, v|
      execute <<~SQL
        INSERT INTO product_readings ( product_id, read_at, indicator_name, indicator_datatype,
          absolute_measure_value_value, absolute_measure_value_unit, measure_value_value, measure_value_unit,
          created_at, updated_at )
          SELECT
            p.id, p.born_at, '#{k.to_s}', 'measure',
            #{v[0]}, '#{v[1]}', #{v[0]}, '#{v[1]}',
            now(), now()
          FROM products p
          WHERE p.type = 'Equipment'
          AND p.nature_id IN (SELECT id FROM product_natures pn WHERE pn.variety = 'tractor')
      SQL
    end
  end

  def down
    # NOPE
  end
end
