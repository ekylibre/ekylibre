DROP TABLE IF EXISTS registered_legal_positions;

        CREATE UNLOGGED TABLE registered_legal_positions (
          id integer PRIMARY KEY NOT NULL,
          name jsonb,
          nature character varying NOT NULL,
          country character varying NOT NULL,
          code character varying NOT NULL,
          insee_code character varying NOT NULL,
          fiscal_positions text[]
        );
