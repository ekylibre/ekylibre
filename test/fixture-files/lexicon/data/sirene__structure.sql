DROP TABLE IF EXISTS registered_enterprises;

        CREATE UNLOGGED TABLE registered_enterprises (
          establishment_number character varying PRIMARY KEY NOT NULL,
          french_main_activity_code character varying NOT NULL,
          name character varying,
          address character varying,
          postal_code character varying,
          city character varying,
          country character varying
        );

        CREATE INDEX registered_enterprises_french_main_activity_code ON registered_enterprises(french_main_activity_code);
        CREATE INDEX registered_enterprises_name ON registered_enterprises(name);
