DROP TABLE IF EXISTS master_doer_contracts;
DROP TABLE IF EXISTS master_prices;

CREATE TABLE master_prices (
  id character varying PRIMARY KEY NOT NULL,
  reference_name character varying NOT NULL,
  reference_article_name character varying NOT NULL,
  unit_pretax_amount numeric(19,4) NOT NULL,
  currency character varying NOT NULL,
  reference_packaging_name character varying NOT NULL,
  started_on date NOT NULL,
  variant_id character varying,
  packaging_id character varying,
  usage character varying NOT NULL,
  main_indicator character varying,
  main_indicator_unit character varying,
  main_indicator_minimal_value numeric(19,4),
  main_indicator_maximal_value numeric(19,4),
  working_flow_value numeric(19,4),
  working_flow_unit character varying,
  threshold_min_value numeric(19,4),
  threshold_max_value numeric(19,4)
);

CREATE INDEX master_prices_reference_name ON master_prices(reference_name);
CREATE INDEX master_prices_reference_article_name ON master_prices(reference_article_name);
CREATE INDEX master_prices_reference_packaging_name ON master_prices(reference_packaging_name);

CREATE TABLE master_doer_contracts (
  id character varying PRIMARY KEY NOT NULL,
 reference_name character varying NOT NULL,
  name jsonb,
 duration character varying,
 weekly_working_time character varying,
 gross_hourly_wage numeric(19,4),
 net_hourly_wage numeric(19,4),
 coefficient_total_cost numeric(19,4),
 variant_id character varying
);
