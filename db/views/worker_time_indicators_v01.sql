SELECT
	worker_id,
	min(started_at) start_at,
	max(stopped_at) stop_at,
	max(stopped_at) - min(started_at) duration
FROM (
  SELECT
  s.*,
  count(*) filter(WHERE started_at > lag_stopped_at) over(PARTITION BY worker_id ORDER BY started_at) grp
  FROM (
    SELECT
    s.*,
    lag(stopped_at) over(PARTITION BY worker_id ORDER BY started_at) lag_stopped_at
    FROM (
      SELECT
      worker_id,
      started_at,
      stopped_at
    	FROM (
        SELECT
        wtl.worker_id AS worker_id,
        wtl.started_at AS started_at,
        wtl.duration AS duration,
        wtl.stopped_at AS stopped_at,
        'worker_time_log' AS nature
        FROM worker_time_logs wtl
        UNION ALL
        SELECT
        ip.product_id AS worker_id,
        iwp.started_at AS started_at,
        iwp.duration AS duration,
        iwp.stopped_at AS stopped_at,
        'intervention' AS nature
        FROM intervention_working_periods iwp
        JOIN interventions i ON i.id = iwp.intervention_id
        JOIN intervention_parameters ip ON ip.intervention_id = i.id AND ip.type = 'InterventionDoer'
        WHERE iwp.intervention_participation_id IS NULL AND ip.product_id NOT IN (SELECT product_id FROM intervention_participations WHERE intervention_id = i.id)
        UNION ALL
        SELECT
        ipa.product_id AS worker_id,
        iwp.started_at AS started_at,
        iwp.duration AS duration,
        iwp.stopped_at AS stopped_at,
        'intervention_participation' AS nature
        FROM intervention_working_periods iwp
        JOIN intervention_participations ipa ON ipa.id = iwp.intervention_participation_id
        JOIN intervention_parameters ip ON ip.product_id = ipa.product_id AND ip.type = 'InterventionDoer'
        WHERE iwp.intervention_id IS NULL
        GROUP BY ipa.product_id, started_at, stopped_at, duration, nature
        ORDER BY worker_id, started_at) s
      ) s
    ) s
  ) s
GROUP BY worker_id, grp
ORDER BY worker_id, start_at;
