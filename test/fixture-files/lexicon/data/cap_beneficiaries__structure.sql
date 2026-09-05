DROP TABLE IF EXISTS registered_cap_subsidies;
DROP TABLE IF EXISTS registered_cap_beneficiaries;

        CREATE TABLE registered_cap_beneficiaries (
          id SERIAL PRIMARY KEY NOT NULL,
          siren character varying NOT NULL,
          year integer NOT NULL,
          beneficiary_name character varying,
          beneficiary_firstname character varying,
          company_name character varying,
          commune character varying,
          feaga_total numeric(14,2),
          feader_total numeric(14,2),
          cofinanced_total numeric(14,2),
          total_feader_cofinanced numeric(14,2),
          total_eu_cofinanced numeric(14,2),
          UNIQUE (siren, year)
        );

        CREATE INDEX registered_cap_beneficiaries_siren ON registered_cap_beneficiaries(siren);
        CREATE INDEX registered_cap_beneficiaries_year ON registered_cap_beneficiaries(year);
        CREATE INDEX registered_cap_beneficiaries_commune ON registered_cap_beneficiaries(commune);

        CREATE TABLE registered_cap_subsidies (
          id SERIAL PRIMARY KEY NOT NULL,
          siren character varying NOT NULL,
          year integer NOT NULL,
          intervention_code character varying NOT NULL,
          intervention_label character varying,
          intervention_objective text,
          intervention_start_date date,
          intervention_end_date date,
          feaga_amount numeric(14,2),
          feader_amount numeric(14,2),
          cofinanced_amount numeric(14,2)
        );

        CREATE INDEX registered_cap_subsidies_siren ON registered_cap_subsidies(siren);
        CREATE INDEX registered_cap_subsidies_year ON registered_cap_subsidies(year);
        CREATE INDEX registered_cap_subsidies_intervention_code ON registered_cap_subsidies(intervention_code);
        CREATE INDEX registered_cap_subsidies_siren_year ON registered_cap_subsidies(siren, year);
