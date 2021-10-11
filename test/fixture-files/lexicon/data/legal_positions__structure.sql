DROP TABLE IF EXISTS master_legal_positions;

        CREATE TABLE master_legal_positions (
          code character varying PRIMARY KEY NOT NULL,
          name jsonb,
          nature character varying NOT NULL,
          country character varying NOT NULL,
          insee_code character varying NOT NULL,
          fiscal_positions text[]
        );
