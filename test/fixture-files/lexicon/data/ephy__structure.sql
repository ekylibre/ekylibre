DROP TABLE IF EXISTS registered_phytosanitary_target_name_to_pfi_targets;
DROP TABLE IF EXISTS registered_phytosanitary_symbols;
DROP TABLE IF EXISTS registered_phytosanitary_risks;
DROP TABLE IF EXISTS registered_phytosanitary_usages;
DROP TABLE IF EXISTS registered_phytosanitary_products;
DROP TABLE IF EXISTS registered_phytosanitary_cropsets;

        CREATE TABLE registered_phytosanitary_cropsets (
          id character varying PRIMARY KEY NOT NULL,
          name character varying NOT NULL,
          label jsonb,
          crop_names text[],
          crop_labels jsonb,
          record_checksum integer
        );

        CREATE INDEX registered_phytosanitary_cropsets_crop_names ON registered_phytosanitary_cropsets(crop_names);

        CREATE UNLOGGED TABLE registered_phytosanitary_products (
          id integer PRIMARY KEY NOT NULL,
          reference_name character varying NOT NULL,
          name character varying NOT NULL,
          other_names text[],
          natures text[],
          active_compounds text[],
          france_maaid character varying NOT NULL,
          mix_category_codes integer[],
          in_field_reentry_delay interval,
          state character varying NOT NULL,
          started_on date,
          stopped_on date,
          allowed_mentions jsonb,
          restricted_mentions character varying,
          operator_protection_mentions text,
          firm_name character varying,
          product_type character varying,
          record_checksum integer
        );

        CREATE INDEX registered_phytosanitary_products_name ON registered_phytosanitary_products(name);
        CREATE INDEX registered_phytosanitary_products_natures ON registered_phytosanitary_products(natures);
        CREATE INDEX registered_phytosanitary_products_france_maaid ON registered_phytosanitary_products(france_maaid);
        CREATE INDEX registered_phytosanitary_products_firm_name ON registered_phytosanitary_products(firm_name);
        CREATE INDEX registered_phytosanitary_products_reference_name ON registered_phytosanitary_products(reference_name);

        CREATE UNLOGGED TABLE registered_phytosanitary_usages (
          id character varying PRIMARY KEY NOT NULL,
          lib_court integer,
          product_id integer NOT NULL,
          ephy_usage_phrase character varying NOT NULL,
          crop jsonb,
          crop_label_fra character varying,
          species text[],  --could be an array by is originaly a string--
          target_name jsonb,
          target_name_label_fra character varying,
          description jsonb,
          treatment jsonb,
          dose_quantity numeric(19,4),
          dose_unit character varying,
          dose_unit_name character varying,
          dose_unit_factor real,
          pre_harvest_delay interval,
          pre_harvest_delay_bbch integer,
          applications_count integer,
          applications_frequency interval,
          development_stage_min integer,
          development_stage_max integer,
          usage_conditions character varying,
          untreated_buffer_aquatic integer,
          untreated_buffer_arthropod integer,
          untreated_buffer_plants integer,
          decision_date date,
          state character varying NOT NULL,
          record_checksum integer
        );

        CREATE INDEX registered_phytosanitary_usages_product_id ON registered_phytosanitary_usages(product_id);
        CREATE INDEX registered_phytosanitary_usages_species ON registered_phytosanitary_usages(species);

        CREATE UNLOGGED TABLE registered_phytosanitary_risks (
          product_id integer NOT NULL,
          risk_code character varying NOT NULL,
          risk_phrase character varying NOT NULL,
          record_checksum integer,
          PRIMARY KEY(product_id, risk_code)
        );

        CREATE INDEX registered_phytosanitary_risks_product_id ON registered_phytosanitary_risks(product_id);

        CREATE UNLOGGED TABLE registered_phytosanitary_symbols (
          id character varying PRIMARY KEY NOT NULL,
          symbol_name character varying
        );

        CREATE INDEX registered_phytosanitary_symbols_id ON registered_phytosanitary_symbols(id);
        CREATE INDEX registered_phytosanitary_symbols_symbol_name ON registered_phytosanitary_symbols(symbol_name);

        CREATE UNLOGGED TABLE registered_phytosanitary_target_name_to_pfi_targets (
          ephy_name character varying PRIMARY KEY NOT NULL,
          pfi_id integer,
          pfi_name character varying,
          default_pfi_treatment_type_id character varying

        );

        CREATE INDEX registered_phytosanitary_target_name_to_pfi_targets_ephy_name ON registered_phytosanitary_target_name_to_pfi_targets(ephy_name);
