class FixLexiconData < ActiveRecord::Migration[5.0]
  def up
    # fix hectoliter unit coefficient
    execute <<~SQL
      UPDATE units SET coefficient = 100.0 WHERE reference_name = 'hectoliter' AND type = 'ReferenceUnit'
    SQL
    # fix tractor indicators natures
    execute <<~SQL
      UPDATE product_natures SET frozen_indicators_list = NULL,
      variable_indicators_list = 'fuel_consumption, geolocation, motor_power, hour_counter, ground_speed'
      WHERE reference_name = 'tractor'
    SQL
    # fix sprayer indicators natures
    execute <<~SQL
      UPDATE product_natures SET frozen_indicators_list = NULL,
      variable_indicators_list = 'geolocation, application_width, element_count, nominal_storable_net_volume, rows_count, theoretical_working_speed'
      WHERE reference_name = 'sprayer'
    SQL
    # fix vine_crop indicators natures
    execute <<~SQL
      UPDATE product_natures SET frozen_indicators_list = 'net_surface_area',
      variable_indicators_list = 'certification, certification_label, complanted_vine_stock, dead_vine_stock, layered_vine_stock, missing_vine_stock, plants_count, plants_interval, plant_life_state, vine_stock_bud_charge, rows_interval, shape, vine_pruning_system, cut_vine'
      WHERE reference_name = 'vine_crop'
    SQL
  end

  def down
    # NOPE
  end
end
