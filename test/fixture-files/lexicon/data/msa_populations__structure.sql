DROP TABLE IF EXISTS registered_msa_populations;

        CREATE TABLE registered_msa_populations (
          id SERIAL PRIMARY KEY NOT NULL,
          insee_code character varying NOT NULL,
          city_name character varying,
          year integer NOT NULL,
          new_contracts integer,
          farm_chiefs integer,
          retired_non_salaried integer,
          retired_salaried integer,
          UNIQUE (insee_code, year)
        );
        CREATE INDEX registered_msa_populations_insee_code ON registered_msa_populations(insee_code);
        CREATE INDEX registered_msa_populations_year ON registered_msa_populations(year);
