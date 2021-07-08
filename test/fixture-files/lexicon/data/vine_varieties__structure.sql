DROP TABLE IF EXISTS registered_vine_varieties;

        CREATE TABLE registered_vine_varieties (
          id character varying PRIMARY KEY NOT NULL,
          short_name character varying NOT NULL,
          long_name character varying,
          category character varying NOT NULL,
          fr_validated boolean,
          utilities text[],
          color character varying,
          custom_code character varying
        );

        CREATE INDEX registered_vine_varieties_id ON registered_vine_varieties(id);
