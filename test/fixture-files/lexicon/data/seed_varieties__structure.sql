DROP TABLE IF EXISTS registered_seed_varieties;

        CREATE TABLE registered_seed_varieties (
          id character varying PRIMARY KEY NOT NULL,
          id_specie character varying NOT NULL,
          specie_name jsonb,
          specie_name_fra character varying,
          variety_name character varying,
          registration_date date
        );

        CREATE INDEX registered_seed_varieties_id ON registered_seed_varieties(id);
        CREATE INDEX registered_seed_varieties_id_specie ON registered_seed_varieties(id_specie);
