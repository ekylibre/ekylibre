--# MAIN ACTIVITY
SELECT
   a.id AS activity_id,
   c.id AS campaign_id,
   COALESCE((SELECT SUM(ap.size_value) FROM activity_productions AS ap
   WHERE ap.activity_id = a.id AND ap.id IN (
     SELECT apc.activity_production_id
      FROM activity_productions_campaigns AS apc WHERE apc.campaign_id = c.id)
   ), '1') AS activity_size_value,
   COALESCE(a.size_unit_name, 'unity') AS activity_size_unit,
   'main_direct_product' AS economic_indicator,
   abm.global_amount AS amount,
   abm.variant_id AS output_variant_id,
   abm.unit_id AS output_variant_unit_id

FROM activity_budgets AS ab
JOIN activities AS a ON ab.activity_id = a.id
JOIN campaigns AS c ON ab.campaign_id = c.id
JOIN activity_budget_items AS abm ON abm.activity_budget_id = ab.id AND abm.main_output IS TRUE
WHERE abm.direction = 'revenue'
AND a.nature = 'main'
GROUP BY a.id, c.id, abm.id
UNION ALL
SELECT
   a.id AS activity_id,
   c.id AS campaign_id,
   COALESCE((SELECT SUM(ap.size_value) FROM activity_productions AS ap
   WHERE ap.activity_id = a.id AND ap.id IN (
     SELECT apc.activity_production_id
      FROM activity_productions_campaigns AS apc WHERE apc.campaign_id = c.id)
   ), '1') AS activity_size_value,
   COALESCE(a.size_unit_name, 'unity') AS activity_size_unit,
   'other_direct_product' AS economic_indicator,
   SUM(abi.global_amount) AS amount,
   NULL AS output_variant_id,
   NULL AS output_variant_unit_id

FROM activity_budgets AS ab
JOIN activities AS a ON ab.activity_id = a.id
JOIN campaigns AS c ON ab.campaign_id = c.id
LEFT JOIN activity_budget_items AS abi ON abi.activity_budget_id = ab.id
WHERE abi.direction = 'revenue' AND abi.main_output IS FALSE
AND a.nature = 'main'
GROUP BY a.id, c.id
UNION ALL
SELECT
   a.id AS activity_id,
   c.id AS campaign_id,
   COALESCE((SELECT SUM(ap.size_value) FROM activity_productions AS ap
   WHERE ap.activity_id = a.id AND ap.id IN (
     SELECT apc.activity_production_id
      FROM activity_productions_campaigns AS apc WHERE apc.campaign_id = c.id)
   ), '1') AS activity_size_value,
   COALESCE(a.size_unit_name, 'unity') AS activity_size_unit,
   'fixed_direct_charge' AS economic_indicator,
   SUM(abi.global_amount) AS amount,
   NULL AS output_variant_id,
   NULL AS output_variant_unit_id

FROM activity_budgets AS ab
JOIN activities AS a ON ab.activity_id = a.id
JOIN campaigns AS c ON ab.campaign_id = c.id
LEFT JOIN activity_budget_items AS abi ON abi.activity_budget_id = ab.id
WHERE abi.direction = 'expense' AND abi.nature <> 'dynamic'
AND a.nature = 'main'
GROUP BY a.id, c.id
UNION ALL
SELECT
   a.id AS activity_id,
   c.id AS campaign_id,
   COALESCE((SELECT SUM(ap.size_value) FROM activity_productions AS ap
   WHERE ap.activity_id = a.id AND ap.id IN (
     SELECT apc.activity_production_id
      FROM activity_productions_campaigns AS apc WHERE apc.campaign_id = c.id)
   ), '1') AS activity_size_value,
   COALESCE(a.size_unit_name, 'unity') AS activity_size_unit,
   'proportional_direct_charge' AS economic_indicator,
   SUM(abi.global_amount) AS amount,
   NULL AS output_variant_id,
   NULL AS output_variant_unit_id

FROM activity_budgets AS ab
JOIN activities AS a ON ab.activity_id = a.id
JOIN campaigns AS c ON ab.campaign_id = c.id
LEFT JOIN activity_budget_items AS abi ON abi.activity_budget_id = ab.id
WHERE abi.direction = 'expense' AND abi.nature = 'dynamic'
AND a.nature = 'main'
GROUP BY a.id, c.id
UNION ALL
SELECT
   a.id AS activity_id,
   c.id AS campaign_id,
   '1' AS activity_size_value,
   'unity' AS activity_size_unit,
   'global_indirect_product' AS economic_indicator,
   SUM(abi.global_amount) AS amount,
   NULL AS output_variant_id,
   NULL AS output_variant_unit_id

FROM activity_budgets AS ab
JOIN activities AS a ON ab.activity_id = a.id
JOIN campaigns AS c ON ab.campaign_id = c.id
LEFT JOIN activity_budget_items AS abi ON abi.activity_budget_id = ab.id
WHERE abi.direction = 'revenue'
AND a.nature = 'auxiliary'
GROUP BY a.id, c.id
UNION ALL
SELECT
   a.id AS activity_id,
   c.id AS campaign_id,
   '1' AS activity_size_value,
   'unity' AS activity_size_unit,
   'global_indirect_charge' AS economic_indicator,
   SUM(abi.global_amount) AS amount,
   NULL AS output_variant_id,
   NULL AS output_variant_unit_id

FROM activity_budgets AS ab
JOIN activities AS a ON ab.activity_id = a.id
JOIN campaigns AS c ON ab.campaign_id = c.id
LEFT JOIN activity_budget_items AS abi ON abi.activity_budget_id = ab.id
WHERE abi.direction = 'expense'
AND a.nature = 'auxiliary'
GROUP BY a.id, c.id
ORDER BY activity_id, campaign_id
