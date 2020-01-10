class AddApprovedInputVolume < ActiveRecord::Migration
  def change
    reversible do |dir|

      dir.up do
        execute <<-SQL
          UPDATE product_natures
            SET variable_indicators_list = array_to_string(array_replace(regexp_split_to_array(variable_indicators_list, ', '), 'approved_input_dose', 'approved_input_volume'), ', ')
            WHERE reference_name IN ('foliar_spray', 'fungicide', 'herbicide', 'insecticide', 'molluscicide')
        SQL
      end

      dir.down do
        execute <<-SQL
          UPDATE product_natures
            SET variable_indicators_list = array_to_string(array_replace(regexp_split_to_array(variable_indicators_list, ', '), 'approved_input_volume', 'approved_input_dose'), ', ')
            WHERE reference_name IN ('foliar_spray', 'fungicide', 'herbicide', 'insecticide', 'molluscicide')
        SQL
      end
    end
  end
end
