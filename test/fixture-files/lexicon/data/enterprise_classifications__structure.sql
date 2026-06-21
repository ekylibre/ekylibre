DROP TABLE IF EXISTS registered_agricultural_naf_otex_codes;
DROP TABLE IF EXISTS registered_agricultural_otex_codes;
DROP TABLE IF EXISTS registered_agricultural_naf_codes;

        CREATE TABLE registered_agricultural_naf_codes (
          code character varying PRIMARY KEY NOT NULL,
          label jsonb NOT NULL
        );

        CREATE TABLE registered_agricultural_otex_codes (
          code character varying PRIMARY KEY NOT NULL,
          label jsonb NOT NULL,
          parent_code character varying NOT NULL,
          parent_label jsonb NOT NULL
        );
        CREATE INDEX registered_agricultural_otex_codes_parent_code
          ON registered_agricultural_otex_codes(parent_code);

        CREATE TABLE registered_agricultural_naf_otex_codes (
          id SERIAL PRIMARY KEY NOT NULL,
          otex_code character varying NOT NULL,
          naf_code character varying NOT NULL,
          UNIQUE (otex_code, naf_code)
        );
        CREATE INDEX registered_agricultural_naf_otex_codes_otex_code
          ON registered_agricultural_naf_otex_codes(otex_code);
        CREATE INDEX registered_agricultural_naf_otex_codes_naf_code
          ON registered_agricultural_naf_otex_codes(naf_code);
