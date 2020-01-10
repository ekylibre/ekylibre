class CleanInterventionWorkingPeriod < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
          DELETE FROM intervention_working_periods
            WHERE intervention_id NOT IN (SELECT id FROM interventions)
        SQL
        add_foreign_key :intervention_working_periods, :interventions
      end

      dir.down do
        remove_foreign_key :intervention_working_periods, :interventions
      end
    end
  end
end
