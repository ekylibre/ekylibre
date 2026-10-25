DROP TABLE IF EXISTS registered_rica_modalities;
DROP TABLE IF EXISTS registered_rica_variables;
DROP TABLE IF EXISTS registered_rica_holdings;

        CREATE TABLE registered_rica_holdings (
          id SERIAL PRIMARY KEY NOT NULL,
          idnum integer NOT NULL,
          year integer NOT NULL,
          region_code character varying,
          new_region_code character varying,
          ote_17 character varying,
          ote_64 character varying,
          economic_dimension_class character varying,
          legal_form character varying,
          altitude_zone character varying,
          less_favoured_zone character varying,
          environmental_zone character varying,
          closing_date date,
          sau_ha numeric(14,2),
          total_area_ha numeric(14,2),
          gross_product numeric(14,2),
          gross_operating_surplus numeric(14,2),
          operating_result numeric(14,2),
          extrapolation_coefficient numeric(14,4),
          data jsonb,
          UNIQUE (idnum, year)
        );
        CREATE INDEX registered_rica_holdings_year ON registered_rica_holdings(year);
        CREATE INDEX registered_rica_holdings_ote_17 ON registered_rica_holdings(ote_17);
        CREATE INDEX registered_rica_holdings_ote_64 ON registered_rica_holdings(ote_64);
        CREATE INDEX registered_rica_holdings_region_code ON registered_rica_holdings(region_code);
        CREATE INDEX registered_rica_holdings_data ON registered_rica_holdings USING GIN (data);

        CREATE TABLE registered_rica_variables (
          year integer NOT NULL,
          code character varying NOT NULL,
          label character varying,
          data_type character varying,
          length integer,
          PRIMARY KEY (year, code)
        );
        CREATE INDEX registered_rica_variables_code ON registered_rica_variables(code);

        CREATE TABLE registered_rica_modalities (
          year integer NOT NULL,
          variable_code character varying NOT NULL,
          modality_code character varying NOT NULL,
          label character varying,
          PRIMARY KEY (year, variable_code, modality_code)
        );
        CREATE INDEX registered_rica_modalities_variable_code ON registered_rica_modalities(variable_code);
