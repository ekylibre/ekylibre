DROP TABLE IF EXISTS registered_seeds;

        CREATE UNLOGGED TABLE registered_seeds (
          number integer PRIMARY KEY NOT NULL,
          specie character varying NOT NULL,
          name jsonb,
          complete_name jsonb
        );

        CREATE INDEX registered_seeds_specie ON registered_seeds(specie);
