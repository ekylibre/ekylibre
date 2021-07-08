DROP TABLE IF EXISTS master_variants;
DROP TABLE IF EXISTS master_variant_natures;
DROP TABLE IF EXISTS master_variant_categories;

CREATE TABLE master_variant_categories (
  reference_name character varying PRIMARY KEY NOT NULL,
  family character varying NOT NULL,
  fixed_asset_account character varying,
  fixed_asset_allocation_account character varying,
  fixed_asset_expenses_account character varying,
  depreciation_percentage numeric(5,2),
  purchase_account character varying,
  sale_account character varying,
  stock_account character varying,
  stock_movement_account character varying,
  default_vat_rate numeric(5,2),
  payment_frequency_value integer,
  payment_frequency_unit character varying,
  translation_id character varying NOT NULL
);

CREATE INDEX master_variant_categories_reference_name ON master_variant_categories(reference_name);

CREATE TABLE master_variant_natures (
  reference_name character varying PRIMARY KEY NOT NULL,
  family character varying NOT NULL,
  population_counting character varying NOT NULL,
  frozen_indicators text[],
  variable_indicators text[],
  abilities text[],
  variety character varying NOT NULL,
  derivative_of character varying,
  translation_id character varying NOT NULL
);

CREATE INDEX master_variant_natures_reference_name ON master_variant_natures(reference_name);

        CREATE TABLE master_variants (
          reference_name character varying PRIMARY KEY NOT NULL,
          family character varying NOT NULL,
          category character varying NOT NULL,
          nature character varying NOT NULL,
          sub_family character varying,
          default_unit character varying NOT NULL,
          target_specie character varying,
          specie character varying,
          indicators jsonb,
          translation_id character varying NOT NULL
        );
  
        CREATE INDEX master_variants_reference_name ON master_variants(reference_name);
        CREATE INDEX master_variants_category ON master_variants(category);
        CREATE INDEX master_variants_nature ON master_variants(nature);
