DROP TABLE IF EXISTS registered_agroedi_codes;

        CREATE UNLOGGED TABLE registered_agroedi_codes (
          id integer PRIMARY KEY NOT NULL,
          repository_id integer NOT NULL,
          reference_id integer NOT NULL,
          reference_code character varying,
          reference_label character varying,
          ekylibre_scope character varying,
          ekylibre_value character varying
        );

        CREATE INDEX registered_agroedi_codes_reference_code ON registered_agroedi_codes(reference_code);
