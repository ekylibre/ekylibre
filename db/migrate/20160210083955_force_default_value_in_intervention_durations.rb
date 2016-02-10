class ForceDefaultValueInInterventionDurations < ActiveRecord::Migration
  def change
    change_column_default :interventions, :working_duration, 0
    change_column_default :interventions, :whole_duration, 0
    reversible do |d|
      d.up do
        execute 'UPDATE interventions SET working_duration = 0 WHERE working_duration IS NULL'
        execute 'UPDATE interventions SET whole_duration = 0 WHERE whole_duration IS NULL'
      end
    end
    change_column_null :interventions, :working_duration, false
    change_column_null :interventions, :whole_duration, false
  end
end
