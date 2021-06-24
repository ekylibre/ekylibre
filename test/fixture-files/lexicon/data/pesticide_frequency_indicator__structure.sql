DROP TABLE IF EXISTS registered_pfi_segments;
DROP TABLE IF EXISTS registered_pfi_treatment_types;
DROP TABLE IF EXISTS registered_pfi_doses;
DROP TABLE IF EXISTS registered_pfi_targets;
DROP TABLE IF EXISTS registered_pfi_crops;

        CREATE UNLOGGED TABLE registered_pfi_crops (
          id integer PRIMARY KEY NOT NULL,
          reference_label_fra character varying
        );

        CREATE UNLOGGED TABLE registered_pfi_targets (
          id integer PRIMARY KEY NOT NULL,
          reference_label_fra character varying
        );

        CREATE UNLOGGED TABLE registered_pfi_doses (
          france_maaid integer NOT NULL,
          pesticide_name character varying,
          harvest_year integer NOT NULL,
          active integer NOT NULL,
          crop_id integer NOT NULL,
          target_id integer,
          functions character varying,
          dose_unity character varying,
          dose_quantity numeric(19,4)
        );

        CREATE INDEX registered_pfi_doses_france_maaid ON registered_pfi_doses(france_maaid);
        CREATE INDEX registered_pfi_doses_harvest_year ON registered_pfi_doses(harvest_year);
        CREATE INDEX registered_pfi_doses_crop_id ON registered_pfi_doses(crop_id);

        CREATE UNLOGGED TABLE registered_pfi_treatment_types (
          id character varying PRIMARY KEY NOT NULL,
          label_fra character varying
        );

        CREATE UNLOGGED TABLE registered_pfi_segments (
          id character varying PRIMARY KEY NOT NULL,
          label_fra character varying,
          description character varying
        );
