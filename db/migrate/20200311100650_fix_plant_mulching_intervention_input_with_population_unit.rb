# Plant mulching intervention inputs have their 'quantity_population' field value set at 0 because of XML procedure having an error on input handlers and causing Procedo to fail when processing quantity convertion
# This migration updates the 'quantity_population' field value with the most simple case where 'quantity_handler' field value is 'population' --> then 'quantity_population' = 'quantity_value'
# If other units are set, a more complex operation is required
class FixPlantMulchingInterventionInputWithPopulationUnit < ActiveRecord::Migration
  def up
    execute <<-SQL
      UPDATE intervention_parameters
      SET quantity_population = quantity_value
      WHERE type = 'InterventionInput'
      AND reference_name = 'mulching_material'
      AND quantity_handler = 'population'
      AND quantity_population = 0
      AND quantity_value != 0
    SQL

    execute <<-SQL
      UPDATE product_movements pm
      SET delta = -1 * ip.quantity_value
      FROM intervention_parameters ip
      WHERE ip.id = pm.originator_id
      AND ip.reference_name = 'mulching_material'
      AND ip.quantity_handler = 'population'
      AND ip.quantity_value != 0
      AND pm.delta = 0
    SQL
  end

  def down
    execute <<-SQL
      UPDATE intervention_parameters
      SET quantity_population = 0
      WHERE type = 'InterventionInput'
      AND reference_name = 'mulching_material'
      AND quantity_handler = 'population'
      AND quantity_value != 0
    SQL

    execute <<-SQL
      UPDATE product_movements
      SET delta = 0
      FROM product_movements pm
      JOIN intervention_parameters ip
      ON ip.id = pm.originator_id
      WHERE reference_name = 'mulching_material'
    SQL
  end
end
