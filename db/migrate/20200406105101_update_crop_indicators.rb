class UpdateCropIndicators < ActiveRecord::Migration[4.2]
  def change
    reversible do |dir|
      dir.up do
        # Update vine_crop nature and indicators
        execute <<-SQL
          UPDATE product_natures
          SET reference_name = 'vine_crop',
          variable_indicators_list = 'certification, certification_label, complanted_vine_stock, dead_vine_stock, layered_vine_stock, missing_vine_stock, plants_count, plants_interval, plant_life_state, rootstock_bud_charge, rows_interval, shape, vine_pruning_system'
          WHERE reference_name = 'wine_crop' AND imported_from = 'Nomenclature'
        SQL

        # Update indicator rootstock_variety instead of woodstock_variety
        execute <<-SQL
          UPDATE product_nature_variant_readings
          SET indicator_name = 'rootstock_variety'
          WHERE indicator_name = 'woodstock_variety'
        SQL

        execute <<-SQL
          UPDATE product_readings
          SET indicator_name = 'rootstock_variety'
          WHERE indicator_name = 'woodstock_variety'
        SQL

        # change indicator certification and rootstock_variety to text instead of nomen choices (because provide by Lexicon now)
        execute <<-SQL
          UPDATE product_nature_variant_readings
          SET indicator_datatype = 'string',
          string_value = choice_value
          WHERE (indicator_name = 'certification' OR indicator_name = 'rootstock_variety') AND indicator_datatype = 'choice'
        SQL

        execute <<-SQL
          UPDATE product_readings
          SET indicator_datatype = 'string',
          string_value = choice_value
          WHERE (indicator_name = 'certification' OR indicator_name = 'rootstock_variety') AND indicator_datatype = 'choice'
        SQL

      end
      dir.down do
        execute <<-SQL
          UPDATE product_nature_variant_readings
          SET indicator_name = 'woodstock_variety'
          WHERE indicator_name = 'rootstock_variety'
        SQL

        execute <<-SQL
          UPDATE product_readings
          SET indicator_name = 'woodstock_variety'
          WHERE indicator_name = 'rootstock_variety'
        SQL

        execute <<-SQL
          UPDATE product_natures
          SET reference_name = 'wine_crop',
          variable_indicators_list = 'certification, plant_life_state, plants_count, plants_interval, rows_interval, shape, woodstock_variety'
          WHERE reference_name = 'vine_crop' AND imported_from = 'Nomenclature'
        SQL

        execute <<-SQL
          UPDATE product_nature_variant_readings
          SET indicator_datatype = 'choice',
          choice_value = string_value
          WHERE (indicator_name = 'certification' OR indicator_name = 'woodstock_variety') AND indicator_datatype = 'string'
        SQL

        execute <<-SQL
          UPDATE product_readings
          SET indicator_datatype = 'choice',
          choice_value = string_value
          WHERE (indicator_name = 'certification' OR indicator_name = 'woodstock_variety') AND indicator_datatype = 'string'
        SQL
      end
    end
  end
end
