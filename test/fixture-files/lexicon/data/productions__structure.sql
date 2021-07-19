DROP TABLE IF EXISTS master_crop_production_tfi_codes;
DROP TABLE IF EXISTS master_crop_production_cap_codes;
DROP TABLE IF EXISTS master_crop_production_start_states;
DROP TABLE IF EXISTS master_crop_productions;

        CREATE TABLE master_crop_productions (
          reference_name character varying PRIMARY KEY NOT NULL,
          specie character varying NOT NULL,
          usage character varying,
          started_on DATE NOT NULL,
          stopped_on DATE NOT NULL,
          agroedi_crop_code character varying,
          season character varying,
          life_duration interval,
          translation_id character varying NOT NULL
        );

        CREATE INDEX master_crop_productions_specie ON master_crop_productions(specie);
        CREATE INDEX master_crop_productions_agroedi_crop_code ON master_crop_productions(agroedi_crop_code);

      CREATE TABLE master_crop_production_start_states (
        production character varying NOT NULL,
        year integer NOT NULL,
        key character varying NOT NULL
      );

      CREATE TABLE master_crop_production_cap_codes (
        cap_code character varying NOT NULL,
        cap_label character varying NOT NULL,
        production character varying NOT NULL,
        year integer NOT NULL,
        PRIMARY KEY(cap_code, production, year)
      );

      CREATE TABLE master_crop_production_tfi_codes (
        tfi_code character varying NOT NULL,
        tfi_label character varying NOT NULL,
        production character varying,
        campaign integer NOT NULL
      );
