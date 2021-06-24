DROP TABLE IF EXISTS phenological_stages;

        CREATE TABLE phenological_stages (
          id integer PRIMARY KEY NOT NULL,
          bbch character varying,
          biaggiolini character varying,
          eichhorn_lorenz character varying,
          chasselas_date date,
          label jsonb,
          description jsonb
        );
