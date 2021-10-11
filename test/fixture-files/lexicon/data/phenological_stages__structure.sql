DROP TABLE IF EXISTS master_phenological_stages;

        CREATE TABLE master_phenological_stages (
          bbch_code integer PRIMARY KEY NOT NULL,
          biaggiolini character varying,
          eichhorn_lorenz character varying,
          chasselas_date character varying,
          label jsonb,
          description jsonb
        );
