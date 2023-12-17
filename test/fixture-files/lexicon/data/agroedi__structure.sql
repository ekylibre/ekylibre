DROP TABLE IF EXISTS registered_agroedi_crops;
DROP TABLE IF EXISTS registered_agroedi_codes;

        CREATE TABLE registered_agroedi_codes (
          repository_id integer NOT NULL,
          reference_id integer NOT NULL,
          reference_code character varying,
          reference_label character varying,
          ekylibre_scope character varying,
          ekylibre_value character varying
        );
        CREATE INDEX registered_agroedi_codes_reference_code ON registered_agroedi_codes(reference_code);

        CREATE TABLE registered_agroedi_crops (
          agroedi_code character varying NOT NULL,
          agroedi_name character varying NOT NULL,
          production character varying
        );
