class DestroyAllCostingsWithoutParent < ActiveRecord::Migration
  def up
    execute <<~SQL
      DELETE FROM intervention_costings
      WHERE intervention_costings.id IN (
        SELECT intervention_costings.id FROM intervention_costings
        LEFT JOIN interventions ON interventions.costing_id = intervention_costings.id
        WHERE interventions.id IS NULL
      )
    SQL
  end
end
