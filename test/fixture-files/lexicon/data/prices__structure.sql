DROP TABLE IF EXISTS master_phytosanitary_prices;
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
          reference_name character varying PRIMARY KEY NOT NULL,
          worker_variant character varying NOT NULL,
          salaried boolean,
          contract_end character varying,
          legal_monthly_working_time numeric(8,2) NOT NULL,
          legal_monthly_offline_time numeric(8,2) NOT NULL,
          min_raw_wage_per_hour numeric(8,2) NOT NULL,
          salary_charges_ratio numeric(8,2) NOT NULL,
          farm_charges_ratio numeric(8,2) NOT NULL,
          translation_id character varying NOT NULL
        );

        CREATE TABLE master_phytosanitary_prices (
          id character varying PRIMARY KEY NOT NULL,
          reference_name character varying NOT NULL,
          reference_article_name integer NOT NULL,
          unit_pretax_amount numeric(19,4) NOT NULL,
          currency character varying NOT NULL,
          reference_packaging_name character varying NOT NULL,
          started_on date NOT NULL,
          usage character varying NOT NULL
        );
