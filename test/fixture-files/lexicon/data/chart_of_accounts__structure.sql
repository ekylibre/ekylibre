DROP TABLE IF EXISTS registered_chart_of_accounts;

        CREATE UNLOGGED TABLE registered_chart_of_accounts (
          id character varying PRIMARY KEY NOT NULL,
          account_number character varying NOT NULL,
          chart_id character varying NOT NULL,
          reference_name character varying,
          previous_reference_name character varying,
          name jsonb
        );

        CREATE INDEX registered_chart_of_accounts_account_number ON registered_chart_of_accounts(account_number);
