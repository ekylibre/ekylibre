class UpdateVineStockBudCharge < ActiveRecord::Migration[4.2]
  def change
    reversible do |dir|
      dir.up do
        # Update vine_crop nature and indicators
        execute <<-SQL
          UPDATE product_natures
          SET variable_indicators_list = 'certification, certification_label, complanted_vine_stock, dead_vine_stock, layered_vine_stock, missing_vine_stock, plants_count, plants_interval, plant_life_state, vine_stock_bud_charge, rows_interval, shape, vine_pruning_system'
          WHERE reference_name = 'vine_crop' AND imported_from = 'Nomenclature'
        SQL

        # Update indicator rootstock_variety instead of woodstock_variety
        execute <<-SQL
          UPDATE product_nature_variant_readings
          SET indicator_name = 'vine_stock_bud_charge'
          WHERE indicator_name = 'rootstock_bud_charge'
        SQL

        execute <<-SQL
          UPDATE product_readings
          SET indicator_name = 'vine_stock_bud_charge'
          WHERE indicator_name = 'rootstock_bud_charge'
        SQL
      end

      dir.down do
        execute <<-SQL
          UPDATE product_nature_variant_readings
          SET indicator_name = 'rootstock_bud_charge'
          WHERE indicator_name = 'vine_stock_bud_charge'
        SQL

        execute <<-SQL
          UPDATE product_readings
          SET indicator_name = 'rootstock_bud_charge'
          WHERE indicator_name = 'vine_stock_bud_charge'
        SQL

        execute <<-SQL
          UPDATE product_natures
          SET variable_indicators_list = 'certification, certification_label, complanted_vine_stock, dead_vine_stock, layered_vine_stock, missing_vine_stock, plants_count, plants_interval, plant_life_state, rootstock_bud_charge, rows_interval, shape, vine_pruning_system'
          WHERE reference_name = 'vine_crop' AND imported_from = 'Nomenclature'
        SQL
      end
    end
  end
end
