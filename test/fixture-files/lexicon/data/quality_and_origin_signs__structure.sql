DROP TABLE IF EXISTS registered_quality_and_origin_signs;

        CREATE TABLE registered_quality_and_origin_signs (
          id integer PRIMARY KEY NOT NULL,
          ida integer NOT NULL,
          geographic_area character varying,
          fr_sign character varying,
          eu_sign character varying,
          product_human_name JSONB,
          product_human_name_fra character varying,
          reference_number character varying
        );
