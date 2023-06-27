--# MAIN ACTIVITY
SELECT
  ca.id AS campaign_id,
  act.id AS activity_id,
  ap.id AS activity_production_id,
  pr.id AS crop_id,
  ROUND(SUM((ihc.harvest_percentage_repartition * ih.quantity_value) / 100.0), 2) AS crop_incoming_harvest_quantity,
  ih.quantity_unit AS crop_incoming_harvest_unit,
  ap.size_value AS crop_area_value,
  ap.size_unit_name AS crop_area_unit,
  ROUND((SUM((ihc.harvest_percentage_repartition * ih.quantity_value) / 100.0) / ap.size_value), 2) AS crop_incoming_harvest_yield_value,
  CONCAT(ih.quantity_unit, '_per_', ap.size_unit_name) AS crop_incoming_harvest_yield_unit
FROM incoming_harvest_crops AS ihc
JOIN incoming_harvests AS ih ON ih.id = ihc.incoming_harvest_id
JOIN products AS pr ON ihc.crop_id = pr.id
JOIN activity_productions AS ap ON pr.activity_production_id = ap.id
JOIN campaigns AS ca ON ap.campaign_id = ca.id
JOIN activities as act ON ap.activity_id = act.id
GROUP BY ca.id, act.id, ap.id, pr.id, ih.quantity_unit
ORDER BY ca.name, act.name, ap.name, pr.name
