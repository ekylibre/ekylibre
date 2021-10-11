DROP TABLE IF EXISTS master_chart_of_accounts;

        CREATE TABLE master_chart_of_accounts (
          id integer PRIMARY KEY NOT NULL,
          reference_name character varying,
          previous_reference_name character varying,
          fr_pcga character varying,
          fr_pcg82 character varying,
          name jsonb
        );

        CREATE INDEX master_chart_of_accounts_reference_name ON master_chart_of_accounts(reference_name);
