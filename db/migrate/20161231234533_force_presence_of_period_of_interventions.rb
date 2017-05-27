class ForcePresenceOfPeriodOfInterventions < ActiveRecord::Migration
  def change
    reversible do |r|
      r.up do
        execute 'UPDATE interventions SET started_at = s.started_at FROM (SELECT intervention_id, MIN(started_at) AS started_at FROM intervention_working_periods GROUP BY 1) AS s WHERE interventions.started_at IS NULL AND interventions.id = s.intervention_id'
        execute 'UPDATE interventions SET stopped_at = s.stopped_at FROM (SELECT intervention_id, MAX(stopped_at) AS stopped_at FROM intervention_working_periods GROUP BY 1) AS s WHERE interventions.stopped_at IS NULL AND interventions.id = s.intervention_id'
        execute 'UPDATE interventions SET started_at = created_at WHERE started_at IS NULL'
        execute "UPDATE interventions SET stopped_at = started_at + '1 hour'::INTERVAL WHERE stopped_at IS NULL"
        execute "UPDATE interventions SET whole_duration = EXTRACT('epoch' FROM (stopped_at - started_at)::INTERVAL) WHERE whole_duration IS NULL"
        execute "UPDATE interventions SET working_duration = s.d FROM (SELECT intervention_id, SUM(EXTRACT('epoch' FROM (stopped_at - started_at)::INTERVAL)) AS d FROM intervention_working_periods GROUP BY 1) AS s WHERE working_duration IS NULL AND s.intervention_id = interventions.id"
        execute 'UPDATE interventions SET working_duration = whole_duration WHERE working_duration IS NULL'
        change_column_null :interventions, :started_at, false
        change_column_null :interventions, :stopped_at, false
        change_column_default :interventions, :whole_duration, nil
        change_column_default :interventions, :working_duration, nil
      end
      r.down do
        change_column_null :interventions, :started_at, true
        change_column_null :interventions, :stopped_at, true
        change_column_default :interventions, :whole_duration, 0
        change_column_default :interventions, :working_duration, 0
      end
    end
  end
end
