class SetWorkflowUnit < ActiveRecord::Migration[5.0]
  def up
    # add hectare_per_hour in workflow_unit if workflow value is present
    execute <<~SQL
      UPDATE intervention_templates SET workflow_unit = 'hectare_per_hour'
      WHERE workflow_value IS NOT NULL
    SQL
  end

  def down
    # NOPE
  end
end
