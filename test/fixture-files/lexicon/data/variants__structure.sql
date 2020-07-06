DROP TABLE IF EXISTS variant_prices;
DROP TABLE IF EXISTS variant_units;
DROP TABLE IF EXISTS variant_doer_contracts;
DROP TABLE IF EXISTS variants;
DROP TABLE IF EXISTS variant_natures;
DROP TABLE IF EXISTS variant_categories;

        CREATE UNLOGGED TABLE variant_categories (
          id integer PRIMARY KEY NOT NULL,
          reference_name character varying NOT NULL,
          name jsonb,
          label_fra character varying NOT NULL,
          nature character varying NOT NULL,
          fixed_asset_account character varying,
          fixed_asset_allocation_account character varying,
          fixed_asset_expenses_account character varying,
          depreciation_percentage integer,
          purchase_account character varying,
          sale_account character varying,
          stock_account character varying,
          stock_movement_account character varying,
          purchasable boolean,
          saleable boolean,
          depreciable boolean,
          storable boolean,
          default_vat_rate numeric(5,2),
          payment_frequency_value integer,
          payment_frequency_unit character varying
        );

        CREATE INDEX variant_categories_reference_name ON variant_categories(reference_name);

        CREATE UNLOGGED TABLE variant_natures (
          id integer PRIMARY KEY NOT NULL,
          reference_name character varying NOT NULL,
          name jsonb,
          label_fra character varying NOT NULL,
          nature character varying,
          population_counting character varying NOT NULL,
          indicators text[],
          abilities text[],
          variety character varying,
          derivative_of character varying
        );

        CREATE INDEX variant_natures_variety ON variant_natures(variety);
        CREATE INDEX variant_natures_reference_name ON variant_natures(reference_name);

        CREATE UNLOGGED TABLE variants (
          id character varying PRIMARY KEY NOT NULL,
          class_name character varying,
          reference_name character varying NOT NULL,
          name jsonb,
          label_fra character varying NOT NULL,
          category character varying,
          nature character varying,
          sub_nature character varying,
          default_unit character varying,
          target_specie character varying,
          specie character varying,
          eu_product_code character varying,
          indicators jsonb,
          variant_category_id integer,
          variant_nature_id integer
        );

        CREATE INDEX variants_reference_name ON variants(reference_name);
        CREATE INDEX variants_category ON variants(category);
        CREATE INDEX variants_nature ON variants(nature);
        CREATE INDEX variants_variant_category_id ON variants(variant_category_id);
        CREATE INDEX variants_variant_nature_id ON variants(variant_nature_id);

        CREATE UNLOGGED TABLE variant_doer_contracts (
          id character varying PRIMARY KEY NOT NULL,
          reference_name character varying NOT NULL,
          name jsonb,
          duration character varying,
          weekly_working_time character varying,
          gross_hourly_wage numeric(19,4),
          net_hourly_wage numeric(19,4),
          coefficient_total_cost numeric(19,4),
          variant_id character varying
        );

        CREATE UNLOGGED TABLE variant_units (
          id character varying PRIMARY KEY NOT NULL,
          class_name character varying NOT NULL,
          reference_name character varying NOT NULL,
          name jsonb,
          capacity numeric(25,10),
          capacity_unit character varying,
          dimension character varying,
          symbol character varying,
          a numeric(25,10),
          d numeric(25,10),
          b numeric(25,10),
          unit_id character varying
        );

        CREATE INDEX variant_units_reference_name ON variant_units(reference_name);
        CREATE INDEX variant_units_unit_id ON variant_units(unit_id);

        CREATE UNLOGGED TABLE variant_prices (
          id character varying PRIMARY KEY NOT NULL,
          reference_name character varying NOT NULL,
          reference_article_name character varying NOT NULL,
          unit_pretax_amount numeric(19,4) NOT NULL,
          currency character varying NOT NULL,
          reference_packaging_name character varying NOT NULL,
          started_on date NOT NULL,
          variant_id character varying,
          packaging_id character varying,
          usage character varying NOT NULL,
          main_indicator character varying,
          main_indicator_unit character varying,
          main_indicator_minimal_value numeric(19,4),
          main_indicator_maximal_value numeric(19,4),
          working_flow_value numeric(19,4),
          working_flow_unit character varying,
          threshold_min_value numeric(19,4),
          threshold_max_value numeric(19,4)
        );

        CREATE INDEX variant_prices_reference_name ON variant_prices(reference_name);
        CREATE INDEX variant_prices_reference_article_name ON variant_prices(reference_article_name);
        CREATE INDEX variant_prices_reference_packaging_name ON variant_prices(reference_packaging_name);
