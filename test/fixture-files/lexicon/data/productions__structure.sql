DROP TABLE IF EXISTS master_production_prices;
DROP TABLE IF EXISTS master_production_yields;
DROP TABLE IF EXISTS master_crop_production_tfi_codes;
DROP TABLE IF EXISTS master_crop_production_cap_sna_codes;
DROP TABLE IF EXISTS master_crop_production_cap_codes;
DROP TABLE IF EXISTS master_production_start_states;
DROP TABLE IF EXISTS master_productions;

        CREATE TABLE master_productions (
          reference_name character varying PRIMARY KEY NOT NULL,
          activity_family character varying NOT NULL,
          specie character varying,
          usage character varying,
          started_on DATE NOT NULL,
          stopped_on DATE NOT NULL,
          agroedi_crop_code character varying,
          season character varying,
          life_duration interval,
          idea_botanic_family character varying,
          idea_specie_family character varying,
          idea_output_family character varying,
          color character varying,
          translation_id character varying NOT NULL
        );

        CREATE INDEX master_productions_reference_name ON master_productions(reference_name);
        CREATE INDEX master_productions_specie ON master_productions(specie);
        CREATE INDEX master_productions_activity_family ON master_productions(activity_family);
        CREATE INDEX master_productions_agroedi_crop_code ON master_productions(agroedi_crop_code);

        CREATE TABLE master_production_start_states (
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

        CREATE TABLE master_crop_production_cap_sna_codes (
          reference_name character varying PRIMARY KEY NOT NULL,
          nature character varying NOT NULL,
          parent character varying,
          translation_id character varying NOT NULL
        );

        CREATE TABLE master_crop_production_tfi_codes (
          tfi_code character varying NOT NULL,
          tfi_label character varying NOT NULL,
          production character varying,
          campaign integer NOT NULL
        );

        CREATE TABLE master_production_yields (
          department_zone character varying NOT NULL,
          specie character varying NOT NULL,
          production character varying NOT NULL,
          yield_value numeric(8,2) NOT NULL,
          yield_unit character varying NOT NULL,
          campaign integer NOT NULL
        );
        CREATE INDEX master_production_yields_specie ON master_production_yields(specie);
        CREATE INDEX master_production_yields_production ON master_production_yields(production);
        CREATE INDEX master_production_yields_campaign ON master_production_yields(campaign);

        CREATE TABLE master_production_prices (
          department_zone character varying NOT NULL,
          started_on DATE NOT NULL,
          nature character varying,
          price_duration interval NOT NULL,
          specie character varying NOT NULL,
          waiting_price numeric(8,2) NOT NULL,
          final_price numeric(8,2) NOT NULL,
          currency character varying NOT NULL,
          price_unit character varying NOT NULL,
          product_output_specie character varying NOT NULL,
          production_reference_name character varying,
          campaign integer,
          organic boolean,
          label character varying
        );
        CREATE INDEX master_production_prices_specie ON master_production_prices(specie);
        CREATE INDEX master_production_prices_department_zone ON master_production_prices(department_zone);
        CREATE INDEX master_production_prices_started_on ON master_production_prices(started_on);
        CREATE INDEX master_production_prices_product_output_specie ON master_production_prices(product_output_specie);
