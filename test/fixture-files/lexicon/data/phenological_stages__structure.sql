DROP TABLE IF EXISTS master_phenological_stages;

        CREATE TABLE master_phenological_stages (
          id character varying PRIMARY KEY NOT NULL,
          bbch_code character varying NOT NULL,
          variety character varying NOT NULL,
          biaggiolini character varying,
          eichhorn_lorenz character varying,
          chasselas_date character varying,
          label jsonb,
          description jsonb
        );
