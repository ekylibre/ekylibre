class ReUpdateVineStockBudCharge < ActiveRecord::Migration[4.2]
  def change
    reversible do |dir|
      dir.up do
        # Update vine_crop nature and indicators
        execute <<-SQL
          UPDATE product_natures
          SET variable_indicators_list = 'certification, certification_label, complanted_vine_stock, dead_vine_stock, layered_vine_stock, missing_vine_stock, plants_count, plants_interval, plant_life_state, vine_stock_bud_charge, rows_interval, shape, vine_pruning_system'
          WHERE reference_name = 'vine_crop' AND imported_from = 'Nomenclature'
        SQL
      end
    end
  end
end
