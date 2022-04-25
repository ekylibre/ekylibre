--
-- PostgreSQL database dump
--

-- Dumped from database version 13.5 (Ubuntu 13.5-2.pgdg20.04+1)
-- Dumped by pg_dump version 13.5 (Ubuntu 13.5-2.pgdg20.04+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: lexicon; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA lexicon;


--
-- Name: postgis; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA postgis;


--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: compute_journal_entry_continuous_number(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.compute_journal_entry_continuous_number() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
            BEGIN
              NEW.continuous_number := (SELECT (COALESCE(MAX(continuous_number),0)+1) FROM journal_entries);
              RETURN NEW;
            END
            $$;


--
-- Name: compute_outgoing_payment_list_cache(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.compute_outgoing_payment_list_cache() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              DECLARE
                new_id INTEGER DEFAULT NULL;
                old_id INTEGER DEFAULT NULL;
              BEGIN
                IF TG_OP <> 'DELETE' THEN
                  new_id := NEW.list_id;
                END IF;

                IF TG_OP <> 'INSERT' THEN
                  old_id := OLD.list_id;
                END IF;

                UPDATE outgoing_payment_lists
                   SET cached_payment_count = payments.count,
                       cached_total_sum = payments.total
                  FROM (
                    SELECT outgoing_payments.list_id AS list_id,
                           SUM(outgoing_payments.amount) AS total,
                           COUNT(outgoing_payments.id) AS count
                      FROM outgoing_payments
                      GROUP BY outgoing_payments.list_id
                  ) AS payments
                  WHERE payments.list_id = id
                    AND ((new_id IS NOT NULL AND id = new_id)
                     OR  (old_id IS NOT NULL AND id = old_id));
                RETURN NEW;
              END
            $$;


--
-- Name: compute_partial_isacompta_lettering(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.compute_partial_isacompta_lettering() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  DECLARE
    journal_entry_item_ids integer DEFAULT NULL;
    new_letter varchar DEFAULT NULL;
    old_letter varchar DEFAULT NULL;
  BEGIN
    journal_entry_item_ids := NEW.id;
    new_letter := NEW.letter;
    old_letter := OLD.letter;

    UPDATE journal_entry_items
      SET isacompta_letter = (CASE WHEN RIGHT(new_letter, 1) = '*'
        THEN (CASE WHEN LEFT(journal_entry_items.isacompta_letter, 1) = '#'
                THEN journal_entry_items.isacompta_letter
                ELSE '#' || journal_entry_items.isacompta_letter
                END)
        ELSE (CASE
               WHEN LEFT(journal_entry_items.isacompta_letter, 1) = '#'
               THEN LTRIM(journal_entry_items.isacompta_letter, '#')
               ELSE journal_entry_items.isacompta_letter
               END)
        END)
    WHERE id = journal_entry_item_ids AND new_letter <> old_letter;

    RETURN NEW;
  END;
$$;


--
-- Name: compute_partial_lettering(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.compute_partial_lettering() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE
      new_letter varchar DEFAULT NULL;
      old_letter varchar DEFAULT NULL;
      new_account_id integer DEFAULT NULL;
      old_account_id integer DEFAULT NULL;
    BEGIN
    IF TG_OP <> 'DELETE' THEN
      IF NEW.letter IS NOT NULL THEN
        new_letter := substring(NEW.letter from '[A-z]*');
      END IF;

    IF NEW.account_id IS NOT NULL THEN
      new_account_id := NEW.account_id;
    END IF;
  END IF;

  IF TG_OP <> 'INSERT' THEN
    IF OLD.letter IS NOT NULL THEN
      old_letter := substring(OLD.letter from '[A-z]*');
    END IF;

    IF OLD.account_id IS NOT NULL THEN
      old_account_id := OLD.account_id;
    END IF;
  END IF;

  UPDATE journal_entry_items
  SET letter = (CASE
                  WHEN modified_letter_groups.balance <> 0
                  THEN modified_letter_groups.letter || '*'
                  ELSE modified_letter_groups.letter
                END),
      lettered_at = (CASE
                  WHEN modified_letter_groups.balance <> 0
                  THEN NULL
                  ELSE NOW()
                END)
  FROM (SELECT new_letter AS letter,
               account_id AS account_id,
               SUM(debit) - SUM(credit) AS balance
            FROM journal_entry_items
            WHERE account_id = new_account_id
              AND journal_entry_items.state <> 'closed'
              AND letter SIMILAR TO (COALESCE(new_letter, '') || '\**')
              AND new_letter IS NOT NULL
              AND new_account_id IS NOT NULL
            GROUP BY account_id
        UNION ALL
        SELECT old_letter AS letter,
               account_id AS account_id,
               SUM(debit) - SUM(credit) AS balance
          FROM journal_entry_items
          WHERE account_id = old_account_id
            AND journal_entry_items.state <> 'closed'
            AND letter SIMILAR TO (COALESCE(old_letter, '') || '\**')
            AND old_letter IS NOT NULL
            AND old_account_id IS NOT NULL
          GROUP BY account_id) AS modified_letter_groups
  WHERE modified_letter_groups.account_id = journal_entry_items.account_id
  AND journal_entry_items.state <> 'closed'
  AND journal_entry_items.letter SIMILAR TO (modified_letter_groups.letter || '\**');

  RETURN NEW;
END;
$$;


--
-- Name: synchronize_jei_with_entry(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.synchronize_jei_with_entry() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  synced_entry_id integer DEFAULT NULL;
BEGIN
  IF TG_NARGS <> 0 THEN
    IF TG_ARGV[0] = 'jei' THEN
      synced_entry_id := NEW.entry_id;
    END IF;

    IF TG_ARGV[0] = 'entry' THEN
      synced_entry_id := NEW.id;
    END IF;
  END IF;

  UPDATE journal_entry_items AS jei
  SET state = entries.state,
      printed_on = entries.printed_on,
      journal_id = entries.journal_id,
      financial_year_id = entries.financial_year_id,
      entry_number = entries.number,
      real_currency = entries.real_currency,
      real_currency_rate = entries.real_currency_rate
  FROM journal_entries AS entries
  WHERE jei.entry_id = synced_entry_id
    AND entries.id = synced_entry_id
    AND synced_entry_id IS NOT NULL
    AND (jei.state <> entries.state
     OR jei.printed_on <> entries.printed_on
     OR jei.journal_id <> entries.journal_id
     OR jei.financial_year_id <> entries.financial_year_id
     OR jei.entry_number <> entries.number
     OR jei.real_currency <> entries.real_currency
     OR jei.real_currency_rate <> entries.real_currency_rate);
  RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: datasource_credits; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.datasource_credits (
    datasource character varying,
    name character varying,
    url character varying,
    provider character varying,
    licence character varying,
    licence_url character varying,
    updated_at timestamp with time zone
);


--
-- Name: intervention_model_items; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.intervention_model_items (
    id character varying NOT NULL,
    procedure_item_reference character varying NOT NULL,
    article_reference character varying,
    indicator_name character varying,
    indicator_value numeric(19,4),
    indicator_unit character varying,
    intervention_model_id character varying
);


--
-- Name: intervention_models; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.intervention_models (
    id character varying NOT NULL,
    name jsonb,
    category_name jsonb,
    number character varying,
    procedure_reference character varying NOT NULL,
    working_flow numeric(19,4),
    working_flow_unit character varying
);


--
-- Name: master_budgets; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.master_budgets (
    activity_family character varying NOT NULL,
    budget_category character varying NOT NULL,
    variant character varying NOT NULL,
    mode character varying,
    proportionnal_key character varying,
    repetition integer NOT NULL,
    frequency character varying NOT NULL,
    start_month integer NOT NULL,
    quantity numeric(8,2) NOT NULL,
    unit_pretax_amount numeric(8,2) NOT NULL,
    tax_rate numeric(8,2) NOT NULL,
    unit character varying NOT NULL,
    direction character varying NOT NULL
);


--
-- Name: master_chart_of_accounts; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.master_chart_of_accounts (
    id integer NOT NULL,
    reference_name character varying,
    previous_reference_name character varying,
    fr_pcga character varying,
    fr_pcg82 character varying,
    name jsonb
);


--
-- Name: master_crop_production_cap_codes; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.master_crop_production_cap_codes (
    cap_code character varying NOT NULL,
    cap_label character varying NOT NULL,
    production character varying NOT NULL,
    year integer NOT NULL
);


--
-- Name: master_crop_production_cap_sna_codes; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.master_crop_production_cap_sna_codes (
    reference_name character varying NOT NULL,
    nature character varying NOT NULL,
    parent character varying,
    translation_id character varying NOT NULL
);


--
-- Name: master_crop_production_prices; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.master_crop_production_prices (
    department_zone character varying NOT NULL,
    started_on date NOT NULL,
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


--
-- Name: master_crop_production_start_states; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.master_crop_production_start_states (
    production character varying NOT NULL,
    year integer NOT NULL,
    key character varying NOT NULL
);


--
-- Name: master_crop_production_tfi_codes; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.master_crop_production_tfi_codes (
    tfi_code character varying NOT NULL,
    tfi_label character varying NOT NULL,
    production character varying,
    campaign integer NOT NULL
);


--
-- Name: master_crop_production_yields; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.master_crop_production_yields (
    department_zone character varying NOT NULL,
    specie character varying NOT NULL,
    production character varying NOT NULL,
    yield_value numeric(8,2) NOT NULL,
    yield_unit character varying NOT NULL,
    campaign integer NOT NULL
);


--
-- Name: master_crop_productions; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.master_crop_productions (
    reference_name character varying NOT NULL,
    activity_family character varying NOT NULL,
    specie character varying,
    usage character varying,
    started_on date NOT NULL,
    stopped_on date NOT NULL,
    agroedi_crop_code character varying,
    season character varying,
    life_duration interval,
    idea_botanic_family character varying,
    idea_specie_family character varying,
    idea_output_family character varying,
    translation_id character varying NOT NULL
);


--
-- Name: master_dimensions; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.master_dimensions (
    reference_name character varying NOT NULL,
    symbol character varying NOT NULL,
    translation_id character varying NOT NULL
);


--
-- Name: master_doer_contracts; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.master_doer_contracts (
    reference_name character varying NOT NULL,
    worker_variant character varying NOT NULL,
    salaried boolean,
    contract_end character varying,
    legal_monthly_working_time numeric(8,2) NOT NULL,
    legal_monthly_offline_time numeric(8,2) NOT NULL,
    min_raw_wage_per_hour numeric(8,2) NOT NULL,
    salary_charges_ratio numeric(8,2) NOT NULL,
    farm_charges_ratio numeric(8,2) NOT NULL,
    translation_id character varying NOT NULL
);


--
-- Name: master_legal_positions; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.master_legal_positions (
    code character varying NOT NULL,
    name jsonb,
    nature character varying NOT NULL,
    country character varying NOT NULL,
    insee_code character varying NOT NULL,
    fiscal_positions text[]
);


--
-- Name: master_packagings; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.master_packagings (
    reference_name character varying NOT NULL,
    capacity numeric(25,10) NOT NULL,
    capacity_unit character varying NOT NULL,
    translation_id character varying NOT NULL
);


--
-- Name: master_phenological_stages; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.master_phenological_stages (
    bbch_code integer NOT NULL,
    biaggiolini character varying,
    eichhorn_lorenz character varying,
    chasselas_date character varying,
    label jsonb,
    description jsonb
);


--
-- Name: master_phytosanitary_prices; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.master_phytosanitary_prices (
    id character varying NOT NULL,
    reference_name character varying NOT NULL,
    reference_article_name integer NOT NULL,
    unit_pretax_amount numeric(19,4) NOT NULL,
    currency character varying NOT NULL,
    reference_packaging_name character varying NOT NULL,
    started_on date NOT NULL,
    usage character varying NOT NULL
);


--
-- Name: master_prices; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.master_prices (
    id character varying NOT NULL,
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


--
-- Name: master_taxonomy; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.master_taxonomy (
    reference_name character varying NOT NULL,
    parent character varying,
    taxonomic_rank character varying,
    translation_id character varying NOT NULL
);


--
-- Name: master_translations; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.master_translations (
    id character varying NOT NULL,
    fra character varying NOT NULL,
    eng character varying NOT NULL
);


--
-- Name: master_units; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.master_units (
    reference_name character varying NOT NULL,
    dimension character varying NOT NULL,
    symbol character varying NOT NULL,
    a numeric(25,10),
    d numeric(25,10),
    b numeric(25,10),
    translation_id character varying NOT NULL
);


--
-- Name: master_user_roles; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.master_user_roles (
    reference_name character varying NOT NULL,
    accesses text[],
    translation_id character varying NOT NULL
);


--
-- Name: master_variant_categories; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.master_variant_categories (
    reference_name character varying NOT NULL,
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
    pictogram character varying,
    translation_id character varying NOT NULL
);


--
-- Name: master_variant_natures; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.master_variant_natures (
    reference_name character varying NOT NULL,
    family character varying NOT NULL,
    population_counting character varying NOT NULL,
    frozen_indicators text[],
    variable_indicators text[],
    abilities text[],
    variety character varying NOT NULL,
    derivative_of character varying,
    pictogram character varying,
    translation_id character varying NOT NULL
);


--
-- Name: master_variants; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.master_variants (
    reference_name character varying NOT NULL,
    family character varying NOT NULL,
    category character varying NOT NULL,
    nature character varying NOT NULL,
    sub_family character varying,
    default_unit character varying NOT NULL,
    target_specie character varying,
    specie character varying,
    indicators jsonb,
    pictogram character varying,
    translation_id character varying NOT NULL
);


--
-- Name: registered_agroedi_codes; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.registered_agroedi_codes (
    id integer NOT NULL,
    repository_id integer NOT NULL,
    reference_id integer NOT NULL,
    reference_code character varying,
    reference_label character varying,
    ekylibre_scope character varying,
    ekylibre_value character varying
);


--
-- Name: registered_cadastral_buildings; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.registered_cadastral_buildings (
    id integer NOT NULL,
    nature character varying,
    shape postgis.geometry(MultiPolygon,4326) NOT NULL,
    centroid postgis.geometry(Point,4326)
);


--
-- Name: registered_cadastral_buildings_id_seq; Type: SEQUENCE; Schema: lexicon; Owner: -
--

CREATE SEQUENCE lexicon.registered_cadastral_buildings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: registered_cadastral_buildings_id_seq; Type: SEQUENCE OWNED BY; Schema: lexicon; Owner: -
--

ALTER SEQUENCE lexicon.registered_cadastral_buildings_id_seq OWNED BY lexicon.registered_cadastral_buildings.id;


--
-- Name: registered_cadastral_parcels; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.registered_cadastral_parcels (
    id character varying NOT NULL,
    town_insee_code character varying,
    section_prefix character varying,
    section character varying,
    work_number character varying,
    net_surface_area integer,
    shape postgis.geometry(MultiPolygon,4326) NOT NULL,
    centroid postgis.geometry(Point,4326)
);


--
-- Name: registered_cadastral_prices; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.registered_cadastral_prices (
    id integer NOT NULL,
    mutation_id character varying,
    mutation_date date,
    mutation_reference character varying,
    mutation_nature character varying,
    cadastral_price numeric(14,2),
    cadastral_parcel_id character varying,
    building_nature character varying,
    building_area integer,
    cadastral_parcel_area integer,
    address character varying,
    postal_code character varying,
    city character varying,
    department character varying,
    centroid postgis.geometry(Point,4326)
);


--
-- Name: registered_cadastral_prices_id_seq; Type: SEQUENCE; Schema: lexicon; Owner: -
--

CREATE SEQUENCE lexicon.registered_cadastral_prices_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: registered_cadastral_prices_id_seq; Type: SEQUENCE OWNED BY; Schema: lexicon; Owner: -
--

ALTER SEQUENCE lexicon.registered_cadastral_prices_id_seq OWNED BY lexicon.registered_cadastral_prices.id;


--
-- Name: registered_enterprises; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.registered_enterprises (
    establishment_number character varying NOT NULL,
    french_main_activity_code character varying NOT NULL,
    name character varying,
    address character varying,
    postal_code character varying,
    city character varying,
    country character varying
);


--
-- Name: registered_eu_market_prices; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.registered_eu_market_prices (
    id character varying NOT NULL,
    nature character varying,
    category character varying,
    specie character varying,
    production_reference_name character varying,
    sector_code character varying,
    product_code character varying,
    product_label character varying,
    product_description character varying,
    unit_value integer,
    unit_name character varying,
    country character varying,
    price numeric(8,2),
    start_date date
);


--
-- Name: registered_graphic_parcels; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.registered_graphic_parcels (
    id character varying NOT NULL,
    city_name character varying,
    shape postgis.geometry(Polygon,4326) NOT NULL,
    centroid postgis.geometry(Point,4326)
);


--
-- Name: registered_hydrographic_items; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.registered_hydrographic_items (
    id character varying NOT NULL,
    name jsonb,
    nature character varying,
    point postgis.geometry(Point,4326),
    shape postgis.geometry(MultiPolygon,4326),
    lines postgis.geometry(MultiLineString,4326)
);


--
-- Name: registered_phytosanitary_cropsets; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.registered_phytosanitary_cropsets (
    id character varying NOT NULL,
    name character varying NOT NULL,
    label jsonb,
    crop_names text[],
    crop_labels jsonb,
    record_checksum integer
);


--
-- Name: registered_phytosanitary_products; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.registered_phytosanitary_products (
    id integer NOT NULL,
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


--
-- Name: registered_phytosanitary_risks; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.registered_phytosanitary_risks (
    product_id integer NOT NULL,
    risk_code character varying NOT NULL,
    risk_phrase character varying NOT NULL,
    record_checksum integer
);


--
-- Name: registered_phytosanitary_symbols; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.registered_phytosanitary_symbols (
    id character varying NOT NULL,
    symbol_name character varying
);


--
-- Name: registered_phytosanitary_target_name_to_pfi_targets; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.registered_phytosanitary_target_name_to_pfi_targets (
    ephy_name character varying NOT NULL,
    pfi_id integer,
    pfi_name character varying,
    default_pfi_treatment_type_id character varying
);


--
-- Name: registered_phytosanitary_usages; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.registered_phytosanitary_usages (
    id character varying NOT NULL,
    lib_court integer,
    product_id integer NOT NULL,
    ephy_usage_phrase character varying NOT NULL,
    crop jsonb,
    crop_label_fra character varying,
    species text[],
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


--
-- Name: registered_postal_codes; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.registered_postal_codes (
    id character varying NOT NULL,
    country character varying NOT NULL,
    code character varying NOT NULL,
    city_name character varying NOT NULL,
    postal_code character varying NOT NULL,
    city_delivery_name character varying,
    city_delivery_detail character varying,
    city_centroid postgis.geometry(Point,4326),
    city_shape postgis.geometry(MultiPolygon,4326)
);


--
-- Name: registered_protected_water_zones; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.registered_protected_water_zones (
    id character varying NOT NULL,
    administrative_zone character varying,
    creator_name character varying,
    name character varying,
    updated_on date,
    shape postgis.geometry(MultiPolygon,4326) NOT NULL
);


--
-- Name: registered_quality_and_origin_signs; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.registered_quality_and_origin_signs (
    id integer NOT NULL,
    ida integer NOT NULL,
    geographic_area character varying,
    fr_sign character varying,
    eu_sign character varying,
    product_human_name jsonb,
    product_human_name_fra character varying,
    reference_number character varying
);


--
-- Name: registered_seed_varieties; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.registered_seed_varieties (
    id character varying NOT NULL,
    id_specie character varying NOT NULL,
    specie_name jsonb,
    specie_name_fra character varying,
    variety_name character varying,
    registration_date date
);


--
-- Name: registered_soil_available_water_capacities; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.registered_soil_available_water_capacities (
    id character varying NOT NULL,
    available_water_reference_value integer,
    available_water_min_value numeric(19,4),
    available_water_max_value numeric(19,4),
    available_water_unit character varying,
    available_water_label character varying,
    shape postgis.geometry(MultiPolygon,4326) NOT NULL
);


--
-- Name: registered_soil_depths; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.registered_soil_depths (
    id character varying NOT NULL,
    soil_depth_value numeric(19,4),
    soil_depth_unit character varying,
    shape postgis.geometry(MultiPolygon,4326) NOT NULL
);


--
-- Name: registered_vine_varieties; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.registered_vine_varieties (
    id character varying NOT NULL,
    short_name character varying NOT NULL,
    long_name character varying,
    category character varying NOT NULL,
    fr_validated boolean,
    utilities text[],
    color character varying,
    custom_code character varying
);


--
-- Name: technical_sequences; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.technical_sequences (
    id character varying NOT NULL,
    family character varying,
    production_reference_name character varying NOT NULL,
    production_system character varying,
    translation_id character varying NOT NULL
);


--
-- Name: technical_workflow_procedure_items; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.technical_workflow_procedure_items (
    id character varying NOT NULL,
    actor_reference character varying,
    procedure_item_reference character varying,
    article_reference character varying,
    quantity numeric(19,4),
    unit character varying,
    procedure_reference character varying NOT NULL,
    technical_workflow_procedure_id character varying NOT NULL
);


--
-- Name: technical_workflow_procedures; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.technical_workflow_procedures (
    id character varying NOT NULL,
    "position" integer NOT NULL,
    name jsonb NOT NULL,
    repetition integer,
    frequency character varying,
    period character varying,
    bbch_stage character varying,
    procedure_reference character varying NOT NULL,
    technical_workflow_id character varying NOT NULL
);


--
-- Name: technical_workflow_sequences; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.technical_workflow_sequences (
    technical_sequence_id character varying NOT NULL,
    year_start integer,
    year_stop integer,
    technical_workflow_id character varying NOT NULL
);


--
-- Name: technical_workflows; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.technical_workflows (
    id character varying NOT NULL,
    family character varying,
    production_reference_name character varying,
    production_system character varying,
    start_day integer,
    start_month integer,
    unit character varying,
    life_state character varying,
    life_cycle character varying,
    translation_id character varying NOT NULL
);


--
-- Name: version; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.version (
    version character varying
);


--
-- Name: account_balances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_balances (
    id integer NOT NULL,
    account_id integer NOT NULL,
    financial_year_id integer NOT NULL,
    global_debit numeric(19,4) DEFAULT 0.0 NOT NULL,
    global_credit numeric(19,4) DEFAULT 0.0 NOT NULL,
    global_balance numeric(19,4) DEFAULT 0.0 NOT NULL,
    global_count integer DEFAULT 0 NOT NULL,
    local_debit numeric(19,4) DEFAULT 0.0 NOT NULL,
    local_credit numeric(19,4) DEFAULT 0.0 NOT NULL,
    local_balance numeric(19,4) DEFAULT 0.0 NOT NULL,
    local_count integer DEFAULT 0 NOT NULL,
    currency character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: account_balances_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.account_balances_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_balances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.account_balances_id_seq OWNED BY public.account_balances.id;


--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts (
    id integer NOT NULL,
    number character varying NOT NULL,
    name character varying NOT NULL,
    label character varying NOT NULL,
    debtor boolean DEFAULT false NOT NULL,
    last_letter character varying,
    description text,
    reconcilable boolean DEFAULT false NOT NULL,
    usages text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb,
    auxiliary_number character varying,
    nature character varying,
    centralizing_account_name character varying,
    already_existing boolean DEFAULT false NOT NULL,
    provider jsonb,
    last_isacompta_letter jsonb DEFAULT '{}'::jsonb
);


--
-- Name: accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts_id_seq OWNED BY public.accounts.id;


--
-- Name: activities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activities (
    id integer NOT NULL,
    name character varying NOT NULL,
    description text,
    family character varying NOT NULL,
    nature character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    with_supports boolean NOT NULL,
    with_cultivation boolean NOT NULL,
    support_variety character varying,
    cultivation_variety character varying,
    size_indicator_name character varying,
    size_unit_name character varying,
    suspended boolean DEFAULT false NOT NULL,
    production_cycle character varying NOT NULL,
    custom_fields jsonb,
    use_countings boolean DEFAULT false NOT NULL,
    use_gradings boolean DEFAULT false NOT NULL,
    measure_grading_items_count boolean DEFAULT false NOT NULL,
    measure_grading_net_mass boolean DEFAULT false NOT NULL,
    grading_net_mass_unit_name character varying,
    measure_grading_sizes boolean DEFAULT false NOT NULL,
    grading_sizes_indicator_name character varying,
    grading_sizes_unit_name character varying,
    production_system_name character varying,
    use_seasons boolean DEFAULT false,
    use_tactics boolean DEFAULT false,
    codes jsonb,
    production_started_on date,
    production_stopped_on date,
    life_duration numeric(5,2),
    start_state_of_production_year integer,
    reference_name character varying,
    distribution_key character varying,
    isacompta_analytic_code character varying(2),
    production_started_on_year integer,
    production_stopped_on_year integer
);


--
-- Name: activity_budgets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity_budgets (
    id integer NOT NULL,
    activity_id integer NOT NULL,
    campaign_id integer NOT NULL,
    currency character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    nature character varying,
    technical_itinerary_id integer
);


--
-- Name: activity_productions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity_productions (
    id integer NOT NULL,
    support_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    usage character varying NOT NULL,
    size_value numeric(19,4) NOT NULL,
    size_indicator_name character varying NOT NULL,
    size_unit_name character varying,
    activity_id integer NOT NULL,
    cultivable_zone_id integer,
    irrigated boolean DEFAULT false NOT NULL,
    nitrate_fixing boolean DEFAULT false NOT NULL,
    support_shape postgis.geometry(MultiPolygon,4326),
    support_nature character varying,
    started_on date,
    stopped_on date,
    state character varying,
    rank_number integer NOT NULL,
    campaign_id integer,
    custom_fields jsonb,
    season_id integer,
    tactic_id integer,
    technical_itinerary_id integer,
    predicated_sowing_date date,
    batch_planting boolean,
    number_of_batch integer,
    sowing_interval integer,
    provider jsonb DEFAULT '{}'::jsonb,
    headland_shape postgis.geometry(Geometry,4326),
    custom_name character varying,
    starting_year integer,
    reference_name character varying
);


--
-- Name: campaigns; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.campaigns (
    id integer NOT NULL,
    name character varying NOT NULL,
    description text,
    harvest_year integer,
    closed boolean DEFAULT false NOT NULL,
    closed_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: activities_campaigns; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.activities_campaigns AS
 SELECT DISTINCT c.id AS campaign_id,
    a.id AS activity_id
   FROM (public.activities a
     LEFT JOIN public.campaigns c ON ((((a.id, c.id) IN ( SELECT ab.activity_id,
            ab.campaign_id
           FROM public.activity_budgets ab
          WHERE ((ab.campaign_id = c.id) AND (ab.activity_id = a.id)))) OR ((a.id, c.id) IN ( SELECT ap.activity_id,
            ap.campaign_id
           FROM public.activity_productions ap
          WHERE ((ap.campaign_id = c.id) AND (ap.activity_id = a.id)))))));


--
-- Name: activities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.activities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.activities_id_seq OWNED BY public.activities.id;


--
-- Name: intervention_parameters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.intervention_parameters (
    id integer NOT NULL,
    intervention_id integer NOT NULL,
    product_id integer,
    variant_id integer,
    quantity_population numeric(19,4),
    working_zone postgis.geometry(MultiPolygon,4326),
    reference_name character varying NOT NULL,
    "position" integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    event_participation_id integer,
    outcoming_product_id integer,
    type character varying,
    new_container_id integer,
    new_group_id integer,
    new_variant_id integer,
    quantity_handler character varying,
    quantity_value numeric(19,4),
    quantity_unit_name character varying,
    quantity_indicator_name character varying,
    group_id integer,
    new_name character varying,
    component_id integer,
    assembly_id integer,
    currency character varying,
    unit_pretax_stock_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    dead boolean DEFAULT false NOT NULL,
    identification_number character varying,
    batch_number character varying,
    usage_id character varying,
    allowed_entry_factor interval,
    allowed_harvest_factor interval,
    imputation_ratio numeric(19,4) DEFAULT 1 NOT NULL,
    reference_data jsonb DEFAULT '{}'::jsonb,
    using_live_data boolean DEFAULT true,
    applications_frequency interval,
    specie_variety jsonb DEFAULT '{}'::jsonb
);


--
-- Name: intervention_working_periods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.intervention_working_periods (
    id integer NOT NULL,
    intervention_id integer,
    started_at timestamp without time zone NOT NULL,
    stopped_at timestamp without time zone NOT NULL,
    duration integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    intervention_participation_id integer,
    nature character varying
);


--
-- Name: interventions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.interventions (
    id integer NOT NULL,
    issue_id integer,
    prescription_id integer,
    procedure_name character varying NOT NULL,
    state character varying NOT NULL,
    started_at timestamp without time zone NOT NULL,
    stopped_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    event_id integer,
    number character varying,
    description text,
    working_duration integer NOT NULL,
    whole_duration integer NOT NULL,
    actions character varying,
    custom_fields jsonb,
    nature character varying NOT NULL,
    request_intervention_id integer,
    trouble_encountered boolean DEFAULT false NOT NULL,
    trouble_description text,
    accounted_at timestamp without time zone,
    currency character varying,
    journal_entry_id integer,
    request_compliant boolean,
    auto_calculate_working_periods boolean DEFAULT false,
    intervention_proposal_id integer,
    parent_id integer,
    purchase_id integer,
    costing_id integer,
    validator_id integer,
    providers jsonb,
    provider jsonb
);


--
-- Name: products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.products (
    id integer NOT NULL,
    type character varying,
    name character varying NOT NULL,
    number character varying NOT NULL,
    variant_id integer NOT NULL,
    nature_id integer NOT NULL,
    category_id integer NOT NULL,
    initial_born_at timestamp without time zone,
    initial_dead_at timestamp without time zone,
    initial_container_id integer,
    initial_owner_id integer,
    initial_enjoyer_id integer,
    initial_population numeric(19,4) DEFAULT 0.0,
    initial_shape postgis.geometry(MultiPolygon,4326),
    initial_father_id integer,
    initial_mother_id integer,
    variety character varying NOT NULL,
    derivative_of character varying,
    tracking_id integer,
    fixed_asset_id integer,
    born_at timestamp without time zone,
    dead_at timestamp without time zone,
    description text,
    picture_file_name character varying,
    picture_content_type character varying,
    picture_file_size integer,
    picture_updated_at timestamp without time zone,
    identification_number character varying,
    work_number character varying,
    address_id integer,
    parent_id integer,
    default_storage_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    person_id integer,
    initial_geolocation postgis.geometry(Point,4326),
    uuid uuid,
    initial_movement_id integer,
    custom_fields jsonb,
    team_id integer,
    member_variant_id integer,
    birth_date_completeness character varying,
    birth_farm_number character varying,
    country character varying,
    filiation_status character varying,
    first_calving_on timestamp without time zone,
    mother_country character varying,
    mother_variety character varying,
    mother_identification_number character varying,
    father_country character varying,
    father_variety character varying,
    father_identification_number character varying,
    origin_country character varying,
    origin_identification_number character varying,
    end_of_life_reason character varying,
    originator_id integer,
    codes jsonb,
    reading_cache jsonb DEFAULT '{}'::jsonb,
    activity_production_id integer,
    conditioning_unit_id integer,
    type_of_occupancy character varying,
    specie_variety jsonb DEFAULT '{}'::jsonb,
    provider jsonb DEFAULT '{}'::jsonb,
    isacompta_analytic_code character varying(2),
    worker_group_item_id integer
);


--
-- Name: activities_interventions; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.activities_interventions AS
 SELECT DISTINCT interventions.id AS intervention_id,
    activities.id AS activity_id,
    intervention_working_periods.started_at AS intervention_started_at,
    intervention_working_periods.duration AS intervention_working_duration,
    round(sum(DISTINCT intervention_parameters.imputation_ratio), 2) AS imputation_ratio,
    ((intervention_working_periods.duration)::numeric * round(sum(DISTINCT intervention_parameters.imputation_ratio), 2)) AS intervention_activity_working_duration
   FROM (((((public.activities
     JOIN public.activity_productions ON ((activity_productions.activity_id = activities.id)))
     JOIN public.products ON ((products.activity_production_id = activity_productions.id)))
     JOIN public.intervention_parameters ON (((products.id = intervention_parameters.product_id) AND ((intervention_parameters.type)::text = 'InterventionTarget'::text))))
     JOIN public.interventions ON ((intervention_parameters.intervention_id = interventions.id)))
     JOIN public.intervention_working_periods ON ((interventions.id = intervention_working_periods.intervention_id)))
  GROUP BY interventions.id, activities.id, intervention_working_periods.started_at, intervention_working_periods.duration
  ORDER BY interventions.id, activities.id, intervention_working_periods.started_at;


--
-- Name: activity_budget_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity_budget_items (
    id integer NOT NULL,
    variant_id integer,
    direction character varying NOT NULL,
    amount numeric(19,4) DEFAULT 0.0,
    unit_amount numeric(19,4) DEFAULT 0.0,
    quantity numeric(19,4) DEFAULT 0.0,
    variant_indicator character varying,
    variant_unit character varying,
    computation_method character varying NOT NULL,
    currency character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    unit_population numeric(19,4),
    unit_currency character varying NOT NULL,
    activity_budget_id integer NOT NULL,
    used_on date,
    paid_on date,
    product_parameter_id integer,
    nature character varying,
    origin character varying,
    unit_id integer,
    repetition integer DEFAULT 1 NOT NULL,
    frequency character varying DEFAULT 'per_year'::character varying NOT NULL,
    global_amount numeric(19,4),
    main_output boolean DEFAULT false NOT NULL,
    use_transfer_price boolean DEFAULT false,
    transfer_price double precision,
    locked boolean DEFAULT false,
    transfered_activity_budget_id integer
);


--
-- Name: activity_budget_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.activity_budget_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_budget_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.activity_budget_items_id_seq OWNED BY public.activity_budget_items.id;


--
-- Name: activity_budgets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.activity_budgets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_budgets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.activity_budgets_id_seq OWNED BY public.activity_budgets.id;


--
-- Name: activity_distributions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity_distributions (
    id integer NOT NULL,
    activity_id integer NOT NULL,
    affectation_percentage numeric(19,4) NOT NULL,
    main_activity_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: activity_distributions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.activity_distributions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_distributions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.activity_distributions_id_seq OWNED BY public.activity_distributions.id;


--
-- Name: activity_inspection_calibration_natures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity_inspection_calibration_natures (
    id integer NOT NULL,
    scale_id integer NOT NULL,
    marketable boolean DEFAULT false NOT NULL,
    minimal_value numeric(19,4) NOT NULL,
    maximal_value numeric(19,4) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: activity_inspection_calibration_natures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.activity_inspection_calibration_natures_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_inspection_calibration_natures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.activity_inspection_calibration_natures_id_seq OWNED BY public.activity_inspection_calibration_natures.id;


--
-- Name: activity_inspection_calibration_scales; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity_inspection_calibration_scales (
    id integer NOT NULL,
    activity_id integer NOT NULL,
    size_indicator_name character varying NOT NULL,
    size_unit_name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: activity_inspection_calibration_scales_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.activity_inspection_calibration_scales_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_inspection_calibration_scales_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.activity_inspection_calibration_scales_id_seq OWNED BY public.activity_inspection_calibration_scales.id;


--
-- Name: activity_inspection_point_natures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity_inspection_point_natures (
    id integer NOT NULL,
    activity_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    name character varying NOT NULL,
    category character varying NOT NULL
);


--
-- Name: activity_inspection_point_natures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.activity_inspection_point_natures_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_inspection_point_natures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.activity_inspection_point_natures_id_seq OWNED BY public.activity_inspection_point_natures.id;


--
-- Name: activity_production_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity_production_batches (
    id integer NOT NULL,
    number integer,
    day_interval integer,
    irregular_batch boolean DEFAULT false,
    activity_production_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    planning_scenario_activity_plot_id integer
);


--
-- Name: activity_production_batches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.activity_production_batches_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_production_batches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.activity_production_batches_id_seq OWNED BY public.activity_production_batches.id;


--
-- Name: activity_production_irregular_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity_production_irregular_batches (
    id integer NOT NULL,
    activity_production_batch_id integer,
    estimated_sowing_date date,
    area numeric,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: activity_production_irregular_batches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.activity_production_irregular_batches_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_production_irregular_batches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.activity_production_irregular_batches_id_seq OWNED BY public.activity_production_irregular_batches.id;


--
-- Name: activity_productions_campaigns; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.activity_productions_campaigns AS
 SELECT DISTINCT c.id AS campaign_id,
    ap.id AS activity_production_id
   FROM ((public.activity_productions ap
     JOIN public.activities a ON ((ap.activity_id = a.id)))
     JOIN public.campaigns c ON ((c.id = ap.campaign_id)))
  WHERE ((a.production_cycle)::text = 'annual'::text)
UNION
 SELECT DISTINCT c.id AS campaign_id,
    ap.id AS activity_production_id
   FROM ((public.activity_productions ap
     JOIN public.campaigns c ON ((((date_part('year'::text, ap.started_on) <= (c.harvest_year)::double precision) AND ((c.harvest_year)::double precision < date_part('year'::text, ap.stopped_on))) OR ((date_part('year'::text, ap.started_on) < (c.harvest_year)::double precision) AND ((c.harvest_year)::double precision <= date_part('year'::text, ap.stopped_on))))))
     JOIN public.activities a ON ((ap.activity_id = a.id)))
  WHERE (((a.production_cycle)::text = 'perennial'::text) AND (ap.stopped_on IS NOT NULL) AND (ap.started_on IS NOT NULL))
  ORDER BY 1, 2;


--
-- Name: activity_productions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.activity_productions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_productions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.activity_productions_id_seq OWNED BY public.activity_productions.id;


--
-- Name: activity_productions_interventions; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.activity_productions_interventions AS
 SELECT DISTINCT interventions.id AS intervention_id,
    products.activity_production_id,
    intervention_working_periods.started_at AS intervention_started_at,
    intervention_working_periods.duration AS intervention_working_duration,
    round(sum(DISTINCT intervention_parameters.imputation_ratio), 2) AS imputation_ratio,
    ((intervention_working_periods.duration)::numeric * round(sum(DISTINCT intervention_parameters.imputation_ratio), 2)) AS intervention_activity_working_duration
   FROM ((((public.activity_productions
     JOIN public.products ON ((products.activity_production_id = activity_productions.id)))
     JOIN public.intervention_parameters ON (((products.id = intervention_parameters.product_id) AND ((intervention_parameters.type)::text = 'InterventionTarget'::text))))
     JOIN public.interventions ON ((intervention_parameters.intervention_id = interventions.id)))
     JOIN public.intervention_working_periods ON ((interventions.id = intervention_working_periods.intervention_id)))
  GROUP BY interventions.id, products.activity_production_id, intervention_working_periods.started_at, intervention_working_periods.duration
  ORDER BY interventions.id, products.activity_production_id, intervention_working_periods.started_at;


--
-- Name: intervention_costings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.intervention_costings (
    id integer NOT NULL,
    inputs_cost numeric,
    doers_cost numeric,
    tools_cost numeric,
    receptions_cost numeric,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: activity_productions_interventions_costs; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.activity_productions_interventions_costs AS
 SELECT activity_productions.id AS activity_production_id,
    interventions.id AS intervention_id,
    intervention_targets.product_id AS target_id,
    (intervention_costings.inputs_cost * intervention_targets.imputation_ratio) AS inputs,
    (intervention_costings.doers_cost * intervention_targets.imputation_ratio) AS doers,
    (intervention_costings.tools_cost * intervention_targets.imputation_ratio) AS tools,
    (intervention_costings.receptions_cost * intervention_targets.imputation_ratio) AS receptions,
    ((((intervention_costings.inputs_cost + intervention_costings.doers_cost) + intervention_costings.tools_cost) + intervention_costings.receptions_cost) * intervention_targets.imputation_ratio) AS total
   FROM ((((public.activity_productions
     JOIN public.products ON ((products.activity_production_id = activity_productions.id)))
     JOIN public.intervention_parameters intervention_targets ON (((intervention_targets.product_id = products.id) AND ((intervention_targets.type)::text = 'InterventionTarget'::text))))
     JOIN public.interventions ON ((interventions.id = intervention_targets.intervention_id)))
     JOIN public.intervention_costings ON ((interventions.costing_id = intervention_costings.id)))
  WHERE (((interventions.state)::text <> 'rejected'::text) AND ((interventions.nature)::text = 'record'::text));


--
-- Name: activity_seasons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity_seasons (
    id integer NOT NULL,
    activity_id integer NOT NULL,
    name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: activity_seasons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.activity_seasons_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_seasons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.activity_seasons_id_seq OWNED BY public.activity_seasons.id;


--
-- Name: activity_tactics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity_tactics (
    id integer NOT NULL,
    activity_id integer NOT NULL,
    name character varying NOT NULL,
    planned_on date,
    mode_delta integer,
    mode character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    "default" boolean DEFAULT false,
    technical_workflow_id character varying,
    campaign_id integer,
    technical_itinerary_id integer,
    technical_sequence_id character varying
);


--
-- Name: activity_tactics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.activity_tactics_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_tactics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.activity_tactics_id_seq OWNED BY public.activity_tactics.id;


--
-- Name: affairs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.affairs (
    id integer NOT NULL,
    number character varying,
    closed boolean DEFAULT false NOT NULL,
    closed_at timestamp without time zone,
    third_id integer NOT NULL,
    currency character varying NOT NULL,
    debit numeric(19,4) DEFAULT 0.0 NOT NULL,
    credit numeric(19,4) DEFAULT 0.0 NOT NULL,
    accounted_at timestamp without time zone,
    journal_entry_id integer,
    deals_count integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    cash_session_id integer,
    responsible_id integer,
    dead_line_at timestamp without time zone,
    name character varying,
    description text,
    pretax_amount numeric(19,4) DEFAULT 0.0,
    origin character varying,
    type character varying,
    state character varying,
    probability_percentage numeric(19,4) DEFAULT 0.0,
    letter character varying
);


--
-- Name: affairs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.affairs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: affairs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.affairs_id_seq OWNED BY public.affairs.id;


--
-- Name: alert_phases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alert_phases (
    id integer NOT NULL,
    alert_id integer NOT NULL,
    started_at timestamp without time zone NOT NULL,
    level integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: alert_phases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.alert_phases_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: alert_phases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.alert_phases_id_seq OWNED BY public.alert_phases.id;


--
-- Name: alerts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alerts (
    id integer NOT NULL,
    sensor_id integer,
    nature character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: alerts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.alerts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: alerts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.alerts_id_seq OWNED BY public.alerts.id;


--
-- Name: analyses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.analyses (
    id integer NOT NULL,
    number character varying NOT NULL,
    nature character varying NOT NULL,
    reference_number character varying,
    product_id integer,
    sampler_id integer,
    analyser_id integer,
    description text,
    geolocation postgis.geometry(Point,4326),
    sampled_at timestamp without time zone NOT NULL,
    analysed_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    host_id integer,
    sensor_id integer,
    sampling_temporal_mode character varying DEFAULT 'instant'::character varying NOT NULL,
    stopped_at timestamp without time zone,
    retrieval_status character varying DEFAULT 'ok'::character varying NOT NULL,
    retrieval_message character varying,
    custom_fields jsonb
);


--
-- Name: analyses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.analyses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: analyses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.analyses_id_seq OWNED BY public.analyses.id;


--
-- Name: analysis_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.analysis_items (
    id integer NOT NULL,
    analysis_id integer NOT NULL,
    indicator_name character varying NOT NULL,
    indicator_datatype character varying NOT NULL,
    absolute_measure_value_value numeric(19,4),
    absolute_measure_value_unit character varying,
    boolean_value boolean DEFAULT false NOT NULL,
    choice_value character varying,
    decimal_value numeric(19,4),
    multi_polygon_value postgis.geometry(MultiPolygon,4326),
    integer_value integer,
    measure_value_value numeric(19,4),
    measure_value_unit character varying,
    point_value postgis.geometry(Point,4326),
    string_value text,
    annotation text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    product_reading_id integer,
    geometry_value postgis.geometry(Geometry,4326)
);


--
-- Name: analysis_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.analysis_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: analysis_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.analysis_items_id_seq OWNED BY public.analysis_items.id;


--
-- Name: analytic_segments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.analytic_segments (
    id integer NOT NULL,
    analytic_sequence_id integer NOT NULL,
    name character varying NOT NULL,
    "position" integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: analytic_segments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.analytic_segments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: analytic_segments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.analytic_segments_id_seq OWNED BY public.analytic_segments.id;


--
-- Name: analytic_sequences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.analytic_sequences (
    id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: analytic_sequences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.analytic_sequences_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: analytic_sequences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.analytic_sequences_id_seq OWNED BY public.analytic_sequences.id;


--
-- Name: product_memberships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_memberships (
    id integer NOT NULL,
    originator_type character varying,
    originator_id integer,
    member_id integer NOT NULL,
    nature character varying NOT NULL,
    group_id integer NOT NULL,
    started_at timestamp without time zone NOT NULL,
    stopped_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    intervention_id integer
);


--
-- Name: animals_interventions; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.animals_interventions AS
 SELECT 'animal_group'::text AS initial_target,
    intervention.id AS intervention_id,
    animal_group.id AS animal_group_id,
    animal.id AS animal_id
   FROM ((((public.interventions intervention
     JOIN public.intervention_parameters target ON (((target.intervention_id = intervention.id) AND ((target.type)::text = 'InterventionTarget'::text))))
     JOIN public.products animal_group ON (((animal_group.id = target.product_id) AND ((animal_group.type)::text = 'AnimalGroup'::text))))
     LEFT JOIN public.product_memberships pm ON (((pm.group_id = animal_group.id) AND (((intervention.started_at >= pm.started_at) AND (intervention.started_at <= pm.stopped_at)) OR ((intervention.started_at > pm.started_at) AND (pm.stopped_at IS NULL)) OR ((intervention.stopped_at >= pm.started_at) AND (intervention.stopped_at <= pm.stopped_at)) OR ((intervention.stopped_at > pm.started_at) AND (pm.stopped_at IS NULL))))))
     LEFT JOIN public.products animal ON (((pm.member_id = animal.id) AND ((animal.type)::text = 'Animal'::text))))
  GROUP BY intervention.id, animal.id, animal_group.id, pm.group_id
UNION ALL
 SELECT 'animal'::text AS initial_target,
    intervention.id AS intervention_id,
    animal_group.id AS animal_group_id,
    animal.id AS animal_id
   FROM ((((public.interventions intervention
     JOIN public.intervention_parameters target ON (((target.intervention_id = intervention.id) AND ((target.type)::text = 'InterventionTarget'::text))))
     JOIN public.products animal ON (((animal.id = target.product_id) AND ((animal.type)::text = 'Animal'::text))))
     LEFT JOIN public.product_memberships pm ON (((pm.member_id = animal.id) AND (((intervention.started_at >= pm.started_at) AND (intervention.started_at <= pm.stopped_at)) OR ((intervention.started_at > pm.started_at) AND (pm.stopped_at IS NULL)) OR ((intervention.stopped_at >= pm.started_at) AND (intervention.stopped_at <= pm.stopped_at)) OR ((intervention.stopped_at > pm.started_at) AND (pm.stopped_at IS NULL))))))
     LEFT JOIN public.products animal_group ON (((pm.group_id = animal_group.id) AND ((animal_group.type)::text = 'AnimalGroup'::text))))
  GROUP BY intervention.id, animal.id, animal_group.id, pm.group_id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.attachments (
    id integer NOT NULL,
    resource_type character varying NOT NULL,
    resource_id integer NOT NULL,
    document_id integer NOT NULL,
    nature character varying,
    expired_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    deleted_at timestamp without time zone,
    deleter_id integer
);


--
-- Name: attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.attachments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.attachments_id_seq OWNED BY public.attachments.id;


--
-- Name: bank_statement_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bank_statement_items (
    id integer NOT NULL,
    bank_statement_id integer NOT NULL,
    name character varying NOT NULL,
    debit numeric(19,4) DEFAULT 0.0 NOT NULL,
    credit numeric(19,4) DEFAULT 0.0 NOT NULL,
    currency character varying NOT NULL,
    transfered_on date NOT NULL,
    initiated_on date,
    transaction_number character varying,
    letter character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    memo character varying,
    accounted_at timestamp without time zone,
    journal_entry_id integer,
    transaction_nature character varying
);


--
-- Name: bank_statement_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bank_statement_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bank_statement_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bank_statement_items_id_seq OWNED BY public.bank_statement_items.id;


--
-- Name: bank_statements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bank_statements (
    id integer NOT NULL,
    cash_id integer NOT NULL,
    started_on date NOT NULL,
    stopped_on date NOT NULL,
    number character varying NOT NULL,
    debit numeric(19,4) DEFAULT 0.0 NOT NULL,
    credit numeric(19,4) DEFAULT 0.0 NOT NULL,
    currency character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb,
    initial_balance_debit numeric(19,4) DEFAULT 0.0 NOT NULL,
    initial_balance_credit numeric(19,4) DEFAULT 0.0 NOT NULL,
    journal_entry_id integer,
    accounted_at timestamp without time zone
);


--
-- Name: bank_statements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bank_statements_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bank_statements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bank_statements_id_seq OWNED BY public.bank_statements.id;


--
-- Name: call_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.call_messages (
    id integer NOT NULL,
    status character varying,
    headers text,
    body text,
    type character varying,
    nature character varying NOT NULL,
    ip_address character varying,
    url character varying,
    format character varying,
    ssl character varying,
    verb character varying,
    request_id integer,
    call_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: call_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.call_messages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: call_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.call_messages_id_seq OWNED BY public.call_messages.id;


--
-- Name: calls; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.calls (
    id integer NOT NULL,
    state character varying,
    integration_name character varying,
    name character varying,
    arguments jsonb,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    source_type character varying,
    source_id integer
);


--
-- Name: calls_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.calls_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: calls_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.calls_id_seq OWNED BY public.calls.id;


--
-- Name: campaigns_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.campaigns_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: campaigns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.campaigns_id_seq OWNED BY public.campaigns.id;


--
-- Name: campaigns_interventions; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.campaigns_interventions AS
 SELECT DISTINCT c.id AS campaign_id,
    i.id AS intervention_id
   FROM (((((public.interventions i
     JOIN public.intervention_parameters ip ON ((ip.intervention_id = i.id)))
     JOIN public.products p ON (((p.id = ip.product_id) AND ((p.type)::text <> 'Animal'::text))))
     JOIN public.activity_productions ap ON ((ap.id = p.activity_production_id)))
     JOIN public.activities a ON ((a.id = ap.activity_id)))
     JOIN public.campaigns c ON (((c.id = ap.campaign_id) OR (((a.production_cycle)::text = 'perennial'::text) AND (i.started_at >= ap.started_on) AND (i.started_at > COALESCE(make_date(((c.harvest_year + a.production_stopped_on_year) - 1), (date_part('month'::text, a.production_stopped_on))::integer, (date_part('day'::text, a.production_stopped_on))::integer), make_date((c.harvest_year - 1), 12, 31))) AND (i.started_at <= COALESCE(make_date((c.harvest_year + a.production_stopped_on_year), (date_part('month'::text, a.production_stopped_on))::integer, (date_part('day'::text, a.production_stopped_on))::integer), make_date(c.harvest_year, 12, 31))) AND (i.started_at <= ap.stopped_on)))))
UNION ALL
 SELECT DISTINCT c.id AS campaign_id,
    i.id AS intervention_id
   FROM (((((((public.interventions i
     JOIN public.intervention_parameters ip ON ((ip.intervention_id = i.id)))
     JOIN public.products p ON (((p.id = ip.product_id) AND ((p.type)::text = 'Animal'::text))))
     JOIN public.product_memberships pm ON (((pm.member_id = p.id) AND (((i.started_at >= pm.started_at) AND (i.started_at <= pm.stopped_at)) OR ((i.started_at > pm.started_at) AND (pm.stopped_at IS NULL)) OR ((i.stopped_at >= pm.started_at) AND (i.stopped_at <= pm.stopped_at)) OR ((i.stopped_at > pm.started_at) AND (pm.stopped_at IS NULL))))))
     JOIN public.products animal_group ON (((pm.group_id = animal_group.id) AND ((animal_group.type)::text = 'AnimalGroup'::text))))
     JOIN public.activity_productions ap ON ((ap.id = animal_group.activity_production_id)))
     JOIN public.activities a ON ((a.id = ap.activity_id)))
     JOIN public.campaigns c ON (((c.id = ap.campaign_id) OR (((a.production_cycle)::text = 'perennial'::text) AND (i.started_at >= ap.started_on) AND (i.started_at > COALESCE(make_date(((c.harvest_year + a.production_stopped_on_year) - 1), (date_part('month'::text, a.production_stopped_on))::integer, (date_part('day'::text, a.production_stopped_on))::integer), make_date((c.harvest_year - 1), 12, 31))) AND (i.started_at <= COALESCE(make_date((c.harvest_year + a.production_stopped_on_year), (date_part('month'::text, a.production_stopped_on))::integer, (date_part('day'::text, a.production_stopped_on))::integer), make_date(c.harvest_year, 12, 31))) AND (i.started_at <= ap.stopped_on)))));


--
-- Name: cap_islets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cap_islets (
    id integer NOT NULL,
    cap_statement_id integer NOT NULL,
    islet_number character varying NOT NULL,
    town_number character varying,
    shape postgis.geometry(MultiPolygon,4326) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: cap_islets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cap_islets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cap_islets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cap_islets_id_seq OWNED BY public.cap_islets.id;


--
-- Name: cap_land_parcels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cap_land_parcels (
    id integer NOT NULL,
    cap_islet_id integer NOT NULL,
    support_id integer,
    land_parcel_number character varying NOT NULL,
    main_crop_code character varying NOT NULL,
    main_crop_precision character varying,
    main_crop_seed_production boolean DEFAULT false NOT NULL,
    main_crop_commercialisation boolean DEFAULT false NOT NULL,
    shape postgis.geometry(MultiPolygon,4326) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: cap_land_parcels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cap_land_parcels_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cap_land_parcels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cap_land_parcels_id_seq OWNED BY public.cap_land_parcels.id;


--
-- Name: cap_neutral_areas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cap_neutral_areas (
    id integer NOT NULL,
    cap_statement_id integer NOT NULL,
    number character varying NOT NULL,
    category character varying NOT NULL,
    nature character varying NOT NULL,
    shape postgis.geometry(Geometry,4326) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: cap_neutral_areas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cap_neutral_areas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cap_neutral_areas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cap_neutral_areas_id_seq OWNED BY public.cap_neutral_areas.id;


--
-- Name: cap_statements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cap_statements (
    id integer NOT NULL,
    campaign_id integer NOT NULL,
    declarant_id integer,
    pacage_number character varying,
    siret_number character varying,
    farm_name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: cap_statements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cap_statements_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cap_statements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cap_statements_id_seq OWNED BY public.cap_statements.id;


--
-- Name: cash_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cash_sessions (
    id integer NOT NULL,
    cash_id integer NOT NULL,
    number character varying,
    started_at timestamp without time zone NOT NULL,
    stopped_at timestamp without time zone,
    currency character varying,
    noticed_start_amount numeric(19,4) DEFAULT 0.0,
    noticed_stop_amount numeric(19,4) DEFAULT 0.0,
    expected_stop_amount numeric(19,4) DEFAULT 0.0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: cash_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cash_sessions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cash_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cash_sessions_id_seq OWNED BY public.cash_sessions.id;


--
-- Name: cash_transfers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cash_transfers (
    id integer NOT NULL,
    number character varying NOT NULL,
    description text,
    transfered_at timestamp without time zone NOT NULL,
    accounted_at timestamp without time zone,
    emission_amount numeric(19,4) NOT NULL,
    emission_currency character varying NOT NULL,
    emission_cash_id integer NOT NULL,
    emission_journal_entry_id integer,
    currency_rate numeric(19,10) NOT NULL,
    reception_amount numeric(19,4) NOT NULL,
    reception_currency character varying NOT NULL,
    reception_cash_id integer NOT NULL,
    reception_journal_entry_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb
);


--
-- Name: cash_transfers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cash_transfers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cash_transfers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cash_transfers_id_seq OWNED BY public.cash_transfers.id;


--
-- Name: cashes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cashes (
    id integer NOT NULL,
    name character varying NOT NULL,
    nature character varying DEFAULT 'bank_account'::character varying NOT NULL,
    journal_id integer NOT NULL,
    main_account_id integer NOT NULL,
    bank_code character varying,
    bank_agency_code character varying,
    bank_account_number character varying,
    bank_account_key character varying,
    bank_agency_address text,
    bank_name character varying,
    mode character varying DEFAULT 'iban'::character varying NOT NULL,
    bank_identifier_code character varying,
    iban character varying,
    spaced_iban character varying,
    currency character varying NOT NULL,
    country character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    container_id integer,
    last_number integer,
    owner_id integer,
    custom_fields jsonb,
    bank_account_holder_name character varying,
    suspend_until_reconciliation boolean DEFAULT false NOT NULL,
    suspense_account_id integer,
    by_default boolean DEFAULT false,
    enable_bookkeep_bank_item_details boolean DEFAULT false,
    provider jsonb
);


--
-- Name: cashes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cashes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cashes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cashes_id_seq OWNED BY public.cashes.id;


--
-- Name: catalog_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.catalog_items (
    id integer NOT NULL,
    name character varying NOT NULL,
    variant_id integer NOT NULL,
    catalog_id integer NOT NULL,
    reference_tax_id integer,
    amount numeric(19,4) NOT NULL,
    all_taxes_included boolean DEFAULT false NOT NULL,
    currency character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    commercial_description text,
    commercial_name character varying,
    started_at timestamp without time zone NOT NULL,
    stopped_at timestamp without time zone,
    reference_name character varying,
    unit_id integer NOT NULL,
    sale_item_id integer,
    purchase_item_id integer
);


--
-- Name: catalog_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.catalog_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: catalog_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.catalog_items_id_seq OWNED BY public.catalog_items.id;


--
-- Name: catalogs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.catalogs (
    id integer NOT NULL,
    name character varying NOT NULL,
    usage character varying NOT NULL,
    code character varying NOT NULL,
    by_default boolean DEFAULT false NOT NULL,
    all_taxes_included boolean DEFAULT false NOT NULL,
    currency character varying NOT NULL,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    provider jsonb
);


--
-- Name: catalogs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.catalogs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: catalogs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.catalogs_id_seq OWNED BY public.catalogs.id;


--
-- Name: contract_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contract_items (
    id integer NOT NULL,
    contract_id integer NOT NULL,
    variant_id integer NOT NULL,
    quantity numeric(19,4) DEFAULT 0.0 NOT NULL,
    unit_pretax_amount numeric(19,4) NOT NULL,
    pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: contract_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contract_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contract_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contract_items_id_seq OWNED BY public.contract_items.id;


--
-- Name: contracts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contracts (
    id integer NOT NULL,
    number character varying,
    description character varying,
    state character varying,
    reference_number character varying,
    started_on date,
    stopped_on date,
    custom_fields jsonb,
    pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    currency character varying NOT NULL,
    responsible_id integer NOT NULL,
    supplier_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: contracts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contracts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contracts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contracts_id_seq OWNED BY public.contracts.id;


--
-- Name: crop_group_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.crop_group_items (
    id integer NOT NULL,
    crop_group_id integer,
    crop_type character varying,
    crop_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    lock_version integer DEFAULT 0 NOT NULL,
    creator_id integer,
    updater_id integer
);


--
-- Name: crop_group_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.crop_group_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crop_group_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.crop_group_items_id_seq OWNED BY public.crop_group_items.id;


--
-- Name: crop_group_labellings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.crop_group_labellings (
    id integer NOT NULL,
    crop_group_id integer,
    label_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    lock_version integer DEFAULT 0 NOT NULL,
    creator_id integer,
    updater_id integer
);


--
-- Name: crop_group_labellings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.crop_group_labellings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crop_group_labellings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.crop_group_labellings_id_seq OWNED BY public.crop_group_labellings.id;


--
-- Name: crop_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.crop_groups (
    id integer NOT NULL,
    name character varying NOT NULL,
    target character varying DEFAULT 'plant'::character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    lock_version integer DEFAULT 0 NOT NULL,
    creator_id integer,
    updater_id integer
);


--
-- Name: crop_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.crop_groups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crop_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.crop_groups_id_seq OWNED BY public.crop_groups.id;


--
-- Name: crumbs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.crumbs (
    id integer NOT NULL,
    user_id integer,
    geolocation postgis.geometry(Point,4326) NOT NULL,
    read_at timestamp without time zone NOT NULL,
    accuracy numeric(19,4) NOT NULL,
    nature character varying NOT NULL,
    metadata text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    intervention_parameter_id integer,
    device_uid character varying NOT NULL,
    intervention_participation_id integer,
    provider jsonb,
    ride_id integer
);


--
-- Name: crumbs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.crumbs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crumbs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.crumbs_id_seq OWNED BY public.crumbs.id;


--
-- Name: cultivable_zones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cultivable_zones (
    id integer NOT NULL,
    name character varying NOT NULL,
    work_number character varying NOT NULL,
    shape postgis.geometry(MultiPolygon,4326) NOT NULL,
    description text,
    uuid uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb,
    production_system_name character varying,
    soil_nature character varying,
    owner_id integer,
    farmer_id integer,
    codes jsonb,
    provider jsonb
);


--
-- Name: cultivable_zones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cultivable_zones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cultivable_zones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cultivable_zones_id_seq OWNED BY public.cultivable_zones.id;


--
-- Name: custom_field_choices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.custom_field_choices (
    id integer NOT NULL,
    custom_field_id integer NOT NULL,
    name character varying NOT NULL,
    value character varying,
    "position" integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: custom_field_choices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.custom_field_choices_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: custom_field_choices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.custom_field_choices_id_seq OWNED BY public.custom_field_choices.id;


--
-- Name: custom_fields; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.custom_fields (
    id integer NOT NULL,
    name character varying NOT NULL,
    nature character varying NOT NULL,
    column_name character varying NOT NULL,
    active boolean DEFAULT true NOT NULL,
    required boolean DEFAULT false NOT NULL,
    maximal_length integer,
    minimal_value numeric(19,4),
    maximal_value numeric(19,4),
    customized_type character varying NOT NULL,
    minimal_length integer,
    "position" integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: custom_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.custom_fields_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: custom_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.custom_fields_id_seq OWNED BY public.custom_fields.id;


--
-- Name: cvi_cadastral_plant_cvi_land_parcels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cvi_cadastral_plant_cvi_land_parcels (
    id integer NOT NULL,
    percentage numeric DEFAULT 1.0,
    cvi_land_parcel_id integer,
    cvi_cadastral_plant_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    lock_version integer DEFAULT 0 NOT NULL,
    creator_id integer,
    updater_id integer
);


--
-- Name: cvi_cadastral_plant_cvi_land_parcels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cvi_cadastral_plant_cvi_land_parcels_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cvi_cadastral_plant_cvi_land_parcels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cvi_cadastral_plant_cvi_land_parcels_id_seq OWNED BY public.cvi_cadastral_plant_cvi_land_parcels.id;


--
-- Name: cvi_cadastral_plants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cvi_cadastral_plants (
    id integer NOT NULL,
    section character varying NOT NULL,
    work_number character varying NOT NULL,
    land_parcel_number character varying,
    designation_of_origin_id integer,
    vine_variety_id character varying,
    area_value numeric(19,4),
    area_unit character varying,
    planting_campaign character varying,
    rootstock_id character varying,
    inter_vine_plant_distance_value numeric(19,4),
    inter_vine_plant_distance_unit character varying,
    inter_row_distance_value numeric(19,4),
    inter_row_distance_unit character varying,
    state character varying NOT NULL,
    cvi_statement_id integer,
    land_parcel_id character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    type_of_occupancy character varying,
    cvi_cultivable_zone_id integer,
    cadastral_ref_updated boolean DEFAULT false,
    land_modification_date date,
    lock_version integer DEFAULT 0 NOT NULL,
    creator_id integer,
    updater_id integer
);


--
-- Name: cvi_cadastral_plants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cvi_cadastral_plants_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cvi_cadastral_plants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cvi_cadastral_plants_id_seq OWNED BY public.cvi_cadastral_plants.id;


--
-- Name: cvi_cultivable_zones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cvi_cultivable_zones (
    id integer NOT NULL,
    name character varying NOT NULL,
    declared_area_unit character varying,
    declared_area_value numeric(19,4),
    calculated_area_unit character varying,
    calculated_area_value numeric(19,4),
    land_parcels_status character varying DEFAULT 'not_started'::character varying,
    shape postgis.geometry(Geometry,4326),
    cvi_statement_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    lock_version integer DEFAULT 0 NOT NULL,
    creator_id integer,
    updater_id integer
);


--
-- Name: cvi_cultivable_zones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cvi_cultivable_zones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cvi_cultivable_zones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cvi_cultivable_zones_id_seq OWNED BY public.cvi_cultivable_zones.id;


--
-- Name: cvi_land_parcels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cvi_land_parcels (
    id integer NOT NULL,
    name character varying NOT NULL,
    designation_of_origin_id integer,
    vine_variety_id character varying,
    calculated_area_unit character varying,
    calculated_area_value numeric(19,5),
    declared_area_unit character varying,
    declared_area_value numeric(19,5),
    shape postgis.geometry(Geometry,4326),
    inter_vine_plant_distance_value numeric(19,4),
    inter_vine_plant_distance_unit character varying,
    inter_row_distance_value numeric(19,4),
    inter_row_distance_unit character varying,
    state character varying,
    cvi_cultivable_zone_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    planting_campaign character varying,
    land_modification_date date,
    activity_id integer,
    rootstock_id character varying,
    lock_version integer DEFAULT 0 NOT NULL,
    creator_id integer,
    updater_id integer
);


--
-- Name: cvi_land_parcels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cvi_land_parcels_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cvi_land_parcels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cvi_land_parcels_id_seq OWNED BY public.cvi_land_parcels.id;


--
-- Name: cvi_statements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cvi_statements (
    id integer NOT NULL,
    cvi_number character varying NOT NULL,
    extraction_date date NOT NULL,
    siret_number character varying NOT NULL,
    farm_name character varying NOT NULL,
    declarant character varying NOT NULL,
    total_area_value numeric(19,4),
    total_area_unit character varying,
    cadastral_plant_count integer DEFAULT 0,
    cadastral_sub_plant_count integer DEFAULT 0,
    state character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    campaign_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    creator_id integer,
    updater_id integer
);


--
-- Name: cvi_statements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cvi_statements_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cvi_statements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cvi_statements_id_seq OWNED BY public.cvi_statements.id;


--
-- Name: daily_charges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.daily_charges (
    id integer NOT NULL,
    reference_date date,
    product_type character varying,
    product_general_type character varying,
    quantity numeric,
    area numeric,
    intervention_template_product_parameter_id integer,
    activity_production_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    activity_id integer
);


--
-- Name: daily_charges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.daily_charges_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: daily_charges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.daily_charges_id_seq OWNED BY public.daily_charges.id;


--
-- Name: dashboards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dashboards (
    id integer NOT NULL,
    owner_id integer NOT NULL,
    name character varying NOT NULL,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: dashboards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dashboards_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dashboards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dashboards_id_seq OWNED BY public.dashboards.id;


--
-- Name: debt_transfers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.debt_transfers (
    id integer NOT NULL,
    affair_id integer NOT NULL,
    debt_transfer_affair_id integer NOT NULL,
    amount numeric(19,4) DEFAULT 0.0,
    number character varying,
    nature character varying NOT NULL,
    currency character varying NOT NULL,
    journal_entry_id integer,
    accounted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: debt_transfers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.debt_transfers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: debt_transfers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.debt_transfers_id_seq OWNED BY public.debt_transfers.id;


--
-- Name: deliveries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.deliveries (
    id integer NOT NULL,
    transporter_id integer,
    responsible_id integer,
    started_at timestamp without time zone,
    annotation text,
    number character varying,
    reference_number character varying,
    transporter_purchase_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    stopped_at timestamp without time zone,
    state character varying NOT NULL,
    driver_id integer,
    mode character varying,
    custom_fields jsonb
);


--
-- Name: deliveries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.deliveries_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: deliveries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.deliveries_id_seq OWNED BY public.deliveries.id;


--
-- Name: delivery_tools; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delivery_tools (
    id integer NOT NULL,
    delivery_id integer,
    tool_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: delivery_tools_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.delivery_tools_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delivery_tools_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.delivery_tools_id_seq OWNED BY public.delivery_tools.id;


--
-- Name: deposits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.deposits (
    id integer NOT NULL,
    number character varying NOT NULL,
    cash_id integer NOT NULL,
    mode_id integer NOT NULL,
    amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    payments_count integer DEFAULT 0 NOT NULL,
    description text,
    locked boolean DEFAULT false NOT NULL,
    responsible_id integer,
    accounted_at timestamp without time zone,
    journal_entry_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb
);


--
-- Name: deposits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.deposits_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: deposits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.deposits_id_seq OWNED BY public.deposits.id;


--
-- Name: districts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.districts (
    id integer NOT NULL,
    name character varying NOT NULL,
    code character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: districts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.districts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: districts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.districts_id_seq OWNED BY public.districts.id;


--
-- Name: document_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.document_templates (
    id integer NOT NULL,
    name character varying NOT NULL,
    active boolean DEFAULT false NOT NULL,
    by_default boolean DEFAULT false NOT NULL,
    nature character varying NOT NULL,
    language character varying NOT NULL,
    archiving character varying NOT NULL,
    managed boolean DEFAULT false NOT NULL,
    formats character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    file_extension character varying DEFAULT 'xml'::character varying,
    signed boolean DEFAULT false NOT NULL
);


--
-- Name: document_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.document_templates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: document_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.document_templates_id_seq OWNED BY public.document_templates.id;


--
-- Name: documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.documents (
    id integer NOT NULL,
    number character varying NOT NULL,
    name character varying NOT NULL,
    nature character varying,
    key character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    uploaded boolean DEFAULT false NOT NULL,
    template_id integer,
    file_file_name character varying,
    file_file_size integer,
    file_content_type character varying,
    file_updated_at timestamp without time zone,
    file_fingerprint character varying,
    file_pages_count integer,
    file_content_text text,
    custom_fields jsonb,
    sha256_fingerprint character varying,
    signature text,
    mandatory boolean DEFAULT false,
    processable_attachment boolean DEFAULT true NOT NULL
);


--
-- Name: documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.documents_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.documents_id_seq OWNED BY public.documents.id;


--
-- Name: economic_cash_indicators; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.economic_cash_indicators (
    id integer NOT NULL,
    context character varying,
    context_color character varying,
    activity_id integer,
    activity_budget_id integer,
    activity_budget_item_id integer,
    worker_contract_id integer,
    loan_id integer,
    campaign_id integer,
    product_nature_variant_id integer,
    used_on date,
    paid_on date,
    direction character varying,
    nature character varying,
    origin character varying,
    pretax_amount numeric,
    amount numeric,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: economic_cash_indicators_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.economic_cash_indicators_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: economic_cash_indicators_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.economic_cash_indicators_id_seq OWNED BY public.economic_cash_indicators.id;


--
-- Name: entities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.entities (
    id integer NOT NULL,
    nature character varying NOT NULL,
    last_name character varying NOT NULL,
    first_name character varying,
    full_name character varying NOT NULL,
    number character varying,
    active boolean DEFAULT true NOT NULL,
    born_at timestamp without time zone,
    dead_at timestamp without time zone,
    client boolean DEFAULT false NOT NULL,
    client_account_id integer,
    supplier boolean DEFAULT false NOT NULL,
    supplier_account_id integer,
    transporter boolean DEFAULT false NOT NULL,
    prospect boolean DEFAULT false NOT NULL,
    vat_subjected boolean DEFAULT true NOT NULL,
    reminder_submissive boolean DEFAULT false NOT NULL,
    deliveries_conditions character varying,
    description text,
    language character varying NOT NULL,
    country character varying,
    currency character varying NOT NULL,
    authorized_payments_count integer,
    responsible_id integer,
    proposer_id integer,
    meeting_origin character varying,
    first_met_at timestamp without time zone,
    activity_code character varying,
    vat_number character varying,
    siret_number character varying,
    locked boolean DEFAULT false NOT NULL,
    of_company boolean DEFAULT false NOT NULL,
    picture_file_name character varying,
    picture_content_type character varying,
    picture_file_size integer,
    picture_updated_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    title character varying,
    custom_fields jsonb,
    employee boolean DEFAULT false NOT NULL,
    employee_account_id integer,
    codes jsonb,
    supplier_payment_delay character varying,
    bank_account_holder_name character varying,
    bank_identifier_code character varying,
    iban character varying,
    supplier_payment_mode_id integer,
    first_financial_year_ends_on date,
    legal_position_code character varying,
    provider jsonb,
    CONSTRAINT company_born_at_not_null CHECK (((of_company = false) OR ((of_company = true) AND (born_at IS NOT NULL))))
);


--
-- Name: incoming_payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.incoming_payments (
    id integer NOT NULL,
    paid_at timestamp without time zone,
    amount numeric(19,4) NOT NULL,
    mode_id integer NOT NULL,
    bank_name character varying,
    bank_check_number character varying,
    bank_account_number character varying,
    payer_id integer,
    to_bank_at timestamp without time zone NOT NULL,
    deposit_id integer,
    responsible_id integer,
    scheduled boolean DEFAULT false NOT NULL,
    received boolean DEFAULT true NOT NULL,
    number character varying,
    accounted_at timestamp without time zone,
    receipt text,
    journal_entry_id integer,
    commission_account_id integer,
    commission_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    currency character varying NOT NULL,
    downpayment boolean DEFAULT true NOT NULL,
    affair_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb,
    codes jsonb,
    provider jsonb
);


--
-- Name: journal_entry_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.journal_entry_items (
    id integer NOT NULL,
    entry_id integer NOT NULL,
    journal_id integer NOT NULL,
    bank_statement_id integer,
    financial_year_id integer NOT NULL,
    state character varying NOT NULL,
    printed_on date NOT NULL,
    entry_number character varying NOT NULL,
    letter character varying,
    "position" integer,
    description text,
    account_id integer NOT NULL,
    name character varying NOT NULL,
    real_debit numeric(19,4) DEFAULT 0.0 NOT NULL,
    real_credit numeric(19,4) DEFAULT 0.0 NOT NULL,
    real_currency character varying NOT NULL,
    real_currency_rate numeric(19,10) DEFAULT 0.0 NOT NULL,
    debit numeric(19,4) DEFAULT 0.0 NOT NULL,
    credit numeric(19,4) DEFAULT 0.0 NOT NULL,
    balance numeric(19,4) DEFAULT 0.0 NOT NULL,
    currency character varying NOT NULL,
    absolute_debit numeric(19,4) DEFAULT 0.0 NOT NULL,
    absolute_credit numeric(19,4) DEFAULT 0.0 NOT NULL,
    absolute_currency character varying NOT NULL,
    cumulated_absolute_debit numeric(19,4) DEFAULT 0.0 NOT NULL,
    cumulated_absolute_credit numeric(19,4) DEFAULT 0.0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    real_balance numeric(19,4) DEFAULT 0.0 NOT NULL,
    bank_statement_letter character varying,
    activity_budget_id integer,
    team_id integer,
    tax_id integer,
    pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    real_pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    absolute_pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    tax_declaration_item_id integer,
    resource_type character varying,
    resource_id integer,
    resource_prism character varying,
    variant_id integer,
    tax_declaration_mode character varying,
    project_budget_id integer,
    equipment_id integer,
    accounting_label character varying,
    lettered_at timestamp without time zone,
    isacompta_letter character varying(4)
);


--
-- Name: outgoing_payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.outgoing_payments (
    id integer NOT NULL,
    accounted_at timestamp without time zone,
    amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    bank_check_number character varying,
    delivered boolean DEFAULT false NOT NULL,
    journal_entry_id integer,
    responsible_id integer NOT NULL,
    payee_id integer NOT NULL,
    mode_id integer NOT NULL,
    number character varying,
    paid_at timestamp without time zone,
    to_bank_at timestamp without time zone NOT NULL,
    cash_id integer NOT NULL,
    currency character varying NOT NULL,
    downpayment boolean DEFAULT false NOT NULL,
    affair_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb,
    list_id integer,
    "position" integer,
    type character varying,
    CONSTRAINT outgoing_payment_delivered CHECK (((delivered = false) OR ((delivered = true) AND (paid_at IS NOT NULL))))
);


--
-- Name: purchase_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.purchase_items (
    id integer NOT NULL,
    purchase_id integer NOT NULL,
    variant_id integer,
    quantity numeric(19,4) NOT NULL,
    pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    tax_id integer NOT NULL,
    currency character varying NOT NULL,
    label text,
    annotation text,
    "position" integer,
    account_id integer NOT NULL,
    unit_pretax_amount numeric(19,4) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    unit_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    fixed boolean DEFAULT false NOT NULL,
    reduction_percentage numeric(19,4) DEFAULT 0.0 NOT NULL,
    activity_budget_id integer,
    team_id integer,
    depreciable_product_id integer,
    fixed_asset_id integer,
    preexisting_asset boolean,
    equipment_id integer,
    role character varying,
    project_budget_id integer,
    fixed_asset_stopped_on date,
    accounting_label character varying,
    conditioning_unit_id integer NOT NULL,
    conditioning_quantity numeric(20,10) NOT NULL,
    catalog_item_id integer
);


--
-- Name: purchases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.purchases (
    id integer NOT NULL,
    supplier_id integer NOT NULL,
    number character varying NOT NULL,
    pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    delivery_address_id integer,
    description text,
    planned_at timestamp without time zone,
    confirmed_at timestamp without time zone,
    invoiced_at timestamp without time zone,
    accounted_at timestamp without time zone,
    journal_entry_id integer,
    reference_number character varying,
    state character varying NOT NULL,
    responsible_id integer,
    currency character varying NOT NULL,
    nature_id integer,
    affair_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb,
    undelivered_invoice_journal_entry_id integer,
    quantity_gap_on_invoice_journal_entry_id integer,
    payment_delay character varying,
    payment_at timestamp without time zone,
    contract_id integer,
    tax_payability character varying NOT NULL,
    type character varying,
    ordered_at timestamp without time zone,
    command_mode character varying,
    estimate_reception_date timestamp without time zone,
    reconciliation_state character varying
);


--
-- Name: sale_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sale_items (
    id integer NOT NULL,
    sale_id integer NOT NULL,
    variant_id integer NOT NULL,
    quantity numeric(19,4) NOT NULL,
    pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    tax_id integer,
    currency character varying NOT NULL,
    label text,
    annotation text,
    "position" integer,
    account_id integer,
    unit_pretax_amount numeric(19,4),
    reduction_percentage numeric(19,4) DEFAULT 0.0 NOT NULL,
    credited_item_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    unit_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    credited_quantity numeric(19,4),
    activity_budget_id integer,
    team_id integer,
    codes jsonb,
    compute_from character varying NOT NULL,
    accounting_label character varying,
    fixed boolean DEFAULT false NOT NULL,
    preexisting_asset boolean,
    depreciable_product_id integer,
    fixed_asset_id integer,
    conditioning_unit_id integer NOT NULL,
    conditioning_quantity numeric(20,10) NOT NULL,
    catalog_item_id integer,
    shipment_item_id integer,
    catalog_item_update boolean DEFAULT false
);


--
-- Name: sales; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sales (
    id integer NOT NULL,
    client_id integer NOT NULL,
    nature_id integer,
    number character varying NOT NULL,
    pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    state character varying NOT NULL,
    expired_at timestamp without time zone,
    has_downpayment boolean DEFAULT false NOT NULL,
    downpayment_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    address_id integer,
    invoice_address_id integer,
    delivery_address_id integer,
    subject character varying,
    function_title character varying,
    introduction text,
    conclusion text,
    description text,
    confirmed_at timestamp without time zone,
    responsible_id integer,
    letter_format boolean DEFAULT true NOT NULL,
    annotation text,
    transporter_id integer,
    accounted_at timestamp without time zone,
    journal_entry_id integer,
    reference_number character varying,
    invoiced_at timestamp without time zone,
    credit boolean DEFAULT false NOT NULL,
    payment_at timestamp without time zone,
    credited_sale_id integer,
    initial_number character varying,
    currency character varying NOT NULL,
    affair_id integer,
    expiration_delay character varying,
    payment_delay character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb,
    codes jsonb,
    undelivered_invoice_journal_entry_id integer,
    quantity_gap_on_invoice_journal_entry_id integer,
    client_reference character varying,
    provider jsonb
);


--
-- Name: economic_situations; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.economic_situations AS
 SELECT entities.id,
    COALESCE(client_accounting.balance, (0)::numeric) AS client_accounting_balance,
    COALESCE(supplier_accounting.balance, (0)::numeric) AS supplier_accounting_balance,
    (COALESCE(client_accounting.balance, (0)::numeric) + COALESCE(supplier_accounting.balance, (0)::numeric)) AS accounting_balance,
    COALESCE(client_trade.balance, (0)::numeric) AS client_trade_balance,
    COALESCE(supplier_trade.balance, (0)::numeric) AS supplier_trade_balance,
    (COALESCE(client_trade.balance, (0)::numeric) + COALESCE(supplier_trade.balance, (0)::numeric)) AS trade_balance,
    entities.creator_id,
    entities.created_at,
    entities.updater_id,
    entities.updated_at,
    entities.lock_version
   FROM ((((public.entities
     LEFT JOIN ( SELECT entities_1.id AS entity_id,
            (- sum(client_items.balance)) AS balance
           FROM ((public.entities entities_1
             JOIN public.accounts clients ON ((entities_1.client_account_id = clients.id)))
             JOIN public.journal_entry_items client_items ON ((clients.id = client_items.account_id)))
          GROUP BY entities_1.id) client_accounting ON ((entities.id = client_accounting.entity_id)))
     LEFT JOIN ( SELECT entities_1.id AS entity_id,
            (- sum(supplier_items.balance)) AS balance
           FROM ((public.entities entities_1
             JOIN public.accounts suppliers ON ((entities_1.supplier_account_id = suppliers.id)))
             JOIN public.journal_entry_items supplier_items ON ((suppliers.id = supplier_items.account_id)))
          GROUP BY entities_1.id) supplier_accounting ON ((entities.id = supplier_accounting.entity_id)))
     LEFT JOIN ( SELECT client_tradings.entity_id,
            sum(client_tradings.amount) AS balance
           FROM ( SELECT entities_1.id AS entity_id,
                    (- sale_items.amount) AS amount
                   FROM ((public.entities entities_1
                     JOIN public.sales ON ((entities_1.id = sales.client_id)))
                     JOIN public.sale_items ON ((sales.id = sale_items.sale_id)))
                UNION ALL
                 SELECT entities_1.id AS entity_id,
                    incoming_payments.amount
                   FROM (public.entities entities_1
                     JOIN public.incoming_payments ON ((entities_1.id = incoming_payments.payer_id)))) client_tradings
          GROUP BY client_tradings.entity_id) client_trade ON ((entities.id = client_trade.entity_id)))
     LEFT JOIN ( SELECT supplier_tradings.entity_id,
            sum(supplier_tradings.amount) AS balance
           FROM ( SELECT entities_1.id AS entity_id,
                    purchase_items.amount
                   FROM ((public.entities entities_1
                     JOIN public.purchases ON ((entities_1.id = purchases.supplier_id)))
                     JOIN public.purchase_items ON ((purchases.id = purchase_items.purchase_id)))
                UNION ALL
                 SELECT entities_1.id AS entity_id,
                    (- outgoing_payments.amount) AS amount
                   FROM (public.entities entities_1
                     JOIN public.outgoing_payments ON ((entities_1.id = outgoing_payments.payee_id)))) supplier_tradings
          GROUP BY supplier_tradings.entity_id) supplier_trade ON ((entities.id = supplier_trade.entity_id)));


--
-- Name: entities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.entities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: entities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.entities_id_seq OWNED BY public.entities.id;


--
-- Name: entity_addresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.entity_addresses (
    id integer NOT NULL,
    entity_id integer NOT NULL,
    canal character varying NOT NULL,
    coordinate character varying NOT NULL,
    by_default boolean DEFAULT false NOT NULL,
    deleted_at timestamp without time zone,
    thread character varying,
    name character varying,
    mail_line_1 character varying,
    mail_line_2 character varying,
    mail_line_3 character varying,
    mail_line_4 character varying,
    mail_line_5 character varying,
    mail_line_6 character varying,
    mail_country character varying,
    mail_postal_zone_id integer,
    mail_geolocation postgis.geometry(Point,4326),
    mail_auto_update boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: entity_addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.entity_addresses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: entity_addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.entity_addresses_id_seq OWNED BY public.entity_addresses.id;


--
-- Name: entity_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.entity_links (
    id integer NOT NULL,
    nature character varying NOT NULL,
    entity_id integer NOT NULL,
    entity_role character varying NOT NULL,
    linked_id integer NOT NULL,
    linked_role character varying NOT NULL,
    started_at timestamp without time zone,
    stopped_at timestamp without time zone,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    post character varying,
    main boolean DEFAULT false NOT NULL
);


--
-- Name: entity_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.entity_links_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: entity_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.entity_links_id_seq OWNED BY public.entity_links.id;


--
-- Name: event_participations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.event_participations (
    id integer NOT NULL,
    event_id integer NOT NULL,
    participant_id integer NOT NULL,
    state character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: event_participations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.event_participations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: event_participations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.event_participations_id_seq OWNED BY public.event_participations.id;


--
-- Name: events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events (
    id integer NOT NULL,
    name character varying NOT NULL,
    started_at timestamp without time zone NOT NULL,
    stopped_at timestamp without time zone,
    restricted boolean DEFAULT false NOT NULL,
    duration integer,
    place character varying,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    nature character varying NOT NULL,
    affair_id integer,
    custom_fields jsonb
);


--
-- Name: events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_id_seq OWNED BY public.events.id;


--
-- Name: financial_year_archives; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.financial_year_archives (
    id integer NOT NULL,
    financial_year_id integer NOT NULL,
    timing character varying NOT NULL,
    sha256_fingerprint character varying NOT NULL,
    signature text NOT NULL,
    path character varying NOT NULL
);


--
-- Name: financial_year_archives_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.financial_year_archives_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: financial_year_archives_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.financial_year_archives_id_seq OWNED BY public.financial_year_archives.id;


--
-- Name: financial_year_exchanges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.financial_year_exchanges (
    id integer NOT NULL,
    financial_year_id integer NOT NULL,
    started_on date NOT NULL,
    stopped_on date NOT NULL,
    closed_at timestamp without time zone,
    public_token character varying,
    public_token_expired_at timestamp without time zone,
    import_file_file_name character varying,
    import_file_content_type character varying,
    import_file_file_size integer,
    import_file_updated_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    format character varying DEFAULT 'ekyagri'::character varying NOT NULL,
    transmit_isacompta_analytic_codes boolean DEFAULT false,
    exported_journal_ids character varying[] DEFAULT '{}'::character varying[]
);


--
-- Name: financial_year_exchanges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.financial_year_exchanges_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: financial_year_exchanges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.financial_year_exchanges_id_seq OWNED BY public.financial_year_exchanges.id;


--
-- Name: financial_years; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.financial_years (
    id integer NOT NULL,
    code character varying NOT NULL,
    closed boolean DEFAULT false NOT NULL,
    started_on date NOT NULL,
    stopped_on date NOT NULL,
    currency character varying NOT NULL,
    currency_precision integer,
    last_journal_entry_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb,
    tax_declaration_frequency character varying,
    tax_declaration_mode character varying NOT NULL,
    accountant_id integer,
    state character varying,
    already_existing boolean DEFAULT false NOT NULL,
    closer_id integer
);


--
-- Name: financial_years_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.financial_years_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: financial_years_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.financial_years_id_seq OWNED BY public.financial_years.id;


--
-- Name: fixed_asset_depreciations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fixed_asset_depreciations (
    id integer NOT NULL,
    fixed_asset_id integer NOT NULL,
    journal_entry_id integer,
    accountable boolean DEFAULT false NOT NULL,
    accounted_at timestamp without time zone,
    started_on date NOT NULL,
    stopped_on date NOT NULL,
    amount numeric(19,4) NOT NULL,
    "position" integer,
    locked boolean DEFAULT false NOT NULL,
    financial_year_id integer,
    depreciable_amount numeric(19,4),
    depreciated_amount numeric(19,4),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: fixed_asset_depreciations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fixed_asset_depreciations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fixed_asset_depreciations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.fixed_asset_depreciations_id_seq OWNED BY public.fixed_asset_depreciations.id;


--
-- Name: fixed_assets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fixed_assets (
    id integer NOT NULL,
    allocation_account_id integer,
    journal_id integer NOT NULL,
    name character varying NOT NULL,
    number character varying NOT NULL,
    description text,
    purchased_on date,
    purchase_id integer,
    purchase_item_id integer,
    ceded boolean,
    ceded_on date,
    sale_id integer,
    sale_item_id integer,
    purchase_amount numeric(19,4),
    started_on date NOT NULL,
    stopped_on date,
    depreciable_amount numeric(19,4) NOT NULL,
    depreciated_amount numeric(19,4) NOT NULL,
    depreciation_method character varying NOT NULL,
    currency character varying NOT NULL,
    current_amount numeric(19,4),
    expenses_account_id integer,
    depreciation_percentage numeric(19,4),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb,
    product_id integer,
    state character varying,
    depreciation_period character varying,
    accounted_at timestamp without time zone,
    journal_entry_id integer,
    asset_account_id integer,
    sold_on date,
    scrapped_on date,
    sold_journal_entry_id integer,
    scrapped_journal_entry_id integer,
    depreciation_fiscal_coefficient numeric,
    selling_amount numeric(19,4),
    pretax_selling_amount numeric(19,4),
    tax_id integer,
    waiting_on date,
    waiting_journal_entry_id integer,
    waiting_asset_account_id integer,
    special_imputation_asset_account_id integer,
    provider jsonb,
    activity_id integer
);


--
-- Name: fixed_assets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fixed_assets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fixed_assets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.fixed_assets_id_seq OWNED BY public.fixed_assets.id;


--
-- Name: gap_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gap_items (
    id integer NOT NULL,
    gap_id integer NOT NULL,
    pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    tax_id integer,
    currency character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: gap_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.gap_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gap_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.gap_items_id_seq OWNED BY public.gap_items.id;


--
-- Name: gaps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gaps (
    id integer NOT NULL,
    number character varying NOT NULL,
    printed_at timestamp without time zone NOT NULL,
    direction character varying NOT NULL,
    affair_id integer,
    entity_id integer NOT NULL,
    pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    currency character varying NOT NULL,
    accounted_at timestamp without time zone,
    journal_entry_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    type character varying
);


--
-- Name: gaps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.gaps_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gaps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.gaps_id_seq OWNED BY public.gaps.id;


--
-- Name: georeadings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.georeadings (
    id integer NOT NULL,
    name character varying NOT NULL,
    nature character varying NOT NULL,
    number character varying,
    description text,
    content postgis.geometry(Geometry,4326) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: georeadings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.georeadings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: georeadings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.georeadings_id_seq OWNED BY public.georeadings.id;


--
-- Name: guide_analyses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.guide_analyses (
    id integer NOT NULL,
    guide_id integer NOT NULL,
    execution_number integer NOT NULL,
    latest boolean DEFAULT false NOT NULL,
    started_at timestamp without time zone NOT NULL,
    stopped_at timestamp without time zone NOT NULL,
    acceptance_status character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: guide_analyses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.guide_analyses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: guide_analyses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.guide_analyses_id_seq OWNED BY public.guide_analyses.id;


--
-- Name: guide_analysis_points; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.guide_analysis_points (
    id integer NOT NULL,
    analysis_id integer NOT NULL,
    reference_name character varying NOT NULL,
    acceptance_status character varying NOT NULL,
    advice_reference_name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: guide_analysis_points_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.guide_analysis_points_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: guide_analysis_points_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.guide_analysis_points_id_seq OWNED BY public.guide_analysis_points.id;


--
-- Name: guides; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.guides (
    id integer NOT NULL,
    name character varying NOT NULL,
    nature character varying NOT NULL,
    active boolean DEFAULT false NOT NULL,
    external boolean DEFAULT false NOT NULL,
    frequency character varying NOT NULL,
    reference_name character varying,
    reference_source_file_name character varying,
    reference_source_content_type character varying,
    reference_source_file_size integer,
    reference_source_updated_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: guides_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.guides_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: guides_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.guides_id_seq OWNED BY public.guides.id;


--
-- Name: idea_diagnostic_item_values; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.idea_diagnostic_item_values (
    id integer NOT NULL,
    idea_diagnostic_item_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    boolean_value boolean,
    float_value double precision,
    integer_value integer,
    string_value character varying,
    nature character varying DEFAULT 'string'::character varying,
    name character varying
);


--
-- Name: idea_diagnostic_item_values_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.idea_diagnostic_item_values_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: idea_diagnostic_item_values_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.idea_diagnostic_item_values_id_seq OWNED BY public.idea_diagnostic_item_values.id;


--
-- Name: idea_diagnostic_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.idea_diagnostic_items (
    id integer NOT NULL,
    idea_diagnostic_id integer,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    "group" character varying,
    idea_id character varying,
    value integer,
    treshold integer
);


--
-- Name: idea_diagnostic_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.idea_diagnostic_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: idea_diagnostic_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.idea_diagnostic_items_id_seq OWNED BY public.idea_diagnostic_items.id;


--
-- Name: idea_diagnostic_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.idea_diagnostic_results (
    id integer NOT NULL,
    overlap_resut character varying,
    normal_result character varying,
    idea_diagnostic_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: idea_diagnostic_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.idea_diagnostic_results_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: idea_diagnostic_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.idea_diagnostic_results_id_seq OWNED BY public.idea_diagnostic_results.id;


--
-- Name: idea_diagnostics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.idea_diagnostics (
    id integer NOT NULL,
    name character varying NOT NULL,
    code character varying NOT NULL,
    state character varying,
    campaign_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    auditor_id integer,
    stopped_at timestamp without time zone
);


--
-- Name: idea_diagnostics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.idea_diagnostics_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: idea_diagnostics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.idea_diagnostics_id_seq OWNED BY public.idea_diagnostics.id;


--
-- Name: identifiers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.identifiers (
    id integer NOT NULL,
    net_service_id integer,
    nature character varying NOT NULL,
    value character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: identifiers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.identifiers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: identifiers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.identifiers_id_seq OWNED BY public.identifiers.id;


--
-- Name: imports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.imports (
    id integer NOT NULL,
    state character varying NOT NULL,
    nature character varying NOT NULL,
    archive_file_name character varying,
    archive_content_type character varying,
    archive_file_size integer,
    archive_updated_at timestamp without time zone,
    importer_id integer,
    imported_at timestamp without time zone,
    progression_percentage numeric(19,4),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    options jsonb
);


--
-- Name: imports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.imports_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: imports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.imports_id_seq OWNED BY public.imports.id;


--
-- Name: incoming_payment_modes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.incoming_payment_modes (
    id integer NOT NULL,
    name character varying NOT NULL,
    cash_id integer,
    active boolean DEFAULT false,
    "position" integer,
    with_accounting boolean DEFAULT false NOT NULL,
    with_commission boolean DEFAULT false NOT NULL,
    commission_percentage numeric(19,4) DEFAULT 0.0 NOT NULL,
    commission_base_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    commission_account_id integer,
    with_deposit boolean DEFAULT false NOT NULL,
    depositables_account_id integer,
    depositables_journal_id integer,
    detail_payments boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    provider jsonb
);


--
-- Name: incoming_payment_modes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.incoming_payment_modes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: incoming_payment_modes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.incoming_payment_modes_id_seq OWNED BY public.incoming_payment_modes.id;


--
-- Name: incoming_payments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.incoming_payments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: incoming_payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.incoming_payments_id_seq OWNED BY public.incoming_payments.id;


--
-- Name: inspection_calibrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inspection_calibrations (
    id integer NOT NULL,
    inspection_id integer NOT NULL,
    nature_id integer NOT NULL,
    items_count_value integer,
    net_mass_value numeric(19,4),
    minimal_size_value numeric(19,4),
    maximal_size_value numeric(19,4),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: inspection_calibrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.inspection_calibrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: inspection_calibrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.inspection_calibrations_id_seq OWNED BY public.inspection_calibrations.id;


--
-- Name: inspection_points; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inspection_points (
    id integer NOT NULL,
    inspection_id integer NOT NULL,
    nature_id integer NOT NULL,
    items_count_value integer,
    net_mass_value numeric(19,4),
    minimal_size_value numeric(19,4),
    maximal_size_value numeric(19,4),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: inspection_points_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.inspection_points_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: inspection_points_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.inspection_points_id_seq OWNED BY public.inspection_points.id;


--
-- Name: inspections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inspections (
    id integer NOT NULL,
    activity_id integer NOT NULL,
    product_id integer NOT NULL,
    number character varying NOT NULL,
    sampled_at timestamp without time zone NOT NULL,
    implanter_rows_number integer,
    implanter_working_width numeric(19,4),
    comment text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    implanter_application_width numeric(19,4),
    sampling_distance numeric(19,4),
    product_net_surface_area_value numeric(19,4),
    product_net_surface_area_unit character varying,
    forecast_harvest_week integer
);


--
-- Name: inspections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.inspections_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: inspections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.inspections_id_seq OWNED BY public.inspections.id;


--
-- Name: integrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integrations (
    id integer NOT NULL,
    nature character varying NOT NULL,
    initialization_vectors jsonb,
    ciphered_parameters jsonb,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    data jsonb DEFAULT '{}'::jsonb,
    last_sync_at timestamp without time zone,
    state character varying
);


--
-- Name: integrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integrations_id_seq OWNED BY public.integrations.id;


--
-- Name: intervention_costings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.intervention_costings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: intervention_costings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.intervention_costings_id_seq OWNED BY public.intervention_costings.id;


--
-- Name: intervention_crop_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.intervention_crop_groups (
    id integer NOT NULL,
    crop_group_id integer,
    intervention_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: intervention_crop_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.intervention_crop_groups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: intervention_crop_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.intervention_crop_groups_id_seq OWNED BY public.intervention_crop_groups.id;


--
-- Name: intervention_labellings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.intervention_labellings (
    id integer NOT NULL,
    intervention_id integer NOT NULL,
    label_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: intervention_labellings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.intervention_labellings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: intervention_labellings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.intervention_labellings_id_seq OWNED BY public.intervention_labellings.id;


--
-- Name: intervention_parameter_readings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.intervention_parameter_readings (
    id integer NOT NULL,
    indicator_name character varying NOT NULL,
    indicator_datatype character varying NOT NULL,
    absolute_measure_value_value numeric(19,4),
    absolute_measure_value_unit character varying,
    boolean_value boolean DEFAULT false NOT NULL,
    choice_value character varying,
    decimal_value numeric(19,4),
    multi_polygon_value postgis.geometry(MultiPolygon,4326),
    integer_value integer,
    measure_value_value numeric(19,4),
    measure_value_unit character varying,
    point_value postgis.geometry(Point,4326),
    string_value text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    parameter_id integer NOT NULL,
    geometry_value postgis.geometry(Geometry,4326)
);


--
-- Name: intervention_parameter_readings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.intervention_parameter_readings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: intervention_parameter_readings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.intervention_parameter_readings_id_seq OWNED BY public.intervention_parameter_readings.id;


--
-- Name: intervention_parameter_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.intervention_parameter_settings (
    id integer NOT NULL,
    intervention_id integer,
    intervention_parameter_id integer,
    nature character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: intervention_parameter_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.intervention_parameter_settings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: intervention_parameter_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.intervention_parameter_settings_id_seq OWNED BY public.intervention_parameter_settings.id;


--
-- Name: intervention_parameters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.intervention_parameters_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: intervention_parameters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.intervention_parameters_id_seq OWNED BY public.intervention_parameters.id;


--
-- Name: intervention_participations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.intervention_participations (
    id integer NOT NULL,
    intervention_id integer,
    product_id integer,
    state character varying,
    request_compliant boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    procedure_name character varying
);


--
-- Name: intervention_participations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.intervention_participations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: intervention_participations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.intervention_participations_id_seq OWNED BY public.intervention_participations.id;


--
-- Name: intervention_proposal_parameters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.intervention_proposal_parameters (
    id integer NOT NULL,
    intervention_proposal_id integer,
    product_id integer,
    product_nature_variant_id integer,
    product_type character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    intervention_template_product_parameter_id integer,
    quantity numeric,
    unit character varying
);


--
-- Name: intervention_proposal_parameters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.intervention_proposal_parameters_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: intervention_proposal_parameters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.intervention_proposal_parameters_id_seq OWNED BY public.intervention_proposal_parameters.id;


--
-- Name: intervention_proposals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.intervention_proposals (
    id integer NOT NULL,
    technical_itinerary_intervention_template_id integer,
    estimated_date date,
    area numeric,
    activity_production_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    number integer,
    target character varying,
    batch_number integer,
    activity_production_irregular_batch_id integer
);


--
-- Name: intervention_proposals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.intervention_proposals_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: intervention_proposals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.intervention_proposals_id_seq OWNED BY public.intervention_proposals.id;


--
-- Name: intervention_setting_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.intervention_setting_items (
    id integer NOT NULL,
    intervention_parameter_setting_id integer,
    intervention_id integer,
    indicator_name character varying NOT NULL,
    indicator_datatype character varying NOT NULL,
    absolute_measure_value_value numeric(19,4),
    absolute_measure_value_unit character varying,
    boolean_value boolean DEFAULT false NOT NULL,
    choice_value character varying,
    decimal_value numeric(19,4),
    geometry_value postgis.geometry(Geometry,4326),
    integer_value integer,
    measure_value_value numeric(19,4),
    measure_value_unit character varying,
    point_value postgis.geometry(Point,4326),
    string_value text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: intervention_setting_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.intervention_setting_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: intervention_setting_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.intervention_setting_items_id_seq OWNED BY public.intervention_setting_items.id;


--
-- Name: intervention_template_activities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.intervention_template_activities (
    id integer NOT NULL,
    intervention_template_id integer,
    activity_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: intervention_template_activities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.intervention_template_activities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: intervention_template_activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.intervention_template_activities_id_seq OWNED BY public.intervention_template_activities.id;


--
-- Name: intervention_template_product_parameters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.intervention_template_product_parameters (
    id integer NOT NULL,
    intervention_template_id integer,
    product_nature_id integer,
    product_nature_variant_id integer,
    activity_id integer,
    quantity numeric,
    unit character varying,
    type character varying,
    procedure jsonb,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    intervention_model_item_id character varying,
    technical_workflow_procedure_item_id character varying
);


--
-- Name: intervention_template_product_parameters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.intervention_template_product_parameters_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: intervention_template_product_parameters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.intervention_template_product_parameters_id_seq OWNED BY public.intervention_template_product_parameters.id;


--
-- Name: intervention_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.intervention_templates (
    id integer NOT NULL,
    name character varying,
    active boolean DEFAULT true,
    description character varying,
    procedure_name character varying,
    campaign_id integer,
    preparation_time_hours integer,
    preparation_time_minutes integer,
    workflow numeric,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    originator_id integer,
    technical_workflow_procedure_id character varying,
    intervention_model_id character varying
);


--
-- Name: intervention_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.intervention_templates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: intervention_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.intervention_templates_id_seq OWNED BY public.intervention_templates.id;


--
-- Name: intervention_working_periods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.intervention_working_periods_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: intervention_working_periods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.intervention_working_periods_id_seq OWNED BY public.intervention_working_periods.id;


--
-- Name: interventions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.interventions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: interventions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.interventions_id_seq OWNED BY public.interventions.id;


--
-- Name: inventories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventories (
    id integer NOT NULL,
    number character varying NOT NULL,
    reflected_at timestamp without time zone,
    reflected boolean DEFAULT false NOT NULL,
    responsible_id integer,
    accounted_at timestamp without time zone,
    journal_entry_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    name character varying NOT NULL,
    achieved_at timestamp without time zone,
    custom_fields jsonb,
    financial_year_id integer,
    currency character varying,
    product_nature_category_id integer,
    journal_id integer,
    disable_accountancy boolean DEFAULT false
);


--
-- Name: inventories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.inventories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: inventories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.inventories_id_seq OWNED BY public.inventories.id;


--
-- Name: inventory_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_items (
    id integer NOT NULL,
    inventory_id integer NOT NULL,
    product_id integer NOT NULL,
    expected_population numeric(19,4) NOT NULL,
    actual_population numeric(19,4) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    product_movement_id integer,
    currency character varying,
    unit_pretax_stock_amount numeric(19,4) DEFAULT 0.0 NOT NULL
);


--
-- Name: inventory_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.inventory_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: inventory_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.inventory_items_id_seq OWNED BY public.inventory_items.id;


--
-- Name: issues; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.issues (
    id integer NOT NULL,
    target_type character varying,
    target_id integer,
    nature character varying NOT NULL,
    observed_at timestamp without time zone NOT NULL,
    priority integer,
    gravity integer,
    state character varying,
    name character varying NOT NULL,
    description text,
    picture_file_name character varying,
    picture_content_type character varying,
    picture_file_size integer,
    picture_updated_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    geolocation postgis.geometry(Point,4326),
    custom_fields jsonb,
    dead boolean DEFAULT false
);


--
-- Name: issues_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.issues_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: issues_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.issues_id_seq OWNED BY public.issues.id;


--
-- Name: journal_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.journal_entries (
    id integer NOT NULL,
    journal_id integer NOT NULL,
    financial_year_id integer,
    number character varying NOT NULL,
    resource_type character varying,
    resource_id integer,
    state character varying NOT NULL,
    printed_on date NOT NULL,
    real_debit numeric(19,4) DEFAULT 0.0 NOT NULL,
    real_credit numeric(19,4) DEFAULT 0.0 NOT NULL,
    real_currency character varying NOT NULL,
    real_currency_rate numeric(19,10) DEFAULT 0.0 NOT NULL,
    debit numeric(19,4) DEFAULT 0.0 NOT NULL,
    credit numeric(19,4) DEFAULT 0.0 NOT NULL,
    balance numeric(19,4) DEFAULT 0.0 NOT NULL,
    currency character varying NOT NULL,
    absolute_debit numeric(19,4) DEFAULT 0.0 NOT NULL,
    absolute_credit numeric(19,4) DEFAULT 0.0 NOT NULL,
    absolute_currency character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    real_balance numeric(19,4) DEFAULT 0.0 NOT NULL,
    resource_prism character varying,
    financial_year_exchange_id integer,
    reference_number character varying,
    continuous_number integer,
    validated_at timestamp without time zone,
    compliance jsonb DEFAULT '{}'::jsonb,
    name character varying,
    provider jsonb
);


--
-- Name: journal_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.journal_entries_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: journal_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.journal_entries_id_seq OWNED BY public.journal_entries.id;


--
-- Name: journal_entry_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.journal_entry_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: journal_entry_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.journal_entry_items_id_seq OWNED BY public.journal_entry_items.id;


--
-- Name: journals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.journals (
    id integer NOT NULL,
    nature character varying NOT NULL,
    name character varying NOT NULL,
    code character varying NOT NULL,
    closed_on date NOT NULL,
    currency character varying NOT NULL,
    used_for_affairs boolean DEFAULT false NOT NULL,
    used_for_gaps boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb,
    used_for_permanent_stock_inventory boolean DEFAULT false NOT NULL,
    used_for_unbilled_payables boolean DEFAULT false NOT NULL,
    used_for_tax_declarations boolean DEFAULT false NOT NULL,
    accountant_id integer,
    provider jsonb,
    isacompta_code character varying(2),
    isacompta_label character varying(30),
    financial_year_exchange_id integer
);


--
-- Name: journals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.journals_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: journals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.journals_id_seq OWNED BY public.journals.id;


--
-- Name: labels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.labels (
    id integer NOT NULL,
    name character varying NOT NULL,
    color character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: labels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.labels_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: labels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.labels_id_seq OWNED BY public.labels.id;


--
-- Name: listing_node_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.listing_node_items (
    id integer NOT NULL,
    node_id integer NOT NULL,
    nature character varying NOT NULL,
    value text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: listing_node_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.listing_node_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: listing_node_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.listing_node_items_id_seq OWNED BY public.listing_node_items.id;


--
-- Name: listing_nodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.listing_nodes (
    id integer NOT NULL,
    name character varying NOT NULL,
    label character varying NOT NULL,
    nature character varying NOT NULL,
    "position" integer,
    exportable boolean DEFAULT true NOT NULL,
    parent_id integer,
    item_nature character varying,
    item_value text,
    item_listing_id integer,
    item_listing_node_id integer,
    listing_id integer NOT NULL,
    key character varying,
    sql_type character varying,
    condition_value character varying,
    condition_operator character varying,
    attribute_name character varying,
    lft integer,
    rgt integer,
    depth integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: listing_nodes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.listing_nodes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: listing_nodes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.listing_nodes_id_seq OWNED BY public.listing_nodes.id;


--
-- Name: listings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.listings (
    id integer NOT NULL,
    name character varying NOT NULL,
    root_model character varying NOT NULL,
    query text,
    description text,
    story text,
    conditions text,
    mail text,
    source text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: listings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.listings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: listings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.listings_id_seq OWNED BY public.listings.id;


--
-- Name: loan_repayments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.loan_repayments (
    id integer NOT NULL,
    loan_id integer NOT NULL,
    "position" integer NOT NULL,
    amount numeric(19,4) NOT NULL,
    base_amount numeric(19,4) NOT NULL,
    interest_amount numeric(19,4) NOT NULL,
    insurance_amount numeric(19,4) NOT NULL,
    remaining_amount numeric(19,4) NOT NULL,
    due_on date NOT NULL,
    journal_entry_id integer,
    accounted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    accountable boolean DEFAULT false NOT NULL,
    locked boolean DEFAULT false NOT NULL
);


--
-- Name: loan_repayments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.loan_repayments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: loan_repayments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.loan_repayments_id_seq OWNED BY public.loan_repayments.id;


--
-- Name: loans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.loans (
    id integer NOT NULL,
    lender_id integer NOT NULL,
    name character varying NOT NULL,
    cash_id integer NOT NULL,
    currency character varying NOT NULL,
    amount numeric(19,4) NOT NULL,
    interest_percentage numeric(19,4) NOT NULL,
    insurance_percentage numeric(19,4) NOT NULL,
    started_on date NOT NULL,
    repayment_duration integer NOT NULL,
    repayment_period character varying NOT NULL,
    repayment_method character varying NOT NULL,
    shift_duration integer DEFAULT 0 NOT NULL,
    shift_method character varying,
    journal_entry_id integer,
    accounted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb,
    insurance_repayment_method character varying,
    state character varying,
    ongoing_at timestamp without time zone,
    repaid_at timestamp without time zone,
    loan_account_id integer,
    interest_account_id integer,
    insurance_account_id integer,
    use_bank_guarantee boolean,
    bank_guarantee_account_id integer,
    bank_guarantee_amount integer,
    accountable_repayments_started_on date,
    initial_releasing_amount boolean DEFAULT true NOT NULL,
    provider jsonb,
    activity_id integer
);


--
-- Name: loans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.loans_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: loans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.loans_id_seq OWNED BY public.loans.id;


--
-- Name: locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.locations (
    id integer NOT NULL,
    registered_postal_zone_id character varying,
    locality character varying,
    localizable_type character varying,
    localizable_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    lock_version integer DEFAULT 0 NOT NULL,
    creator_id integer,
    updater_id integer
);


--
-- Name: locations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.locations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.locations_id_seq OWNED BY public.locations.id;


--
-- Name: manure_management_plan_zones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.manure_management_plan_zones (
    id integer NOT NULL,
    plan_id integer NOT NULL,
    activity_production_id integer NOT NULL,
    computation_method character varying NOT NULL,
    administrative_area character varying,
    cultivation_variety character varying,
    soil_nature character varying,
    expected_yield numeric(19,4),
    nitrogen_need numeric(19,4),
    absorbed_nitrogen_at_opening numeric(19,4),
    mineral_nitrogen_at_opening numeric(19,4),
    humus_mineralization numeric(19,4),
    meadow_humus_mineralization numeric(19,4),
    previous_cultivation_residue_mineralization numeric(19,4),
    intermediate_cultivation_residue_mineralization numeric(19,4),
    irrigation_water_nitrogen numeric(19,4),
    organic_fertilizer_mineral_fraction numeric(19,4),
    nitrogen_at_closing numeric(19,4),
    soil_production numeric(19,4),
    nitrogen_input numeric(19,4),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    maximum_nitrogen_input numeric(19,4)
);


--
-- Name: manure_management_plan_zones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.manure_management_plan_zones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: manure_management_plan_zones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.manure_management_plan_zones_id_seq OWNED BY public.manure_management_plan_zones.id;


--
-- Name: manure_management_plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.manure_management_plans (
    id integer NOT NULL,
    name character varying NOT NULL,
    campaign_id integer NOT NULL,
    recommender_id integer NOT NULL,
    opened_at timestamp without time zone NOT NULL,
    default_computation_method character varying NOT NULL,
    locked boolean DEFAULT false NOT NULL,
    selected boolean DEFAULT false NOT NULL,
    annotation text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: manure_management_plans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.manure_management_plans_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: manure_management_plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.manure_management_plans_id_seq OWNED BY public.manure_management_plans.id;


--
-- Name: map_layers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.map_layers (
    id integer NOT NULL,
    name character varying NOT NULL,
    url character varying NOT NULL,
    reference_name character varying,
    attribution character varying,
    subdomains character varying,
    min_zoom integer,
    max_zoom integer,
    managed boolean DEFAULT false NOT NULL,
    tms boolean DEFAULT false NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    by_default boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    nature character varying,
    "position" integer,
    opacity integer
);


--
-- Name: map_layers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.map_layers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: map_layers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.map_layers_id_seq OWNED BY public.map_layers.id;


--
-- Name: naming_format_fields; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.naming_format_fields (
    id integer NOT NULL,
    type character varying NOT NULL,
    field_name character varying NOT NULL,
    "position" integer,
    naming_format_id integer,
    creator_id integer,
    created_at timestamp without time zone,
    updater_id integer,
    updated_at timestamp without time zone,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: naming_format_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.naming_format_fields_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: naming_format_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.naming_format_fields_id_seq OWNED BY public.naming_format_fields.id;


--
-- Name: naming_formats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.naming_formats (
    id integer NOT NULL,
    name character varying NOT NULL,
    type character varying NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: naming_formats_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.naming_formats_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: naming_formats_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.naming_formats_id_seq OWNED BY public.naming_formats.id;


--
-- Name: net_services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.net_services (
    id integer NOT NULL,
    reference_name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: net_services_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.net_services_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: net_services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.net_services_id_seq OWNED BY public.net_services.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id integer NOT NULL,
    recipient_id integer NOT NULL,
    message character varying NOT NULL,
    level character varying NOT NULL,
    read_at timestamp without time zone,
    target_type character varying,
    target_id integer,
    target_url character varying,
    interpolations json,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notifications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: observations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.observations (
    id integer NOT NULL,
    subject_type character varying NOT NULL,
    subject_id integer NOT NULL,
    importance character varying NOT NULL,
    content text NOT NULL,
    observed_at timestamp without time zone NOT NULL,
    author_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: observations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.observations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: observations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.observations_id_seq OWNED BY public.observations.id;


--
-- Name: outgoing_payment_lists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.outgoing_payment_lists (
    id integer NOT NULL,
    number character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    mode_id integer NOT NULL,
    cached_payment_count integer,
    cached_total_sum numeric
);


--
-- Name: outgoing_payment_lists_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.outgoing_payment_lists_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: outgoing_payment_lists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.outgoing_payment_lists_id_seq OWNED BY public.outgoing_payment_lists.id;


--
-- Name: outgoing_payment_modes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.outgoing_payment_modes (
    id integer NOT NULL,
    name character varying NOT NULL,
    with_accounting boolean DEFAULT false NOT NULL,
    cash_id integer,
    "position" integer,
    active boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    sepa boolean DEFAULT false NOT NULL
);


--
-- Name: outgoing_payment_modes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.outgoing_payment_modes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: outgoing_payment_modes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.outgoing_payment_modes_id_seq OWNED BY public.outgoing_payment_modes.id;


--
-- Name: outgoing_payments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.outgoing_payments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: outgoing_payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.outgoing_payments_id_seq OWNED BY public.outgoing_payments.id;


--
-- Name: parcel_item_storings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parcel_item_storings (
    id integer NOT NULL,
    parcel_item_id integer NOT NULL,
    storage_id integer NOT NULL,
    quantity numeric(19,4),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    product_id integer,
    conditioning_unit_id integer NOT NULL,
    conditioning_quantity numeric(20,10) NOT NULL
);


--
-- Name: parcel_item_storings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.parcel_item_storings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: parcel_item_storings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.parcel_item_storings_id_seq OWNED BY public.parcel_item_storings.id;


--
-- Name: parcel_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parcel_items (
    id integer NOT NULL,
    parcel_id integer NOT NULL,
    sale_item_id integer,
    purchase_invoice_item_id integer,
    source_product_id integer,
    product_id integer,
    analysis_id integer,
    variant_id integer,
    parted boolean DEFAULT false NOT NULL,
    population numeric(19,4),
    shape postgis.geometry(MultiPolygon,4326),
    product_enjoyment_id integer,
    product_ownership_id integer,
    product_localization_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    product_movement_id integer,
    source_product_movement_id integer,
    product_identification_number character varying,
    product_name character varying,
    currency character varying,
    unit_pretax_stock_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    non_compliant boolean,
    delivery_mode character varying,
    delivery_id integer,
    transporter_id integer,
    non_compliant_detail character varying,
    role character varying,
    equipment_id integer,
    purchase_order_item_id integer,
    product_work_number character varying,
    type character varying,
    merge_stock boolean DEFAULT false,
    project_budget_id integer,
    purchase_order_to_close_id integer,
    activity_budget_id integer,
    team_id integer,
    annotation text,
    conditioning_unit_id integer,
    conditioning_quantity numeric(20,10),
    unit_pretax_sale_amount numeric(19,4)
);


--
-- Name: parcel_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.parcel_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: parcel_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.parcel_items_id_seq OWNED BY public.parcel_items.id;


--
-- Name: parcels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parcels (
    id integer NOT NULL,
    number character varying NOT NULL,
    nature character varying NOT NULL,
    reference_number character varying,
    recipient_id integer,
    sender_id integer,
    address_id integer,
    storage_id integer,
    delivery_id integer,
    sale_id integer,
    purchase_id integer,
    transporter_id integer,
    remain_owner boolean DEFAULT false NOT NULL,
    delivery_mode character varying,
    state character varying NOT NULL,
    planned_at timestamp without time zone NOT NULL,
    ordered_at timestamp without time zone,
    in_preparation_at timestamp without time zone,
    prepared_at timestamp without time zone,
    given_at timestamp without time zone,
    "position" integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb,
    with_delivery boolean DEFAULT false NOT NULL,
    separated_stock boolean,
    accounted_at timestamp without time zone,
    currency character varying,
    journal_entry_id integer,
    undelivered_invoice_journal_entry_id integer,
    contract_id integer,
    pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    responsible_id integer,
    type character varying,
    late_delivery boolean,
    intervention_id integer,
    reconciliation_state character varying,
    sale_nature_id integer
);


--
-- Name: parcels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.parcels_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: parcels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.parcels_id_seq OWNED BY public.parcels.id;


--
-- Name: payslip_natures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payslip_natures (
    id integer NOT NULL,
    name character varying NOT NULL,
    currency character varying NOT NULL,
    active boolean DEFAULT false NOT NULL,
    by_default boolean DEFAULT false NOT NULL,
    with_accounting boolean DEFAULT false NOT NULL,
    journal_id integer NOT NULL,
    account_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: payslip_natures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payslip_natures_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payslip_natures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payslip_natures_id_seq OWNED BY public.payslip_natures.id;


--
-- Name: payslips; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payslips (
    id integer NOT NULL,
    number character varying NOT NULL,
    nature_id integer NOT NULL,
    employee_id integer,
    account_id integer,
    started_on date NOT NULL,
    stopped_on date NOT NULL,
    emitted_on date,
    state character varying NOT NULL,
    amount numeric(19,4) NOT NULL,
    currency character varying NOT NULL,
    accounted_at timestamp without time zone,
    journal_entry_id integer,
    affair_id integer,
    custom_fields jsonb,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: payslips_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payslips_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payslips_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payslips_id_seq OWNED BY public.payslips.id;


--
-- Name: pfi_campaigns_activities_interventions; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.pfi_campaigns_activities_interventions AS
SELECT
    NULL::integer AS campaign_id,
    NULL::integer AS activity_id,
    NULL::integer AS activity_production_id,
    NULL::integer AS crop_id,
    NULL::character varying AS segment_code,
    NULL::numeric AS crop_pfi_value,
    NULL::numeric(19,4) AS activity_production_surface_area,
    NULL::numeric(19,4) AS crop_surface_area,
    NULL::numeric AS activity_production_pfi_value,
    NULL::numeric AS activity_pfi_value;


--
-- Name: pfi_intervention_parameters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pfi_intervention_parameters (
    id integer NOT NULL,
    pfi_value numeric(19,4) DEFAULT 1.0 NOT NULL,
    nature character varying NOT NULL,
    segment_code character varying,
    signature text,
    response jsonb NOT NULL,
    campaign_id integer,
    input_id integer,
    target_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: pfi_intervention_parameters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pfi_intervention_parameters_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pfi_intervention_parameters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pfi_intervention_parameters_id_seq OWNED BY public.pfi_intervention_parameters.id;


--
-- Name: planning_scenario_activities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.planning_scenario_activities (
    id integer NOT NULL,
    activity_id integer,
    planning_scenario_id integer,
    creator_id integer,
    updater_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: planning_scenario_activities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.planning_scenario_activities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: planning_scenario_activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.planning_scenario_activities_id_seq OWNED BY public.planning_scenario_activities.id;


--
-- Name: planning_scenario_activity_plots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.planning_scenario_activity_plots (
    id integer NOT NULL,
    planning_scenario_activity_id integer,
    technical_itinerary_id integer,
    area numeric,
    planned_at date,
    creator_id integer,
    updater_id integer,
    batch_planting boolean DEFAULT false,
    number_of_batch integer,
    sowing_interval integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: planning_scenario_activity_plots_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.planning_scenario_activity_plots_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: planning_scenario_activity_plots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.planning_scenario_activity_plots_id_seq OWNED BY public.planning_scenario_activity_plots.id;


--
-- Name: planning_scenarios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.planning_scenarios (
    id integer NOT NULL,
    name character varying,
    description character varying,
    campaign_id integer,
    area numeric,
    creator_id integer,
    updater_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: planning_scenarios_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.planning_scenarios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: planning_scenarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.planning_scenarios_id_seq OWNED BY public.planning_scenarios.id;


--
-- Name: plant_counting_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plant_counting_items (
    id integer NOT NULL,
    plant_counting_id integer NOT NULL,
    value integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: plant_counting_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.plant_counting_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plant_counting_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.plant_counting_items_id_seq OWNED BY public.plant_counting_items.id;


--
-- Name: plant_countings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plant_countings (
    id integer NOT NULL,
    plant_id integer NOT NULL,
    plant_density_abacus_id integer NOT NULL,
    plant_density_abacus_item_id integer NOT NULL,
    average_value numeric(19,4),
    read_at timestamp without time zone,
    comment text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    number character varying,
    nature character varying,
    working_width_value numeric(19,4),
    rows_count_value integer
);


--
-- Name: plant_countings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.plant_countings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plant_countings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.plant_countings_id_seq OWNED BY public.plant_countings.id;


--
-- Name: plant_density_abaci; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plant_density_abaci (
    id integer NOT NULL,
    name character varying NOT NULL,
    germination_percentage numeric(19,4),
    seeding_density_unit character varying NOT NULL,
    sampling_length_unit character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    activity_id integer NOT NULL
);


--
-- Name: plant_density_abaci_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.plant_density_abaci_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plant_density_abaci_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.plant_density_abaci_id_seq OWNED BY public.plant_density_abaci.id;


--
-- Name: plant_density_abacus_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plant_density_abacus_items (
    id integer NOT NULL,
    plant_density_abacus_id integer NOT NULL,
    seeding_density_value numeric(19,4) NOT NULL,
    plants_count integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: plant_density_abacus_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.plant_density_abacus_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plant_density_abacus_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.plant_density_abacus_items_id_seq OWNED BY public.plant_density_abacus_items.id;


--
-- Name: postal_zones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.postal_zones (
    id integer NOT NULL,
    postal_code character varying NOT NULL,
    name character varying NOT NULL,
    country character varying NOT NULL,
    district_id integer,
    city character varying,
    city_name character varying,
    code character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: postal_zones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.postal_zones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: postal_zones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.postal_zones_id_seq OWNED BY public.postal_zones.id;


--
-- Name: preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.preferences (
    id integer NOT NULL,
    name character varying NOT NULL,
    nature character varying NOT NULL,
    string_value text,
    boolean_value boolean,
    integer_value integer,
    decimal_value numeric(19,4),
    record_value_type character varying,
    record_value_id integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: preferences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.preferences_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.preferences_id_seq OWNED BY public.preferences.id;


--
-- Name: prescriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prescriptions (
    id integer NOT NULL,
    prescriptor_id integer NOT NULL,
    reference_number character varying,
    delivered_at timestamp without time zone,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb
);


--
-- Name: prescriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.prescriptions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: prescriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.prescriptions_id_seq OWNED BY public.prescriptions.id;


--
-- Name: product_enjoyments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_enjoyments (
    id integer NOT NULL,
    originator_type character varying,
    originator_id integer,
    product_id integer NOT NULL,
    nature character varying NOT NULL,
    enjoyer_id integer,
    started_at timestamp without time zone,
    stopped_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    intervention_id integer
);


--
-- Name: product_enjoyments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_enjoyments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_enjoyments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_enjoyments_id_seq OWNED BY public.product_enjoyments.id;


--
-- Name: product_labellings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_labellings (
    id integer NOT NULL,
    product_id integer NOT NULL,
    label_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: product_labellings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_labellings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_labellings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_labellings_id_seq OWNED BY public.product_labellings.id;


--
-- Name: product_linkages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_linkages (
    id integer NOT NULL,
    originator_type character varying,
    originator_id integer,
    carrier_id integer NOT NULL,
    point character varying NOT NULL,
    nature character varying NOT NULL,
    carried_id integer,
    started_at timestamp without time zone,
    stopped_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    intervention_id integer
);


--
-- Name: product_linkages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_linkages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_linkages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_linkages_id_seq OWNED BY public.product_linkages.id;


--
-- Name: product_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_links (
    id integer NOT NULL,
    originator_type character varying,
    originator_id integer,
    product_id integer NOT NULL,
    nature character varying NOT NULL,
    linked_id integer,
    started_at timestamp without time zone,
    stopped_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    intervention_id integer
);


--
-- Name: product_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_links_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_links_id_seq OWNED BY public.product_links.id;


--
-- Name: product_localizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_localizations (
    id integer NOT NULL,
    originator_type character varying,
    originator_id integer,
    product_id integer NOT NULL,
    nature character varying NOT NULL,
    container_id integer,
    started_at timestamp without time zone,
    stopped_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    intervention_id integer
);


--
-- Name: product_localizations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_localizations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_localizations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_localizations_id_seq OWNED BY public.product_localizations.id;


--
-- Name: product_memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_memberships_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_memberships_id_seq OWNED BY public.product_memberships.id;


--
-- Name: product_movements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_movements (
    id integer NOT NULL,
    product_id integer NOT NULL,
    intervention_id integer,
    originator_type character varying,
    originator_id integer,
    delta numeric(19,4) NOT NULL,
    population numeric(19,4) NOT NULL,
    started_at timestamp without time zone NOT NULL,
    stopped_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    description character varying
);


--
-- Name: product_movements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_movements_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_movements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_movements_id_seq OWNED BY public.product_movements.id;


--
-- Name: product_nature_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_nature_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    number character varying NOT NULL,
    description text,
    reference_name character varying,
    pictogram character varying,
    active boolean DEFAULT false NOT NULL,
    depreciable boolean DEFAULT false NOT NULL,
    saleable boolean DEFAULT false NOT NULL,
    purchasable boolean DEFAULT false NOT NULL,
    storable boolean DEFAULT false NOT NULL,
    reductible boolean DEFAULT false NOT NULL,
    subscribing boolean DEFAULT false NOT NULL,
    charge_account_id integer,
    product_account_id integer,
    fixed_asset_account_id integer,
    stock_account_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    fixed_asset_allocation_account_id integer,
    fixed_asset_expenses_account_id integer,
    fixed_asset_depreciation_percentage numeric(19,4) DEFAULT 0.0,
    fixed_asset_depreciation_method character varying,
    custom_fields jsonb,
    stock_movement_account_id integer,
    asset_fixable boolean DEFAULT false,
    type character varying NOT NULL,
    imported_from character varying,
    provider jsonb
);


--
-- Name: product_nature_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_nature_categories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_nature_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_nature_categories_id_seq OWNED BY public.product_nature_categories.id;


--
-- Name: product_nature_category_taxations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_nature_category_taxations (
    id integer NOT NULL,
    product_nature_category_id integer NOT NULL,
    tax_id integer NOT NULL,
    usage character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: product_nature_category_taxations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_nature_category_taxations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_nature_category_taxations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_nature_category_taxations_id_seq OWNED BY public.product_nature_category_taxations.id;


--
-- Name: product_nature_variant_components; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_nature_variant_components (
    id integer NOT NULL,
    product_nature_variant_id integer NOT NULL,
    part_product_nature_variant_id integer,
    parent_id integer,
    deleted_at timestamp without time zone,
    name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: product_nature_variant_components_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_nature_variant_components_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_nature_variant_components_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_nature_variant_components_id_seq OWNED BY public.product_nature_variant_components.id;


--
-- Name: product_nature_variant_readings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_nature_variant_readings (
    id integer NOT NULL,
    variant_id integer NOT NULL,
    indicator_name character varying NOT NULL,
    indicator_datatype character varying NOT NULL,
    absolute_measure_value_value numeric(19,4),
    absolute_measure_value_unit character varying,
    boolean_value boolean DEFAULT false NOT NULL,
    choice_value character varying,
    decimal_value numeric(19,4),
    multi_polygon_value postgis.geometry(MultiPolygon,4326),
    integer_value integer,
    measure_value_value numeric(19,4),
    measure_value_unit character varying,
    point_value postgis.geometry(Point,4326),
    string_value text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    geometry_value postgis.geometry(Geometry,4326)
);


--
-- Name: product_nature_variant_readings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_nature_variant_readings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_nature_variant_readings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_nature_variant_readings_id_seq OWNED BY public.product_nature_variant_readings.id;


--
-- Name: units; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.units (
    id integer NOT NULL,
    name character varying NOT NULL,
    reference_name character varying,
    base_unit_id integer,
    symbol character varying,
    work_code character varying,
    coefficient numeric(20,10) DEFAULT 1.0 NOT NULL,
    description text,
    dimension character varying NOT NULL,
    type character varying NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    provider jsonb,
    lock_version integer DEFAULT 0 NOT NULL,
    creator_id integer,
    updater_id integer
);


--
-- Name: product_nature_variant_suppliers_infos; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.product_nature_variant_suppliers_infos AS
 SELECT total_purchase_infos.full_name AS supplier_name,
    total_purchase_infos.entity_id,
    total_purchase_infos.variant_id,
    total_purchase_infos.ordered_quantity,
    total_purchase_infos.ordered_unit_name,
    round((total_purchase_infos.total_amount / total_purchase_infos.ordered_quantity), 2) AS average_unit_pretax_amount,
    latest_purchases.unit_pretax_amount AS last_unit_pretax_amount
   FROM (( SELECT p.supplier_id,
            sum(pi.conditioning_quantity) AS ordered_quantity,
            sum((pi.unit_pretax_amount * pi.conditioning_quantity)) AS total_amount,
            pi_units.name AS ordered_unit_name,
            pi.variant_id,
            e.full_name,
            e.id AS entity_id
           FROM (((public.purchase_items pi
             JOIN public.units pi_units ON ((pi.conditioning_unit_id = pi_units.id)))
             JOIN public.purchases p ON ((pi.purchase_id = p.id)))
             JOIN public.entities e ON ((e.id = p.supplier_id)))
          WHERE ((p.type)::text = 'PurchaseInvoice'::text)
          GROUP BY p.supplier_id, pi.variant_id, pi_units.name, e.full_name, e.id) total_purchase_infos
     JOIN ( SELECT DISTINCT ON (p.supplier_id, pi.variant_id) p.supplier_id,
            pi.variant_id,
            pi.unit_pretax_amount
           FROM (public.purchase_items pi
             JOIN public.purchases p ON ((pi.purchase_id = p.id)))
          WHERE ((p.type)::text = 'PurchaseInvoice'::text)
          ORDER BY p.supplier_id, pi.variant_id, p.invoiced_at DESC) latest_purchases ON (((latest_purchases.supplier_id = total_purchase_infos.supplier_id) AND (latest_purchases.variant_id = total_purchase_infos.variant_id))))
  WHERE (total_purchase_infos.ordered_quantity <> (0)::numeric);


--
-- Name: product_nature_variants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_nature_variants (
    id integer NOT NULL,
    category_id integer NOT NULL,
    nature_id integer NOT NULL,
    name character varying NOT NULL,
    work_number character varying,
    variety character varying NOT NULL,
    derivative_of character varying,
    reference_name character varying,
    unit_name character varying,
    active boolean DEFAULT true NOT NULL,
    picture_file_name character varying,
    picture_content_type character varying,
    picture_file_size integer,
    picture_updated_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb,
    gtin character varying,
    number character varying NOT NULL,
    stock_account_id integer,
    stock_movement_account_id integer,
    france_maaid character varying,
    providers jsonb,
    default_quantity numeric(19,4) DEFAULT 1 NOT NULL,
    default_unit_name character varying NOT NULL,
    default_unit_id integer NOT NULL,
    specie_variety character varying,
    type character varying NOT NULL,
    imported_from character varying,
    provider jsonb,
    pictogram character varying
);


--
-- Name: product_nature_variants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_nature_variants_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_nature_variants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_nature_variants_id_seq OWNED BY public.product_nature_variants.id;


--
-- Name: product_natures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_natures (
    id integer NOT NULL,
    name character varying NOT NULL,
    number character varying NOT NULL,
    variety character varying NOT NULL,
    derivative_of character varying,
    reference_name character varying,
    active boolean DEFAULT false NOT NULL,
    evolvable boolean DEFAULT false NOT NULL,
    population_counting character varying NOT NULL,
    abilities_list text,
    variable_indicators_list text,
    frozen_indicators_list text,
    linkage_points_list text,
    derivatives_list text,
    picture_file_name character varying,
    picture_content_type character varying,
    picture_file_size integer,
    picture_updated_at timestamp without time zone,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb,
    subscribing boolean DEFAULT false NOT NULL,
    subscription_nature_id integer,
    subscription_years_count integer DEFAULT 0 NOT NULL,
    subscription_months_count integer DEFAULT 0 NOT NULL,
    subscription_days_count integer DEFAULT 0 NOT NULL,
    type character varying NOT NULL,
    imported_from character varying,
    provider jsonb
);


--
-- Name: product_natures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_natures_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_natures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_natures_id_seq OWNED BY public.product_natures.id;


--
-- Name: product_ownerships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_ownerships (
    id integer NOT NULL,
    originator_type character varying,
    originator_id integer,
    product_id integer NOT NULL,
    nature character varying NOT NULL,
    owner_id integer,
    started_at timestamp without time zone,
    stopped_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    intervention_id integer
);


--
-- Name: product_ownerships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_ownerships_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_ownerships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_ownerships_id_seq OWNED BY public.product_ownerships.id;


--
-- Name: product_phases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_phases (
    id integer NOT NULL,
    originator_type character varying,
    originator_id integer,
    product_id integer NOT NULL,
    variant_id integer NOT NULL,
    nature_id integer NOT NULL,
    category_id integer NOT NULL,
    started_at timestamp without time zone,
    stopped_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    intervention_id integer
);


--
-- Name: product_phases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_phases_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_phases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_phases_id_seq OWNED BY public.product_phases.id;


--
-- Name: product_populations; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.product_populations AS
SELECT
    NULL::integer AS product_id,
    NULL::timestamp without time zone AS started_at,
    NULL::numeric AS value,
    NULL::integer AS creator_id,
    NULL::timestamp without time zone AS created_at,
    NULL::timestamp without time zone AS updated_at,
    NULL::integer AS updater_id,
    NULL::integer AS id,
    NULL::integer AS lock_version;


--
-- Name: product_readings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_readings (
    id integer NOT NULL,
    originator_type character varying,
    originator_id integer,
    product_id integer NOT NULL,
    read_at timestamp without time zone NOT NULL,
    indicator_name character varying NOT NULL,
    indicator_datatype character varying NOT NULL,
    absolute_measure_value_value numeric(19,4),
    absolute_measure_value_unit character varying,
    boolean_value boolean DEFAULT false NOT NULL,
    choice_value character varying,
    decimal_value numeric(19,4),
    multi_polygon_value postgis.geometry(MultiPolygon,4326),
    integer_value integer,
    measure_value_value numeric(19,4),
    measure_value_unit character varying,
    point_value postgis.geometry(Point,4326),
    string_value text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    geometry_value postgis.geometry(Geometry,4326)
);


--
-- Name: product_readings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_readings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_readings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_readings_id_seq OWNED BY public.product_readings.id;


--
-- Name: products_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.products_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.products_id_seq OWNED BY public.products.id;


--
-- Name: project_budgets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_budgets (
    id integer NOT NULL,
    name character varying,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    isacompta_analytic_code character varying(2)
);


--
-- Name: project_budgets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_budgets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_budgets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_budgets_id_seq OWNED BY public.project_budgets.id;


--
-- Name: purchase_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.purchase_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: purchase_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.purchase_items_id_seq OWNED BY public.purchase_items.id;


--
-- Name: purchase_natures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.purchase_natures (
    id integer NOT NULL,
    active boolean DEFAULT true NOT NULL,
    name character varying NOT NULL,
    description text,
    journal_id integer NOT NULL,
    by_default boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: purchase_natures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.purchase_natures_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: purchase_natures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.purchase_natures_id_seq OWNED BY public.purchase_natures.id;


--
-- Name: purchases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.purchases_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: purchases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.purchases_id_seq OWNED BY public.purchases.id;


--
-- Name: regularizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.regularizations (
    id integer NOT NULL,
    affair_id integer NOT NULL,
    journal_entry_id integer NOT NULL,
    currency character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: regularizations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.regularizations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: regularizations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.regularizations_id_seq OWNED BY public.regularizations.id;


--
-- Name: ride_sets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ride_sets (
    id integer NOT NULL,
    started_at timestamp without time zone,
    stopped_at timestamp without time zone,
    road integer,
    nature character varying,
    sleep_count integer,
    provider jsonb,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    number character varying,
    duration interval,
    sleep_duration interval,
    area_without_overlap double precision,
    area_with_overlap double precision,
    area_smart double precision,
    gasoline double precision,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    shape postgis.geometry(Geometry,4326)
);


--
-- Name: ride_sets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ride_sets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ride_sets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ride_sets_id_seq OWNED BY public.ride_sets.id;


--
-- Name: rides; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rides (
    id integer NOT NULL,
    number character varying,
    started_at timestamp without time zone,
    stopped_at timestamp without time zone,
    sleep_count integer,
    equipment_name character varying,
    provider jsonb,
    state character varying,
    product_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    duration interval,
    sleep_duration interval,
    distance_km double precision,
    area_without_overlap double precision,
    area_with_overlap double precision,
    area_smart double precision,
    gasoline double precision,
    nature character varying,
    ride_set_id integer,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    intervention_id integer,
    shape postgis.geometry(Geometry,4326)
);


--
-- Name: rides_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rides_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rides_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rides_id_seq OWNED BY public.rides.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id integer NOT NULL,
    name character varying NOT NULL,
    rights text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    reference_name character varying
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: sale_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sale_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sale_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sale_items_id_seq OWNED BY public.sale_items.id;


--
-- Name: sale_natures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sale_natures (
    id integer NOT NULL,
    name character varying NOT NULL,
    active boolean DEFAULT true NOT NULL,
    by_default boolean DEFAULT false NOT NULL,
    downpayment boolean DEFAULT false NOT NULL,
    downpayment_minimum numeric(19,4) DEFAULT 0.0,
    downpayment_percentage numeric(19,4) DEFAULT 0.0,
    payment_mode_id integer,
    catalog_id integer NOT NULL,
    payment_mode_complement text,
    currency character varying NOT NULL,
    sales_conditions text,
    expiration_delay character varying NOT NULL,
    payment_delay character varying NOT NULL,
    journal_id integer,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    provider jsonb
);


--
-- Name: sale_natures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sale_natures_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sale_natures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sale_natures_id_seq OWNED BY public.sale_natures.id;


--
-- Name: sales_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sales_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sales_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sales_id_seq OWNED BY public.sales.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: sensors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sensors (
    id integer NOT NULL,
    vendor_euid character varying,
    model_euid character varying,
    name character varying NOT NULL,
    retrieval_mode character varying NOT NULL,
    access_parameters json,
    product_id integer,
    embedded boolean DEFAULT false NOT NULL,
    host_id integer,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    token character varying,
    custom_fields jsonb,
    euid character varying,
    partner_url character varying,
    battery_level numeric(19,4),
    last_transmission_at timestamp without time zone
);


--
-- Name: sensors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sensors_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sensors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sensors_id_seq OWNED BY public.sensors.id;


--
-- Name: sequences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sequences (
    id integer NOT NULL,
    name character varying NOT NULL,
    number_format character varying NOT NULL,
    period character varying DEFAULT 'number'::character varying NOT NULL,
    last_year integer,
    last_month integer,
    last_cweek integer,
    last_number integer,
    number_increment integer DEFAULT 1 NOT NULL,
    number_start integer DEFAULT 1 NOT NULL,
    usage character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: sequences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sequences_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sequences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sequences_id_seq OWNED BY public.sequences.id;


--
-- Name: subscription_natures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscription_natures (
    id integer NOT NULL,
    name character varying NOT NULL,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: subscription_natures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.subscription_natures_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subscription_natures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.subscription_natures_id_seq OWNED BY public.subscription_natures.id;


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscriptions (
    id integer NOT NULL,
    started_on date NOT NULL,
    stopped_on date NOT NULL,
    address_id integer,
    quantity integer NOT NULL,
    suspended boolean DEFAULT false NOT NULL,
    nature_id integer,
    subscriber_id integer,
    description text,
    number character varying,
    sale_item_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb,
    parent_id integer,
    swim_lane_uuid uuid NOT NULL
);


--
-- Name: subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.subscriptions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.subscriptions_id_seq OWNED BY public.subscriptions.id;


--
-- Name: supervision_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.supervision_items (
    id integer NOT NULL,
    supervision_id integer NOT NULL,
    sensor_id integer NOT NULL,
    color character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: supervision_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.supervision_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: supervision_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.supervision_items_id_seq OWNED BY public.supervision_items.id;


--
-- Name: supervisions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.supervisions (
    id integer NOT NULL,
    name character varying NOT NULL,
    time_window integer,
    view_parameters json,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb
);


--
-- Name: supervisions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.supervisions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: supervisions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.supervisions_id_seq OWNED BY public.supervisions.id;


--
-- Name: synchronization_operations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.synchronization_operations (
    id integer NOT NULL,
    operation_name character varying NOT NULL,
    state character varying NOT NULL,
    finished_at timestamp without time zone,
    notification_id integer,
    request jsonb,
    response jsonb,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    originator_type character varying,
    originator_id integer
);


--
-- Name: synchronization_operations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.synchronization_operations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: synchronization_operations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.synchronization_operations_id_seq OWNED BY public.synchronization_operations.id;


--
-- Name: target_distributions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.target_distributions (
    id integer NOT NULL,
    target_id integer NOT NULL,
    activity_production_id integer NOT NULL,
    activity_id integer NOT NULL,
    started_at timestamp without time zone,
    stopped_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: target_distributions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.target_distributions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: target_distributions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.target_distributions_id_seq OWNED BY public.target_distributions.id;


--
-- Name: tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tasks (
    id integer NOT NULL,
    name character varying NOT NULL,
    state character varying NOT NULL,
    nature character varying NOT NULL,
    entity_id integer NOT NULL,
    executor_id integer,
    sale_opportunity_id integer,
    description text,
    due_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb
);


--
-- Name: tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tasks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tasks_id_seq OWNED BY public.tasks.id;


--
-- Name: tax_declaration_item_parts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tax_declaration_item_parts (
    id integer NOT NULL,
    tax_declaration_item_id integer NOT NULL,
    journal_entry_item_id integer NOT NULL,
    account_id integer NOT NULL,
    tax_amount numeric(19,4) NOT NULL,
    pretax_amount numeric(19,4) NOT NULL,
    total_tax_amount numeric(19,4) NOT NULL,
    total_pretax_amount numeric(19,4) NOT NULL,
    direction character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: tax_declaration_item_parts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tax_declaration_item_parts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tax_declaration_item_parts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tax_declaration_item_parts_id_seq OWNED BY public.tax_declaration_item_parts.id;


--
-- Name: tax_declaration_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tax_declaration_items (
    id integer NOT NULL,
    tax_declaration_id integer NOT NULL,
    tax_id integer NOT NULL,
    currency character varying NOT NULL,
    collected_tax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    deductible_tax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    deductible_pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    collected_pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    fixed_asset_deductible_pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    fixed_asset_deductible_tax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    balance_pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    balance_tax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    intracommunity_payable_tax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    intracommunity_payable_pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL
);


--
-- Name: tax_declaration_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tax_declaration_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tax_declaration_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tax_declaration_items_id_seq OWNED BY public.tax_declaration_items.id;


--
-- Name: tax_declarations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tax_declarations (
    id integer NOT NULL,
    financial_year_id integer NOT NULL,
    journal_entry_id integer,
    accounted_at timestamp without time zone,
    responsible_id integer,
    mode character varying NOT NULL,
    description text,
    started_on date NOT NULL,
    stopped_on date NOT NULL,
    currency character varying NOT NULL,
    number character varying,
    reference_number character varying,
    state character varying,
    invoiced_on date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: tax_declarations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tax_declarations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tax_declarations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tax_declarations_id_seq OWNED BY public.tax_declarations.id;


--
-- Name: taxes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.taxes (
    id integer NOT NULL,
    name character varying NOT NULL,
    amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    description text,
    collect_account_id integer,
    deduction_account_id integer,
    reference_name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    active boolean DEFAULT false NOT NULL,
    nature character varying NOT NULL,
    country character varying NOT NULL,
    fixed_asset_deduction_account_id integer,
    fixed_asset_collect_account_id integer,
    intracommunity boolean DEFAULT false NOT NULL,
    intracommunity_payable_account_id integer,
    provider jsonb
);


--
-- Name: taxes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.taxes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: taxes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.taxes_id_seq OWNED BY public.taxes.id;


--
-- Name: teams; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.teams (
    id integer NOT NULL,
    name character varying NOT NULL,
    description text,
    parent_id integer,
    lft integer,
    rgt integer,
    depth integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    isacompta_analytic_code character varying(2)
);


--
-- Name: teams_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.teams_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: teams_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.teams_id_seq OWNED BY public.teams.id;


--
-- Name: technical_itineraries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.technical_itineraries (
    id integer NOT NULL,
    name character varying,
    campaign_id integer,
    activity_id integer,
    description character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    originator_id integer,
    technical_workflow_id character varying
);


--
-- Name: technical_itineraries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.technical_itineraries_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: technical_itineraries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.technical_itineraries_id_seq OWNED BY public.technical_itineraries.id;


--
-- Name: technical_itinerary_intervention_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.technical_itinerary_intervention_templates (
    id integer NOT NULL,
    technical_itinerary_id integer,
    intervention_template_id integer,
    "position" integer,
    day_between_intervention integer,
    duration integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    dont_divide_duration boolean DEFAULT false,
    reference_hash character varying,
    parent_hash character varying,
    day_since_start numeric(19,4),
    repetition integer DEFAULT 1 NOT NULL,
    frequency character varying DEFAULT 'per_year'::character varying NOT NULL
);


--
-- Name: technical_itinerary_intervention_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.technical_itinerary_intervention_templates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: technical_itinerary_intervention_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.technical_itinerary_intervention_templates_id_seq OWNED BY public.technical_itinerary_intervention_templates.id;


--
-- Name: tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tokens (
    id integer NOT NULL,
    name character varying NOT NULL,
    value character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tokens_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tokens_id_seq OWNED BY public.tokens.id;


--
-- Name: trackings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trackings (
    id integer NOT NULL,
    name character varying NOT NULL,
    serial character varying,
    active boolean DEFAULT true NOT NULL,
    description text,
    product_id integer,
    producer_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    usage_limit_on date,
    usage_limit_nature character varying
);


--
-- Name: trackings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trackings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trackings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trackings_id_seq OWNED BY public.trackings.id;


--
-- Name: units_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.units_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: units_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.units_id_seq OWNED BY public.units.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id integer NOT NULL,
    first_name character varying NOT NULL,
    last_name character varying NOT NULL,
    locked boolean DEFAULT false NOT NULL,
    email character varying NOT NULL,
    person_id integer,
    role_id integer,
    maximal_grantable_reduction_percentage numeric(19,4) DEFAULT 5.0 NOT NULL,
    administrator boolean DEFAULT false NOT NULL,
    rights text,
    description text,
    commercial boolean DEFAULT false NOT NULL,
    team_id integer,
    employed boolean DEFAULT false NOT NULL,
    employment character varying,
    language character varying NOT NULL,
    last_sign_in_at timestamp without time zone,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0,
    current_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying,
    last_sign_in_ip character varying,
    confirmation_token character varying,
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    unconfirmed_email character varying,
    failed_attempts integer DEFAULT 0,
    unlock_token character varying,
    locked_at timestamp without time zone,
    authentication_token character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    invitation_token character varying,
    invitation_created_at timestamp without time zone,
    invitation_sent_at timestamp without time zone,
    invitation_accepted_at timestamp without time zone,
    invitation_limit integer,
    invited_by_id integer,
    invitations_count integer DEFAULT 0,
    signup_at timestamp without time zone,
    provider character varying,
    uid character varying
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.versions (
    id integer NOT NULL,
    event character varying NOT NULL,
    item_type character varying,
    item_id integer,
    item_object text,
    item_changes text,
    created_at timestamp without time zone NOT NULL,
    creator_id integer,
    creator_name character varying
);


--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.versions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.versions_id_seq OWNED BY public.versions.id;


--
-- Name: wice_grid_serialized_queries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wice_grid_serialized_queries (
    id integer NOT NULL,
    name character varying,
    grid_name character varying,
    query text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: wice_grid_serialized_queries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wice_grid_serialized_queries_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wice_grid_serialized_queries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.wice_grid_serialized_queries_id_seq OWNED BY public.wice_grid_serialized_queries.id;


--
-- Name: wine_incoming_harvest_inputs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wine_incoming_harvest_inputs (
    id integer NOT NULL,
    wine_incoming_harvest_id integer NOT NULL,
    input_id integer NOT NULL,
    quantity_value numeric(19,4) NOT NULL,
    quantity_unit character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: wine_incoming_harvest_inputs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wine_incoming_harvest_inputs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wine_incoming_harvest_inputs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.wine_incoming_harvest_inputs_id_seq OWNED BY public.wine_incoming_harvest_inputs.id;


--
-- Name: wine_incoming_harvest_plants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wine_incoming_harvest_plants (
    id integer NOT NULL,
    wine_incoming_harvest_id integer NOT NULL,
    plant_id integer NOT NULL,
    harvest_percentage_received numeric(19,4) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    rows_harvested character varying
);


--
-- Name: wine_incoming_harvest_plants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wine_incoming_harvest_plants_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wine_incoming_harvest_plants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.wine_incoming_harvest_plants_id_seq OWNED BY public.wine_incoming_harvest_plants.id;


--
-- Name: wine_incoming_harvest_presses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wine_incoming_harvest_presses (
    id integer NOT NULL,
    wine_incoming_harvest_id integer NOT NULL,
    press_id integer,
    quantity_value numeric(19,4) NOT NULL,
    quantity_unit character varying NOT NULL,
    pressing_started_at time without time zone,
    pressing_schedule character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: wine_incoming_harvest_presses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wine_incoming_harvest_presses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wine_incoming_harvest_presses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.wine_incoming_harvest_presses_id_seq OWNED BY public.wine_incoming_harvest_presses.id;


--
-- Name: wine_incoming_harvest_storages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wine_incoming_harvest_storages (
    id integer NOT NULL,
    wine_incoming_harvest_id integer NOT NULL,
    storage_id integer NOT NULL,
    quantity_value numeric(19,4) NOT NULL,
    quantity_unit character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: wine_incoming_harvest_storages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wine_incoming_harvest_storages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wine_incoming_harvest_storages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.wine_incoming_harvest_storages_id_seq OWNED BY public.wine_incoming_harvest_storages.id;


--
-- Name: wine_incoming_harvests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wine_incoming_harvests (
    id integer NOT NULL,
    number character varying,
    ticket_number character varying,
    description text,
    campaign_id integer NOT NULL,
    analysis_id integer,
    received_at timestamp without time zone NOT NULL,
    quantity_value numeric(19,4) NOT NULL,
    quantity_unit character varying NOT NULL,
    additional_informations jsonb DEFAULT '{}'::jsonb,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: wine_incoming_harvests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wine_incoming_harvests_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wine_incoming_harvests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.wine_incoming_harvests_id_seq OWNED BY public.wine_incoming_harvests.id;


--
-- Name: worker_contracts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.worker_contracts (
    id integer NOT NULL,
    entity_id integer NOT NULL,
    name character varying,
    description text,
    reference_name character varying,
    nature character varying,
    contract_end character varying,
    started_at timestamp without time zone NOT NULL,
    stopped_at timestamp without time zone,
    salaried boolean DEFAULT false NOT NULL,
    monthly_duration numeric(8,2) NOT NULL,
    raw_hourly_amount numeric(8,2) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb
);


--
-- Name: worker_contracts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.worker_contracts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: worker_contracts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.worker_contracts_id_seq OWNED BY public.worker_contracts.id;


--
-- Name: worker_group_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.worker_group_items (
    id integer NOT NULL,
    worker_id integer,
    worker_group_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: worker_group_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.worker_group_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: worker_group_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.worker_group_items_id_seq OWNED BY public.worker_group_items.id;


--
-- Name: worker_group_labellings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.worker_group_labellings (
    id integer NOT NULL,
    worker_group_id integer,
    label_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: worker_group_labellings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.worker_group_labellings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: worker_group_labellings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.worker_group_labellings_id_seq OWNED BY public.worker_group_labellings.id;


--
-- Name: worker_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.worker_groups (
    id integer NOT NULL,
    name character varying NOT NULL,
    work_number character varying,
    active boolean DEFAULT true NOT NULL,
    usage character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: worker_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.worker_groups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: worker_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.worker_groups_id_seq OWNED BY public.worker_groups.id;


--
-- Name: worker_time_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.worker_time_logs (
    id integer NOT NULL,
    worker_id integer NOT NULL,
    started_at timestamp without time zone NOT NULL,
    stopped_at timestamp without time zone NOT NULL,
    duration integer NOT NULL,
    description text,
    custom_fields jsonb DEFAULT '{}'::jsonb,
    provider jsonb DEFAULT '{}'::jsonb,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: worker_time_indicators; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.worker_time_indicators AS
 SELECT s.worker_id,
    min(s.started_at) AS start_at,
    max(s.stopped_at) AS stop_at,
    (max(s.stopped_at) - min(s.started_at)) AS duration
   FROM ( SELECT s_1.worker_id,
            s_1.started_at,
            s_1.stopped_at,
            s_1.lag_stopped_at,
            count(*) FILTER (WHERE (s_1.started_at > s_1.lag_stopped_at)) OVER (PARTITION BY s_1.worker_id ORDER BY s_1.started_at) AS grp
           FROM ( SELECT s_2.worker_id,
                    s_2.started_at,
                    s_2.stopped_at,
                    lag(s_2.stopped_at) OVER (PARTITION BY s_2.worker_id ORDER BY s_2.started_at) AS lag_stopped_at
                   FROM ( SELECT s_3.worker_id,
                            s_3.started_at,
                            s_3.stopped_at
                           FROM ( SELECT wtl.worker_id,
                                    wtl.started_at,
                                    wtl.duration,
                                    wtl.stopped_at,
                                    'worker_time_log'::text AS nature
                                   FROM public.worker_time_logs wtl
                                UNION ALL
                                 SELECT ip.product_id AS worker_id,
                                    iwp.started_at,
                                    iwp.duration,
                                    iwp.stopped_at,
                                    'intervention'::text AS nature
                                   FROM ((public.intervention_working_periods iwp
                                     JOIN public.interventions i ON ((i.id = iwp.intervention_id)))
                                     JOIN public.intervention_parameters ip ON (((ip.intervention_id = i.id) AND ((ip.type)::text = 'InterventionDoer'::text))))
                                  WHERE ((iwp.intervention_participation_id IS NULL) AND (NOT (ip.product_id IN ( SELECT intervention_participations.product_id
   FROM public.intervention_participations
  WHERE (intervention_participations.intervention_id = i.id)))))
                                UNION ALL
                                 SELECT ipa.product_id AS worker_id,
                                    iwp.started_at,
                                    iwp.duration,
                                    iwp.stopped_at,
                                    'intervention_participation'::text AS nature
                                   FROM ((public.intervention_working_periods iwp
                                     JOIN public.intervention_participations ipa ON ((ipa.id = iwp.intervention_participation_id)))
                                     JOIN public.intervention_parameters ip ON (((ip.product_id = ipa.product_id) AND ((ip.type)::text = 'InterventionDoer'::text))))
                                  WHERE (iwp.intervention_id IS NULL)
                                  GROUP BY ipa.product_id, iwp.started_at, iwp.stopped_at, iwp.duration, iwp.nature
                          ORDER BY 1, 2) s_3) s_2) s_1) s
  GROUP BY s.worker_id, s.grp
  ORDER BY s.worker_id, (min(s.started_at))
  WITH NO DATA;


--
-- Name: worker_time_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.worker_time_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: worker_time_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.worker_time_logs_id_seq OWNED BY public.worker_time_logs.id;


--
-- Name: registered_cadastral_buildings id; Type: DEFAULT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.registered_cadastral_buildings ALTER COLUMN id SET DEFAULT nextval('lexicon.registered_cadastral_buildings_id_seq'::regclass);


--
-- Name: registered_cadastral_prices id; Type: DEFAULT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.registered_cadastral_prices ALTER COLUMN id SET DEFAULT nextval('lexicon.registered_cadastral_prices_id_seq'::regclass);


--
-- Name: account_balances id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_balances ALTER COLUMN id SET DEFAULT nextval('public.account_balances_id_seq'::regclass);


--
-- Name: accounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts ALTER COLUMN id SET DEFAULT nextval('public.accounts_id_seq'::regclass);


--
-- Name: activities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activities ALTER COLUMN id SET DEFAULT nextval('public.activities_id_seq'::regclass);


--
-- Name: activity_budget_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_budget_items ALTER COLUMN id SET DEFAULT nextval('public.activity_budget_items_id_seq'::regclass);


--
-- Name: activity_budgets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_budgets ALTER COLUMN id SET DEFAULT nextval('public.activity_budgets_id_seq'::regclass);


--
-- Name: activity_distributions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_distributions ALTER COLUMN id SET DEFAULT nextval('public.activity_distributions_id_seq'::regclass);


--
-- Name: activity_inspection_calibration_natures id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_inspection_calibration_natures ALTER COLUMN id SET DEFAULT nextval('public.activity_inspection_calibration_natures_id_seq'::regclass);


--
-- Name: activity_inspection_calibration_scales id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_inspection_calibration_scales ALTER COLUMN id SET DEFAULT nextval('public.activity_inspection_calibration_scales_id_seq'::regclass);


--
-- Name: activity_inspection_point_natures id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_inspection_point_natures ALTER COLUMN id SET DEFAULT nextval('public.activity_inspection_point_natures_id_seq'::regclass);


--
-- Name: activity_production_batches id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_production_batches ALTER COLUMN id SET DEFAULT nextval('public.activity_production_batches_id_seq'::regclass);


--
-- Name: activity_production_irregular_batches id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_production_irregular_batches ALTER COLUMN id SET DEFAULT nextval('public.activity_production_irregular_batches_id_seq'::regclass);


--
-- Name: activity_productions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_productions ALTER COLUMN id SET DEFAULT nextval('public.activity_productions_id_seq'::regclass);


--
-- Name: activity_seasons id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_seasons ALTER COLUMN id SET DEFAULT nextval('public.activity_seasons_id_seq'::regclass);


--
-- Name: activity_tactics id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_tactics ALTER COLUMN id SET DEFAULT nextval('public.activity_tactics_id_seq'::regclass);


--
-- Name: affairs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.affairs ALTER COLUMN id SET DEFAULT nextval('public.affairs_id_seq'::regclass);


--
-- Name: alert_phases id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_phases ALTER COLUMN id SET DEFAULT nextval('public.alert_phases_id_seq'::regclass);


--
-- Name: alerts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alerts ALTER COLUMN id SET DEFAULT nextval('public.alerts_id_seq'::regclass);


--
-- Name: analyses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.analyses ALTER COLUMN id SET DEFAULT nextval('public.analyses_id_seq'::regclass);


--
-- Name: analysis_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.analysis_items ALTER COLUMN id SET DEFAULT nextval('public.analysis_items_id_seq'::regclass);


--
-- Name: analytic_segments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.analytic_segments ALTER COLUMN id SET DEFAULT nextval('public.analytic_segments_id_seq'::regclass);


--
-- Name: analytic_sequences id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.analytic_sequences ALTER COLUMN id SET DEFAULT nextval('public.analytic_sequences_id_seq'::regclass);


--
-- Name: attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attachments ALTER COLUMN id SET DEFAULT nextval('public.attachments_id_seq'::regclass);


--
-- Name: bank_statement_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bank_statement_items ALTER COLUMN id SET DEFAULT nextval('public.bank_statement_items_id_seq'::regclass);


--
-- Name: bank_statements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bank_statements ALTER COLUMN id SET DEFAULT nextval('public.bank_statements_id_seq'::regclass);


--
-- Name: call_messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.call_messages ALTER COLUMN id SET DEFAULT nextval('public.call_messages_id_seq'::regclass);


--
-- Name: calls id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calls ALTER COLUMN id SET DEFAULT nextval('public.calls_id_seq'::regclass);


--
-- Name: campaigns id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaigns ALTER COLUMN id SET DEFAULT nextval('public.campaigns_id_seq'::regclass);


--
-- Name: cap_islets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cap_islets ALTER COLUMN id SET DEFAULT nextval('public.cap_islets_id_seq'::regclass);


--
-- Name: cap_land_parcels id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cap_land_parcels ALTER COLUMN id SET DEFAULT nextval('public.cap_land_parcels_id_seq'::regclass);


--
-- Name: cap_neutral_areas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cap_neutral_areas ALTER COLUMN id SET DEFAULT nextval('public.cap_neutral_areas_id_seq'::regclass);


--
-- Name: cap_statements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cap_statements ALTER COLUMN id SET DEFAULT nextval('public.cap_statements_id_seq'::regclass);


--
-- Name: cash_sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cash_sessions ALTER COLUMN id SET DEFAULT nextval('public.cash_sessions_id_seq'::regclass);


--
-- Name: cash_transfers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cash_transfers ALTER COLUMN id SET DEFAULT nextval('public.cash_transfers_id_seq'::regclass);


--
-- Name: cashes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cashes ALTER COLUMN id SET DEFAULT nextval('public.cashes_id_seq'::regclass);


--
-- Name: catalog_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_items ALTER COLUMN id SET DEFAULT nextval('public.catalog_items_id_seq'::regclass);


--
-- Name: catalogs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalogs ALTER COLUMN id SET DEFAULT nextval('public.catalogs_id_seq'::regclass);


--
-- Name: contract_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contract_items ALTER COLUMN id SET DEFAULT nextval('public.contract_items_id_seq'::regclass);


--
-- Name: contracts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contracts ALTER COLUMN id SET DEFAULT nextval('public.contracts_id_seq'::regclass);


--
-- Name: crop_group_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crop_group_items ALTER COLUMN id SET DEFAULT nextval('public.crop_group_items_id_seq'::regclass);


--
-- Name: crop_group_labellings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crop_group_labellings ALTER COLUMN id SET DEFAULT nextval('public.crop_group_labellings_id_seq'::regclass);


--
-- Name: crop_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crop_groups ALTER COLUMN id SET DEFAULT nextval('public.crop_groups_id_seq'::regclass);


--
-- Name: crumbs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crumbs ALTER COLUMN id SET DEFAULT nextval('public.crumbs_id_seq'::regclass);


--
-- Name: cultivable_zones id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cultivable_zones ALTER COLUMN id SET DEFAULT nextval('public.cultivable_zones_id_seq'::regclass);


--
-- Name: custom_field_choices id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_field_choices ALTER COLUMN id SET DEFAULT nextval('public.custom_field_choices_id_seq'::regclass);


--
-- Name: custom_fields id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_fields ALTER COLUMN id SET DEFAULT nextval('public.custom_fields_id_seq'::regclass);


--
-- Name: cvi_cadastral_plant_cvi_land_parcels id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cvi_cadastral_plant_cvi_land_parcels ALTER COLUMN id SET DEFAULT nextval('public.cvi_cadastral_plant_cvi_land_parcels_id_seq'::regclass);


--
-- Name: cvi_cadastral_plants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cvi_cadastral_plants ALTER COLUMN id SET DEFAULT nextval('public.cvi_cadastral_plants_id_seq'::regclass);


--
-- Name: cvi_cultivable_zones id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cvi_cultivable_zones ALTER COLUMN id SET DEFAULT nextval('public.cvi_cultivable_zones_id_seq'::regclass);


--
-- Name: cvi_land_parcels id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cvi_land_parcels ALTER COLUMN id SET DEFAULT nextval('public.cvi_land_parcels_id_seq'::regclass);


--
-- Name: cvi_statements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cvi_statements ALTER COLUMN id SET DEFAULT nextval('public.cvi_statements_id_seq'::regclass);


--
-- Name: daily_charges id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_charges ALTER COLUMN id SET DEFAULT nextval('public.daily_charges_id_seq'::regclass);


--
-- Name: dashboards id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dashboards ALTER COLUMN id SET DEFAULT nextval('public.dashboards_id_seq'::regclass);


--
-- Name: debt_transfers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.debt_transfers ALTER COLUMN id SET DEFAULT nextval('public.debt_transfers_id_seq'::regclass);


--
-- Name: deliveries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deliveries ALTER COLUMN id SET DEFAULT nextval('public.deliveries_id_seq'::regclass);


--
-- Name: delivery_tools id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delivery_tools ALTER COLUMN id SET DEFAULT nextval('public.delivery_tools_id_seq'::regclass);


--
-- Name: deposits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deposits ALTER COLUMN id SET DEFAULT nextval('public.deposits_id_seq'::regclass);


--
-- Name: districts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.districts ALTER COLUMN id SET DEFAULT nextval('public.districts_id_seq'::regclass);


--
-- Name: document_templates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_templates ALTER COLUMN id SET DEFAULT nextval('public.document_templates_id_seq'::regclass);


--
-- Name: documents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documents ALTER COLUMN id SET DEFAULT nextval('public.documents_id_seq'::regclass);


--
-- Name: economic_cash_indicators id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.economic_cash_indicators ALTER COLUMN id SET DEFAULT nextval('public.economic_cash_indicators_id_seq'::regclass);


--
-- Name: entities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entities ALTER COLUMN id SET DEFAULT nextval('public.entities_id_seq'::regclass);


--
-- Name: entity_addresses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entity_addresses ALTER COLUMN id SET DEFAULT nextval('public.entity_addresses_id_seq'::regclass);


--
-- Name: entity_links id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entity_links ALTER COLUMN id SET DEFAULT nextval('public.entity_links_id_seq'::regclass);


--
-- Name: event_participations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_participations ALTER COLUMN id SET DEFAULT nextval('public.event_participations_id_seq'::regclass);


--
-- Name: events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events ALTER COLUMN id SET DEFAULT nextval('public.events_id_seq'::regclass);


--
-- Name: financial_year_archives id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.financial_year_archives ALTER COLUMN id SET DEFAULT nextval('public.financial_year_archives_id_seq'::regclass);


--
-- Name: financial_year_exchanges id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.financial_year_exchanges ALTER COLUMN id SET DEFAULT nextval('public.financial_year_exchanges_id_seq'::regclass);


--
-- Name: financial_years id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.financial_years ALTER COLUMN id SET DEFAULT nextval('public.financial_years_id_seq'::regclass);


--
-- Name: fixed_asset_depreciations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fixed_asset_depreciations ALTER COLUMN id SET DEFAULT nextval('public.fixed_asset_depreciations_id_seq'::regclass);


--
-- Name: fixed_assets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fixed_assets ALTER COLUMN id SET DEFAULT nextval('public.fixed_assets_id_seq'::regclass);


--
-- Name: gap_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gap_items ALTER COLUMN id SET DEFAULT nextval('public.gap_items_id_seq'::regclass);


--
-- Name: gaps id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gaps ALTER COLUMN id SET DEFAULT nextval('public.gaps_id_seq'::regclass);


--
-- Name: georeadings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.georeadings ALTER COLUMN id SET DEFAULT nextval('public.georeadings_id_seq'::regclass);


--
-- Name: guide_analyses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.guide_analyses ALTER COLUMN id SET DEFAULT nextval('public.guide_analyses_id_seq'::regclass);


--
-- Name: guide_analysis_points id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.guide_analysis_points ALTER COLUMN id SET DEFAULT nextval('public.guide_analysis_points_id_seq'::regclass);


--
-- Name: guides id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.guides ALTER COLUMN id SET DEFAULT nextval('public.guides_id_seq'::regclass);


--
-- Name: idea_diagnostic_item_values id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.idea_diagnostic_item_values ALTER COLUMN id SET DEFAULT nextval('public.idea_diagnostic_item_values_id_seq'::regclass);


--
-- Name: idea_diagnostic_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.idea_diagnostic_items ALTER COLUMN id SET DEFAULT nextval('public.idea_diagnostic_items_id_seq'::regclass);


--
-- Name: idea_diagnostic_results id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.idea_diagnostic_results ALTER COLUMN id SET DEFAULT nextval('public.idea_diagnostic_results_id_seq'::regclass);


--
-- Name: idea_diagnostics id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.idea_diagnostics ALTER COLUMN id SET DEFAULT nextval('public.idea_diagnostics_id_seq'::regclass);


--
-- Name: identifiers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.identifiers ALTER COLUMN id SET DEFAULT nextval('public.identifiers_id_seq'::regclass);


--
-- Name: imports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.imports ALTER COLUMN id SET DEFAULT nextval('public.imports_id_seq'::regclass);


--
-- Name: incoming_payment_modes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incoming_payment_modes ALTER COLUMN id SET DEFAULT nextval('public.incoming_payment_modes_id_seq'::regclass);


--
-- Name: incoming_payments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incoming_payments ALTER COLUMN id SET DEFAULT nextval('public.incoming_payments_id_seq'::regclass);


--
-- Name: inspection_calibrations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inspection_calibrations ALTER COLUMN id SET DEFAULT nextval('public.inspection_calibrations_id_seq'::regclass);


--
-- Name: inspection_points id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inspection_points ALTER COLUMN id SET DEFAULT nextval('public.inspection_points_id_seq'::regclass);


--
-- Name: inspections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inspections ALTER COLUMN id SET DEFAULT nextval('public.inspections_id_seq'::regclass);


--
-- Name: integrations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integrations ALTER COLUMN id SET DEFAULT nextval('public.integrations_id_seq'::regclass);


--
-- Name: intervention_costings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_costings ALTER COLUMN id SET DEFAULT nextval('public.intervention_costings_id_seq'::regclass);


--
-- Name: intervention_crop_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_crop_groups ALTER COLUMN id SET DEFAULT nextval('public.intervention_crop_groups_id_seq'::regclass);


--
-- Name: intervention_labellings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_labellings ALTER COLUMN id SET DEFAULT nextval('public.intervention_labellings_id_seq'::regclass);


--
-- Name: intervention_parameter_readings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_parameter_readings ALTER COLUMN id SET DEFAULT nextval('public.intervention_parameter_readings_id_seq'::regclass);


--
-- Name: intervention_parameter_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_parameter_settings ALTER COLUMN id SET DEFAULT nextval('public.intervention_parameter_settings_id_seq'::regclass);


--
-- Name: intervention_parameters id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_parameters ALTER COLUMN id SET DEFAULT nextval('public.intervention_parameters_id_seq'::regclass);


--
-- Name: intervention_participations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_participations ALTER COLUMN id SET DEFAULT nextval('public.intervention_participations_id_seq'::regclass);


--
-- Name: intervention_proposal_parameters id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_proposal_parameters ALTER COLUMN id SET DEFAULT nextval('public.intervention_proposal_parameters_id_seq'::regclass);


--
-- Name: intervention_proposals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_proposals ALTER COLUMN id SET DEFAULT nextval('public.intervention_proposals_id_seq'::regclass);


--
-- Name: intervention_setting_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_setting_items ALTER COLUMN id SET DEFAULT nextval('public.intervention_setting_items_id_seq'::regclass);


--
-- Name: intervention_template_activities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_template_activities ALTER COLUMN id SET DEFAULT nextval('public.intervention_template_activities_id_seq'::regclass);


--
-- Name: intervention_template_product_parameters id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_template_product_parameters ALTER COLUMN id SET DEFAULT nextval('public.intervention_template_product_parameters_id_seq'::regclass);


--
-- Name: intervention_templates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_templates ALTER COLUMN id SET DEFAULT nextval('public.intervention_templates_id_seq'::regclass);


--
-- Name: intervention_working_periods id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_working_periods ALTER COLUMN id SET DEFAULT nextval('public.intervention_working_periods_id_seq'::regclass);


--
-- Name: interventions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interventions ALTER COLUMN id SET DEFAULT nextval('public.interventions_id_seq'::regclass);


--
-- Name: inventories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventories ALTER COLUMN id SET DEFAULT nextval('public.inventories_id_seq'::regclass);


--
-- Name: inventory_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_items ALTER COLUMN id SET DEFAULT nextval('public.inventory_items_id_seq'::regclass);


--
-- Name: issues id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues ALTER COLUMN id SET DEFAULT nextval('public.issues_id_seq'::regclass);


--
-- Name: journal_entries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_entries ALTER COLUMN id SET DEFAULT nextval('public.journal_entries_id_seq'::regclass);


--
-- Name: journal_entry_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_entry_items ALTER COLUMN id SET DEFAULT nextval('public.journal_entry_items_id_seq'::regclass);


--
-- Name: journals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journals ALTER COLUMN id SET DEFAULT nextval('public.journals_id_seq'::regclass);


--
-- Name: labels id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labels ALTER COLUMN id SET DEFAULT nextval('public.labels_id_seq'::regclass);


--
-- Name: listing_node_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.listing_node_items ALTER COLUMN id SET DEFAULT nextval('public.listing_node_items_id_seq'::regclass);


--
-- Name: listing_nodes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.listing_nodes ALTER COLUMN id SET DEFAULT nextval('public.listing_nodes_id_seq'::regclass);


--
-- Name: listings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.listings ALTER COLUMN id SET DEFAULT nextval('public.listings_id_seq'::regclass);


--
-- Name: loan_repayments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_repayments ALTER COLUMN id SET DEFAULT nextval('public.loan_repayments_id_seq'::regclass);


--
-- Name: loans id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loans ALTER COLUMN id SET DEFAULT nextval('public.loans_id_seq'::regclass);


--
-- Name: locations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locations ALTER COLUMN id SET DEFAULT nextval('public.locations_id_seq'::regclass);


--
-- Name: manure_management_plan_zones id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manure_management_plan_zones ALTER COLUMN id SET DEFAULT nextval('public.manure_management_plan_zones_id_seq'::regclass);


--
-- Name: manure_management_plans id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manure_management_plans ALTER COLUMN id SET DEFAULT nextval('public.manure_management_plans_id_seq'::regclass);


--
-- Name: map_layers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.map_layers ALTER COLUMN id SET DEFAULT nextval('public.map_layers_id_seq'::regclass);


--
-- Name: naming_format_fields id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.naming_format_fields ALTER COLUMN id SET DEFAULT nextval('public.naming_format_fields_id_seq'::regclass);


--
-- Name: naming_formats id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.naming_formats ALTER COLUMN id SET DEFAULT nextval('public.naming_formats_id_seq'::regclass);


--
-- Name: net_services id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.net_services ALTER COLUMN id SET DEFAULT nextval('public.net_services_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: observations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.observations ALTER COLUMN id SET DEFAULT nextval('public.observations_id_seq'::regclass);


--
-- Name: outgoing_payment_lists id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outgoing_payment_lists ALTER COLUMN id SET DEFAULT nextval('public.outgoing_payment_lists_id_seq'::regclass);


--
-- Name: outgoing_payment_modes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outgoing_payment_modes ALTER COLUMN id SET DEFAULT nextval('public.outgoing_payment_modes_id_seq'::regclass);


--
-- Name: outgoing_payments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outgoing_payments ALTER COLUMN id SET DEFAULT nextval('public.outgoing_payments_id_seq'::regclass);


--
-- Name: parcel_item_storings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_item_storings ALTER COLUMN id SET DEFAULT nextval('public.parcel_item_storings_id_seq'::regclass);


--
-- Name: parcel_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_items ALTER COLUMN id SET DEFAULT nextval('public.parcel_items_id_seq'::regclass);


--
-- Name: parcels id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcels ALTER COLUMN id SET DEFAULT nextval('public.parcels_id_seq'::regclass);


--
-- Name: payslip_natures id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payslip_natures ALTER COLUMN id SET DEFAULT nextval('public.payslip_natures_id_seq'::regclass);


--
-- Name: payslips id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payslips ALTER COLUMN id SET DEFAULT nextval('public.payslips_id_seq'::regclass);


--
-- Name: pfi_intervention_parameters id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pfi_intervention_parameters ALTER COLUMN id SET DEFAULT nextval('public.pfi_intervention_parameters_id_seq'::regclass);


--
-- Name: planning_scenario_activities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planning_scenario_activities ALTER COLUMN id SET DEFAULT nextval('public.planning_scenario_activities_id_seq'::regclass);


--
-- Name: planning_scenario_activity_plots id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planning_scenario_activity_plots ALTER COLUMN id SET DEFAULT nextval('public.planning_scenario_activity_plots_id_seq'::regclass);


--
-- Name: planning_scenarios id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planning_scenarios ALTER COLUMN id SET DEFAULT nextval('public.planning_scenarios_id_seq'::regclass);


--
-- Name: plant_counting_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plant_counting_items ALTER COLUMN id SET DEFAULT nextval('public.plant_counting_items_id_seq'::regclass);


--
-- Name: plant_countings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plant_countings ALTER COLUMN id SET DEFAULT nextval('public.plant_countings_id_seq'::regclass);


--
-- Name: plant_density_abaci id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plant_density_abaci ALTER COLUMN id SET DEFAULT nextval('public.plant_density_abaci_id_seq'::regclass);


--
-- Name: plant_density_abacus_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plant_density_abacus_items ALTER COLUMN id SET DEFAULT nextval('public.plant_density_abacus_items_id_seq'::regclass);


--
-- Name: postal_zones id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.postal_zones ALTER COLUMN id SET DEFAULT nextval('public.postal_zones_id_seq'::regclass);


--
-- Name: preferences id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preferences ALTER COLUMN id SET DEFAULT nextval('public.preferences_id_seq'::regclass);


--
-- Name: prescriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prescriptions ALTER COLUMN id SET DEFAULT nextval('public.prescriptions_id_seq'::regclass);


--
-- Name: product_enjoyments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_enjoyments ALTER COLUMN id SET DEFAULT nextval('public.product_enjoyments_id_seq'::regclass);


--
-- Name: product_labellings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_labellings ALTER COLUMN id SET DEFAULT nextval('public.product_labellings_id_seq'::regclass);


--
-- Name: product_linkages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_linkages ALTER COLUMN id SET DEFAULT nextval('public.product_linkages_id_seq'::regclass);


--
-- Name: product_links id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_links ALTER COLUMN id SET DEFAULT nextval('public.product_links_id_seq'::regclass);


--
-- Name: product_localizations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_localizations ALTER COLUMN id SET DEFAULT nextval('public.product_localizations_id_seq'::regclass);


--
-- Name: product_memberships id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_memberships ALTER COLUMN id SET DEFAULT nextval('public.product_memberships_id_seq'::regclass);


--
-- Name: product_movements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_movements ALTER COLUMN id SET DEFAULT nextval('public.product_movements_id_seq'::regclass);


--
-- Name: product_nature_categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_nature_categories ALTER COLUMN id SET DEFAULT nextval('public.product_nature_categories_id_seq'::regclass);


--
-- Name: product_nature_category_taxations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_nature_category_taxations ALTER COLUMN id SET DEFAULT nextval('public.product_nature_category_taxations_id_seq'::regclass);


--
-- Name: product_nature_variant_components id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_nature_variant_components ALTER COLUMN id SET DEFAULT nextval('public.product_nature_variant_components_id_seq'::regclass);


--
-- Name: product_nature_variant_readings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_nature_variant_readings ALTER COLUMN id SET DEFAULT nextval('public.product_nature_variant_readings_id_seq'::regclass);


--
-- Name: product_nature_variants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_nature_variants ALTER COLUMN id SET DEFAULT nextval('public.product_nature_variants_id_seq'::regclass);


--
-- Name: product_natures id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_natures ALTER COLUMN id SET DEFAULT nextval('public.product_natures_id_seq'::regclass);


--
-- Name: product_ownerships id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ownerships ALTER COLUMN id SET DEFAULT nextval('public.product_ownerships_id_seq'::regclass);


--
-- Name: product_phases id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_phases ALTER COLUMN id SET DEFAULT nextval('public.product_phases_id_seq'::regclass);


--
-- Name: product_readings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_readings ALTER COLUMN id SET DEFAULT nextval('public.product_readings_id_seq'::regclass);


--
-- Name: products id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products ALTER COLUMN id SET DEFAULT nextval('public.products_id_seq'::regclass);


--
-- Name: project_budgets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_budgets ALTER COLUMN id SET DEFAULT nextval('public.project_budgets_id_seq'::regclass);


--
-- Name: purchase_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_items ALTER COLUMN id SET DEFAULT nextval('public.purchase_items_id_seq'::regclass);


--
-- Name: purchase_natures id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_natures ALTER COLUMN id SET DEFAULT nextval('public.purchase_natures_id_seq'::regclass);


--
-- Name: purchases id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchases ALTER COLUMN id SET DEFAULT nextval('public.purchases_id_seq'::regclass);


--
-- Name: regularizations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regularizations ALTER COLUMN id SET DEFAULT nextval('public.regularizations_id_seq'::regclass);


--
-- Name: ride_sets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ride_sets ALTER COLUMN id SET DEFAULT nextval('public.ride_sets_id_seq'::regclass);


--
-- Name: rides id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rides ALTER COLUMN id SET DEFAULT nextval('public.rides_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: sale_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_items ALTER COLUMN id SET DEFAULT nextval('public.sale_items_id_seq'::regclass);


--
-- Name: sale_natures id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_natures ALTER COLUMN id SET DEFAULT nextval('public.sale_natures_id_seq'::regclass);


--
-- Name: sales id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales ALTER COLUMN id SET DEFAULT nextval('public.sales_id_seq'::regclass);


--
-- Name: sensors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensors ALTER COLUMN id SET DEFAULT nextval('public.sensors_id_seq'::regclass);


--
-- Name: sequences id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sequences ALTER COLUMN id SET DEFAULT nextval('public.sequences_id_seq'::regclass);


--
-- Name: subscription_natures id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscription_natures ALTER COLUMN id SET DEFAULT nextval('public.subscription_natures_id_seq'::regclass);


--
-- Name: subscriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions ALTER COLUMN id SET DEFAULT nextval('public.subscriptions_id_seq'::regclass);


--
-- Name: supervision_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supervision_items ALTER COLUMN id SET DEFAULT nextval('public.supervision_items_id_seq'::regclass);


--
-- Name: supervisions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supervisions ALTER COLUMN id SET DEFAULT nextval('public.supervisions_id_seq'::regclass);


--
-- Name: synchronization_operations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.synchronization_operations ALTER COLUMN id SET DEFAULT nextval('public.synchronization_operations_id_seq'::regclass);


--
-- Name: target_distributions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.target_distributions ALTER COLUMN id SET DEFAULT nextval('public.target_distributions_id_seq'::regclass);


--
-- Name: tasks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks ALTER COLUMN id SET DEFAULT nextval('public.tasks_id_seq'::regclass);


--
-- Name: tax_declaration_item_parts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tax_declaration_item_parts ALTER COLUMN id SET DEFAULT nextval('public.tax_declaration_item_parts_id_seq'::regclass);


--
-- Name: tax_declaration_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tax_declaration_items ALTER COLUMN id SET DEFAULT nextval('public.tax_declaration_items_id_seq'::regclass);


--
-- Name: tax_declarations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tax_declarations ALTER COLUMN id SET DEFAULT nextval('public.tax_declarations_id_seq'::regclass);


--
-- Name: taxes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taxes ALTER COLUMN id SET DEFAULT nextval('public.taxes_id_seq'::regclass);


--
-- Name: teams id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams ALTER COLUMN id SET DEFAULT nextval('public.teams_id_seq'::regclass);


--
-- Name: technical_itineraries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.technical_itineraries ALTER COLUMN id SET DEFAULT nextval('public.technical_itineraries_id_seq'::regclass);


--
-- Name: technical_itinerary_intervention_templates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.technical_itinerary_intervention_templates ALTER COLUMN id SET DEFAULT nextval('public.technical_itinerary_intervention_templates_id_seq'::regclass);


--
-- Name: tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tokens ALTER COLUMN id SET DEFAULT nextval('public.tokens_id_seq'::regclass);


--
-- Name: trackings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trackings ALTER COLUMN id SET DEFAULT nextval('public.trackings_id_seq'::regclass);


--
-- Name: units id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.units ALTER COLUMN id SET DEFAULT nextval('public.units_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions ALTER COLUMN id SET DEFAULT nextval('public.versions_id_seq'::regclass);


--
-- Name: wice_grid_serialized_queries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wice_grid_serialized_queries ALTER COLUMN id SET DEFAULT nextval('public.wice_grid_serialized_queries_id_seq'::regclass);


--
-- Name: wine_incoming_harvest_inputs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wine_incoming_harvest_inputs ALTER COLUMN id SET DEFAULT nextval('public.wine_incoming_harvest_inputs_id_seq'::regclass);


--
-- Name: wine_incoming_harvest_plants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wine_incoming_harvest_plants ALTER COLUMN id SET DEFAULT nextval('public.wine_incoming_harvest_plants_id_seq'::regclass);


--
-- Name: wine_incoming_harvest_presses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wine_incoming_harvest_presses ALTER COLUMN id SET DEFAULT nextval('public.wine_incoming_harvest_presses_id_seq'::regclass);


--
-- Name: wine_incoming_harvest_storages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wine_incoming_harvest_storages ALTER COLUMN id SET DEFAULT nextval('public.wine_incoming_harvest_storages_id_seq'::regclass);


--
-- Name: wine_incoming_harvests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wine_incoming_harvests ALTER COLUMN id SET DEFAULT nextval('public.wine_incoming_harvests_id_seq'::regclass);


--
-- Name: worker_contracts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_contracts ALTER COLUMN id SET DEFAULT nextval('public.worker_contracts_id_seq'::regclass);


--
-- Name: worker_group_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_group_items ALTER COLUMN id SET DEFAULT nextval('public.worker_group_items_id_seq'::regclass);


--
-- Name: worker_group_labellings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_group_labellings ALTER COLUMN id SET DEFAULT nextval('public.worker_group_labellings_id_seq'::regclass);


--
-- Name: worker_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_groups ALTER COLUMN id SET DEFAULT nextval('public.worker_groups_id_seq'::regclass);


--
-- Name: worker_time_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_time_logs ALTER COLUMN id SET DEFAULT nextval('public.worker_time_logs_id_seq'::regclass);


--
-- Name: activities activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_pkey PRIMARY KEY (id);


--
-- Name: activity_budget_items activity_budget_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_budget_items
    ADD CONSTRAINT activity_budget_items_pkey PRIMARY KEY (id);


--
-- Name: economic_indicators; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.economic_indicators AS
 SELECT a.id AS activity_id,
    c.id AS campaign_id,
    COALESCE(( SELECT sum(ap.size_value) AS sum
           FROM public.activity_productions ap
          WHERE ((ap.activity_id = a.id) AND (ap.id IN ( SELECT apc.activity_production_id
                   FROM public.activity_productions_campaigns apc
                  WHERE (apc.campaign_id = c.id))))), '1'::numeric) AS activity_size_value,
    COALESCE(a.size_unit_name, 'unity'::character varying) AS activity_size_unit,
    'main_direct_product'::text AS economic_indicator,
    abm.global_amount AS amount,
    abm.variant_id AS output_variant_id,
    abm.unit_id AS output_variant_unit_id
   FROM (((public.activity_budgets ab
     JOIN public.activities a ON ((ab.activity_id = a.id)))
     JOIN public.campaigns c ON ((ab.campaign_id = c.id)))
     JOIN public.activity_budget_items abm ON (((abm.activity_budget_id = ab.id) AND (abm.main_output IS TRUE))))
  WHERE (((abm.direction)::text = 'revenue'::text) AND ((a.nature)::text = 'main'::text))
  GROUP BY a.id, c.id, abm.id
UNION ALL
 SELECT a.id AS activity_id,
    c.id AS campaign_id,
    COALESCE(( SELECT sum(ap.size_value) AS sum
           FROM public.activity_productions ap
          WHERE ((ap.activity_id = a.id) AND (ap.id IN ( SELECT apc.activity_production_id
                   FROM public.activity_productions_campaigns apc
                  WHERE (apc.campaign_id = c.id))))), '1'::numeric) AS activity_size_value,
    COALESCE(a.size_unit_name, 'unity'::character varying) AS activity_size_unit,
    'other_direct_product'::text AS economic_indicator,
    sum(abi.global_amount) AS amount,
    NULL::integer AS output_variant_id,
    NULL::integer AS output_variant_unit_id
   FROM (((public.activity_budgets ab
     JOIN public.activities a ON ((ab.activity_id = a.id)))
     JOIN public.campaigns c ON ((ab.campaign_id = c.id)))
     LEFT JOIN public.activity_budget_items abi ON ((abi.activity_budget_id = ab.id)))
  WHERE (((abi.direction)::text = 'revenue'::text) AND (abi.main_output IS FALSE) AND ((a.nature)::text = 'main'::text))
  GROUP BY a.id, c.id
UNION ALL
 SELECT a.id AS activity_id,
    c.id AS campaign_id,
    COALESCE(( SELECT sum(ap.size_value) AS sum
           FROM public.activity_productions ap
          WHERE ((ap.activity_id = a.id) AND (ap.id IN ( SELECT apc.activity_production_id
                   FROM public.activity_productions_campaigns apc
                  WHERE (apc.campaign_id = c.id))))), '1'::numeric) AS activity_size_value,
    COALESCE(a.size_unit_name, 'unity'::character varying) AS activity_size_unit,
    'fixed_direct_charge'::text AS economic_indicator,
    sum(abi.global_amount) AS amount,
    NULL::integer AS output_variant_id,
    NULL::integer AS output_variant_unit_id
   FROM (((public.activity_budgets ab
     JOIN public.activities a ON ((ab.activity_id = a.id)))
     JOIN public.campaigns c ON ((ab.campaign_id = c.id)))
     LEFT JOIN public.activity_budget_items abi ON ((abi.activity_budget_id = ab.id)))
  WHERE (((abi.direction)::text = 'expense'::text) AND ((abi.nature)::text <> 'dynamic'::text) AND ((a.nature)::text = 'main'::text))
  GROUP BY a.id, c.id
UNION ALL
 SELECT a.id AS activity_id,
    c.id AS campaign_id,
    COALESCE(( SELECT sum(ap.size_value) AS sum
           FROM public.activity_productions ap
          WHERE ((ap.activity_id = a.id) AND (ap.id IN ( SELECT apc.activity_production_id
                   FROM public.activity_productions_campaigns apc
                  WHERE (apc.campaign_id = c.id))))), '1'::numeric) AS activity_size_value,
    COALESCE(a.size_unit_name, 'unity'::character varying) AS activity_size_unit,
    'proportional_direct_charge'::text AS economic_indicator,
    sum(abi.global_amount) AS amount,
    NULL::integer AS output_variant_id,
    NULL::integer AS output_variant_unit_id
   FROM (((public.activity_budgets ab
     JOIN public.activities a ON ((ab.activity_id = a.id)))
     JOIN public.campaigns c ON ((ab.campaign_id = c.id)))
     LEFT JOIN public.activity_budget_items abi ON ((abi.activity_budget_id = ab.id)))
  WHERE (((abi.direction)::text = 'expense'::text) AND ((abi.nature)::text = 'dynamic'::text) AND ((a.nature)::text = 'main'::text))
  GROUP BY a.id, c.id
UNION ALL
 SELECT a.id AS activity_id,
    c.id AS campaign_id,
    '1'::numeric AS activity_size_value,
    'unity'::character varying AS activity_size_unit,
    'global_indirect_product'::text AS economic_indicator,
    sum(abi.global_amount) AS amount,
    NULL::integer AS output_variant_id,
    NULL::integer AS output_variant_unit_id
   FROM (((public.activity_budgets ab
     JOIN public.activities a ON ((ab.activity_id = a.id)))
     JOIN public.campaigns c ON ((ab.campaign_id = c.id)))
     LEFT JOIN public.activity_budget_items abi ON ((abi.activity_budget_id = ab.id)))
  WHERE (((abi.direction)::text = 'revenue'::text) AND ((a.nature)::text = 'auxiliary'::text))
  GROUP BY a.id, c.id
UNION ALL
 SELECT a.id AS activity_id,
    c.id AS campaign_id,
    '1'::numeric AS activity_size_value,
    'unity'::character varying AS activity_size_unit,
    'global_indirect_charge'::text AS economic_indicator,
    sum(abi.global_amount) AS amount,
    NULL::integer AS output_variant_id,
    NULL::integer AS output_variant_unit_id
   FROM (((public.activity_budgets ab
     JOIN public.activities a ON ((ab.activity_id = a.id)))
     JOIN public.campaigns c ON ((ab.campaign_id = c.id)))
     LEFT JOIN public.activity_budget_items abi ON ((abi.activity_budget_id = ab.id)))
  WHERE (((abi.direction)::text = 'expense'::text) AND ((a.nature)::text = 'auxiliary'::text))
  GROUP BY a.id, c.id
  ORDER BY 1, 2
  WITH NO DATA;


--
-- Name: intervention_model_items intervention_model_items_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.intervention_model_items
    ADD CONSTRAINT intervention_model_items_pkey PRIMARY KEY (id);


--
-- Name: intervention_models intervention_models_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.intervention_models
    ADD CONSTRAINT intervention_models_pkey PRIMARY KEY (id);


--
-- Name: master_chart_of_accounts master_chart_of_accounts_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.master_chart_of_accounts
    ADD CONSTRAINT master_chart_of_accounts_pkey PRIMARY KEY (id);


--
-- Name: master_crop_production_cap_codes master_crop_production_cap_codes_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.master_crop_production_cap_codes
    ADD CONSTRAINT master_crop_production_cap_codes_pkey PRIMARY KEY (cap_code, production, year);


--
-- Name: master_crop_production_cap_sna_codes master_crop_production_cap_sna_codes_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.master_crop_production_cap_sna_codes
    ADD CONSTRAINT master_crop_production_cap_sna_codes_pkey PRIMARY KEY (reference_name);


--
-- Name: master_crop_productions master_crop_productions_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.master_crop_productions
    ADD CONSTRAINT master_crop_productions_pkey PRIMARY KEY (reference_name);


--
-- Name: master_dimensions master_dimensions_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.master_dimensions
    ADD CONSTRAINT master_dimensions_pkey PRIMARY KEY (reference_name);


--
-- Name: master_doer_contracts master_doer_contracts_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.master_doer_contracts
    ADD CONSTRAINT master_doer_contracts_pkey PRIMARY KEY (reference_name);


--
-- Name: master_legal_positions master_legal_positions_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.master_legal_positions
    ADD CONSTRAINT master_legal_positions_pkey PRIMARY KEY (code);


--
-- Name: master_packagings master_packagings_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.master_packagings
    ADD CONSTRAINT master_packagings_pkey PRIMARY KEY (reference_name);


--
-- Name: master_phenological_stages master_phenological_stages_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.master_phenological_stages
    ADD CONSTRAINT master_phenological_stages_pkey PRIMARY KEY (bbch_code);


--
-- Name: master_phytosanitary_prices master_phytosanitary_prices_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.master_phytosanitary_prices
    ADD CONSTRAINT master_phytosanitary_prices_pkey PRIMARY KEY (id);


--
-- Name: master_prices master_prices_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.master_prices
    ADD CONSTRAINT master_prices_pkey PRIMARY KEY (id);


--
-- Name: master_taxonomy master_taxonomy_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.master_taxonomy
    ADD CONSTRAINT master_taxonomy_pkey PRIMARY KEY (reference_name);


--
-- Name: master_translations master_translations_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.master_translations
    ADD CONSTRAINT master_translations_pkey PRIMARY KEY (id);


--
-- Name: master_units master_units_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.master_units
    ADD CONSTRAINT master_units_pkey PRIMARY KEY (reference_name);


--
-- Name: master_user_roles master_user_roles_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.master_user_roles
    ADD CONSTRAINT master_user_roles_pkey PRIMARY KEY (reference_name);


--
-- Name: master_variant_categories master_variant_categories_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.master_variant_categories
    ADD CONSTRAINT master_variant_categories_pkey PRIMARY KEY (reference_name);


--
-- Name: master_variant_natures master_variant_natures_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.master_variant_natures
    ADD CONSTRAINT master_variant_natures_pkey PRIMARY KEY (reference_name);


--
-- Name: master_variants master_variants_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.master_variants
    ADD CONSTRAINT master_variants_pkey PRIMARY KEY (reference_name);


--
-- Name: registered_agroedi_codes registered_agroedi_codes_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.registered_agroedi_codes
    ADD CONSTRAINT registered_agroedi_codes_pkey PRIMARY KEY (id);


--
-- Name: registered_cadastral_buildings registered_cadastral_buildings_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.registered_cadastral_buildings
    ADD CONSTRAINT registered_cadastral_buildings_pkey PRIMARY KEY (id);


--
-- Name: registered_cadastral_parcels registered_cadastral_parcels_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.registered_cadastral_parcels
    ADD CONSTRAINT registered_cadastral_parcels_pkey PRIMARY KEY (id);


--
-- Name: registered_cadastral_prices registered_cadastral_prices_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.registered_cadastral_prices
    ADD CONSTRAINT registered_cadastral_prices_pkey PRIMARY KEY (id);


--
-- Name: registered_enterprises registered_enterprises_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.registered_enterprises
    ADD CONSTRAINT registered_enterprises_pkey PRIMARY KEY (establishment_number);


--
-- Name: registered_eu_market_prices registered_eu_market_prices_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.registered_eu_market_prices
    ADD CONSTRAINT registered_eu_market_prices_pkey PRIMARY KEY (id);


--
-- Name: registered_hydrographic_items registered_hydrographic_items_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.registered_hydrographic_items
    ADD CONSTRAINT registered_hydrographic_items_pkey PRIMARY KEY (id);


--
-- Name: registered_phytosanitary_cropsets registered_phytosanitary_cropsets_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.registered_phytosanitary_cropsets
    ADD CONSTRAINT registered_phytosanitary_cropsets_pkey PRIMARY KEY (id);


--
-- Name: registered_phytosanitary_products registered_phytosanitary_products_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.registered_phytosanitary_products
    ADD CONSTRAINT registered_phytosanitary_products_pkey PRIMARY KEY (id);


--
-- Name: registered_phytosanitary_risks registered_phytosanitary_risks_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.registered_phytosanitary_risks
    ADD CONSTRAINT registered_phytosanitary_risks_pkey PRIMARY KEY (product_id, risk_code);


--
-- Name: registered_phytosanitary_symbols registered_phytosanitary_symbols_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.registered_phytosanitary_symbols
    ADD CONSTRAINT registered_phytosanitary_symbols_pkey PRIMARY KEY (id);


--
-- Name: registered_phytosanitary_target_name_to_pfi_targets registered_phytosanitary_target_name_to_pfi_targets_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.registered_phytosanitary_target_name_to_pfi_targets
    ADD CONSTRAINT registered_phytosanitary_target_name_to_pfi_targets_pkey PRIMARY KEY (ephy_name);


--
-- Name: registered_phytosanitary_usages registered_phytosanitary_usages_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.registered_phytosanitary_usages
    ADD CONSTRAINT registered_phytosanitary_usages_pkey PRIMARY KEY (id);


--
-- Name: registered_postal_codes registered_postal_codes_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.registered_postal_codes
    ADD CONSTRAINT registered_postal_codes_pkey PRIMARY KEY (id);


--
-- Name: registered_quality_and_origin_signs registered_quality_and_origin_signs_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.registered_quality_and_origin_signs
    ADD CONSTRAINT registered_quality_and_origin_signs_pkey PRIMARY KEY (id);


--
-- Name: registered_seed_varieties registered_seed_varieties_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.registered_seed_varieties
    ADD CONSTRAINT registered_seed_varieties_pkey PRIMARY KEY (id);


--
-- Name: registered_soil_available_water_capacities registered_soil_available_water_capacities_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.registered_soil_available_water_capacities
    ADD CONSTRAINT registered_soil_available_water_capacities_pkey PRIMARY KEY (id);


--
-- Name: registered_soil_depths registered_soil_depths_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.registered_soil_depths
    ADD CONSTRAINT registered_soil_depths_pkey PRIMARY KEY (id);


--
-- Name: registered_vine_varieties registered_vine_varieties_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.registered_vine_varieties
    ADD CONSTRAINT registered_vine_varieties_pkey PRIMARY KEY (id);


--
-- Name: technical_sequences technical_sequences_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.technical_sequences
    ADD CONSTRAINT technical_sequences_pkey PRIMARY KEY (id);


--
-- Name: technical_workflow_procedure_items technical_workflow_procedure_items_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.technical_workflow_procedure_items
    ADD CONSTRAINT technical_workflow_procedure_items_pkey PRIMARY KEY (id);


--
-- Name: technical_workflow_procedures technical_workflow_procedures_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.technical_workflow_procedures
    ADD CONSTRAINT technical_workflow_procedures_pkey PRIMARY KEY (id);


--
-- Name: technical_workflows technical_workflows_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.technical_workflows
    ADD CONSTRAINT technical_workflows_pkey PRIMARY KEY (id);


--
-- Name: account_balances account_balances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_balances
    ADD CONSTRAINT account_balances_pkey PRIMARY KEY (id);


--
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: activity_budgets activity_budgets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_budgets
    ADD CONSTRAINT activity_budgets_pkey PRIMARY KEY (id);


--
-- Name: activity_distributions activity_distributions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_distributions
    ADD CONSTRAINT activity_distributions_pkey PRIMARY KEY (id);


--
-- Name: activity_inspection_calibration_natures activity_inspection_calibration_natures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_inspection_calibration_natures
    ADD CONSTRAINT activity_inspection_calibration_natures_pkey PRIMARY KEY (id);


--
-- Name: activity_inspection_calibration_scales activity_inspection_calibration_scales_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_inspection_calibration_scales
    ADD CONSTRAINT activity_inspection_calibration_scales_pkey PRIMARY KEY (id);


--
-- Name: activity_inspection_point_natures activity_inspection_point_natures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_inspection_point_natures
    ADD CONSTRAINT activity_inspection_point_natures_pkey PRIMARY KEY (id);


--
-- Name: activity_production_batches activity_production_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_production_batches
    ADD CONSTRAINT activity_production_batches_pkey PRIMARY KEY (id);


--
-- Name: activity_production_irregular_batches activity_production_irregular_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_production_irregular_batches
    ADD CONSTRAINT activity_production_irregular_batches_pkey PRIMARY KEY (id);


--
-- Name: activity_productions activity_productions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_productions
    ADD CONSTRAINT activity_productions_pkey PRIMARY KEY (id);


--
-- Name: activity_seasons activity_seasons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_seasons
    ADD CONSTRAINT activity_seasons_pkey PRIMARY KEY (id);


--
-- Name: activity_tactics activity_tactics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_tactics
    ADD CONSTRAINT activity_tactics_pkey PRIMARY KEY (id);


--
-- Name: affairs affairs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.affairs
    ADD CONSTRAINT affairs_pkey PRIMARY KEY (id);


--
-- Name: alert_phases alert_phases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_phases
    ADD CONSTRAINT alert_phases_pkey PRIMARY KEY (id);


--
-- Name: alerts alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_pkey PRIMARY KEY (id);


--
-- Name: analyses analyses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.analyses
    ADD CONSTRAINT analyses_pkey PRIMARY KEY (id);


--
-- Name: analysis_items analysis_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.analysis_items
    ADD CONSTRAINT analysis_items_pkey PRIMARY KEY (id);


--
-- Name: analytic_segments analytic_segments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.analytic_segments
    ADD CONSTRAINT analytic_segments_pkey PRIMARY KEY (id);


--
-- Name: analytic_sequences analytic_sequences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.analytic_sequences
    ADD CONSTRAINT analytic_sequences_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: attachments attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attachments
    ADD CONSTRAINT attachments_pkey PRIMARY KEY (id);


--
-- Name: bank_statement_items bank_statement_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bank_statement_items
    ADD CONSTRAINT bank_statement_items_pkey PRIMARY KEY (id);


--
-- Name: bank_statements bank_statements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bank_statements
    ADD CONSTRAINT bank_statements_pkey PRIMARY KEY (id);


--
-- Name: call_messages call_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.call_messages
    ADD CONSTRAINT call_messages_pkey PRIMARY KEY (id);


--
-- Name: calls calls_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calls
    ADD CONSTRAINT calls_pkey PRIMARY KEY (id);


--
-- Name: campaigns campaigns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT campaigns_pkey PRIMARY KEY (id);


--
-- Name: cap_islets cap_islets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cap_islets
    ADD CONSTRAINT cap_islets_pkey PRIMARY KEY (id);


--
-- Name: cap_land_parcels cap_land_parcels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cap_land_parcels
    ADD CONSTRAINT cap_land_parcels_pkey PRIMARY KEY (id);


--
-- Name: cap_neutral_areas cap_neutral_areas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cap_neutral_areas
    ADD CONSTRAINT cap_neutral_areas_pkey PRIMARY KEY (id);


--
-- Name: cap_statements cap_statements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cap_statements
    ADD CONSTRAINT cap_statements_pkey PRIMARY KEY (id);


--
-- Name: cash_sessions cash_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cash_sessions
    ADD CONSTRAINT cash_sessions_pkey PRIMARY KEY (id);


--
-- Name: cash_transfers cash_transfers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cash_transfers
    ADD CONSTRAINT cash_transfers_pkey PRIMARY KEY (id);


--
-- Name: cashes cashes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cashes
    ADD CONSTRAINT cashes_pkey PRIMARY KEY (id);


--
-- Name: catalog_items catalog_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_items
    ADD CONSTRAINT catalog_items_pkey PRIMARY KEY (id);


--
-- Name: catalogs catalogs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalogs
    ADD CONSTRAINT catalogs_pkey PRIMARY KEY (id);


--
-- Name: contract_items contract_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contract_items
    ADD CONSTRAINT contract_items_pkey PRIMARY KEY (id);


--
-- Name: contracts contracts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contracts
    ADD CONSTRAINT contracts_pkey PRIMARY KEY (id);


--
-- Name: crop_group_items crop_group_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crop_group_items
    ADD CONSTRAINT crop_group_items_pkey PRIMARY KEY (id);


--
-- Name: crop_group_labellings crop_group_labellings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crop_group_labellings
    ADD CONSTRAINT crop_group_labellings_pkey PRIMARY KEY (id);


--
-- Name: crop_groups crop_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crop_groups
    ADD CONSTRAINT crop_groups_pkey PRIMARY KEY (id);


--
-- Name: crumbs crumbs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crumbs
    ADD CONSTRAINT crumbs_pkey PRIMARY KEY (id);


--
-- Name: cultivable_zones cultivable_zones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cultivable_zones
    ADD CONSTRAINT cultivable_zones_pkey PRIMARY KEY (id);


--
-- Name: custom_field_choices custom_field_choices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_field_choices
    ADD CONSTRAINT custom_field_choices_pkey PRIMARY KEY (id);


--
-- Name: custom_fields custom_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_fields
    ADD CONSTRAINT custom_fields_pkey PRIMARY KEY (id);


--
-- Name: cvi_cadastral_plant_cvi_land_parcels cvi_cadastral_plant_cvi_land_parcels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cvi_cadastral_plant_cvi_land_parcels
    ADD CONSTRAINT cvi_cadastral_plant_cvi_land_parcels_pkey PRIMARY KEY (id);


--
-- Name: cvi_cadastral_plants cvi_cadastral_plants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cvi_cadastral_plants
    ADD CONSTRAINT cvi_cadastral_plants_pkey PRIMARY KEY (id);


--
-- Name: cvi_cultivable_zones cvi_cultivable_zones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cvi_cultivable_zones
    ADD CONSTRAINT cvi_cultivable_zones_pkey PRIMARY KEY (id);


--
-- Name: cvi_land_parcels cvi_land_parcels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cvi_land_parcels
    ADD CONSTRAINT cvi_land_parcels_pkey PRIMARY KEY (id);


--
-- Name: cvi_statements cvi_statements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cvi_statements
    ADD CONSTRAINT cvi_statements_pkey PRIMARY KEY (id);


--
-- Name: daily_charges daily_charges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_charges
    ADD CONSTRAINT daily_charges_pkey PRIMARY KEY (id);


--
-- Name: dashboards dashboards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dashboards
    ADD CONSTRAINT dashboards_pkey PRIMARY KEY (id);


--
-- Name: debt_transfers debt_transfers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.debt_transfers
    ADD CONSTRAINT debt_transfers_pkey PRIMARY KEY (id);


--
-- Name: deliveries deliveries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deliveries
    ADD CONSTRAINT deliveries_pkey PRIMARY KEY (id);


--
-- Name: delivery_tools delivery_tools_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delivery_tools
    ADD CONSTRAINT delivery_tools_pkey PRIMARY KEY (id);


--
-- Name: deposits deposits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deposits
    ADD CONSTRAINT deposits_pkey PRIMARY KEY (id);


--
-- Name: districts districts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.districts
    ADD CONSTRAINT districts_pkey PRIMARY KEY (id);


--
-- Name: document_templates document_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_templates
    ADD CONSTRAINT document_templates_pkey PRIMARY KEY (id);


--
-- Name: documents documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT documents_pkey PRIMARY KEY (id);


--
-- Name: economic_cash_indicators economic_cash_indicators_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.economic_cash_indicators
    ADD CONSTRAINT economic_cash_indicators_pkey PRIMARY KEY (id);


--
-- Name: entities entities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entities
    ADD CONSTRAINT entities_pkey PRIMARY KEY (id);


--
-- Name: entity_addresses entity_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entity_addresses
    ADD CONSTRAINT entity_addresses_pkey PRIMARY KEY (id);


--
-- Name: entity_links entity_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entity_links
    ADD CONSTRAINT entity_links_pkey PRIMARY KEY (id);


--
-- Name: event_participations event_participations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_participations
    ADD CONSTRAINT event_participations_pkey PRIMARY KEY (id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: financial_year_archives financial_year_archives_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.financial_year_archives
    ADD CONSTRAINT financial_year_archives_pkey PRIMARY KEY (id);


--
-- Name: financial_year_exchanges financial_year_exchanges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.financial_year_exchanges
    ADD CONSTRAINT financial_year_exchanges_pkey PRIMARY KEY (id);


--
-- Name: financial_years financial_years_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.financial_years
    ADD CONSTRAINT financial_years_pkey PRIMARY KEY (id);


--
-- Name: fixed_asset_depreciations fixed_asset_depreciations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fixed_asset_depreciations
    ADD CONSTRAINT fixed_asset_depreciations_pkey PRIMARY KEY (id);


--
-- Name: fixed_assets fixed_assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fixed_assets
    ADD CONSTRAINT fixed_assets_pkey PRIMARY KEY (id);


--
-- Name: gap_items gap_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gap_items
    ADD CONSTRAINT gap_items_pkey PRIMARY KEY (id);


--
-- Name: gaps gaps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gaps
    ADD CONSTRAINT gaps_pkey PRIMARY KEY (id);


--
-- Name: georeadings georeadings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.georeadings
    ADD CONSTRAINT georeadings_pkey PRIMARY KEY (id);


--
-- Name: guide_analyses guide_analyses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.guide_analyses
    ADD CONSTRAINT guide_analyses_pkey PRIMARY KEY (id);


--
-- Name: guide_analysis_points guide_analysis_points_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.guide_analysis_points
    ADD CONSTRAINT guide_analysis_points_pkey PRIMARY KEY (id);


--
-- Name: guides guides_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.guides
    ADD CONSTRAINT guides_pkey PRIMARY KEY (id);


--
-- Name: idea_diagnostic_item_values idea_diagnostic_item_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.idea_diagnostic_item_values
    ADD CONSTRAINT idea_diagnostic_item_values_pkey PRIMARY KEY (id);


--
-- Name: idea_diagnostic_items idea_diagnostic_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.idea_diagnostic_items
    ADD CONSTRAINT idea_diagnostic_items_pkey PRIMARY KEY (id);


--
-- Name: idea_diagnostic_results idea_diagnostic_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.idea_diagnostic_results
    ADD CONSTRAINT idea_diagnostic_results_pkey PRIMARY KEY (id);


--
-- Name: idea_diagnostics idea_diagnostics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.idea_diagnostics
    ADD CONSTRAINT idea_diagnostics_pkey PRIMARY KEY (id);


--
-- Name: identifiers identifiers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.identifiers
    ADD CONSTRAINT identifiers_pkey PRIMARY KEY (id);


--
-- Name: imports imports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.imports
    ADD CONSTRAINT imports_pkey PRIMARY KEY (id);


--
-- Name: incoming_payment_modes incoming_payment_modes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incoming_payment_modes
    ADD CONSTRAINT incoming_payment_modes_pkey PRIMARY KEY (id);


--
-- Name: incoming_payments incoming_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incoming_payments
    ADD CONSTRAINT incoming_payments_pkey PRIMARY KEY (id);


--
-- Name: inspection_calibrations inspection_calibrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inspection_calibrations
    ADD CONSTRAINT inspection_calibrations_pkey PRIMARY KEY (id);


--
-- Name: inspection_points inspection_points_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inspection_points
    ADD CONSTRAINT inspection_points_pkey PRIMARY KEY (id);


--
-- Name: inspections inspections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inspections
    ADD CONSTRAINT inspections_pkey PRIMARY KEY (id);


--
-- Name: integrations integrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integrations
    ADD CONSTRAINT integrations_pkey PRIMARY KEY (id);


--
-- Name: intervention_costings intervention_costings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_costings
    ADD CONSTRAINT intervention_costings_pkey PRIMARY KEY (id);


--
-- Name: intervention_crop_groups intervention_crop_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_crop_groups
    ADD CONSTRAINT intervention_crop_groups_pkey PRIMARY KEY (id);


--
-- Name: intervention_labellings intervention_labellings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_labellings
    ADD CONSTRAINT intervention_labellings_pkey PRIMARY KEY (id);


--
-- Name: intervention_parameter_readings intervention_parameter_readings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_parameter_readings
    ADD CONSTRAINT intervention_parameter_readings_pkey PRIMARY KEY (id);


--
-- Name: intervention_parameter_settings intervention_parameter_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_parameter_settings
    ADD CONSTRAINT intervention_parameter_settings_pkey PRIMARY KEY (id);


--
-- Name: intervention_parameters intervention_parameters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_parameters
    ADD CONSTRAINT intervention_parameters_pkey PRIMARY KEY (id);


--
-- Name: intervention_participations intervention_participations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_participations
    ADD CONSTRAINT intervention_participations_pkey PRIMARY KEY (id);


--
-- Name: intervention_proposal_parameters intervention_proposal_parameters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_proposal_parameters
    ADD CONSTRAINT intervention_proposal_parameters_pkey PRIMARY KEY (id);


--
-- Name: intervention_proposals intervention_proposals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_proposals
    ADD CONSTRAINT intervention_proposals_pkey PRIMARY KEY (id);


--
-- Name: intervention_setting_items intervention_setting_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_setting_items
    ADD CONSTRAINT intervention_setting_items_pkey PRIMARY KEY (id);


--
-- Name: intervention_template_activities intervention_template_activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_template_activities
    ADD CONSTRAINT intervention_template_activities_pkey PRIMARY KEY (id);


--
-- Name: intervention_template_product_parameters intervention_template_product_parameters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_template_product_parameters
    ADD CONSTRAINT intervention_template_product_parameters_pkey PRIMARY KEY (id);


--
-- Name: intervention_templates intervention_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_templates
    ADD CONSTRAINT intervention_templates_pkey PRIMARY KEY (id);


--
-- Name: intervention_working_periods intervention_working_periods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_working_periods
    ADD CONSTRAINT intervention_working_periods_pkey PRIMARY KEY (id);


--
-- Name: interventions interventions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interventions
    ADD CONSTRAINT interventions_pkey PRIMARY KEY (id);


--
-- Name: inventories inventories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventories
    ADD CONSTRAINT inventories_pkey PRIMARY KEY (id);


--
-- Name: inventory_items inventory_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT inventory_items_pkey PRIMARY KEY (id);


--
-- Name: issues issues_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT issues_pkey PRIMARY KEY (id);


--
-- Name: journal_entries journal_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_entries
    ADD CONSTRAINT journal_entries_pkey PRIMARY KEY (id);


--
-- Name: journal_entry_items journal_entry_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_entry_items
    ADD CONSTRAINT journal_entry_items_pkey PRIMARY KEY (id);


--
-- Name: journals journals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journals
    ADD CONSTRAINT journals_pkey PRIMARY KEY (id);


--
-- Name: labels labels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labels
    ADD CONSTRAINT labels_pkey PRIMARY KEY (id);


--
-- Name: listing_node_items listing_node_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.listing_node_items
    ADD CONSTRAINT listing_node_items_pkey PRIMARY KEY (id);


--
-- Name: listing_nodes listing_nodes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.listing_nodes
    ADD CONSTRAINT listing_nodes_pkey PRIMARY KEY (id);


--
-- Name: listings listings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.listings
    ADD CONSTRAINT listings_pkey PRIMARY KEY (id);


--
-- Name: loan_repayments loan_repayments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loan_repayments
    ADD CONSTRAINT loan_repayments_pkey PRIMARY KEY (id);


--
-- Name: loans loans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loans
    ADD CONSTRAINT loans_pkey PRIMARY KEY (id);


--
-- Name: locations locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (id);


--
-- Name: manure_management_plan_zones manure_management_plan_zones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manure_management_plan_zones
    ADD CONSTRAINT manure_management_plan_zones_pkey PRIMARY KEY (id);


--
-- Name: manure_management_plans manure_management_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manure_management_plans
    ADD CONSTRAINT manure_management_plans_pkey PRIMARY KEY (id);


--
-- Name: map_layers map_layers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.map_layers
    ADD CONSTRAINT map_layers_pkey PRIMARY KEY (id);


--
-- Name: naming_format_fields naming_format_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.naming_format_fields
    ADD CONSTRAINT naming_format_fields_pkey PRIMARY KEY (id);


--
-- Name: naming_formats naming_formats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.naming_formats
    ADD CONSTRAINT naming_formats_pkey PRIMARY KEY (id);


--
-- Name: net_services net_services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.net_services
    ADD CONSTRAINT net_services_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: observations observations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.observations
    ADD CONSTRAINT observations_pkey PRIMARY KEY (id);


--
-- Name: outgoing_payment_lists outgoing_payment_lists_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outgoing_payment_lists
    ADD CONSTRAINT outgoing_payment_lists_pkey PRIMARY KEY (id);


--
-- Name: outgoing_payment_modes outgoing_payment_modes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outgoing_payment_modes
    ADD CONSTRAINT outgoing_payment_modes_pkey PRIMARY KEY (id);


--
-- Name: outgoing_payments outgoing_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outgoing_payments
    ADD CONSTRAINT outgoing_payments_pkey PRIMARY KEY (id);


--
-- Name: parcel_item_storings parcel_item_storings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_item_storings
    ADD CONSTRAINT parcel_item_storings_pkey PRIMARY KEY (id);


--
-- Name: parcel_items parcel_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_items
    ADD CONSTRAINT parcel_items_pkey PRIMARY KEY (id);


--
-- Name: parcels parcels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcels
    ADD CONSTRAINT parcels_pkey PRIMARY KEY (id);


--
-- Name: payslip_natures payslip_natures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payslip_natures
    ADD CONSTRAINT payslip_natures_pkey PRIMARY KEY (id);


--
-- Name: payslips payslips_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payslips
    ADD CONSTRAINT payslips_pkey PRIMARY KEY (id);


--
-- Name: pfi_intervention_parameters pfi_intervention_parameters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pfi_intervention_parameters
    ADD CONSTRAINT pfi_intervention_parameters_pkey PRIMARY KEY (id);


--
-- Name: planning_scenario_activities planning_scenario_activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planning_scenario_activities
    ADD CONSTRAINT planning_scenario_activities_pkey PRIMARY KEY (id);


--
-- Name: planning_scenario_activity_plots planning_scenario_activity_plots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planning_scenario_activity_plots
    ADD CONSTRAINT planning_scenario_activity_plots_pkey PRIMARY KEY (id);


--
-- Name: planning_scenarios planning_scenarios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planning_scenarios
    ADD CONSTRAINT planning_scenarios_pkey PRIMARY KEY (id);


--
-- Name: plant_counting_items plant_counting_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plant_counting_items
    ADD CONSTRAINT plant_counting_items_pkey PRIMARY KEY (id);


--
-- Name: plant_countings plant_countings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plant_countings
    ADD CONSTRAINT plant_countings_pkey PRIMARY KEY (id);


--
-- Name: plant_density_abaci plant_density_abaci_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plant_density_abaci
    ADD CONSTRAINT plant_density_abaci_pkey PRIMARY KEY (id);


--
-- Name: plant_density_abacus_items plant_density_abacus_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plant_density_abacus_items
    ADD CONSTRAINT plant_density_abacus_items_pkey PRIMARY KEY (id);


--
-- Name: postal_zones postal_zones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.postal_zones
    ADD CONSTRAINT postal_zones_pkey PRIMARY KEY (id);


--
-- Name: preferences preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preferences
    ADD CONSTRAINT preferences_pkey PRIMARY KEY (id);


--
-- Name: prescriptions prescriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prescriptions
    ADD CONSTRAINT prescriptions_pkey PRIMARY KEY (id);


--
-- Name: product_enjoyments product_enjoyments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_enjoyments
    ADD CONSTRAINT product_enjoyments_pkey PRIMARY KEY (id);


--
-- Name: product_labellings product_labellings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_labellings
    ADD CONSTRAINT product_labellings_pkey PRIMARY KEY (id);


--
-- Name: product_linkages product_linkages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_linkages
    ADD CONSTRAINT product_linkages_pkey PRIMARY KEY (id);


--
-- Name: product_links product_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_links
    ADD CONSTRAINT product_links_pkey PRIMARY KEY (id);


--
-- Name: product_localizations product_localizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_localizations
    ADD CONSTRAINT product_localizations_pkey PRIMARY KEY (id);


--
-- Name: product_memberships product_memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_memberships
    ADD CONSTRAINT product_memberships_pkey PRIMARY KEY (id);


--
-- Name: product_movements product_movements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_movements
    ADD CONSTRAINT product_movements_pkey PRIMARY KEY (id);


--
-- Name: product_nature_categories product_nature_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_nature_categories
    ADD CONSTRAINT product_nature_categories_pkey PRIMARY KEY (id);


--
-- Name: product_nature_category_taxations product_nature_category_taxations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_nature_category_taxations
    ADD CONSTRAINT product_nature_category_taxations_pkey PRIMARY KEY (id);


--
-- Name: product_nature_variant_components product_nature_variant_components_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_nature_variant_components
    ADD CONSTRAINT product_nature_variant_components_pkey PRIMARY KEY (id);


--
-- Name: product_nature_variant_readings product_nature_variant_readings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_nature_variant_readings
    ADD CONSTRAINT product_nature_variant_readings_pkey PRIMARY KEY (id);


--
-- Name: product_nature_variants product_nature_variants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_nature_variants
    ADD CONSTRAINT product_nature_variants_pkey PRIMARY KEY (id);


--
-- Name: product_natures product_natures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_natures
    ADD CONSTRAINT product_natures_pkey PRIMARY KEY (id);


--
-- Name: product_ownerships product_ownerships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ownerships
    ADD CONSTRAINT product_ownerships_pkey PRIMARY KEY (id);


--
-- Name: product_phases product_phases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_phases
    ADD CONSTRAINT product_phases_pkey PRIMARY KEY (id);


--
-- Name: product_readings product_readings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_readings
    ADD CONSTRAINT product_readings_pkey PRIMARY KEY (id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: project_budgets project_budgets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_budgets
    ADD CONSTRAINT project_budgets_pkey PRIMARY KEY (id);


--
-- Name: purchase_items purchase_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_items
    ADD CONSTRAINT purchase_items_pkey PRIMARY KEY (id);


--
-- Name: purchase_natures purchase_natures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_natures
    ADD CONSTRAINT purchase_natures_pkey PRIMARY KEY (id);


--
-- Name: purchases purchases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchases
    ADD CONSTRAINT purchases_pkey PRIMARY KEY (id);


--
-- Name: regularizations regularizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regularizations
    ADD CONSTRAINT regularizations_pkey PRIMARY KEY (id);


--
-- Name: ride_sets ride_sets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ride_sets
    ADD CONSTRAINT ride_sets_pkey PRIMARY KEY (id);


--
-- Name: rides rides_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rides
    ADD CONSTRAINT rides_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: sale_items sale_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_items
    ADD CONSTRAINT sale_items_pkey PRIMARY KEY (id);


--
-- Name: sale_natures sale_natures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_natures
    ADD CONSTRAINT sale_natures_pkey PRIMARY KEY (id);


--
-- Name: sales sales_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sensors sensors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensors
    ADD CONSTRAINT sensors_pkey PRIMARY KEY (id);


--
-- Name: sequences sequences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sequences
    ADD CONSTRAINT sequences_pkey PRIMARY KEY (id);


--
-- Name: subscription_natures subscription_natures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscription_natures
    ADD CONSTRAINT subscription_natures_pkey PRIMARY KEY (id);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: supervision_items supervision_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supervision_items
    ADD CONSTRAINT supervision_items_pkey PRIMARY KEY (id);


--
-- Name: supervisions supervisions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supervisions
    ADD CONSTRAINT supervisions_pkey PRIMARY KEY (id);


--
-- Name: synchronization_operations synchronization_operations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.synchronization_operations
    ADD CONSTRAINT synchronization_operations_pkey PRIMARY KEY (id);


--
-- Name: target_distributions target_distributions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.target_distributions
    ADD CONSTRAINT target_distributions_pkey PRIMARY KEY (id);


--
-- Name: tasks tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (id);


--
-- Name: tax_declaration_item_parts tax_declaration_item_parts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tax_declaration_item_parts
    ADD CONSTRAINT tax_declaration_item_parts_pkey PRIMARY KEY (id);


--
-- Name: tax_declaration_items tax_declaration_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tax_declaration_items
    ADD CONSTRAINT tax_declaration_items_pkey PRIMARY KEY (id);


--
-- Name: tax_declarations tax_declarations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tax_declarations
    ADD CONSTRAINT tax_declarations_pkey PRIMARY KEY (id);


--
-- Name: taxes taxes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taxes
    ADD CONSTRAINT taxes_pkey PRIMARY KEY (id);


--
-- Name: teams teams_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (id);


--
-- Name: technical_itineraries technical_itineraries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.technical_itineraries
    ADD CONSTRAINT technical_itineraries_pkey PRIMARY KEY (id);


--
-- Name: technical_itinerary_intervention_templates technical_itinerary_intervention_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.technical_itinerary_intervention_templates
    ADD CONSTRAINT technical_itinerary_intervention_templates_pkey PRIMARY KEY (id);


--
-- Name: tokens tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tokens
    ADD CONSTRAINT tokens_pkey PRIMARY KEY (id);


--
-- Name: trackings trackings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trackings
    ADD CONSTRAINT trackings_pkey PRIMARY KEY (id);


--
-- Name: units units_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.units
    ADD CONSTRAINT units_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: versions versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: wice_grid_serialized_queries wice_grid_serialized_queries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wice_grid_serialized_queries
    ADD CONSTRAINT wice_grid_serialized_queries_pkey PRIMARY KEY (id);


--
-- Name: wine_incoming_harvest_inputs wine_incoming_harvest_inputs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wine_incoming_harvest_inputs
    ADD CONSTRAINT wine_incoming_harvest_inputs_pkey PRIMARY KEY (id);


--
-- Name: wine_incoming_harvest_plants wine_incoming_harvest_plants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wine_incoming_harvest_plants
    ADD CONSTRAINT wine_incoming_harvest_plants_pkey PRIMARY KEY (id);


--
-- Name: wine_incoming_harvest_presses wine_incoming_harvest_presses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wine_incoming_harvest_presses
    ADD CONSTRAINT wine_incoming_harvest_presses_pkey PRIMARY KEY (id);


--
-- Name: wine_incoming_harvest_storages wine_incoming_harvest_storages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wine_incoming_harvest_storages
    ADD CONSTRAINT wine_incoming_harvest_storages_pkey PRIMARY KEY (id);


--
-- Name: wine_incoming_harvests wine_incoming_harvests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wine_incoming_harvests
    ADD CONSTRAINT wine_incoming_harvests_pkey PRIMARY KEY (id);


--
-- Name: worker_contracts worker_contracts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_contracts
    ADD CONSTRAINT worker_contracts_pkey PRIMARY KEY (id);


--
-- Name: worker_group_items worker_group_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_group_items
    ADD CONSTRAINT worker_group_items_pkey PRIMARY KEY (id);


--
-- Name: worker_group_labellings worker_group_labellings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_group_labellings
    ADD CONSTRAINT worker_group_labellings_pkey PRIMARY KEY (id);


--
-- Name: worker_groups worker_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_groups
    ADD CONSTRAINT worker_groups_pkey PRIMARY KEY (id);


--
-- Name: worker_time_logs worker_time_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_time_logs
    ADD CONSTRAINT worker_time_logs_pkey PRIMARY KEY (id);


--
-- Name: intervention_model_items_article_reference; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX intervention_model_items_article_reference ON lexicon.intervention_model_items USING btree (article_reference);


--
-- Name: intervention_model_items_intervention_model_id; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX intervention_model_items_intervention_model_id ON lexicon.intervention_model_items USING btree (intervention_model_id);


--
-- Name: intervention_model_items_procedure_item_reference; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX intervention_model_items_procedure_item_reference ON lexicon.intervention_model_items USING btree (procedure_item_reference);


--
-- Name: intervention_models_name; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX intervention_models_name ON lexicon.intervention_models USING btree (name);


--
-- Name: intervention_models_procedure_reference; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX intervention_models_procedure_reference ON lexicon.intervention_models USING btree (procedure_reference);


--
-- Name: master_budgets_variant; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_budgets_variant ON lexicon.master_budgets USING btree (variant);


--
-- Name: master_chart_of_accounts_reference_name; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_chart_of_accounts_reference_name ON lexicon.master_chart_of_accounts USING btree (reference_name);


--
-- Name: master_crop_production_prices_department_zone; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_crop_production_prices_department_zone ON lexicon.master_crop_production_prices USING btree (department_zone);


--
-- Name: master_crop_production_prices_product_output_specie; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_crop_production_prices_product_output_specie ON lexicon.master_crop_production_prices USING btree (product_output_specie);


--
-- Name: master_crop_production_prices_specie; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_crop_production_prices_specie ON lexicon.master_crop_production_prices USING btree (specie);


--
-- Name: master_crop_production_prices_started_on; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_crop_production_prices_started_on ON lexicon.master_crop_production_prices USING btree (started_on);


--
-- Name: master_crop_production_yields_campaign; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_crop_production_yields_campaign ON lexicon.master_crop_production_yields USING btree (campaign);


--
-- Name: master_crop_production_yields_production; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_crop_production_yields_production ON lexicon.master_crop_production_yields USING btree (production);


--
-- Name: master_crop_production_yields_specie; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_crop_production_yields_specie ON lexicon.master_crop_production_yields USING btree (specie);


--
-- Name: master_crop_productions_activity_family; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_crop_productions_activity_family ON lexicon.master_crop_productions USING btree (activity_family);


--
-- Name: master_crop_productions_agroedi_crop_code; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_crop_productions_agroedi_crop_code ON lexicon.master_crop_productions USING btree (agroedi_crop_code);


--
-- Name: master_crop_productions_specie; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_crop_productions_specie ON lexicon.master_crop_productions USING btree (specie);


--
-- Name: master_dimensions_reference_name; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_dimensions_reference_name ON lexicon.master_dimensions USING btree (reference_name);


--
-- Name: master_packagings_reference_name; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_packagings_reference_name ON lexicon.master_packagings USING btree (reference_name);


--
-- Name: master_prices_reference_article_name; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_prices_reference_article_name ON lexicon.master_prices USING btree (reference_article_name);


--
-- Name: master_prices_reference_name; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_prices_reference_name ON lexicon.master_prices USING btree (reference_name);


--
-- Name: master_prices_reference_packaging_name; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_prices_reference_packaging_name ON lexicon.master_prices USING btree (reference_packaging_name);


--
-- Name: master_taxonomy_reference_name; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_taxonomy_reference_name ON lexicon.master_taxonomy USING btree (reference_name);


--
-- Name: master_units_reference_name; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_units_reference_name ON lexicon.master_units USING btree (reference_name);


--
-- Name: master_variant_categories_reference_name; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_variant_categories_reference_name ON lexicon.master_variant_categories USING btree (reference_name);


--
-- Name: master_variant_natures_reference_name; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_variant_natures_reference_name ON lexicon.master_variant_natures USING btree (reference_name);


--
-- Name: master_variants_category; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_variants_category ON lexicon.master_variants USING btree (category);


--
-- Name: master_variants_nature; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_variants_nature ON lexicon.master_variants USING btree (nature);


--
-- Name: master_variants_reference_name; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_variants_reference_name ON lexicon.master_variants USING btree (reference_name);


--
-- Name: registered_agroedi_codes_reference_code; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_agroedi_codes_reference_code ON lexicon.registered_agroedi_codes USING btree (reference_code);


--
-- Name: registered_cadastral_buildings_centroid; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_cadastral_buildings_centroid ON lexicon.registered_cadastral_buildings USING gist (centroid);


--
-- Name: registered_cadastral_buildings_id; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_cadastral_buildings_id ON lexicon.registered_cadastral_buildings USING btree (id);


--
-- Name: registered_cadastral_buildings_shape; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_cadastral_buildings_shape ON lexicon.registered_cadastral_buildings USING gist (shape);


--
-- Name: registered_cadastral_parcels_centroid; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_cadastral_parcels_centroid ON lexicon.registered_cadastral_parcels USING gist (centroid);


--
-- Name: registered_cadastral_parcels_id; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_cadastral_parcels_id ON lexicon.registered_cadastral_parcels USING btree (id);


--
-- Name: registered_cadastral_parcels_section; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_cadastral_parcels_section ON lexicon.registered_cadastral_parcels USING btree (section);


--
-- Name: registered_cadastral_parcels_section_prefix; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_cadastral_parcels_section_prefix ON lexicon.registered_cadastral_parcels USING btree (section_prefix);


--
-- Name: registered_cadastral_parcels_shape; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_cadastral_parcels_shape ON lexicon.registered_cadastral_parcels USING gist (shape);


--
-- Name: registered_cadastral_parcels_town_insee_code; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_cadastral_parcels_town_insee_code ON lexicon.registered_cadastral_parcels USING btree (town_insee_code);


--
-- Name: registered_cadastral_parcels_work_number; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_cadastral_parcels_work_number ON lexicon.registered_cadastral_parcels USING btree (work_number);


--
-- Name: registered_cadastral_prices_cadastral_parcel_id; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_cadastral_prices_cadastral_parcel_id ON lexicon.registered_cadastral_prices USING btree (cadastral_parcel_id);


--
-- Name: registered_cadastral_prices_centroid; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_cadastral_prices_centroid ON lexicon.registered_cadastral_prices USING gist (centroid);


--
-- Name: registered_cadastral_prices_department; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_cadastral_prices_department ON lexicon.registered_cadastral_prices USING btree (department);


--
-- Name: registered_cadastral_prices_id; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_cadastral_prices_id ON lexicon.registered_cadastral_prices USING btree (id);


--
-- Name: registered_enterprises_french_main_activity_code; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_enterprises_french_main_activity_code ON lexicon.registered_enterprises USING btree (french_main_activity_code);


--
-- Name: registered_enterprises_name; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_enterprises_name ON lexicon.registered_enterprises USING btree (name);


--
-- Name: registered_eu_market_prices_category; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_eu_market_prices_category ON lexicon.registered_eu_market_prices USING btree (category);


--
-- Name: registered_eu_market_prices_id; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_eu_market_prices_id ON lexicon.registered_eu_market_prices USING btree (id);


--
-- Name: registered_eu_market_prices_product_code; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_eu_market_prices_product_code ON lexicon.registered_eu_market_prices USING btree (product_code);


--
-- Name: registered_eu_market_prices_sector_code; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_eu_market_prices_sector_code ON lexicon.registered_eu_market_prices USING btree (sector_code);


--
-- Name: registered_graphic_parcels_centroid; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_graphic_parcels_centroid ON lexicon.registered_graphic_parcels USING gist (centroid);


--
-- Name: registered_graphic_parcels_id_idx; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_graphic_parcels_id_idx ON lexicon.registered_graphic_parcels USING btree (id);


--
-- Name: registered_graphic_parcels_shape; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_graphic_parcels_shape ON lexicon.registered_graphic_parcels USING gist (shape);


--
-- Name: registered_hydrographic_items_lines; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_hydrographic_items_lines ON lexicon.registered_hydrographic_items USING gist (lines);


--
-- Name: registered_hydrographic_items_nature; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_hydrographic_items_nature ON lexicon.registered_hydrographic_items USING btree (nature);


--
-- Name: registered_hydrographic_items_point; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_hydrographic_items_point ON lexicon.registered_hydrographic_items USING gist (point);


--
-- Name: registered_hydrographic_items_shape; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_hydrographic_items_shape ON lexicon.registered_hydrographic_items USING gist (shape);


--
-- Name: registered_phytosanitary_cropsets_crop_names; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_phytosanitary_cropsets_crop_names ON lexicon.registered_phytosanitary_cropsets USING btree (crop_names);


--
-- Name: registered_phytosanitary_products_firm_name; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_phytosanitary_products_firm_name ON lexicon.registered_phytosanitary_products USING btree (firm_name);


--
-- Name: registered_phytosanitary_products_france_maaid; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_phytosanitary_products_france_maaid ON lexicon.registered_phytosanitary_products USING btree (france_maaid);


--
-- Name: registered_phytosanitary_products_name; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_phytosanitary_products_name ON lexicon.registered_phytosanitary_products USING btree (name);


--
-- Name: registered_phytosanitary_products_natures; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_phytosanitary_products_natures ON lexicon.registered_phytosanitary_products USING btree (natures);


--
-- Name: registered_phytosanitary_products_reference_name; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_phytosanitary_products_reference_name ON lexicon.registered_phytosanitary_products USING btree (reference_name);


--
-- Name: registered_phytosanitary_risks_product_id; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_phytosanitary_risks_product_id ON lexicon.registered_phytosanitary_risks USING btree (product_id);


--
-- Name: registered_phytosanitary_symbols_id; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_phytosanitary_symbols_id ON lexicon.registered_phytosanitary_symbols USING btree (id);


--
-- Name: registered_phytosanitary_symbols_symbol_name; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_phytosanitary_symbols_symbol_name ON lexicon.registered_phytosanitary_symbols USING btree (symbol_name);


--
-- Name: registered_phytosanitary_target_name_to_pfi_targets_ephy_name; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_phytosanitary_target_name_to_pfi_targets_ephy_name ON lexicon.registered_phytosanitary_target_name_to_pfi_targets USING btree (ephy_name);


--
-- Name: registered_phytosanitary_usages_product_id; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_phytosanitary_usages_product_id ON lexicon.registered_phytosanitary_usages USING btree (product_id);


--
-- Name: registered_phytosanitary_usages_species; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_phytosanitary_usages_species ON lexicon.registered_phytosanitary_usages USING btree (species);


--
-- Name: registered_postal_codes_centroid; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_postal_codes_centroid ON lexicon.registered_postal_codes USING gist (city_centroid);


--
-- Name: registered_postal_codes_city_name; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_postal_codes_city_name ON lexicon.registered_postal_codes USING btree (city_name);


--
-- Name: registered_postal_codes_country; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_postal_codes_country ON lexicon.registered_postal_codes USING btree (country);


--
-- Name: registered_postal_codes_postal_code; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_postal_codes_postal_code ON lexicon.registered_postal_codes USING btree (postal_code);


--
-- Name: registered_postal_codes_shape; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_postal_codes_shape ON lexicon.registered_postal_codes USING gist (city_shape);


--
-- Name: registered_protected_water_zones_id; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_protected_water_zones_id ON lexicon.registered_protected_water_zones USING btree (id);


--
-- Name: registered_protected_water_zones_shape; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_protected_water_zones_shape ON lexicon.registered_protected_water_zones USING gist (shape);


--
-- Name: registered_seed_varieties_id; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_seed_varieties_id ON lexicon.registered_seed_varieties USING btree (id);


--
-- Name: registered_seed_varieties_id_specie; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_seed_varieties_id_specie ON lexicon.registered_seed_varieties USING btree (id_specie);


--
-- Name: registered_soil_available_water_capacities_id; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_soil_available_water_capacities_id ON lexicon.registered_soil_available_water_capacities USING btree (id);


--
-- Name: registered_soil_available_water_capacities_shape; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_soil_available_water_capacities_shape ON lexicon.registered_soil_available_water_capacities USING gist (shape);


--
-- Name: registered_soil_depths_id; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_soil_depths_id ON lexicon.registered_soil_depths USING btree (id);


--
-- Name: registered_soil_depths_shape; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_soil_depths_shape ON lexicon.registered_soil_depths USING gist (shape);


--
-- Name: registered_vine_varieties_id; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_vine_varieties_id ON lexicon.registered_vine_varieties USING btree (id);


--
-- Name: technical_sequences_family; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX technical_sequences_family ON lexicon.technical_sequences USING btree (family);


--
-- Name: technical_sequences_id; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX technical_sequences_id ON lexicon.technical_sequences USING btree (id);


--
-- Name: technical_sequences_production_reference_name; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX technical_sequences_production_reference_name ON lexicon.technical_sequences USING btree (production_reference_name);


--
-- Name: technical_workflow_procedure_items_procedure_reference; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX technical_workflow_procedure_items_procedure_reference ON lexicon.technical_workflow_procedure_items USING btree (procedure_reference);


--
-- Name: technical_workflow_procedure_items_technical_workflow_pro_id; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX technical_workflow_procedure_items_technical_workflow_pro_id ON lexicon.technical_workflow_procedure_items USING btree (technical_workflow_procedure_id);


--
-- Name: technical_workflow_sequences_technical_sequence_id; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX technical_workflow_sequences_technical_sequence_id ON lexicon.technical_workflow_sequences USING btree (technical_sequence_id);


--
-- Name: technical_workflow_sequences_technical_workflow_id; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX technical_workflow_sequences_technical_workflow_id ON lexicon.technical_workflow_sequences USING btree (technical_workflow_id);


--
-- Name: technical_workflows_family; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX technical_workflows_family ON lexicon.technical_workflows USING btree (family);


--
-- Name: technical_workflows_id; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX technical_workflows_id ON lexicon.technical_workflows USING btree (id);


--
-- Name: technical_workflows_procedures_procedure_reference; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX technical_workflows_procedures_procedure_reference ON lexicon.technical_workflow_procedures USING btree (procedure_reference);


--
-- Name: technical_workflows_procedures_technical_workflow_id; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX technical_workflows_procedures_technical_workflow_id ON lexicon.technical_workflow_procedures USING btree (technical_workflow_id);


--
-- Name: technical_workflows_production_reference_name; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX technical_workflows_production_reference_name ON lexicon.technical_workflows USING btree (production_reference_name);


--
-- Name: account_provider_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX account_provider_index ON public.accounts USING gin (((provider -> 'vendor'::text)), ((provider -> 'name'::text)), ((provider -> 'id'::text)));


--
-- Name: activity_production_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX activity_production_batch_id ON public.activity_production_batches USING btree (activity_production_id);


--
-- Name: activity_production_irregular_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX activity_production_irregular_batch_id ON public.activity_production_irregular_batches USING btree (activity_production_batch_id);


--
-- Name: cash_provider_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cash_provider_index ON public.cashes USING gin (((provider -> 'vendor'::text)), ((provider -> 'name'::text)), ((provider -> 'id'::text)));


--
-- Name: catalog_provider_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX catalog_provider_index ON public.catalogs USING gin (((provider -> 'vendor'::text)), ((provider -> 'name'::text)), ((provider -> 'id'::text)));


--
-- Name: cultivable_zone_provider_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cultivable_zone_provider_index ON public.cultivable_zones USING gin (((provider -> 'vendor'::text)), ((provider -> 'name'::text)), ((provider -> 'id'::text)));


--
-- Name: entity_provider_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX entity_provider_index ON public.entities USING gin (((provider -> 'vendor'::text)), ((provider -> 'name'::text)), ((provider -> 'id'::text)));


--
-- Name: fixed_asset_provider_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fixed_asset_provider_index ON public.fixed_assets USING gin (((provider -> 'vendor'::text)), ((provider -> 'name'::text)), ((provider -> 'id'::text)));


--
-- Name: idx_wine_incoming_harvest_inputs_incoming_harvests; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_wine_incoming_harvest_inputs_incoming_harvests ON public.wine_incoming_harvest_inputs USING btree (wine_incoming_harvest_id);


--
-- Name: idx_wine_incoming_harvest_plants_incoming_harvests; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_wine_incoming_harvest_plants_incoming_harvests ON public.wine_incoming_harvest_plants USING btree (wine_incoming_harvest_id);


--
-- Name: idx_wine_incoming_harvest_storages_incoming_harvests; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_wine_incoming_harvest_storages_incoming_harvests ON public.wine_incoming_harvest_storages USING btree (wine_incoming_harvest_id);


--
-- Name: incoming_payment_mode_provider_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX incoming_payment_mode_provider_index ON public.incoming_payment_modes USING gin (((provider -> 'vendor'::text)), ((provider -> 'name'::text)), ((provider -> 'id'::text)));


--
-- Name: incoming_payment_provider_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX incoming_payment_provider_index ON public.incoming_payments USING gin (((provider -> 'vendor'::text)), ((provider -> 'name'::text)), ((provider -> 'id'::text)));


--
-- Name: index_account_balances_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_balances_on_account_id ON public.account_balances USING btree (account_id);


--
-- Name: index_account_balances_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_balances_on_created_at ON public.account_balances USING btree (created_at);


--
-- Name: index_account_balances_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_balances_on_creator_id ON public.account_balances USING btree (creator_id);


--
-- Name: index_account_balances_on_financial_year_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_balances_on_financial_year_id ON public.account_balances USING btree (financial_year_id);


--
-- Name: index_account_balances_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_balances_on_updated_at ON public.account_balances USING btree (updated_at);


--
-- Name: index_account_balances_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_balances_on_updater_id ON public.account_balances USING btree (updater_id);


--
-- Name: index_accounts_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_created_at ON public.accounts USING btree (created_at);


--
-- Name: index_accounts_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_creator_id ON public.accounts USING btree (creator_id);


--
-- Name: index_accounts_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_updated_at ON public.accounts USING btree (updated_at);


--
-- Name: index_accounts_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_updater_id ON public.accounts USING btree (updater_id);


--
-- Name: index_activities_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_created_at ON public.activities USING btree (created_at);


--
-- Name: index_activities_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_creator_id ON public.activities USING btree (creator_id);


--
-- Name: index_activities_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_name ON public.activities USING btree (name);


--
-- Name: index_activities_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_updated_at ON public.activities USING btree (updated_at);


--
-- Name: index_activities_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_updater_id ON public.activities USING btree (updater_id);


--
-- Name: index_activity_budget_items_on_activity_budget_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_budget_items_on_activity_budget_id ON public.activity_budget_items USING btree (activity_budget_id);


--
-- Name: index_activity_budget_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_budget_items_on_created_at ON public.activity_budget_items USING btree (created_at);


--
-- Name: index_activity_budget_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_budget_items_on_creator_id ON public.activity_budget_items USING btree (creator_id);


--
-- Name: index_activity_budget_items_on_transfered_activity_budget_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_budget_items_on_transfered_activity_budget_id ON public.activity_budget_items USING btree (transfered_activity_budget_id);


--
-- Name: index_activity_budget_items_on_unit_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_budget_items_on_unit_id ON public.activity_budget_items USING btree (unit_id);


--
-- Name: index_activity_budget_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_budget_items_on_updated_at ON public.activity_budget_items USING btree (updated_at);


--
-- Name: index_activity_budget_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_budget_items_on_updater_id ON public.activity_budget_items USING btree (updater_id);


--
-- Name: index_activity_budget_items_on_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_budget_items_on_variant_id ON public.activity_budget_items USING btree (variant_id);


--
-- Name: index_activity_budgets_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_budgets_on_activity_id ON public.activity_budgets USING btree (activity_id);


--
-- Name: index_activity_budgets_on_activity_id_and_campaign_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_activity_budgets_on_activity_id_and_campaign_id ON public.activity_budgets USING btree (activity_id, campaign_id);


--
-- Name: index_activity_budgets_on_campaign_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_budgets_on_campaign_id ON public.activity_budgets USING btree (campaign_id);


--
-- Name: index_activity_budgets_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_budgets_on_created_at ON public.activity_budgets USING btree (created_at);


--
-- Name: index_activity_budgets_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_budgets_on_creator_id ON public.activity_budgets USING btree (creator_id);


--
-- Name: index_activity_budgets_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_budgets_on_updated_at ON public.activity_budgets USING btree (updated_at);


--
-- Name: index_activity_budgets_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_budgets_on_updater_id ON public.activity_budgets USING btree (updater_id);


--
-- Name: index_activity_distributions_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_distributions_on_activity_id ON public.activity_distributions USING btree (activity_id);


--
-- Name: index_activity_distributions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_distributions_on_created_at ON public.activity_distributions USING btree (created_at);


--
-- Name: index_activity_distributions_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_distributions_on_creator_id ON public.activity_distributions USING btree (creator_id);


--
-- Name: index_activity_distributions_on_main_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_distributions_on_main_activity_id ON public.activity_distributions USING btree (main_activity_id);


--
-- Name: index_activity_distributions_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_distributions_on_updated_at ON public.activity_distributions USING btree (updated_at);


--
-- Name: index_activity_distributions_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_distributions_on_updater_id ON public.activity_distributions USING btree (updater_id);


--
-- Name: index_activity_inspection_calibration_natures_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_inspection_calibration_natures_on_created_at ON public.activity_inspection_calibration_natures USING btree (created_at);


--
-- Name: index_activity_inspection_calibration_natures_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_inspection_calibration_natures_on_creator_id ON public.activity_inspection_calibration_natures USING btree (creator_id);


--
-- Name: index_activity_inspection_calibration_natures_on_scale_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_inspection_calibration_natures_on_scale_id ON public.activity_inspection_calibration_natures USING btree (scale_id);


--
-- Name: index_activity_inspection_calibration_natures_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_inspection_calibration_natures_on_updated_at ON public.activity_inspection_calibration_natures USING btree (updated_at);


--
-- Name: index_activity_inspection_calibration_natures_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_inspection_calibration_natures_on_updater_id ON public.activity_inspection_calibration_natures USING btree (updater_id);


--
-- Name: index_activity_inspection_calibration_scales_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_inspection_calibration_scales_on_activity_id ON public.activity_inspection_calibration_scales USING btree (activity_id);


--
-- Name: index_activity_inspection_calibration_scales_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_inspection_calibration_scales_on_created_at ON public.activity_inspection_calibration_scales USING btree (created_at);


--
-- Name: index_activity_inspection_calibration_scales_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_inspection_calibration_scales_on_creator_id ON public.activity_inspection_calibration_scales USING btree (creator_id);


--
-- Name: index_activity_inspection_calibration_scales_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_inspection_calibration_scales_on_updated_at ON public.activity_inspection_calibration_scales USING btree (updated_at);


--
-- Name: index_activity_inspection_calibration_scales_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_inspection_calibration_scales_on_updater_id ON public.activity_inspection_calibration_scales USING btree (updater_id);


--
-- Name: index_activity_inspection_point_natures_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_inspection_point_natures_on_activity_id ON public.activity_inspection_point_natures USING btree (activity_id);


--
-- Name: index_activity_inspection_point_natures_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_inspection_point_natures_on_created_at ON public.activity_inspection_point_natures USING btree (created_at);


--
-- Name: index_activity_inspection_point_natures_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_inspection_point_natures_on_creator_id ON public.activity_inspection_point_natures USING btree (creator_id);


--
-- Name: index_activity_inspection_point_natures_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_inspection_point_natures_on_updated_at ON public.activity_inspection_point_natures USING btree (updated_at);


--
-- Name: index_activity_inspection_point_natures_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_inspection_point_natures_on_updater_id ON public.activity_inspection_point_natures USING btree (updater_id);


--
-- Name: index_activity_plots_on_scenario_activities_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_plots_on_scenario_activities_id ON public.planning_scenario_activity_plots USING btree (planning_scenario_activity_id);


--
-- Name: index_activity_plots_on_technical_itineraries_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_plots_on_technical_itineraries_id ON public.planning_scenario_activity_plots USING btree (technical_itinerary_id);


--
-- Name: index_activity_productions_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_productions_on_activity_id ON public.activity_productions USING btree (activity_id);


--
-- Name: index_activity_productions_on_campaign_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_productions_on_campaign_id ON public.activity_productions USING btree (campaign_id);


--
-- Name: index_activity_productions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_productions_on_created_at ON public.activity_productions USING btree (created_at);


--
-- Name: index_activity_productions_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_productions_on_creator_id ON public.activity_productions USING btree (creator_id);


--
-- Name: index_activity_productions_on_cultivable_zone_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_productions_on_cultivable_zone_id ON public.activity_productions USING btree (cultivable_zone_id);


--
-- Name: index_activity_productions_on_season_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_productions_on_season_id ON public.activity_productions USING btree (season_id);


--
-- Name: index_activity_productions_on_support_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_productions_on_support_id ON public.activity_productions USING btree (support_id);


--
-- Name: index_activity_productions_on_support_nature; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_productions_on_support_nature ON public.activity_productions USING btree (support_nature);


--
-- Name: index_activity_productions_on_tactic_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_productions_on_tactic_id ON public.activity_productions USING btree (tactic_id);


--
-- Name: index_activity_productions_on_technical_itinerary_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_productions_on_technical_itinerary_id ON public.activity_productions USING btree (technical_itinerary_id);


--
-- Name: index_activity_productions_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_productions_on_updated_at ON public.activity_productions USING btree (updated_at);


--
-- Name: index_activity_productions_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_productions_on_updater_id ON public.activity_productions USING btree (updater_id);


--
-- Name: index_activity_seasons_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_seasons_on_activity_id ON public.activity_seasons USING btree (activity_id);


--
-- Name: index_activity_seasons_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_seasons_on_created_at ON public.activity_seasons USING btree (created_at);


--
-- Name: index_activity_seasons_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_seasons_on_creator_id ON public.activity_seasons USING btree (creator_id);


--
-- Name: index_activity_seasons_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_seasons_on_updated_at ON public.activity_seasons USING btree (updated_at);


--
-- Name: index_activity_seasons_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_seasons_on_updater_id ON public.activity_seasons USING btree (updater_id);


--
-- Name: index_activity_tactics_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_tactics_on_activity_id ON public.activity_tactics USING btree (activity_id);


--
-- Name: index_activity_tactics_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_tactics_on_created_at ON public.activity_tactics USING btree (created_at);


--
-- Name: index_activity_tactics_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_tactics_on_creator_id ON public.activity_tactics USING btree (creator_id);


--
-- Name: index_activity_tactics_on_technical_itinerary_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_tactics_on_technical_itinerary_id ON public.activity_tactics USING btree (technical_itinerary_id);


--
-- Name: index_activity_tactics_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_tactics_on_updated_at ON public.activity_tactics USING btree (updated_at);


--
-- Name: index_activity_tactics_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_tactics_on_updater_id ON public.activity_tactics USING btree (updater_id);


--
-- Name: index_affairs_on_cash_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_affairs_on_cash_session_id ON public.affairs USING btree (cash_session_id);


--
-- Name: index_affairs_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_affairs_on_created_at ON public.affairs USING btree (created_at);


--
-- Name: index_affairs_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_affairs_on_creator_id ON public.affairs USING btree (creator_id);


--
-- Name: index_affairs_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_affairs_on_journal_entry_id ON public.affairs USING btree (journal_entry_id);


--
-- Name: index_affairs_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_affairs_on_name ON public.affairs USING btree (name);


--
-- Name: index_affairs_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_affairs_on_number ON public.affairs USING btree (number);


--
-- Name: index_affairs_on_responsible_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_affairs_on_responsible_id ON public.affairs USING btree (responsible_id);


--
-- Name: index_affairs_on_third_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_affairs_on_third_id ON public.affairs USING btree (third_id);


--
-- Name: index_affairs_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_affairs_on_updated_at ON public.affairs USING btree (updated_at);


--
-- Name: index_affairs_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_affairs_on_updater_id ON public.affairs USING btree (updater_id);


--
-- Name: index_alert_phases_on_alert_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alert_phases_on_alert_id ON public.alert_phases USING btree (alert_id);


--
-- Name: index_alert_phases_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alert_phases_on_created_at ON public.alert_phases USING btree (created_at);


--
-- Name: index_alert_phases_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alert_phases_on_creator_id ON public.alert_phases USING btree (creator_id);


--
-- Name: index_alert_phases_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alert_phases_on_updated_at ON public.alert_phases USING btree (updated_at);


--
-- Name: index_alert_phases_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alert_phases_on_updater_id ON public.alert_phases USING btree (updater_id);


--
-- Name: index_alerts_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alerts_on_created_at ON public.alerts USING btree (created_at);


--
-- Name: index_alerts_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alerts_on_creator_id ON public.alerts USING btree (creator_id);


--
-- Name: index_alerts_on_sensor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alerts_on_sensor_id ON public.alerts USING btree (sensor_id);


--
-- Name: index_alerts_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alerts_on_updated_at ON public.alerts USING btree (updated_at);


--
-- Name: index_alerts_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alerts_on_updater_id ON public.alerts USING btree (updater_id);


--
-- Name: index_analyses_on_analyser_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analyses_on_analyser_id ON public.analyses USING btree (analyser_id);


--
-- Name: index_analyses_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analyses_on_created_at ON public.analyses USING btree (created_at);


--
-- Name: index_analyses_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analyses_on_creator_id ON public.analyses USING btree (creator_id);


--
-- Name: index_analyses_on_host_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analyses_on_host_id ON public.analyses USING btree (host_id);


--
-- Name: index_analyses_on_nature; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analyses_on_nature ON public.analyses USING btree (nature);


--
-- Name: index_analyses_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analyses_on_number ON public.analyses USING btree (number);


--
-- Name: index_analyses_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analyses_on_product_id ON public.analyses USING btree (product_id);


--
-- Name: index_analyses_on_reference_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analyses_on_reference_number ON public.analyses USING btree (reference_number);


--
-- Name: index_analyses_on_sampler_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analyses_on_sampler_id ON public.analyses USING btree (sampler_id);


--
-- Name: index_analyses_on_sensor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analyses_on_sensor_id ON public.analyses USING btree (sensor_id);


--
-- Name: index_analyses_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analyses_on_updated_at ON public.analyses USING btree (updated_at);


--
-- Name: index_analyses_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analyses_on_updater_id ON public.analyses USING btree (updater_id);


--
-- Name: index_analysis_items_on_analysis_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analysis_items_on_analysis_id ON public.analysis_items USING btree (analysis_id);


--
-- Name: index_analysis_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analysis_items_on_created_at ON public.analysis_items USING btree (created_at);


--
-- Name: index_analysis_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analysis_items_on_creator_id ON public.analysis_items USING btree (creator_id);


--
-- Name: index_analysis_items_on_indicator_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analysis_items_on_indicator_name ON public.analysis_items USING btree (indicator_name);


--
-- Name: index_analysis_items_on_product_reading_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analysis_items_on_product_reading_id ON public.analysis_items USING btree (product_reading_id);


--
-- Name: index_analysis_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analysis_items_on_updated_at ON public.analysis_items USING btree (updated_at);


--
-- Name: index_analysis_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analysis_items_on_updater_id ON public.analysis_items USING btree (updater_id);


--
-- Name: index_analytic_segments_on_analytic_sequence_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analytic_segments_on_analytic_sequence_id ON public.analytic_segments USING btree (analytic_sequence_id);


--
-- Name: index_attachments_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_created_at ON public.attachments USING btree (created_at);


--
-- Name: index_attachments_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_creator_id ON public.attachments USING btree (creator_id);


--
-- Name: index_attachments_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_deleted_at ON public.attachments USING btree (deleted_at);


--
-- Name: index_attachments_on_document_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_document_id ON public.attachments USING btree (document_id);


--
-- Name: index_attachments_on_resource_type_and_resource_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_resource_type_and_resource_id ON public.attachments USING btree (resource_type, resource_id);


--
-- Name: index_attachments_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_updated_at ON public.attachments USING btree (updated_at);


--
-- Name: index_attachments_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_updater_id ON public.attachments USING btree (updater_id);


--
-- Name: index_bank_statement_items_on_bank_statement_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bank_statement_items_on_bank_statement_id ON public.bank_statement_items USING btree (bank_statement_id);


--
-- Name: index_bank_statement_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bank_statement_items_on_created_at ON public.bank_statement_items USING btree (created_at);


--
-- Name: index_bank_statement_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bank_statement_items_on_creator_id ON public.bank_statement_items USING btree (creator_id);


--
-- Name: index_bank_statement_items_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bank_statement_items_on_journal_entry_id ON public.bank_statement_items USING btree (journal_entry_id);


--
-- Name: index_bank_statement_items_on_letter; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bank_statement_items_on_letter ON public.bank_statement_items USING btree (letter);


--
-- Name: index_bank_statement_items_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bank_statement_items_on_name ON public.bank_statement_items USING btree (name);


--
-- Name: index_bank_statement_items_on_transaction_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bank_statement_items_on_transaction_number ON public.bank_statement_items USING btree (transaction_number);


--
-- Name: index_bank_statement_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bank_statement_items_on_updated_at ON public.bank_statement_items USING btree (updated_at);


--
-- Name: index_bank_statement_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bank_statement_items_on_updater_id ON public.bank_statement_items USING btree (updater_id);


--
-- Name: index_bank_statements_on_cash_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bank_statements_on_cash_id ON public.bank_statements USING btree (cash_id);


--
-- Name: index_bank_statements_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bank_statements_on_created_at ON public.bank_statements USING btree (created_at);


--
-- Name: index_bank_statements_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bank_statements_on_creator_id ON public.bank_statements USING btree (creator_id);


--
-- Name: index_bank_statements_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bank_statements_on_journal_entry_id ON public.bank_statements USING btree (journal_entry_id);


--
-- Name: index_bank_statements_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bank_statements_on_updated_at ON public.bank_statements USING btree (updated_at);


--
-- Name: index_bank_statements_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bank_statements_on_updater_id ON public.bank_statements USING btree (updater_id);


--
-- Name: index_call_messages_on_call_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_call_messages_on_call_id ON public.call_messages USING btree (call_id);


--
-- Name: index_call_messages_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_call_messages_on_created_at ON public.call_messages USING btree (created_at);


--
-- Name: index_call_messages_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_call_messages_on_creator_id ON public.call_messages USING btree (creator_id);


--
-- Name: index_call_messages_on_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_call_messages_on_request_id ON public.call_messages USING btree (request_id);


--
-- Name: index_call_messages_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_call_messages_on_updated_at ON public.call_messages USING btree (updated_at);


--
-- Name: index_call_messages_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_call_messages_on_updater_id ON public.call_messages USING btree (updater_id);


--
-- Name: index_calls_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_calls_on_created_at ON public.calls USING btree (created_at);


--
-- Name: index_calls_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_calls_on_creator_id ON public.calls USING btree (creator_id);


--
-- Name: index_calls_on_source_type_and_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_calls_on_source_type_and_source_id ON public.calls USING btree (source_type, source_id);


--
-- Name: index_calls_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_calls_on_updated_at ON public.calls USING btree (updated_at);


--
-- Name: index_calls_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_calls_on_updater_id ON public.calls USING btree (updater_id);


--
-- Name: index_campaigns_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_campaigns_on_created_at ON public.campaigns USING btree (created_at);


--
-- Name: index_campaigns_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_campaigns_on_creator_id ON public.campaigns USING btree (creator_id);


--
-- Name: index_campaigns_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_campaigns_on_updated_at ON public.campaigns USING btree (updated_at);


--
-- Name: index_campaigns_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_campaigns_on_updater_id ON public.campaigns USING btree (updater_id);


--
-- Name: index_cap_islets_on_cap_statement_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_islets_on_cap_statement_id ON public.cap_islets USING btree (cap_statement_id);


--
-- Name: index_cap_islets_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_islets_on_created_at ON public.cap_islets USING btree (created_at);


--
-- Name: index_cap_islets_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_islets_on_creator_id ON public.cap_islets USING btree (creator_id);


--
-- Name: index_cap_islets_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_islets_on_updated_at ON public.cap_islets USING btree (updated_at);


--
-- Name: index_cap_islets_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_islets_on_updater_id ON public.cap_islets USING btree (updater_id);


--
-- Name: index_cap_land_parcels_on_cap_islet_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_land_parcels_on_cap_islet_id ON public.cap_land_parcels USING btree (cap_islet_id);


--
-- Name: index_cap_land_parcels_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_land_parcels_on_created_at ON public.cap_land_parcels USING btree (created_at);


--
-- Name: index_cap_land_parcels_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_land_parcels_on_creator_id ON public.cap_land_parcels USING btree (creator_id);


--
-- Name: index_cap_land_parcels_on_support_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_land_parcels_on_support_id ON public.cap_land_parcels USING btree (support_id);


--
-- Name: index_cap_land_parcels_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_land_parcels_on_updated_at ON public.cap_land_parcels USING btree (updated_at);


--
-- Name: index_cap_land_parcels_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_land_parcels_on_updater_id ON public.cap_land_parcels USING btree (updater_id);


--
-- Name: index_cap_neutral_areas_on_cap_statement_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_neutral_areas_on_cap_statement_id ON public.cap_neutral_areas USING btree (cap_statement_id);


--
-- Name: index_cap_neutral_areas_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_neutral_areas_on_created_at ON public.cap_neutral_areas USING btree (created_at);


--
-- Name: index_cap_neutral_areas_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_neutral_areas_on_creator_id ON public.cap_neutral_areas USING btree (creator_id);


--
-- Name: index_cap_neutral_areas_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_neutral_areas_on_updated_at ON public.cap_neutral_areas USING btree (updated_at);


--
-- Name: index_cap_neutral_areas_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_neutral_areas_on_updater_id ON public.cap_neutral_areas USING btree (updater_id);


--
-- Name: index_cap_statements_on_campaign_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_statements_on_campaign_id ON public.cap_statements USING btree (campaign_id);


--
-- Name: index_cap_statements_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_statements_on_created_at ON public.cap_statements USING btree (created_at);


--
-- Name: index_cap_statements_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_statements_on_creator_id ON public.cap_statements USING btree (creator_id);


--
-- Name: index_cap_statements_on_declarant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_statements_on_declarant_id ON public.cap_statements USING btree (declarant_id);


--
-- Name: index_cap_statements_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_statements_on_updated_at ON public.cap_statements USING btree (updated_at);


--
-- Name: index_cap_statements_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_statements_on_updater_id ON public.cap_statements USING btree (updater_id);


--
-- Name: index_cash_sessions_on_cash_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cash_sessions_on_cash_id ON public.cash_sessions USING btree (cash_id);


--
-- Name: index_cash_sessions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cash_sessions_on_created_at ON public.cash_sessions USING btree (created_at);


--
-- Name: index_cash_sessions_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cash_sessions_on_creator_id ON public.cash_sessions USING btree (creator_id);


--
-- Name: index_cash_sessions_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cash_sessions_on_number ON public.cash_sessions USING btree (number);


--
-- Name: index_cash_sessions_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cash_sessions_on_updated_at ON public.cash_sessions USING btree (updated_at);


--
-- Name: index_cash_sessions_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cash_sessions_on_updater_id ON public.cash_sessions USING btree (updater_id);


--
-- Name: index_cash_transfers_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cash_transfers_on_created_at ON public.cash_transfers USING btree (created_at);


--
-- Name: index_cash_transfers_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cash_transfers_on_creator_id ON public.cash_transfers USING btree (creator_id);


--
-- Name: index_cash_transfers_on_emission_cash_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cash_transfers_on_emission_cash_id ON public.cash_transfers USING btree (emission_cash_id);


--
-- Name: index_cash_transfers_on_emission_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cash_transfers_on_emission_journal_entry_id ON public.cash_transfers USING btree (emission_journal_entry_id);


--
-- Name: index_cash_transfers_on_reception_cash_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cash_transfers_on_reception_cash_id ON public.cash_transfers USING btree (reception_cash_id);


--
-- Name: index_cash_transfers_on_reception_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cash_transfers_on_reception_journal_entry_id ON public.cash_transfers USING btree (reception_journal_entry_id);


--
-- Name: index_cash_transfers_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cash_transfers_on_updated_at ON public.cash_transfers USING btree (updated_at);


--
-- Name: index_cash_transfers_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cash_transfers_on_updater_id ON public.cash_transfers USING btree (updater_id);


--
-- Name: index_cashes_on_container_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cashes_on_container_id ON public.cashes USING btree (container_id);


--
-- Name: index_cashes_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cashes_on_created_at ON public.cashes USING btree (created_at);


--
-- Name: index_cashes_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cashes_on_creator_id ON public.cashes USING btree (creator_id);


--
-- Name: index_cashes_on_journal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cashes_on_journal_id ON public.cashes USING btree (journal_id);


--
-- Name: index_cashes_on_main_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cashes_on_main_account_id ON public.cashes USING btree (main_account_id);


--
-- Name: index_cashes_on_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cashes_on_owner_id ON public.cashes USING btree (owner_id);


--
-- Name: index_cashes_on_suspense_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cashes_on_suspense_account_id ON public.cashes USING btree (suspense_account_id);


--
-- Name: index_cashes_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cashes_on_updated_at ON public.cashes USING btree (updated_at);


--
-- Name: index_cashes_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cashes_on_updater_id ON public.cashes USING btree (updater_id);


--
-- Name: index_catalog_items_on_catalog_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_catalog_items_on_catalog_id ON public.catalog_items USING btree (catalog_id);


--
-- Name: index_catalog_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_catalog_items_on_created_at ON public.catalog_items USING btree (created_at);


--
-- Name: index_catalog_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_catalog_items_on_creator_id ON public.catalog_items USING btree (creator_id);


--
-- Name: index_catalog_items_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_catalog_items_on_name ON public.catalog_items USING btree (name);


--
-- Name: index_catalog_items_on_purchase_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_catalog_items_on_purchase_item_id ON public.catalog_items USING btree (purchase_item_id);


--
-- Name: index_catalog_items_on_reference_tax_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_catalog_items_on_reference_tax_id ON public.catalog_items USING btree (reference_tax_id);


--
-- Name: index_catalog_items_on_sale_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_catalog_items_on_sale_item_id ON public.catalog_items USING btree (sale_item_id);


--
-- Name: index_catalog_items_on_unit_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_catalog_items_on_unit_id ON public.catalog_items USING btree (unit_id);


--
-- Name: index_catalog_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_catalog_items_on_updated_at ON public.catalog_items USING btree (updated_at);


--
-- Name: index_catalog_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_catalog_items_on_updater_id ON public.catalog_items USING btree (updater_id);


--
-- Name: index_catalog_items_on_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_catalog_items_on_variant_id ON public.catalog_items USING btree (variant_id);


--
-- Name: index_catalogs_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_catalogs_on_created_at ON public.catalogs USING btree (created_at);


--
-- Name: index_catalogs_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_catalogs_on_creator_id ON public.catalogs USING btree (creator_id);


--
-- Name: index_catalogs_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_catalogs_on_updated_at ON public.catalogs USING btree (updated_at);


--
-- Name: index_catalogs_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_catalogs_on_updater_id ON public.catalogs USING btree (updater_id);


--
-- Name: index_contract_items_on_contract_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contract_items_on_contract_id ON public.contract_items USING btree (contract_id);


--
-- Name: index_contract_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contract_items_on_created_at ON public.contract_items USING btree (created_at);


--
-- Name: index_contract_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contract_items_on_creator_id ON public.contract_items USING btree (creator_id);


--
-- Name: index_contract_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contract_items_on_updated_at ON public.contract_items USING btree (updated_at);


--
-- Name: index_contract_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contract_items_on_updater_id ON public.contract_items USING btree (updater_id);


--
-- Name: index_contract_items_on_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contract_items_on_variant_id ON public.contract_items USING btree (variant_id);


--
-- Name: index_contracts_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contracts_on_created_at ON public.contracts USING btree (created_at);


--
-- Name: index_contracts_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contracts_on_creator_id ON public.contracts USING btree (creator_id);


--
-- Name: index_contracts_on_responsible_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contracts_on_responsible_id ON public.contracts USING btree (responsible_id);


--
-- Name: index_contracts_on_supplier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contracts_on_supplier_id ON public.contracts USING btree (supplier_id);


--
-- Name: index_contracts_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contracts_on_updated_at ON public.contracts USING btree (updated_at);


--
-- Name: index_contracts_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contracts_on_updater_id ON public.contracts USING btree (updater_id);


--
-- Name: index_crop_group_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crop_group_items_on_creator_id ON public.crop_group_items USING btree (creator_id);


--
-- Name: index_crop_group_items_on_crop_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crop_group_items_on_crop_group_id ON public.crop_group_items USING btree (crop_group_id);


--
-- Name: index_crop_group_items_on_crop_type_and_crop_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crop_group_items_on_crop_type_and_crop_id ON public.crop_group_items USING btree (crop_type, crop_id);


--
-- Name: index_crop_group_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crop_group_items_on_updater_id ON public.crop_group_items USING btree (updater_id);


--
-- Name: index_crop_group_labellings_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crop_group_labellings_on_creator_id ON public.crop_group_labellings USING btree (creator_id);


--
-- Name: index_crop_group_labellings_on_crop_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crop_group_labellings_on_crop_group_id ON public.crop_group_labellings USING btree (crop_group_id);


--
-- Name: index_crop_group_labellings_on_label_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crop_group_labellings_on_label_id ON public.crop_group_labellings USING btree (label_id);


--
-- Name: index_crop_group_labellings_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crop_group_labellings_on_updater_id ON public.crop_group_labellings USING btree (updater_id);


--
-- Name: index_crop_groups_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crop_groups_on_creator_id ON public.crop_groups USING btree (creator_id);


--
-- Name: index_crop_groups_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crop_groups_on_updater_id ON public.crop_groups USING btree (updater_id);


--
-- Name: index_crumbs_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crumbs_on_created_at ON public.crumbs USING btree (created_at);


--
-- Name: index_crumbs_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crumbs_on_creator_id ON public.crumbs USING btree (creator_id);


--
-- Name: index_crumbs_on_intervention_parameter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crumbs_on_intervention_parameter_id ON public.crumbs USING btree (intervention_parameter_id);


--
-- Name: index_crumbs_on_intervention_participation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crumbs_on_intervention_participation_id ON public.crumbs USING btree (intervention_participation_id);


--
-- Name: index_crumbs_on_nature; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crumbs_on_nature ON public.crumbs USING btree (nature);


--
-- Name: index_crumbs_on_read_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crumbs_on_read_at ON public.crumbs USING btree (read_at);


--
-- Name: index_crumbs_on_ride_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crumbs_on_ride_id ON public.crumbs USING btree (ride_id);


--
-- Name: index_crumbs_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crumbs_on_updated_at ON public.crumbs USING btree (updated_at);


--
-- Name: index_crumbs_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crumbs_on_updater_id ON public.crumbs USING btree (updater_id);


--
-- Name: index_crumbs_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crumbs_on_user_id ON public.crumbs USING btree (user_id);


--
-- Name: index_cultivable_zones_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cultivable_zones_on_created_at ON public.cultivable_zones USING btree (created_at);


--
-- Name: index_cultivable_zones_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cultivable_zones_on_creator_id ON public.cultivable_zones USING btree (creator_id);


--
-- Name: index_cultivable_zones_on_farmer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cultivable_zones_on_farmer_id ON public.cultivable_zones USING btree (farmer_id);


--
-- Name: index_cultivable_zones_on_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cultivable_zones_on_owner_id ON public.cultivable_zones USING btree (owner_id);


--
-- Name: index_cultivable_zones_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cultivable_zones_on_updated_at ON public.cultivable_zones USING btree (updated_at);


--
-- Name: index_cultivable_zones_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cultivable_zones_on_updater_id ON public.cultivable_zones USING btree (updater_id);


--
-- Name: index_custom_field_choices_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_field_choices_on_created_at ON public.custom_field_choices USING btree (created_at);


--
-- Name: index_custom_field_choices_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_field_choices_on_creator_id ON public.custom_field_choices USING btree (creator_id);


--
-- Name: index_custom_field_choices_on_custom_field_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_field_choices_on_custom_field_id ON public.custom_field_choices USING btree (custom_field_id);


--
-- Name: index_custom_field_choices_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_field_choices_on_updated_at ON public.custom_field_choices USING btree (updated_at);


--
-- Name: index_custom_field_choices_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_field_choices_on_updater_id ON public.custom_field_choices USING btree (updater_id);


--
-- Name: index_custom_fields_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_fields_on_created_at ON public.custom_fields USING btree (created_at);


--
-- Name: index_custom_fields_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_fields_on_creator_id ON public.custom_fields USING btree (creator_id);


--
-- Name: index_custom_fields_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_fields_on_updated_at ON public.custom_fields USING btree (updated_at);


--
-- Name: index_custom_fields_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_fields_on_updater_id ON public.custom_fields USING btree (updater_id);


--
-- Name: index_cvi_cadastral_plant_cvi_land_parcels_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cvi_cadastral_plant_cvi_land_parcels_on_creator_id ON public.cvi_cadastral_plant_cvi_land_parcels USING btree (creator_id);


--
-- Name: index_cvi_cadastral_plant_cvi_land_parcels_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cvi_cadastral_plant_cvi_land_parcels_on_updater_id ON public.cvi_cadastral_plant_cvi_land_parcels USING btree (updater_id);


--
-- Name: index_cvi_cadastral_plants_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cvi_cadastral_plants_on_creator_id ON public.cvi_cadastral_plants USING btree (creator_id);


--
-- Name: index_cvi_cadastral_plants_on_cvi_cultivable_zone_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cvi_cadastral_plants_on_cvi_cultivable_zone_id ON public.cvi_cadastral_plants USING btree (cvi_cultivable_zone_id);


--
-- Name: index_cvi_cadastral_plants_on_cvi_statement_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cvi_cadastral_plants_on_cvi_statement_id ON public.cvi_cadastral_plants USING btree (cvi_statement_id);


--
-- Name: index_cvi_cadastral_plants_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cvi_cadastral_plants_on_updater_id ON public.cvi_cadastral_plants USING btree (updater_id);


--
-- Name: index_cvi_cultivable_zones_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cvi_cultivable_zones_on_creator_id ON public.cvi_cultivable_zones USING btree (creator_id);


--
-- Name: index_cvi_cultivable_zones_on_cvi_statement_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cvi_cultivable_zones_on_cvi_statement_id ON public.cvi_cultivable_zones USING btree (cvi_statement_id);


--
-- Name: index_cvi_cultivable_zones_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cvi_cultivable_zones_on_updater_id ON public.cvi_cultivable_zones USING btree (updater_id);


--
-- Name: index_cvi_land_parcels_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cvi_land_parcels_on_activity_id ON public.cvi_land_parcels USING btree (activity_id);


--
-- Name: index_cvi_land_parcels_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cvi_land_parcels_on_creator_id ON public.cvi_land_parcels USING btree (creator_id);


--
-- Name: index_cvi_land_parcels_on_cvi_cultivable_zone_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cvi_land_parcels_on_cvi_cultivable_zone_id ON public.cvi_land_parcels USING btree (cvi_cultivable_zone_id);


--
-- Name: index_cvi_land_parcels_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cvi_land_parcels_on_updater_id ON public.cvi_land_parcels USING btree (updater_id);


--
-- Name: index_cvi_statements_on_campaign_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cvi_statements_on_campaign_id ON public.cvi_statements USING btree (campaign_id);


--
-- Name: index_cvi_statements_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cvi_statements_on_creator_id ON public.cvi_statements USING btree (creator_id);


--
-- Name: index_cvi_statements_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cvi_statements_on_updater_id ON public.cvi_statements USING btree (updater_id);


--
-- Name: index_daily_charges_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_daily_charges_on_activity_id ON public.daily_charges USING btree (activity_id);


--
-- Name: index_daily_charges_on_activity_production_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_daily_charges_on_activity_production_id ON public.daily_charges USING btree (activity_production_id);


--
-- Name: index_dashboards_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dashboards_on_created_at ON public.dashboards USING btree (created_at);


--
-- Name: index_dashboards_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dashboards_on_creator_id ON public.dashboards USING btree (creator_id);


--
-- Name: index_dashboards_on_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dashboards_on_owner_id ON public.dashboards USING btree (owner_id);


--
-- Name: index_dashboards_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dashboards_on_updated_at ON public.dashboards USING btree (updated_at);


--
-- Name: index_dashboards_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dashboards_on_updater_id ON public.dashboards USING btree (updater_id);


--
-- Name: index_debt_transfers_on_affair_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_debt_transfers_on_affair_id ON public.debt_transfers USING btree (affair_id);


--
-- Name: index_debt_transfers_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_debt_transfers_on_created_at ON public.debt_transfers USING btree (created_at);


--
-- Name: index_debt_transfers_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_debt_transfers_on_creator_id ON public.debt_transfers USING btree (creator_id);


--
-- Name: index_debt_transfers_on_debt_transfer_affair_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_debt_transfers_on_debt_transfer_affair_id ON public.debt_transfers USING btree (debt_transfer_affair_id);


--
-- Name: index_debt_transfers_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_debt_transfers_on_updated_at ON public.debt_transfers USING btree (updated_at);


--
-- Name: index_debt_transfers_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_debt_transfers_on_updater_id ON public.debt_transfers USING btree (updater_id);


--
-- Name: index_deliveries_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deliveries_on_created_at ON public.deliveries USING btree (created_at);


--
-- Name: index_deliveries_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deliveries_on_creator_id ON public.deliveries USING btree (creator_id);


--
-- Name: index_deliveries_on_driver_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deliveries_on_driver_id ON public.deliveries USING btree (driver_id);


--
-- Name: index_deliveries_on_responsible_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deliveries_on_responsible_id ON public.deliveries USING btree (responsible_id);


--
-- Name: index_deliveries_on_transporter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deliveries_on_transporter_id ON public.deliveries USING btree (transporter_id);


--
-- Name: index_deliveries_on_transporter_purchase_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deliveries_on_transporter_purchase_id ON public.deliveries USING btree (transporter_purchase_id);


--
-- Name: index_deliveries_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deliveries_on_updated_at ON public.deliveries USING btree (updated_at);


--
-- Name: index_deliveries_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deliveries_on_updater_id ON public.deliveries USING btree (updater_id);


--
-- Name: index_delivery_tools_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delivery_tools_on_created_at ON public.delivery_tools USING btree (created_at);


--
-- Name: index_delivery_tools_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delivery_tools_on_creator_id ON public.delivery_tools USING btree (creator_id);


--
-- Name: index_delivery_tools_on_delivery_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delivery_tools_on_delivery_id ON public.delivery_tools USING btree (delivery_id);


--
-- Name: index_delivery_tools_on_tool_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delivery_tools_on_tool_id ON public.delivery_tools USING btree (tool_id);


--
-- Name: index_delivery_tools_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delivery_tools_on_updated_at ON public.delivery_tools USING btree (updated_at);


--
-- Name: index_delivery_tools_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delivery_tools_on_updater_id ON public.delivery_tools USING btree (updater_id);


--
-- Name: index_deposits_on_cash_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deposits_on_cash_id ON public.deposits USING btree (cash_id);


--
-- Name: index_deposits_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deposits_on_created_at ON public.deposits USING btree (created_at);


--
-- Name: index_deposits_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deposits_on_creator_id ON public.deposits USING btree (creator_id);


--
-- Name: index_deposits_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deposits_on_journal_entry_id ON public.deposits USING btree (journal_entry_id);


--
-- Name: index_deposits_on_mode_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deposits_on_mode_id ON public.deposits USING btree (mode_id);


--
-- Name: index_deposits_on_responsible_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deposits_on_responsible_id ON public.deposits USING btree (responsible_id);


--
-- Name: index_deposits_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deposits_on_updated_at ON public.deposits USING btree (updated_at);


--
-- Name: index_deposits_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deposits_on_updater_id ON public.deposits USING btree (updater_id);


--
-- Name: index_districts_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_districts_on_created_at ON public.districts USING btree (created_at);


--
-- Name: index_districts_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_districts_on_creator_id ON public.districts USING btree (creator_id);


--
-- Name: index_districts_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_districts_on_updated_at ON public.districts USING btree (updated_at);


--
-- Name: index_districts_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_districts_on_updater_id ON public.districts USING btree (updater_id);


--
-- Name: index_document_templates_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_document_templates_on_created_at ON public.document_templates USING btree (created_at);


--
-- Name: index_document_templates_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_document_templates_on_creator_id ON public.document_templates USING btree (creator_id);


--
-- Name: index_document_templates_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_document_templates_on_updated_at ON public.document_templates USING btree (updated_at);


--
-- Name: index_document_templates_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_document_templates_on_updater_id ON public.document_templates USING btree (updater_id);


--
-- Name: index_documents_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_documents_on_created_at ON public.documents USING btree (created_at);


--
-- Name: index_documents_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_documents_on_creator_id ON public.documents USING btree (creator_id);


--
-- Name: index_documents_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_documents_on_name ON public.documents USING btree (name);


--
-- Name: index_documents_on_nature; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_documents_on_nature ON public.documents USING btree (nature);


--
-- Name: index_documents_on_nature_and_key; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_documents_on_nature_and_key ON public.documents USING btree (nature, key);


--
-- Name: index_documents_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_documents_on_number ON public.documents USING btree (number);


--
-- Name: index_documents_on_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_documents_on_template_id ON public.documents USING btree (template_id);


--
-- Name: index_documents_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_documents_on_updated_at ON public.documents USING btree (updated_at);


--
-- Name: index_documents_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_documents_on_updater_id ON public.documents USING btree (updater_id);


--
-- Name: index_economic_cash_indicators_on_activity_budget_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_economic_cash_indicators_on_activity_budget_id ON public.economic_cash_indicators USING btree (activity_budget_id);


--
-- Name: index_economic_cash_indicators_on_activity_budget_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_economic_cash_indicators_on_activity_budget_item_id ON public.economic_cash_indicators USING btree (activity_budget_item_id);


--
-- Name: index_economic_cash_indicators_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_economic_cash_indicators_on_activity_id ON public.economic_cash_indicators USING btree (activity_id);


--
-- Name: index_economic_cash_indicators_on_campaign_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_economic_cash_indicators_on_campaign_id ON public.economic_cash_indicators USING btree (campaign_id);


--
-- Name: index_economic_cash_indicators_on_context; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_economic_cash_indicators_on_context ON public.economic_cash_indicators USING btree (context);


--
-- Name: index_economic_cash_indicators_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_economic_cash_indicators_on_created_at ON public.economic_cash_indicators USING btree (created_at);


--
-- Name: index_economic_cash_indicators_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_economic_cash_indicators_on_creator_id ON public.economic_cash_indicators USING btree (creator_id);


--
-- Name: index_economic_cash_indicators_on_direction; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_economic_cash_indicators_on_direction ON public.economic_cash_indicators USING btree (direction);


--
-- Name: index_economic_cash_indicators_on_loan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_economic_cash_indicators_on_loan_id ON public.economic_cash_indicators USING btree (loan_id);


--
-- Name: index_economic_cash_indicators_on_nature; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_economic_cash_indicators_on_nature ON public.economic_cash_indicators USING btree (nature);


--
-- Name: index_economic_cash_indicators_on_origin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_economic_cash_indicators_on_origin ON public.economic_cash_indicators USING btree (origin);


--
-- Name: index_economic_cash_indicators_on_paid_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_economic_cash_indicators_on_paid_on ON public.economic_cash_indicators USING btree (paid_on);


--
-- Name: index_economic_cash_indicators_on_product_nature_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_economic_cash_indicators_on_product_nature_variant_id ON public.economic_cash_indicators USING btree (product_nature_variant_id);


--
-- Name: index_economic_cash_indicators_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_economic_cash_indicators_on_updated_at ON public.economic_cash_indicators USING btree (updated_at);


--
-- Name: index_economic_cash_indicators_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_economic_cash_indicators_on_updater_id ON public.economic_cash_indicators USING btree (updater_id);


--
-- Name: index_economic_cash_indicators_on_used_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_economic_cash_indicators_on_used_on ON public.economic_cash_indicators USING btree (used_on);


--
-- Name: index_economic_cash_indicators_on_worker_contract_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_economic_cash_indicators_on_worker_contract_id ON public.economic_cash_indicators USING btree (worker_contract_id);


--
-- Name: index_economic_indicators_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_economic_indicators_on_activity_id ON public.economic_indicators USING btree (activity_id);


--
-- Name: index_economic_indicators_on_campaign_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_economic_indicators_on_campaign_id ON public.economic_indicators USING btree (campaign_id);


--
-- Name: index_entities_on_client_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entities_on_client_account_id ON public.entities USING btree (client_account_id);


--
-- Name: index_entities_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entities_on_created_at ON public.entities USING btree (created_at);


--
-- Name: index_entities_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entities_on_creator_id ON public.entities USING btree (creator_id);


--
-- Name: index_entities_on_employee_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entities_on_employee_account_id ON public.entities USING btree (employee_account_id);


--
-- Name: index_entities_on_full_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entities_on_full_name ON public.entities USING btree (full_name);


--
-- Name: index_entities_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entities_on_number ON public.entities USING btree (number);


--
-- Name: index_entities_on_of_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entities_on_of_company ON public.entities USING btree (of_company);


--
-- Name: index_entities_on_proposer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entities_on_proposer_id ON public.entities USING btree (proposer_id);


--
-- Name: index_entities_on_responsible_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entities_on_responsible_id ON public.entities USING btree (responsible_id);


--
-- Name: index_entities_on_supplier_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entities_on_supplier_account_id ON public.entities USING btree (supplier_account_id);


--
-- Name: index_entities_on_supplier_payment_mode_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entities_on_supplier_payment_mode_id ON public.entities USING btree (supplier_payment_mode_id);


--
-- Name: index_entities_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entities_on_updated_at ON public.entities USING btree (updated_at);


--
-- Name: index_entities_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entities_on_updater_id ON public.entities USING btree (updater_id);


--
-- Name: index_entity_addresses_on_by_default; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_addresses_on_by_default ON public.entity_addresses USING btree (by_default);


--
-- Name: index_entity_addresses_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_addresses_on_created_at ON public.entity_addresses USING btree (created_at);


--
-- Name: index_entity_addresses_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_addresses_on_creator_id ON public.entity_addresses USING btree (creator_id);


--
-- Name: index_entity_addresses_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_addresses_on_deleted_at ON public.entity_addresses USING btree (deleted_at);


--
-- Name: index_entity_addresses_on_entity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_addresses_on_entity_id ON public.entity_addresses USING btree (entity_id);


--
-- Name: index_entity_addresses_on_mail_postal_zone_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_addresses_on_mail_postal_zone_id ON public.entity_addresses USING btree (mail_postal_zone_id);


--
-- Name: index_entity_addresses_on_thread; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_addresses_on_thread ON public.entity_addresses USING btree (thread);


--
-- Name: index_entity_addresses_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_addresses_on_updated_at ON public.entity_addresses USING btree (updated_at);


--
-- Name: index_entity_addresses_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_addresses_on_updater_id ON public.entity_addresses USING btree (updater_id);


--
-- Name: index_entity_links_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_links_on_created_at ON public.entity_links USING btree (created_at);


--
-- Name: index_entity_links_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_links_on_creator_id ON public.entity_links USING btree (creator_id);


--
-- Name: index_entity_links_on_entity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_links_on_entity_id ON public.entity_links USING btree (entity_id);


--
-- Name: index_entity_links_on_entity_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_links_on_entity_role ON public.entity_links USING btree (entity_role);


--
-- Name: index_entity_links_on_linked_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_links_on_linked_id ON public.entity_links USING btree (linked_id);


--
-- Name: index_entity_links_on_linked_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_links_on_linked_role ON public.entity_links USING btree (linked_role);


--
-- Name: index_entity_links_on_nature; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_links_on_nature ON public.entity_links USING btree (nature);


--
-- Name: index_entity_links_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_links_on_updated_at ON public.entity_links USING btree (updated_at);


--
-- Name: index_entity_links_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_links_on_updater_id ON public.entity_links USING btree (updater_id);


--
-- Name: index_event_participations_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_event_participations_on_created_at ON public.event_participations USING btree (created_at);


--
-- Name: index_event_participations_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_event_participations_on_creator_id ON public.event_participations USING btree (creator_id);


--
-- Name: index_event_participations_on_event_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_event_participations_on_event_id ON public.event_participations USING btree (event_id);


--
-- Name: index_event_participations_on_participant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_event_participations_on_participant_id ON public.event_participations USING btree (participant_id);


--
-- Name: index_event_participations_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_event_participations_on_updated_at ON public.event_participations USING btree (updated_at);


--
-- Name: index_event_participations_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_event_participations_on_updater_id ON public.event_participations USING btree (updater_id);


--
-- Name: index_events_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_created_at ON public.events USING btree (created_at);


--
-- Name: index_events_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_creator_id ON public.events USING btree (creator_id);


--
-- Name: index_events_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_updated_at ON public.events USING btree (updated_at);


--
-- Name: index_events_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_updater_id ON public.events USING btree (updater_id);


--
-- Name: index_financial_year_exchanges_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_financial_year_exchanges_on_created_at ON public.financial_year_exchanges USING btree (created_at);


--
-- Name: index_financial_year_exchanges_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_financial_year_exchanges_on_creator_id ON public.financial_year_exchanges USING btree (creator_id);


--
-- Name: index_financial_year_exchanges_on_financial_year_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_financial_year_exchanges_on_financial_year_id ON public.financial_year_exchanges USING btree (financial_year_id);


--
-- Name: index_financial_year_exchanges_on_public_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_financial_year_exchanges_on_public_token ON public.financial_year_exchanges USING btree (public_token);


--
-- Name: index_financial_year_exchanges_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_financial_year_exchanges_on_updated_at ON public.financial_year_exchanges USING btree (updated_at);


--
-- Name: index_financial_year_exchanges_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_financial_year_exchanges_on_updater_id ON public.financial_year_exchanges USING btree (updater_id);


--
-- Name: index_financial_years_on_accountant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_financial_years_on_accountant_id ON public.financial_years USING btree (accountant_id);


--
-- Name: index_financial_years_on_closer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_financial_years_on_closer_id ON public.financial_years USING btree (closer_id);


--
-- Name: index_financial_years_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_financial_years_on_created_at ON public.financial_years USING btree (created_at);


--
-- Name: index_financial_years_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_financial_years_on_creator_id ON public.financial_years USING btree (creator_id);


--
-- Name: index_financial_years_on_last_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_financial_years_on_last_journal_entry_id ON public.financial_years USING btree (last_journal_entry_id);


--
-- Name: index_financial_years_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_financial_years_on_updated_at ON public.financial_years USING btree (updated_at);


--
-- Name: index_financial_years_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_financial_years_on_updater_id ON public.financial_years USING btree (updater_id);


--
-- Name: index_fixed_asset_depreciations_on_accountable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_asset_depreciations_on_accountable ON public.fixed_asset_depreciations USING btree (accountable);


--
-- Name: index_fixed_asset_depreciations_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_asset_depreciations_on_created_at ON public.fixed_asset_depreciations USING btree (created_at);


--
-- Name: index_fixed_asset_depreciations_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_asset_depreciations_on_creator_id ON public.fixed_asset_depreciations USING btree (creator_id);


--
-- Name: index_fixed_asset_depreciations_on_financial_year_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_asset_depreciations_on_financial_year_id ON public.fixed_asset_depreciations USING btree (financial_year_id);


--
-- Name: index_fixed_asset_depreciations_on_fixed_asset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_asset_depreciations_on_fixed_asset_id ON public.fixed_asset_depreciations USING btree (fixed_asset_id);


--
-- Name: index_fixed_asset_depreciations_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_asset_depreciations_on_journal_entry_id ON public.fixed_asset_depreciations USING btree (journal_entry_id);


--
-- Name: index_fixed_asset_depreciations_on_locked; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_asset_depreciations_on_locked ON public.fixed_asset_depreciations USING btree (locked);


--
-- Name: index_fixed_asset_depreciations_on_stopped_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_asset_depreciations_on_stopped_on ON public.fixed_asset_depreciations USING btree (stopped_on);


--
-- Name: index_fixed_asset_depreciations_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_asset_depreciations_on_updated_at ON public.fixed_asset_depreciations USING btree (updated_at);


--
-- Name: index_fixed_asset_depreciations_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_asset_depreciations_on_updater_id ON public.fixed_asset_depreciations USING btree (updater_id);


--
-- Name: index_fixed_assets_on_allocation_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_allocation_account_id ON public.fixed_assets USING btree (allocation_account_id);


--
-- Name: index_fixed_assets_on_asset_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_asset_account_id ON public.fixed_assets USING btree (asset_account_id);


--
-- Name: index_fixed_assets_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_created_at ON public.fixed_assets USING btree (created_at);


--
-- Name: index_fixed_assets_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_creator_id ON public.fixed_assets USING btree (creator_id);


--
-- Name: index_fixed_assets_on_expenses_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_expenses_account_id ON public.fixed_assets USING btree (expenses_account_id);


--
-- Name: index_fixed_assets_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_journal_entry_id ON public.fixed_assets USING btree (journal_entry_id);


--
-- Name: index_fixed_assets_on_journal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_journal_id ON public.fixed_assets USING btree (journal_id);


--
-- Name: index_fixed_assets_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_number ON public.fixed_assets USING btree (number);


--
-- Name: index_fixed_assets_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_product_id ON public.fixed_assets USING btree (product_id);


--
-- Name: index_fixed_assets_on_purchase_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_purchase_id ON public.fixed_assets USING btree (purchase_id);


--
-- Name: index_fixed_assets_on_purchase_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_purchase_item_id ON public.fixed_assets USING btree (purchase_item_id);


--
-- Name: index_fixed_assets_on_sale_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_sale_id ON public.fixed_assets USING btree (sale_id);


--
-- Name: index_fixed_assets_on_sale_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_sale_item_id ON public.fixed_assets USING btree (sale_item_id);


--
-- Name: index_fixed_assets_on_scrapped_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_scrapped_journal_entry_id ON public.fixed_assets USING btree (scrapped_journal_entry_id);


--
-- Name: index_fixed_assets_on_sold_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_sold_journal_entry_id ON public.fixed_assets USING btree (sold_journal_entry_id);


--
-- Name: index_fixed_assets_on_tax_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_tax_id ON public.fixed_assets USING btree (tax_id);


--
-- Name: index_fixed_assets_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_updated_at ON public.fixed_assets USING btree (updated_at);


--
-- Name: index_fixed_assets_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_updater_id ON public.fixed_assets USING btree (updater_id);


--
-- Name: index_gap_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gap_items_on_created_at ON public.gap_items USING btree (created_at);


--
-- Name: index_gap_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gap_items_on_creator_id ON public.gap_items USING btree (creator_id);


--
-- Name: index_gap_items_on_gap_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gap_items_on_gap_id ON public.gap_items USING btree (gap_id);


--
-- Name: index_gap_items_on_tax_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gap_items_on_tax_id ON public.gap_items USING btree (tax_id);


--
-- Name: index_gap_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gap_items_on_updated_at ON public.gap_items USING btree (updated_at);


--
-- Name: index_gap_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gap_items_on_updater_id ON public.gap_items USING btree (updater_id);


--
-- Name: index_gaps_on_affair_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gaps_on_affair_id ON public.gaps USING btree (affair_id);


--
-- Name: index_gaps_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gaps_on_created_at ON public.gaps USING btree (created_at);


--
-- Name: index_gaps_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gaps_on_creator_id ON public.gaps USING btree (creator_id);


--
-- Name: index_gaps_on_direction; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gaps_on_direction ON public.gaps USING btree (direction);


--
-- Name: index_gaps_on_entity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gaps_on_entity_id ON public.gaps USING btree (entity_id);


--
-- Name: index_gaps_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gaps_on_journal_entry_id ON public.gaps USING btree (journal_entry_id);


--
-- Name: index_gaps_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gaps_on_number ON public.gaps USING btree (number);


--
-- Name: index_gaps_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gaps_on_updated_at ON public.gaps USING btree (updated_at);


--
-- Name: index_gaps_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gaps_on_updater_id ON public.gaps USING btree (updater_id);


--
-- Name: index_georeadings_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_georeadings_on_created_at ON public.georeadings USING btree (created_at);


--
-- Name: index_georeadings_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_georeadings_on_creator_id ON public.georeadings USING btree (creator_id);


--
-- Name: index_georeadings_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_georeadings_on_name ON public.georeadings USING btree (name);


--
-- Name: index_georeadings_on_nature; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_georeadings_on_nature ON public.georeadings USING btree (nature);


--
-- Name: index_georeadings_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_georeadings_on_number ON public.georeadings USING btree (number);


--
-- Name: index_georeadings_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_georeadings_on_updated_at ON public.georeadings USING btree (updated_at);


--
-- Name: index_georeadings_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_georeadings_on_updater_id ON public.georeadings USING btree (updater_id);


--
-- Name: index_guide_analyses_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_guide_analyses_on_created_at ON public.guide_analyses USING btree (created_at);


--
-- Name: index_guide_analyses_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_guide_analyses_on_creator_id ON public.guide_analyses USING btree (creator_id);


--
-- Name: index_guide_analyses_on_guide_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_guide_analyses_on_guide_id ON public.guide_analyses USING btree (guide_id);


--
-- Name: index_guide_analyses_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_guide_analyses_on_updated_at ON public.guide_analyses USING btree (updated_at);


--
-- Name: index_guide_analyses_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_guide_analyses_on_updater_id ON public.guide_analyses USING btree (updater_id);


--
-- Name: index_guide_analysis_points_on_analysis_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_guide_analysis_points_on_analysis_id ON public.guide_analysis_points USING btree (analysis_id);


--
-- Name: index_guide_analysis_points_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_guide_analysis_points_on_created_at ON public.guide_analysis_points USING btree (created_at);


--
-- Name: index_guide_analysis_points_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_guide_analysis_points_on_creator_id ON public.guide_analysis_points USING btree (creator_id);


--
-- Name: index_guide_analysis_points_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_guide_analysis_points_on_updated_at ON public.guide_analysis_points USING btree (updated_at);


--
-- Name: index_guide_analysis_points_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_guide_analysis_points_on_updater_id ON public.guide_analysis_points USING btree (updater_id);


--
-- Name: index_guides_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_guides_on_created_at ON public.guides USING btree (created_at);


--
-- Name: index_guides_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_guides_on_creator_id ON public.guides USING btree (creator_id);


--
-- Name: index_guides_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_guides_on_updated_at ON public.guides USING btree (updated_at);


--
-- Name: index_guides_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_guides_on_updater_id ON public.guides USING btree (updater_id);


--
-- Name: index_idea_diagnostic_item_values_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_idea_diagnostic_item_values_on_created_at ON public.idea_diagnostic_item_values USING btree (created_at);


--
-- Name: index_idea_diagnostic_item_values_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_idea_diagnostic_item_values_on_creator_id ON public.idea_diagnostic_item_values USING btree (creator_id);


--
-- Name: index_idea_diagnostic_item_values_on_idea_diagnostic_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_idea_diagnostic_item_values_on_idea_diagnostic_item_id ON public.idea_diagnostic_item_values USING btree (idea_diagnostic_item_id);


--
-- Name: index_idea_diagnostic_item_values_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_idea_diagnostic_item_values_on_updated_at ON public.idea_diagnostic_item_values USING btree (updated_at);


--
-- Name: index_idea_diagnostic_item_values_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_idea_diagnostic_item_values_on_updater_id ON public.idea_diagnostic_item_values USING btree (updater_id);


--
-- Name: index_idea_diagnostic_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_idea_diagnostic_items_on_created_at ON public.idea_diagnostic_items USING btree (created_at);


--
-- Name: index_idea_diagnostic_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_idea_diagnostic_items_on_creator_id ON public.idea_diagnostic_items USING btree (creator_id);


--
-- Name: index_idea_diagnostic_items_on_idea_diagnostic_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_idea_diagnostic_items_on_idea_diagnostic_id ON public.idea_diagnostic_items USING btree (idea_diagnostic_id);


--
-- Name: index_idea_diagnostic_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_idea_diagnostic_items_on_updated_at ON public.idea_diagnostic_items USING btree (updated_at);


--
-- Name: index_idea_diagnostic_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_idea_diagnostic_items_on_updater_id ON public.idea_diagnostic_items USING btree (updater_id);


--
-- Name: index_idea_diagnostic_results_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_idea_diagnostic_results_on_created_at ON public.idea_diagnostic_results USING btree (created_at);


--
-- Name: index_idea_diagnostic_results_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_idea_diagnostic_results_on_creator_id ON public.idea_diagnostic_results USING btree (creator_id);


--
-- Name: index_idea_diagnostic_results_on_idea_diagnostic_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_idea_diagnostic_results_on_idea_diagnostic_id ON public.idea_diagnostic_results USING btree (idea_diagnostic_id);


--
-- Name: index_idea_diagnostic_results_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_idea_diagnostic_results_on_updated_at ON public.idea_diagnostic_results USING btree (updated_at);


--
-- Name: index_idea_diagnostic_results_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_idea_diagnostic_results_on_updater_id ON public.idea_diagnostic_results USING btree (updater_id);


--
-- Name: index_idea_diagnostics_on_auditor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_idea_diagnostics_on_auditor_id ON public.idea_diagnostics USING btree (auditor_id);


--
-- Name: index_idea_diagnostics_on_campaign_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_idea_diagnostics_on_campaign_id ON public.idea_diagnostics USING btree (campaign_id);


--
-- Name: index_idea_diagnostics_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_idea_diagnostics_on_created_at ON public.idea_diagnostics USING btree (created_at);


--
-- Name: index_idea_diagnostics_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_idea_diagnostics_on_creator_id ON public.idea_diagnostics USING btree (creator_id);


--
-- Name: index_idea_diagnostics_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_idea_diagnostics_on_updated_at ON public.idea_diagnostics USING btree (updated_at);


--
-- Name: index_idea_diagnostics_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_idea_diagnostics_on_updater_id ON public.idea_diagnostics USING btree (updater_id);


--
-- Name: index_identifiers_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_identifiers_on_created_at ON public.identifiers USING btree (created_at);


--
-- Name: index_identifiers_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_identifiers_on_creator_id ON public.identifiers USING btree (creator_id);


--
-- Name: index_identifiers_on_nature; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_identifiers_on_nature ON public.identifiers USING btree (nature);


--
-- Name: index_identifiers_on_net_service_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_identifiers_on_net_service_id ON public.identifiers USING btree (net_service_id);


--
-- Name: index_identifiers_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_identifiers_on_updated_at ON public.identifiers USING btree (updated_at);


--
-- Name: index_identifiers_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_identifiers_on_updater_id ON public.identifiers USING btree (updater_id);


--
-- Name: index_imports_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_imports_on_created_at ON public.imports USING btree (created_at);


--
-- Name: index_imports_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_imports_on_creator_id ON public.imports USING btree (creator_id);


--
-- Name: index_imports_on_imported_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_imports_on_imported_at ON public.imports USING btree (imported_at);


--
-- Name: index_imports_on_importer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_imports_on_importer_id ON public.imports USING btree (importer_id);


--
-- Name: index_imports_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_imports_on_updated_at ON public.imports USING btree (updated_at);


--
-- Name: index_imports_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_imports_on_updater_id ON public.imports USING btree (updater_id);


--
-- Name: index_incoming_payment_modes_on_cash_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payment_modes_on_cash_id ON public.incoming_payment_modes USING btree (cash_id);


--
-- Name: index_incoming_payment_modes_on_commission_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payment_modes_on_commission_account_id ON public.incoming_payment_modes USING btree (commission_account_id);


--
-- Name: index_incoming_payment_modes_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payment_modes_on_created_at ON public.incoming_payment_modes USING btree (created_at);


--
-- Name: index_incoming_payment_modes_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payment_modes_on_creator_id ON public.incoming_payment_modes USING btree (creator_id);


--
-- Name: index_incoming_payment_modes_on_depositables_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payment_modes_on_depositables_account_id ON public.incoming_payment_modes USING btree (depositables_account_id);


--
-- Name: index_incoming_payment_modes_on_depositables_journal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payment_modes_on_depositables_journal_id ON public.incoming_payment_modes USING btree (depositables_journal_id);


--
-- Name: index_incoming_payment_modes_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payment_modes_on_updated_at ON public.incoming_payment_modes USING btree (updated_at);


--
-- Name: index_incoming_payment_modes_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payment_modes_on_updater_id ON public.incoming_payment_modes USING btree (updater_id);


--
-- Name: index_incoming_payments_on_accounted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payments_on_accounted_at ON public.incoming_payments USING btree (accounted_at);


--
-- Name: index_incoming_payments_on_affair_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payments_on_affair_id ON public.incoming_payments USING btree (affair_id);


--
-- Name: index_incoming_payments_on_commission_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payments_on_commission_account_id ON public.incoming_payments USING btree (commission_account_id);


--
-- Name: index_incoming_payments_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payments_on_created_at ON public.incoming_payments USING btree (created_at);


--
-- Name: index_incoming_payments_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payments_on_creator_id ON public.incoming_payments USING btree (creator_id);


--
-- Name: index_incoming_payments_on_deposit_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payments_on_deposit_id ON public.incoming_payments USING btree (deposit_id);


--
-- Name: index_incoming_payments_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payments_on_journal_entry_id ON public.incoming_payments USING btree (journal_entry_id);


--
-- Name: index_incoming_payments_on_mode_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payments_on_mode_id ON public.incoming_payments USING btree (mode_id);


--
-- Name: index_incoming_payments_on_payer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payments_on_payer_id ON public.incoming_payments USING btree (payer_id);


--
-- Name: index_incoming_payments_on_responsible_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payments_on_responsible_id ON public.incoming_payments USING btree (responsible_id);


--
-- Name: index_incoming_payments_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payments_on_updated_at ON public.incoming_payments USING btree (updated_at);


--
-- Name: index_incoming_payments_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payments_on_updater_id ON public.incoming_payments USING btree (updater_id);


--
-- Name: index_inspection_calibrations_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspection_calibrations_on_created_at ON public.inspection_calibrations USING btree (created_at);


--
-- Name: index_inspection_calibrations_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspection_calibrations_on_creator_id ON public.inspection_calibrations USING btree (creator_id);


--
-- Name: index_inspection_calibrations_on_inspection_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspection_calibrations_on_inspection_id ON public.inspection_calibrations USING btree (inspection_id);


--
-- Name: index_inspection_calibrations_on_nature_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspection_calibrations_on_nature_id ON public.inspection_calibrations USING btree (nature_id);


--
-- Name: index_inspection_calibrations_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspection_calibrations_on_updated_at ON public.inspection_calibrations USING btree (updated_at);


--
-- Name: index_inspection_calibrations_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspection_calibrations_on_updater_id ON public.inspection_calibrations USING btree (updater_id);


--
-- Name: index_inspection_points_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspection_points_on_created_at ON public.inspection_points USING btree (created_at);


--
-- Name: index_inspection_points_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspection_points_on_creator_id ON public.inspection_points USING btree (creator_id);


--
-- Name: index_inspection_points_on_inspection_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspection_points_on_inspection_id ON public.inspection_points USING btree (inspection_id);


--
-- Name: index_inspection_points_on_nature_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspection_points_on_nature_id ON public.inspection_points USING btree (nature_id);


--
-- Name: index_inspection_points_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspection_points_on_updated_at ON public.inspection_points USING btree (updated_at);


--
-- Name: index_inspection_points_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspection_points_on_updater_id ON public.inspection_points USING btree (updater_id);


--
-- Name: index_inspections_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspections_on_activity_id ON public.inspections USING btree (activity_id);


--
-- Name: index_inspections_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspections_on_created_at ON public.inspections USING btree (created_at);


--
-- Name: index_inspections_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspections_on_creator_id ON public.inspections USING btree (creator_id);


--
-- Name: index_inspections_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspections_on_product_id ON public.inspections USING btree (product_id);


--
-- Name: index_inspections_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspections_on_updated_at ON public.inspections USING btree (updated_at);


--
-- Name: index_inspections_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspections_on_updater_id ON public.inspections USING btree (updater_id);


--
-- Name: index_int_parameter_setting_items_on_int_parameter_setting_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_int_parameter_setting_items_on_int_parameter_setting_id ON public.intervention_setting_items USING btree (intervention_parameter_setting_id);


--
-- Name: index_int_parameter_settings_on_int_parameter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_int_parameter_settings_on_int_parameter_id ON public.intervention_parameter_settings USING btree (intervention_parameter_id);


--
-- Name: index_integrations_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_integrations_on_created_at ON public.integrations USING btree (created_at);


--
-- Name: index_integrations_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_integrations_on_creator_id ON public.integrations USING btree (creator_id);


--
-- Name: index_integrations_on_nature; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_integrations_on_nature ON public.integrations USING btree (nature);


--
-- Name: index_integrations_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_integrations_on_updated_at ON public.integrations USING btree (updated_at);


--
-- Name: index_integrations_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_integrations_on_updater_id ON public.integrations USING btree (updater_id);


--
-- Name: index_intervention_costings_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_costings_on_creator_id ON public.intervention_costings USING btree (creator_id);


--
-- Name: index_intervention_costings_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_costings_on_updater_id ON public.intervention_costings USING btree (updater_id);


--
-- Name: index_intervention_crop_groups_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_crop_groups_on_created_at ON public.intervention_crop_groups USING btree (created_at);


--
-- Name: index_intervention_crop_groups_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_crop_groups_on_creator_id ON public.intervention_crop_groups USING btree (creator_id);


--
-- Name: index_intervention_crop_groups_on_crop_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_crop_groups_on_crop_group_id ON public.intervention_crop_groups USING btree (crop_group_id);


--
-- Name: index_intervention_crop_groups_on_intervention_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_crop_groups_on_intervention_id ON public.intervention_crop_groups USING btree (intervention_id);


--
-- Name: index_intervention_crop_groups_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_crop_groups_on_updated_at ON public.intervention_crop_groups USING btree (updated_at);


--
-- Name: index_intervention_crop_groups_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_crop_groups_on_updater_id ON public.intervention_crop_groups USING btree (updater_id);


--
-- Name: index_intervention_labellings_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_labellings_on_created_at ON public.intervention_labellings USING btree (created_at);


--
-- Name: index_intervention_labellings_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_labellings_on_creator_id ON public.intervention_labellings USING btree (creator_id);


--
-- Name: index_intervention_labellings_on_intervention_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_labellings_on_intervention_id ON public.intervention_labellings USING btree (intervention_id);


--
-- Name: index_intervention_labellings_on_intervention_id_and_label_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_intervention_labellings_on_intervention_id_and_label_id ON public.intervention_labellings USING btree (intervention_id, label_id);


--
-- Name: index_intervention_labellings_on_label_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_labellings_on_label_id ON public.intervention_labellings USING btree (label_id);


--
-- Name: index_intervention_labellings_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_labellings_on_updated_at ON public.intervention_labellings USING btree (updated_at);


--
-- Name: index_intervention_labellings_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_labellings_on_updater_id ON public.intervention_labellings USING btree (updater_id);


--
-- Name: index_intervention_parameter_readings_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameter_readings_on_created_at ON public.intervention_parameter_readings USING btree (created_at);


--
-- Name: index_intervention_parameter_readings_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameter_readings_on_creator_id ON public.intervention_parameter_readings USING btree (creator_id);


--
-- Name: index_intervention_parameter_readings_on_indicator_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameter_readings_on_indicator_name ON public.intervention_parameter_readings USING btree (indicator_name);


--
-- Name: index_intervention_parameter_readings_on_parameter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameter_readings_on_parameter_id ON public.intervention_parameter_readings USING btree (parameter_id);


--
-- Name: index_intervention_parameter_readings_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameter_readings_on_updated_at ON public.intervention_parameter_readings USING btree (updated_at);


--
-- Name: index_intervention_parameter_readings_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameter_readings_on_updater_id ON public.intervention_parameter_readings USING btree (updater_id);


--
-- Name: index_intervention_parameter_settings_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameter_settings_on_created_at ON public.intervention_parameter_settings USING btree (created_at);


--
-- Name: index_intervention_parameter_settings_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameter_settings_on_creator_id ON public.intervention_parameter_settings USING btree (creator_id);


--
-- Name: index_intervention_parameter_settings_on_intervention_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameter_settings_on_intervention_id ON public.intervention_parameter_settings USING btree (intervention_id);


--
-- Name: index_intervention_parameter_settings_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameter_settings_on_updated_at ON public.intervention_parameter_settings USING btree (updated_at);


--
-- Name: index_intervention_parameter_settings_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameter_settings_on_updater_id ON public.intervention_parameter_settings USING btree (updater_id);


--
-- Name: index_intervention_parameters_on_assembly_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_assembly_id ON public.intervention_parameters USING btree (assembly_id);


--
-- Name: index_intervention_parameters_on_component_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_component_id ON public.intervention_parameters USING btree (component_id);


--
-- Name: index_intervention_parameters_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_created_at ON public.intervention_parameters USING btree (created_at);


--
-- Name: index_intervention_parameters_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_creator_id ON public.intervention_parameters USING btree (creator_id);


--
-- Name: index_intervention_parameters_on_event_participation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_event_participation_id ON public.intervention_parameters USING btree (event_participation_id);


--
-- Name: index_intervention_parameters_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_group_id ON public.intervention_parameters USING btree (group_id);


--
-- Name: index_intervention_parameters_on_int_and_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_int_and_type ON public.intervention_parameters USING btree (intervention_id, type);


--
-- Name: index_intervention_parameters_on_intervention_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_intervention_id ON public.intervention_parameters USING btree (intervention_id);


--
-- Name: index_intervention_parameters_on_new_container_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_new_container_id ON public.intervention_parameters USING btree (new_container_id);


--
-- Name: index_intervention_parameters_on_new_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_new_group_id ON public.intervention_parameters USING btree (new_group_id);


--
-- Name: index_intervention_parameters_on_new_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_new_variant_id ON public.intervention_parameters USING btree (new_variant_id);


--
-- Name: index_intervention_parameters_on_outcoming_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_outcoming_product_id ON public.intervention_parameters USING btree (outcoming_product_id);


--
-- Name: index_intervention_parameters_on_pro_and_int_ids; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_pro_and_int_ids ON public.intervention_parameters USING btree (product_id, intervention_id);


--
-- Name: index_intervention_parameters_on_pro_and_ref_and_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_pro_and_ref_and_type ON public.intervention_parameters USING btree (product_id, reference_name, type);


--
-- Name: index_intervention_parameters_on_pro_and_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_pro_and_type ON public.intervention_parameters USING btree (product_id, type);


--
-- Name: index_intervention_parameters_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_product_id ON public.intervention_parameters USING btree (product_id);


--
-- Name: index_intervention_parameters_on_reference_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_reference_name ON public.intervention_parameters USING btree (reference_name);


--
-- Name: index_intervention_parameters_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_type ON public.intervention_parameters USING btree (type);


--
-- Name: index_intervention_parameters_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_updated_at ON public.intervention_parameters USING btree (updated_at);


--
-- Name: index_intervention_parameters_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_updater_id ON public.intervention_parameters USING btree (updater_id);


--
-- Name: index_intervention_parameters_on_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_variant_id ON public.intervention_parameters USING btree (variant_id);


--
-- Name: index_intervention_participations_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_participations_on_created_at ON public.intervention_participations USING btree (created_at);


--
-- Name: index_intervention_participations_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_participations_on_creator_id ON public.intervention_participations USING btree (creator_id);


--
-- Name: index_intervention_participations_on_intervention_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_participations_on_intervention_id ON public.intervention_participations USING btree (intervention_id);


--
-- Name: index_intervention_participations_on_pro_and_int_ids; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_participations_on_pro_and_int_ids ON public.intervention_participations USING btree (product_id, intervention_id);


--
-- Name: index_intervention_participations_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_participations_on_product_id ON public.intervention_participations USING btree (product_id);


--
-- Name: index_intervention_participations_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_participations_on_updated_at ON public.intervention_participations USING btree (updated_at);


--
-- Name: index_intervention_participations_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_participations_on_updater_id ON public.intervention_participations USING btree (updater_id);


--
-- Name: index_intervention_proposal_parameters_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_proposal_parameters_on_product_id ON public.intervention_proposal_parameters USING btree (product_id);


--
-- Name: index_intervention_proposals_on_activity_production_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_proposals_on_activity_production_id ON public.intervention_proposals USING btree (activity_production_id);


--
-- Name: index_intervention_setting_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_setting_items_on_created_at ON public.intervention_setting_items USING btree (created_at);


--
-- Name: index_intervention_setting_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_setting_items_on_creator_id ON public.intervention_setting_items USING btree (creator_id);


--
-- Name: index_intervention_setting_items_on_indicator_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_setting_items_on_indicator_name ON public.intervention_setting_items USING btree (indicator_name);


--
-- Name: index_intervention_setting_items_on_intervention_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_setting_items_on_intervention_id ON public.intervention_setting_items USING btree (intervention_id);


--
-- Name: index_intervention_setting_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_setting_items_on_updated_at ON public.intervention_setting_items USING btree (updated_at);


--
-- Name: index_intervention_setting_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_setting_items_on_updater_id ON public.intervention_setting_items USING btree (updater_id);


--
-- Name: index_intervention_template_activities_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_template_activities_on_activity_id ON public.intervention_template_activities USING btree (activity_id);


--
-- Name: index_intervention_template_product_parameters_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_template_product_parameters_on_activity_id ON public.intervention_template_product_parameters USING btree (activity_id);


--
-- Name: index_intervention_templates_on_campaign_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_templates_on_campaign_id ON public.intervention_templates USING btree (campaign_id);


--
-- Name: index_intervention_working_periods_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_working_periods_on_created_at ON public.intervention_working_periods USING btree (created_at);


--
-- Name: index_intervention_working_periods_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_working_periods_on_creator_id ON public.intervention_working_periods USING btree (creator_id);


--
-- Name: index_intervention_working_periods_on_int_and_int_part_ids; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_working_periods_on_int_and_int_part_ids ON public.intervention_working_periods USING btree (intervention_id, intervention_participation_id);


--
-- Name: index_intervention_working_periods_on_int_part_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_working_periods_on_int_part_id ON public.intervention_working_periods USING btree (intervention_participation_id);


--
-- Name: index_intervention_working_periods_on_intervention_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_working_periods_on_intervention_id ON public.intervention_working_periods USING btree (intervention_id);


--
-- Name: index_intervention_working_periods_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_working_periods_on_updated_at ON public.intervention_working_periods USING btree (updated_at);


--
-- Name: index_intervention_working_periods_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_working_periods_on_updater_id ON public.intervention_working_periods USING btree (updater_id);


--
-- Name: index_interventions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_interventions_on_created_at ON public.interventions USING btree (created_at);


--
-- Name: index_interventions_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_interventions_on_creator_id ON public.interventions USING btree (creator_id);


--
-- Name: index_interventions_on_event_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_interventions_on_event_id ON public.interventions USING btree (event_id);


--
-- Name: index_interventions_on_intervention_proposal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_interventions_on_intervention_proposal_id ON public.interventions USING btree (intervention_proposal_id);


--
-- Name: index_interventions_on_issue_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_interventions_on_issue_id ON public.interventions USING btree (issue_id);


--
-- Name: index_interventions_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_interventions_on_journal_entry_id ON public.interventions USING btree (journal_entry_id);


--
-- Name: index_interventions_on_nature; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_interventions_on_nature ON public.interventions USING btree (nature);


--
-- Name: index_interventions_on_prescription_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_interventions_on_prescription_id ON public.interventions USING btree (prescription_id);


--
-- Name: index_interventions_on_procedure_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_interventions_on_procedure_name ON public.interventions USING btree (procedure_name);


--
-- Name: index_interventions_on_purchase_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_interventions_on_purchase_id ON public.interventions USING btree (purchase_id);


--
-- Name: index_interventions_on_request_intervention_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_interventions_on_request_intervention_id ON public.interventions USING btree (request_intervention_id);


--
-- Name: index_interventions_on_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_interventions_on_started_at ON public.interventions USING btree (started_at);


--
-- Name: index_interventions_on_stopped_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_interventions_on_stopped_at ON public.interventions USING btree (stopped_at);


--
-- Name: index_interventions_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_interventions_on_updated_at ON public.interventions USING btree (updated_at);


--
-- Name: index_interventions_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_interventions_on_updater_id ON public.interventions USING btree (updater_id);


--
-- Name: index_inventories_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventories_on_created_at ON public.inventories USING btree (created_at);


--
-- Name: index_inventories_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventories_on_creator_id ON public.inventories USING btree (creator_id);


--
-- Name: index_inventories_on_financial_year_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventories_on_financial_year_id ON public.inventories USING btree (financial_year_id);


--
-- Name: index_inventories_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventories_on_journal_entry_id ON public.inventories USING btree (journal_entry_id);


--
-- Name: index_inventories_on_product_nature_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventories_on_product_nature_category_id ON public.inventories USING btree (product_nature_category_id);


--
-- Name: index_inventories_on_responsible_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventories_on_responsible_id ON public.inventories USING btree (responsible_id);


--
-- Name: index_inventories_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventories_on_updated_at ON public.inventories USING btree (updated_at);


--
-- Name: index_inventories_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventories_on_updater_id ON public.inventories USING btree (updater_id);


--
-- Name: index_inventory_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventory_items_on_created_at ON public.inventory_items USING btree (created_at);


--
-- Name: index_inventory_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventory_items_on_creator_id ON public.inventory_items USING btree (creator_id);


--
-- Name: index_inventory_items_on_inventory_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventory_items_on_inventory_id ON public.inventory_items USING btree (inventory_id);


--
-- Name: index_inventory_items_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventory_items_on_product_id ON public.inventory_items USING btree (product_id);


--
-- Name: index_inventory_items_on_product_movement_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventory_items_on_product_movement_id ON public.inventory_items USING btree (product_movement_id);


--
-- Name: index_inventory_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventory_items_on_updated_at ON public.inventory_items USING btree (updated_at);


--
-- Name: index_inventory_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventory_items_on_updater_id ON public.inventory_items USING btree (updater_id);


--
-- Name: index_issues_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_created_at ON public.issues USING btree (created_at);


--
-- Name: index_issues_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_creator_id ON public.issues USING btree (creator_id);


--
-- Name: index_issues_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_name ON public.issues USING btree (name);


--
-- Name: index_issues_on_nature; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_nature ON public.issues USING btree (nature);


--
-- Name: index_issues_on_target_type_and_target_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_target_type_and_target_id ON public.issues USING btree (target_type, target_id);


--
-- Name: index_issues_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_updated_at ON public.issues USING btree (updated_at);


--
-- Name: index_issues_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_updater_id ON public.issues USING btree (updater_id);


--
-- Name: index_journal_entries_on_continuous_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_journal_entries_on_continuous_number ON public.journal_entries USING btree (continuous_number);


--
-- Name: index_journal_entries_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entries_on_created_at ON public.journal_entries USING btree (created_at);


--
-- Name: index_journal_entries_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entries_on_creator_id ON public.journal_entries USING btree (creator_id);


--
-- Name: index_journal_entries_on_financial_year_exchange_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entries_on_financial_year_exchange_id ON public.journal_entries USING btree (financial_year_exchange_id);


--
-- Name: index_journal_entries_on_financial_year_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entries_on_financial_year_id ON public.journal_entries USING btree (financial_year_id);


--
-- Name: index_journal_entries_on_journal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entries_on_journal_id ON public.journal_entries USING btree (journal_id);


--
-- Name: index_journal_entries_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entries_on_number ON public.journal_entries USING btree (number);


--
-- Name: index_journal_entries_on_printed_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entries_on_printed_on ON public.journal_entries USING btree (printed_on);


--
-- Name: index_journal_entries_on_resource_type_and_resource_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entries_on_resource_type_and_resource_id ON public.journal_entries USING btree (resource_type, resource_id);


--
-- Name: index_journal_entries_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entries_on_updated_at ON public.journal_entries USING btree (updated_at);


--
-- Name: index_journal_entries_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entries_on_updater_id ON public.journal_entries USING btree (updater_id);


--
-- Name: index_journal_entry_items_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_account_id ON public.journal_entry_items USING btree (account_id);


--
-- Name: index_journal_entry_items_on_activity_budget_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_activity_budget_id ON public.journal_entry_items USING btree (activity_budget_id);


--
-- Name: index_journal_entry_items_on_bank_statement_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_bank_statement_id ON public.journal_entry_items USING btree (bank_statement_id);


--
-- Name: index_journal_entry_items_on_bank_statement_letter; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_bank_statement_letter ON public.journal_entry_items USING btree (bank_statement_letter);


--
-- Name: index_journal_entry_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_created_at ON public.journal_entry_items USING btree (created_at);


--
-- Name: index_journal_entry_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_creator_id ON public.journal_entry_items USING btree (creator_id);


--
-- Name: index_journal_entry_items_on_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_entry_id ON public.journal_entry_items USING btree (entry_id);


--
-- Name: index_journal_entry_items_on_entry_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_entry_number ON public.journal_entry_items USING btree (entry_number);


--
-- Name: index_journal_entry_items_on_financial_year_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_financial_year_id ON public.journal_entry_items USING btree (financial_year_id);


--
-- Name: index_journal_entry_items_on_journal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_journal_id ON public.journal_entry_items USING btree (journal_id);


--
-- Name: index_journal_entry_items_on_letter; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_letter ON public.journal_entry_items USING btree (letter);


--
-- Name: index_journal_entry_items_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_name ON public.journal_entry_items USING btree (name);


--
-- Name: index_journal_entry_items_on_printed_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_printed_on ON public.journal_entry_items USING btree (printed_on);


--
-- Name: index_journal_entry_items_on_project_budget_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_project_budget_id ON public.journal_entry_items USING btree (project_budget_id);


--
-- Name: index_journal_entry_items_on_resource_type_and_resource_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_resource_type_and_resource_id ON public.journal_entry_items USING btree (resource_type, resource_id);


--
-- Name: index_journal_entry_items_on_tax_declaration_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_tax_declaration_item_id ON public.journal_entry_items USING btree (tax_declaration_item_id);


--
-- Name: index_journal_entry_items_on_tax_declaration_mode; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_tax_declaration_mode ON public.journal_entry_items USING btree (tax_declaration_mode);


--
-- Name: index_journal_entry_items_on_tax_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_tax_id ON public.journal_entry_items USING btree (tax_id);


--
-- Name: index_journal_entry_items_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_team_id ON public.journal_entry_items USING btree (team_id);


--
-- Name: index_journal_entry_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_updated_at ON public.journal_entry_items USING btree (updated_at);


--
-- Name: index_journal_entry_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_updater_id ON public.journal_entry_items USING btree (updater_id);


--
-- Name: index_journal_entry_items_on_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_variant_id ON public.journal_entry_items USING btree (variant_id);


--
-- Name: index_journals_on_accountant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journals_on_accountant_id ON public.journals USING btree (accountant_id);


--
-- Name: index_journals_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journals_on_created_at ON public.journals USING btree (created_at);


--
-- Name: index_journals_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journals_on_creator_id ON public.journals USING btree (creator_id);


--
-- Name: index_journals_on_financial_year_exchange_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journals_on_financial_year_exchange_id ON public.journals USING btree (financial_year_exchange_id);


--
-- Name: index_journals_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journals_on_updated_at ON public.journals USING btree (updated_at);


--
-- Name: index_journals_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journals_on_updater_id ON public.journals USING btree (updater_id);


--
-- Name: index_labels_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_labels_on_created_at ON public.labels USING btree (created_at);


--
-- Name: index_labels_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_labels_on_creator_id ON public.labels USING btree (creator_id);


--
-- Name: index_labels_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_labels_on_name ON public.labels USING btree (name);


--
-- Name: index_labels_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_labels_on_updated_at ON public.labels USING btree (updated_at);


--
-- Name: index_labels_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_labels_on_updater_id ON public.labels USING btree (updater_id);


--
-- Name: index_listing_node_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listing_node_items_on_created_at ON public.listing_node_items USING btree (created_at);


--
-- Name: index_listing_node_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listing_node_items_on_creator_id ON public.listing_node_items USING btree (creator_id);


--
-- Name: index_listing_node_items_on_node_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listing_node_items_on_node_id ON public.listing_node_items USING btree (node_id);


--
-- Name: index_listing_node_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listing_node_items_on_updated_at ON public.listing_node_items USING btree (updated_at);


--
-- Name: index_listing_node_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listing_node_items_on_updater_id ON public.listing_node_items USING btree (updater_id);


--
-- Name: index_listing_nodes_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listing_nodes_on_created_at ON public.listing_nodes USING btree (created_at);


--
-- Name: index_listing_nodes_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listing_nodes_on_creator_id ON public.listing_nodes USING btree (creator_id);


--
-- Name: index_listing_nodes_on_exportable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listing_nodes_on_exportable ON public.listing_nodes USING btree (exportable);


--
-- Name: index_listing_nodes_on_item_listing_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listing_nodes_on_item_listing_id ON public.listing_nodes USING btree (item_listing_id);


--
-- Name: index_listing_nodes_on_item_listing_node_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listing_nodes_on_item_listing_node_id ON public.listing_nodes USING btree (item_listing_node_id);


--
-- Name: index_listing_nodes_on_listing_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listing_nodes_on_listing_id ON public.listing_nodes USING btree (listing_id);


--
-- Name: index_listing_nodes_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listing_nodes_on_name ON public.listing_nodes USING btree (name);


--
-- Name: index_listing_nodes_on_nature; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listing_nodes_on_nature ON public.listing_nodes USING btree (nature);


--
-- Name: index_listing_nodes_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listing_nodes_on_parent_id ON public.listing_nodes USING btree (parent_id);


--
-- Name: index_listing_nodes_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listing_nodes_on_updated_at ON public.listing_nodes USING btree (updated_at);


--
-- Name: index_listing_nodes_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listing_nodes_on_updater_id ON public.listing_nodes USING btree (updater_id);


--
-- Name: index_listings_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listings_on_created_at ON public.listings USING btree (created_at);


--
-- Name: index_listings_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listings_on_creator_id ON public.listings USING btree (creator_id);


--
-- Name: index_listings_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listings_on_name ON public.listings USING btree (name);


--
-- Name: index_listings_on_root_model; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listings_on_root_model ON public.listings USING btree (root_model);


--
-- Name: index_listings_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listings_on_updated_at ON public.listings USING btree (updated_at);


--
-- Name: index_listings_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listings_on_updater_id ON public.listings USING btree (updater_id);


--
-- Name: index_loan_repayments_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_repayments_on_created_at ON public.loan_repayments USING btree (created_at);


--
-- Name: index_loan_repayments_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_repayments_on_creator_id ON public.loan_repayments USING btree (creator_id);


--
-- Name: index_loan_repayments_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_repayments_on_journal_entry_id ON public.loan_repayments USING btree (journal_entry_id);


--
-- Name: index_loan_repayments_on_loan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_repayments_on_loan_id ON public.loan_repayments USING btree (loan_id);


--
-- Name: index_loan_repayments_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_repayments_on_updated_at ON public.loan_repayments USING btree (updated_at);


--
-- Name: index_loan_repayments_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_repayments_on_updater_id ON public.loan_repayments USING btree (updater_id);


--
-- Name: index_loans_on_cash_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loans_on_cash_id ON public.loans USING btree (cash_id);


--
-- Name: index_loans_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loans_on_created_at ON public.loans USING btree (created_at);


--
-- Name: index_loans_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loans_on_creator_id ON public.loans USING btree (creator_id);


--
-- Name: index_loans_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loans_on_journal_entry_id ON public.loans USING btree (journal_entry_id);


--
-- Name: index_loans_on_lender_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loans_on_lender_id ON public.loans USING btree (lender_id);


--
-- Name: index_loans_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loans_on_updated_at ON public.loans USING btree (updated_at);


--
-- Name: index_loans_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loans_on_updater_id ON public.loans USING btree (updater_id);


--
-- Name: index_locations_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_locations_on_creator_id ON public.locations USING btree (creator_id);


--
-- Name: index_locations_on_registered_postal_zone_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_locations_on_registered_postal_zone_id ON public.locations USING btree (registered_postal_zone_id);


--
-- Name: index_locations_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_locations_on_updater_id ON public.locations USING btree (updater_id);


--
-- Name: index_manure_management_plan_zones_on_activity_production_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_manure_management_plan_zones_on_activity_production_id ON public.manure_management_plan_zones USING btree (activity_production_id);


--
-- Name: index_manure_management_plan_zones_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_manure_management_plan_zones_on_created_at ON public.manure_management_plan_zones USING btree (created_at);


--
-- Name: index_manure_management_plan_zones_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_manure_management_plan_zones_on_creator_id ON public.manure_management_plan_zones USING btree (creator_id);


--
-- Name: index_manure_management_plan_zones_on_plan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_manure_management_plan_zones_on_plan_id ON public.manure_management_plan_zones USING btree (plan_id);


--
-- Name: index_manure_management_plan_zones_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_manure_management_plan_zones_on_updated_at ON public.manure_management_plan_zones USING btree (updated_at);


--
-- Name: index_manure_management_plan_zones_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_manure_management_plan_zones_on_updater_id ON public.manure_management_plan_zones USING btree (updater_id);


--
-- Name: index_manure_management_plans_on_campaign_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_manure_management_plans_on_campaign_id ON public.manure_management_plans USING btree (campaign_id);


--
-- Name: index_manure_management_plans_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_manure_management_plans_on_created_at ON public.manure_management_plans USING btree (created_at);


--
-- Name: index_manure_management_plans_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_manure_management_plans_on_creator_id ON public.manure_management_plans USING btree (creator_id);


--
-- Name: index_manure_management_plans_on_recommender_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_manure_management_plans_on_recommender_id ON public.manure_management_plans USING btree (recommender_id);


--
-- Name: index_manure_management_plans_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_manure_management_plans_on_updated_at ON public.manure_management_plans USING btree (updated_at);


--
-- Name: index_manure_management_plans_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_manure_management_plans_on_updater_id ON public.manure_management_plans USING btree (updater_id);


--
-- Name: index_map_layers_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_map_layers_on_created_at ON public.map_layers USING btree (created_at);


--
-- Name: index_map_layers_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_map_layers_on_creator_id ON public.map_layers USING btree (creator_id);


--
-- Name: index_map_layers_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_map_layers_on_name ON public.map_layers USING btree (name);


--
-- Name: index_map_layers_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_map_layers_on_updated_at ON public.map_layers USING btree (updated_at);


--
-- Name: index_map_layers_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_map_layers_on_updater_id ON public.map_layers USING btree (updater_id);


--
-- Name: index_naming_format_fields_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_naming_format_fields_on_creator_id ON public.naming_format_fields USING btree (creator_id);


--
-- Name: index_naming_format_fields_on_naming_format_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_naming_format_fields_on_naming_format_id ON public.naming_format_fields USING btree (naming_format_id);


--
-- Name: index_naming_format_fields_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_naming_format_fields_on_updater_id ON public.naming_format_fields USING btree (updater_id);


--
-- Name: index_naming_formats_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_naming_formats_on_creator_id ON public.naming_formats USING btree (creator_id);


--
-- Name: index_naming_formats_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_naming_formats_on_updater_id ON public.naming_formats USING btree (updater_id);


--
-- Name: index_net_services_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_net_services_on_created_at ON public.net_services USING btree (created_at);


--
-- Name: index_net_services_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_net_services_on_creator_id ON public.net_services USING btree (creator_id);


--
-- Name: index_net_services_on_reference_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_net_services_on_reference_name ON public.net_services USING btree (reference_name);


--
-- Name: index_net_services_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_net_services_on_updated_at ON public.net_services USING btree (updated_at);


--
-- Name: index_net_services_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_net_services_on_updater_id ON public.net_services USING btree (updater_id);


--
-- Name: index_notifications_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_created_at ON public.notifications USING btree (created_at);


--
-- Name: index_notifications_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_creator_id ON public.notifications USING btree (creator_id);


--
-- Name: index_notifications_on_level; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_level ON public.notifications USING btree (level);


--
-- Name: index_notifications_on_read_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_read_at ON public.notifications USING btree (read_at);


--
-- Name: index_notifications_on_recipient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_recipient_id ON public.notifications USING btree (recipient_id);


--
-- Name: index_notifications_on_target_type_and_target_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_target_type_and_target_id ON public.notifications USING btree (target_type, target_id);


--
-- Name: index_notifications_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_updated_at ON public.notifications USING btree (updated_at);


--
-- Name: index_notifications_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_updater_id ON public.notifications USING btree (updater_id);


--
-- Name: index_observations_on_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_observations_on_author_id ON public.observations USING btree (author_id);


--
-- Name: index_observations_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_observations_on_created_at ON public.observations USING btree (created_at);


--
-- Name: index_observations_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_observations_on_creator_id ON public.observations USING btree (creator_id);


--
-- Name: index_observations_on_subject_type_and_subject_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_observations_on_subject_type_and_subject_id ON public.observations USING btree (subject_type, subject_id);


--
-- Name: index_observations_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_observations_on_updated_at ON public.observations USING btree (updated_at);


--
-- Name: index_observations_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_observations_on_updater_id ON public.observations USING btree (updater_id);


--
-- Name: index_on_cvi_cadastral_plant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_on_cvi_cadastral_plant_id ON public.cvi_cadastral_plant_cvi_land_parcels USING btree (cvi_cadastral_plant_id);


--
-- Name: index_on_cvi_land_parcel_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_on_cvi_land_parcel_id ON public.cvi_cadastral_plant_cvi_land_parcels USING btree (cvi_land_parcel_id);


--
-- Name: index_outgoing_payment_lists_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payment_lists_on_creator_id ON public.outgoing_payment_lists USING btree (creator_id);


--
-- Name: index_outgoing_payment_lists_on_mode_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payment_lists_on_mode_id ON public.outgoing_payment_lists USING btree (mode_id);


--
-- Name: index_outgoing_payment_lists_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payment_lists_on_updater_id ON public.outgoing_payment_lists USING btree (updater_id);


--
-- Name: index_outgoing_payment_modes_on_cash_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payment_modes_on_cash_id ON public.outgoing_payment_modes USING btree (cash_id);


--
-- Name: index_outgoing_payment_modes_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payment_modes_on_created_at ON public.outgoing_payment_modes USING btree (created_at);


--
-- Name: index_outgoing_payment_modes_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payment_modes_on_creator_id ON public.outgoing_payment_modes USING btree (creator_id);


--
-- Name: index_outgoing_payment_modes_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payment_modes_on_updated_at ON public.outgoing_payment_modes USING btree (updated_at);


--
-- Name: index_outgoing_payment_modes_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payment_modes_on_updater_id ON public.outgoing_payment_modes USING btree (updater_id);


--
-- Name: index_outgoing_payments_on_affair_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payments_on_affair_id ON public.outgoing_payments USING btree (affair_id);


--
-- Name: index_outgoing_payments_on_cash_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payments_on_cash_id ON public.outgoing_payments USING btree (cash_id);


--
-- Name: index_outgoing_payments_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payments_on_created_at ON public.outgoing_payments USING btree (created_at);


--
-- Name: index_outgoing_payments_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payments_on_creator_id ON public.outgoing_payments USING btree (creator_id);


--
-- Name: index_outgoing_payments_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payments_on_journal_entry_id ON public.outgoing_payments USING btree (journal_entry_id);


--
-- Name: index_outgoing_payments_on_mode_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payments_on_mode_id ON public.outgoing_payments USING btree (mode_id);


--
-- Name: index_outgoing_payments_on_payee_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payments_on_payee_id ON public.outgoing_payments USING btree (payee_id);


--
-- Name: index_outgoing_payments_on_responsible_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payments_on_responsible_id ON public.outgoing_payments USING btree (responsible_id);


--
-- Name: index_outgoing_payments_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payments_on_updated_at ON public.outgoing_payments USING btree (updated_at);


--
-- Name: index_outgoing_payments_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payments_on_updater_id ON public.outgoing_payments USING btree (updater_id);


--
-- Name: index_parcel_item_storings_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_item_storings_on_created_at ON public.parcel_item_storings USING btree (created_at);


--
-- Name: index_parcel_item_storings_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_item_storings_on_creator_id ON public.parcel_item_storings USING btree (creator_id);


--
-- Name: index_parcel_item_storings_on_parcel_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_item_storings_on_parcel_item_id ON public.parcel_item_storings USING btree (parcel_item_id);


--
-- Name: index_parcel_item_storings_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_item_storings_on_product_id ON public.parcel_item_storings USING btree (product_id);


--
-- Name: index_parcel_item_storings_on_storage_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_item_storings_on_storage_id ON public.parcel_item_storings USING btree (storage_id);


--
-- Name: index_parcel_item_storings_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_item_storings_on_updated_at ON public.parcel_item_storings USING btree (updated_at);


--
-- Name: index_parcel_item_storings_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_item_storings_on_updater_id ON public.parcel_item_storings USING btree (updater_id);


--
-- Name: index_parcel_items_on_analysis_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_analysis_id ON public.parcel_items USING btree (analysis_id);


--
-- Name: index_parcel_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_created_at ON public.parcel_items USING btree (created_at);


--
-- Name: index_parcel_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_creator_id ON public.parcel_items USING btree (creator_id);


--
-- Name: index_parcel_items_on_delivery_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_delivery_id ON public.parcel_items USING btree (delivery_id);


--
-- Name: index_parcel_items_on_parcel_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_parcel_id ON public.parcel_items USING btree (parcel_id);


--
-- Name: index_parcel_items_on_product_enjoyment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_product_enjoyment_id ON public.parcel_items USING btree (product_enjoyment_id);


--
-- Name: index_parcel_items_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_product_id ON public.parcel_items USING btree (product_id);


--
-- Name: index_parcel_items_on_product_localization_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_product_localization_id ON public.parcel_items USING btree (product_localization_id);


--
-- Name: index_parcel_items_on_product_movement_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_product_movement_id ON public.parcel_items USING btree (product_movement_id);


--
-- Name: index_parcel_items_on_product_ownership_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_product_ownership_id ON public.parcel_items USING btree (product_ownership_id);


--
-- Name: index_parcel_items_on_project_budget_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_project_budget_id ON public.parcel_items USING btree (project_budget_id);


--
-- Name: index_parcel_items_on_purchase_invoice_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_purchase_invoice_item_id ON public.parcel_items USING btree (purchase_invoice_item_id);


--
-- Name: index_parcel_items_on_sale_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_sale_item_id ON public.parcel_items USING btree (sale_item_id);


--
-- Name: index_parcel_items_on_source_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_source_product_id ON public.parcel_items USING btree (source_product_id);


--
-- Name: index_parcel_items_on_source_product_movement_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_source_product_movement_id ON public.parcel_items USING btree (source_product_movement_id);


--
-- Name: index_parcel_items_on_transporter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_transporter_id ON public.parcel_items USING btree (transporter_id);


--
-- Name: index_parcel_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_updated_at ON public.parcel_items USING btree (updated_at);


--
-- Name: index_parcel_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_updater_id ON public.parcel_items USING btree (updater_id);


--
-- Name: index_parcel_items_on_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_variant_id ON public.parcel_items USING btree (variant_id);


--
-- Name: index_parcels_on_address_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_address_id ON public.parcels USING btree (address_id);


--
-- Name: index_parcels_on_contract_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_contract_id ON public.parcels USING btree (contract_id);


--
-- Name: index_parcels_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_created_at ON public.parcels USING btree (created_at);


--
-- Name: index_parcels_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_creator_id ON public.parcels USING btree (creator_id);


--
-- Name: index_parcels_on_delivery_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_delivery_id ON public.parcels USING btree (delivery_id);


--
-- Name: index_parcels_on_intervention_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_intervention_id ON public.parcels USING btree (intervention_id);


--
-- Name: index_parcels_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_journal_entry_id ON public.parcels USING btree (journal_entry_id);


--
-- Name: index_parcels_on_nature; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_nature ON public.parcels USING btree (nature);


--
-- Name: index_parcels_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_parcels_on_number ON public.parcels USING btree (number);


--
-- Name: index_parcels_on_purchase_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_purchase_id ON public.parcels USING btree (purchase_id);


--
-- Name: index_parcels_on_recipient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_recipient_id ON public.parcels USING btree (recipient_id);


--
-- Name: index_parcels_on_responsible_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_responsible_id ON public.parcels USING btree (responsible_id);


--
-- Name: index_parcels_on_sale_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_sale_id ON public.parcels USING btree (sale_id);


--
-- Name: index_parcels_on_sale_nature_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_sale_nature_id ON public.parcels USING btree (sale_nature_id);


--
-- Name: index_parcels_on_sender_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_sender_id ON public.parcels USING btree (sender_id);


--
-- Name: index_parcels_on_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_state ON public.parcels USING btree (state);


--
-- Name: index_parcels_on_storage_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_storage_id ON public.parcels USING btree (storage_id);


--
-- Name: index_parcels_on_transporter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_transporter_id ON public.parcels USING btree (transporter_id);


--
-- Name: index_parcels_on_undelivered_invoice_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_undelivered_invoice_journal_entry_id ON public.parcels USING btree (undelivered_invoice_journal_entry_id);


--
-- Name: index_parcels_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_updated_at ON public.parcels USING btree (updated_at);


--
-- Name: index_parcels_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_updater_id ON public.parcels USING btree (updater_id);


--
-- Name: index_payslip_natures_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payslip_natures_on_account_id ON public.payslip_natures USING btree (account_id);


--
-- Name: index_payslip_natures_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payslip_natures_on_created_at ON public.payslip_natures USING btree (created_at);


--
-- Name: index_payslip_natures_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payslip_natures_on_creator_id ON public.payslip_natures USING btree (creator_id);


--
-- Name: index_payslip_natures_on_journal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payslip_natures_on_journal_id ON public.payslip_natures USING btree (journal_id);


--
-- Name: index_payslip_natures_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_payslip_natures_on_name ON public.payslip_natures USING btree (name);


--
-- Name: index_payslip_natures_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payslip_natures_on_updated_at ON public.payslip_natures USING btree (updated_at);


--
-- Name: index_payslip_natures_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payslip_natures_on_updater_id ON public.payslip_natures USING btree (updater_id);


--
-- Name: index_payslips_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payslips_on_account_id ON public.payslips USING btree (account_id);


--
-- Name: index_payslips_on_affair_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payslips_on_affair_id ON public.payslips USING btree (affair_id);


--
-- Name: index_payslips_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payslips_on_created_at ON public.payslips USING btree (created_at);


--
-- Name: index_payslips_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payslips_on_creator_id ON public.payslips USING btree (creator_id);


--
-- Name: index_payslips_on_employee_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payslips_on_employee_id ON public.payslips USING btree (employee_id);


--
-- Name: index_payslips_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payslips_on_journal_entry_id ON public.payslips USING btree (journal_entry_id);


--
-- Name: index_payslips_on_nature_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payslips_on_nature_id ON public.payslips USING btree (nature_id);


--
-- Name: index_payslips_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payslips_on_number ON public.payslips USING btree (number);


--
-- Name: index_payslips_on_started_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payslips_on_started_on ON public.payslips USING btree (started_on);


--
-- Name: index_payslips_on_stopped_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payslips_on_stopped_on ON public.payslips USING btree (stopped_on);


--
-- Name: index_payslips_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payslips_on_updated_at ON public.payslips USING btree (updated_at);


--
-- Name: index_payslips_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payslips_on_updater_id ON public.payslips USING btree (updater_id);


--
-- Name: index_planning_scenario_activities_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_planning_scenario_activities_on_activity_id ON public.planning_scenario_activities USING btree (activity_id);


--
-- Name: index_planning_scenario_activities_on_planning_scenario_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_planning_scenario_activities_on_planning_scenario_id ON public.planning_scenario_activities USING btree (planning_scenario_id);


--
-- Name: index_planning_scenarios_on_campaign_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_planning_scenarios_on_campaign_id ON public.planning_scenarios USING btree (campaign_id);


--
-- Name: index_plant_counting_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_counting_items_on_created_at ON public.plant_counting_items USING btree (created_at);


--
-- Name: index_plant_counting_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_counting_items_on_creator_id ON public.plant_counting_items USING btree (creator_id);


--
-- Name: index_plant_counting_items_on_plant_counting_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_counting_items_on_plant_counting_id ON public.plant_counting_items USING btree (plant_counting_id);


--
-- Name: index_plant_counting_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_counting_items_on_updated_at ON public.plant_counting_items USING btree (updated_at);


--
-- Name: index_plant_counting_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_counting_items_on_updater_id ON public.plant_counting_items USING btree (updater_id);


--
-- Name: index_plant_countings_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_countings_on_created_at ON public.plant_countings USING btree (created_at);


--
-- Name: index_plant_countings_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_countings_on_creator_id ON public.plant_countings USING btree (creator_id);


--
-- Name: index_plant_countings_on_plant_density_abacus_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_countings_on_plant_density_abacus_id ON public.plant_countings USING btree (plant_density_abacus_id);


--
-- Name: index_plant_countings_on_plant_density_abacus_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_countings_on_plant_density_abacus_item_id ON public.plant_countings USING btree (plant_density_abacus_item_id);


--
-- Name: index_plant_countings_on_plant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_countings_on_plant_id ON public.plant_countings USING btree (plant_id);


--
-- Name: index_plant_countings_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_countings_on_updated_at ON public.plant_countings USING btree (updated_at);


--
-- Name: index_plant_countings_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_countings_on_updater_id ON public.plant_countings USING btree (updater_id);


--
-- Name: index_plant_density_abaci_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_density_abaci_on_created_at ON public.plant_density_abaci USING btree (created_at);


--
-- Name: index_plant_density_abaci_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_density_abaci_on_creator_id ON public.plant_density_abaci USING btree (creator_id);


--
-- Name: index_plant_density_abaci_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_plant_density_abaci_on_name ON public.plant_density_abaci USING btree (name);


--
-- Name: index_plant_density_abaci_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_density_abaci_on_updated_at ON public.plant_density_abaci USING btree (updated_at);


--
-- Name: index_plant_density_abaci_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_density_abaci_on_updater_id ON public.plant_density_abaci USING btree (updater_id);


--
-- Name: index_plant_density_abacus_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_density_abacus_items_on_created_at ON public.plant_density_abacus_items USING btree (created_at);


--
-- Name: index_plant_density_abacus_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_density_abacus_items_on_creator_id ON public.plant_density_abacus_items USING btree (creator_id);


--
-- Name: index_plant_density_abacus_items_on_plant_density_abacus_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_density_abacus_items_on_plant_density_abacus_id ON public.plant_density_abacus_items USING btree (plant_density_abacus_id);


--
-- Name: index_plant_density_abacus_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_density_abacus_items_on_updated_at ON public.plant_density_abacus_items USING btree (updated_at);


--
-- Name: index_plant_density_abacus_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_density_abacus_items_on_updater_id ON public.plant_density_abacus_items USING btree (updater_id);


--
-- Name: index_pnc_on_financial_asset_allocation_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pnc_on_financial_asset_allocation_account_id ON public.product_nature_categories USING btree (fixed_asset_allocation_account_id);


--
-- Name: index_pnc_on_financial_asset_expenses_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pnc_on_financial_asset_expenses_account_id ON public.product_nature_categories USING btree (fixed_asset_expenses_account_id);


--
-- Name: index_postal_zones_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_postal_zones_on_created_at ON public.postal_zones USING btree (created_at);


--
-- Name: index_postal_zones_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_postal_zones_on_creator_id ON public.postal_zones USING btree (creator_id);


--
-- Name: index_postal_zones_on_district_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_postal_zones_on_district_id ON public.postal_zones USING btree (district_id);


--
-- Name: index_postal_zones_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_postal_zones_on_updated_at ON public.postal_zones USING btree (updated_at);


--
-- Name: index_postal_zones_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_postal_zones_on_updater_id ON public.postal_zones USING btree (updater_id);


--
-- Name: index_preferences_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_preferences_on_created_at ON public.preferences USING btree (created_at);


--
-- Name: index_preferences_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_preferences_on_creator_id ON public.preferences USING btree (creator_id);


--
-- Name: index_preferences_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_preferences_on_name ON public.preferences USING btree (name);


--
-- Name: index_preferences_on_record_value_type_and_record_value_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_preferences_on_record_value_type_and_record_value_id ON public.preferences USING btree (record_value_type, record_value_id);


--
-- Name: index_preferences_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_preferences_on_updated_at ON public.preferences USING btree (updated_at);


--
-- Name: index_preferences_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_preferences_on_updater_id ON public.preferences USING btree (updater_id);


--
-- Name: index_preferences_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_preferences_on_user_id ON public.preferences USING btree (user_id);


--
-- Name: index_preferences_on_user_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_preferences_on_user_id_and_name ON public.preferences USING btree (user_id, name);


--
-- Name: index_prescriptions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_prescriptions_on_created_at ON public.prescriptions USING btree (created_at);


--
-- Name: index_prescriptions_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_prescriptions_on_creator_id ON public.prescriptions USING btree (creator_id);


--
-- Name: index_prescriptions_on_delivered_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_prescriptions_on_delivered_at ON public.prescriptions USING btree (delivered_at);


--
-- Name: index_prescriptions_on_prescriptor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_prescriptions_on_prescriptor_id ON public.prescriptions USING btree (prescriptor_id);


--
-- Name: index_prescriptions_on_reference_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_prescriptions_on_reference_number ON public.prescriptions USING btree (reference_number);


--
-- Name: index_prescriptions_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_prescriptions_on_updated_at ON public.prescriptions USING btree (updated_at);


--
-- Name: index_prescriptions_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_prescriptions_on_updater_id ON public.prescriptions USING btree (updater_id);


--
-- Name: index_product_enjoyments_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_enjoyments_on_created_at ON public.product_enjoyments USING btree (created_at);


--
-- Name: index_product_enjoyments_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_enjoyments_on_creator_id ON public.product_enjoyments USING btree (creator_id);


--
-- Name: index_product_enjoyments_on_enjoyer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_enjoyments_on_enjoyer_id ON public.product_enjoyments USING btree (enjoyer_id);


--
-- Name: index_product_enjoyments_on_intervention_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_enjoyments_on_intervention_id ON public.product_enjoyments USING btree (intervention_id);


--
-- Name: index_product_enjoyments_on_originator_type_and_originator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_enjoyments_on_originator_type_and_originator_id ON public.product_enjoyments USING btree (originator_type, originator_id);


--
-- Name: index_product_enjoyments_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_enjoyments_on_product_id ON public.product_enjoyments USING btree (product_id);


--
-- Name: index_product_enjoyments_on_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_enjoyments_on_started_at ON public.product_enjoyments USING btree (started_at);


--
-- Name: index_product_enjoyments_on_stopped_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_enjoyments_on_stopped_at ON public.product_enjoyments USING btree (stopped_at);


--
-- Name: index_product_enjoyments_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_enjoyments_on_updated_at ON public.product_enjoyments USING btree (updated_at);


--
-- Name: index_product_enjoyments_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_enjoyments_on_updater_id ON public.product_enjoyments USING btree (updater_id);


--
-- Name: index_product_labellings_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_labellings_on_created_at ON public.product_labellings USING btree (created_at);


--
-- Name: index_product_labellings_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_labellings_on_creator_id ON public.product_labellings USING btree (creator_id);


--
-- Name: index_product_labellings_on_label_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_labellings_on_label_id ON public.product_labellings USING btree (label_id);


--
-- Name: index_product_labellings_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_labellings_on_product_id ON public.product_labellings USING btree (product_id);


--
-- Name: index_product_labellings_on_product_id_and_label_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_product_labellings_on_product_id_and_label_id ON public.product_labellings USING btree (product_id, label_id);


--
-- Name: index_product_labellings_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_labellings_on_updated_at ON public.product_labellings USING btree (updated_at);


--
-- Name: index_product_labellings_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_labellings_on_updater_id ON public.product_labellings USING btree (updater_id);


--
-- Name: index_product_linkages_on_carried_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_linkages_on_carried_id ON public.product_linkages USING btree (carried_id);


--
-- Name: index_product_linkages_on_carrier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_linkages_on_carrier_id ON public.product_linkages USING btree (carrier_id);


--
-- Name: index_product_linkages_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_linkages_on_created_at ON public.product_linkages USING btree (created_at);


--
-- Name: index_product_linkages_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_linkages_on_creator_id ON public.product_linkages USING btree (creator_id);


--
-- Name: index_product_linkages_on_intervention_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_linkages_on_intervention_id ON public.product_linkages USING btree (intervention_id);


--
-- Name: index_product_linkages_on_originator_type_and_originator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_linkages_on_originator_type_and_originator_id ON public.product_linkages USING btree (originator_type, originator_id);


--
-- Name: index_product_linkages_on_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_linkages_on_started_at ON public.product_linkages USING btree (started_at);


--
-- Name: index_product_linkages_on_stopped_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_linkages_on_stopped_at ON public.product_linkages USING btree (stopped_at);


--
-- Name: index_product_linkages_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_linkages_on_updated_at ON public.product_linkages USING btree (updated_at);


--
-- Name: index_product_linkages_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_linkages_on_updater_id ON public.product_linkages USING btree (updater_id);


--
-- Name: index_product_links_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_links_on_created_at ON public.product_links USING btree (created_at);


--
-- Name: index_product_links_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_links_on_creator_id ON public.product_links USING btree (creator_id);


--
-- Name: index_product_links_on_intervention_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_links_on_intervention_id ON public.product_links USING btree (intervention_id);


--
-- Name: index_product_links_on_linked_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_links_on_linked_id ON public.product_links USING btree (linked_id);


--
-- Name: index_product_links_on_originator_type_and_originator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_links_on_originator_type_and_originator_id ON public.product_links USING btree (originator_type, originator_id);


--
-- Name: index_product_links_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_links_on_product_id ON public.product_links USING btree (product_id);


--
-- Name: index_product_links_on_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_links_on_started_at ON public.product_links USING btree (started_at);


--
-- Name: index_product_links_on_stopped_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_links_on_stopped_at ON public.product_links USING btree (stopped_at);


--
-- Name: index_product_links_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_links_on_updated_at ON public.product_links USING btree (updated_at);


--
-- Name: index_product_links_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_links_on_updater_id ON public.product_links USING btree (updater_id);


--
-- Name: index_product_localizations_on_container_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_localizations_on_container_id ON public.product_localizations USING btree (container_id);


--
-- Name: index_product_localizations_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_localizations_on_created_at ON public.product_localizations USING btree (created_at);


--
-- Name: index_product_localizations_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_localizations_on_creator_id ON public.product_localizations USING btree (creator_id);


--
-- Name: index_product_localizations_on_intervention_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_localizations_on_intervention_id ON public.product_localizations USING btree (intervention_id);


--
-- Name: index_product_localizations_on_originator; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_localizations_on_originator ON public.product_localizations USING btree (originator_id, originator_type);


--
-- Name: index_product_localizations_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_localizations_on_product_id ON public.product_localizations USING btree (product_id);


--
-- Name: index_product_localizations_on_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_localizations_on_started_at ON public.product_localizations USING btree (started_at);


--
-- Name: index_product_localizations_on_stopped_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_localizations_on_stopped_at ON public.product_localizations USING btree (stopped_at);


--
-- Name: index_product_localizations_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_localizations_on_updated_at ON public.product_localizations USING btree (updated_at);


--
-- Name: index_product_localizations_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_localizations_on_updater_id ON public.product_localizations USING btree (updater_id);


--
-- Name: index_product_memberships_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_memberships_on_created_at ON public.product_memberships USING btree (created_at);


--
-- Name: index_product_memberships_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_memberships_on_creator_id ON public.product_memberships USING btree (creator_id);


--
-- Name: index_product_memberships_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_memberships_on_group_id ON public.product_memberships USING btree (group_id);


--
-- Name: index_product_memberships_on_intervention_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_memberships_on_intervention_id ON public.product_memberships USING btree (intervention_id);


--
-- Name: index_product_memberships_on_member_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_memberships_on_member_id ON public.product_memberships USING btree (member_id);


--
-- Name: index_product_memberships_on_originator_type_and_originator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_memberships_on_originator_type_and_originator_id ON public.product_memberships USING btree (originator_type, originator_id);


--
-- Name: index_product_memberships_on_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_memberships_on_started_at ON public.product_memberships USING btree (started_at);


--
-- Name: index_product_memberships_on_stopped_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_memberships_on_stopped_at ON public.product_memberships USING btree (stopped_at);


--
-- Name: index_product_memberships_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_memberships_on_updated_at ON public.product_memberships USING btree (updated_at);


--
-- Name: index_product_memberships_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_memberships_on_updater_id ON public.product_memberships USING btree (updater_id);


--
-- Name: index_product_movements_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_movements_on_created_at ON public.product_movements USING btree (created_at);


--
-- Name: index_product_movements_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_movements_on_creator_id ON public.product_movements USING btree (creator_id);


--
-- Name: index_product_movements_on_intervention_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_movements_on_intervention_id ON public.product_movements USING btree (intervention_id);


--
-- Name: index_product_movements_on_originator_type_and_originator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_movements_on_originator_type_and_originator_id ON public.product_movements USING btree (originator_type, originator_id);


--
-- Name: index_product_movements_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_movements_on_product_id ON public.product_movements USING btree (product_id);


--
-- Name: index_product_movements_on_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_movements_on_started_at ON public.product_movements USING btree (started_at);


--
-- Name: index_product_movements_on_stopped_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_movements_on_stopped_at ON public.product_movements USING btree (stopped_at);


--
-- Name: index_product_movements_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_movements_on_updated_at ON public.product_movements USING btree (updated_at);


--
-- Name: index_product_movements_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_movements_on_updater_id ON public.product_movements USING btree (updater_id);


--
-- Name: index_product_nature_categories_on_charge_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_categories_on_charge_account_id ON public.product_nature_categories USING btree (charge_account_id);


--
-- Name: index_product_nature_categories_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_categories_on_created_at ON public.product_nature_categories USING btree (created_at);


--
-- Name: index_product_nature_categories_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_categories_on_creator_id ON public.product_nature_categories USING btree (creator_id);


--
-- Name: index_product_nature_categories_on_fixed_asset_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_categories_on_fixed_asset_account_id ON public.product_nature_categories USING btree (fixed_asset_account_id);


--
-- Name: index_product_nature_categories_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_categories_on_name ON public.product_nature_categories USING btree (name);


--
-- Name: index_product_nature_categories_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_product_nature_categories_on_number ON public.product_nature_categories USING btree (number);


--
-- Name: index_product_nature_categories_on_product_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_categories_on_product_account_id ON public.product_nature_categories USING btree (product_account_id);


--
-- Name: index_product_nature_categories_on_stock_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_categories_on_stock_account_id ON public.product_nature_categories USING btree (stock_account_id);


--
-- Name: index_product_nature_categories_on_stock_movement_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_categories_on_stock_movement_account_id ON public.product_nature_categories USING btree (stock_movement_account_id);


--
-- Name: index_product_nature_categories_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_categories_on_updated_at ON public.product_nature_categories USING btree (updated_at);


--
-- Name: index_product_nature_categories_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_categories_on_updater_id ON public.product_nature_categories USING btree (updater_id);


--
-- Name: index_product_nature_category_taxations_on_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_category_taxations_on_category_id ON public.product_nature_category_taxations USING btree (product_nature_category_id);


--
-- Name: index_product_nature_category_taxations_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_category_taxations_on_created_at ON public.product_nature_category_taxations USING btree (created_at);


--
-- Name: index_product_nature_category_taxations_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_category_taxations_on_creator_id ON public.product_nature_category_taxations USING btree (creator_id);


--
-- Name: index_product_nature_category_taxations_on_tax_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_category_taxations_on_tax_id ON public.product_nature_category_taxations USING btree (tax_id);


--
-- Name: index_product_nature_category_taxations_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_category_taxations_on_updated_at ON public.product_nature_category_taxations USING btree (updated_at);


--
-- Name: index_product_nature_category_taxations_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_category_taxations_on_updater_id ON public.product_nature_category_taxations USING btree (updater_id);


--
-- Name: index_product_nature_category_taxations_on_usage; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_category_taxations_on_usage ON public.product_nature_category_taxations USING btree (usage);


--
-- Name: index_product_nature_variant_components_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variant_components_on_created_at ON public.product_nature_variant_components USING btree (created_at);


--
-- Name: index_product_nature_variant_components_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variant_components_on_creator_id ON public.product_nature_variant_components USING btree (creator_id);


--
-- Name: index_product_nature_variant_components_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variant_components_on_deleted_at ON public.product_nature_variant_components USING btree (deleted_at);


--
-- Name: index_product_nature_variant_components_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variant_components_on_parent_id ON public.product_nature_variant_components USING btree (parent_id);


--
-- Name: index_product_nature_variant_components_on_part_variant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variant_components_on_part_variant ON public.product_nature_variant_components USING btree (part_product_nature_variant_id);


--
-- Name: index_product_nature_variant_components_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variant_components_on_updated_at ON public.product_nature_variant_components USING btree (updated_at);


--
-- Name: index_product_nature_variant_components_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variant_components_on_updater_id ON public.product_nature_variant_components USING btree (updater_id);


--
-- Name: index_product_nature_variant_components_on_variant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variant_components_on_variant ON public.product_nature_variant_components USING btree (product_nature_variant_id);


--
-- Name: index_product_nature_variant_name_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_product_nature_variant_name_unique ON public.product_nature_variant_components USING btree (name, product_nature_variant_id);


--
-- Name: index_product_nature_variant_readings_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variant_readings_on_created_at ON public.product_nature_variant_readings USING btree (created_at);


--
-- Name: index_product_nature_variant_readings_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variant_readings_on_creator_id ON public.product_nature_variant_readings USING btree (creator_id);


--
-- Name: index_product_nature_variant_readings_on_indicator_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variant_readings_on_indicator_name ON public.product_nature_variant_readings USING btree (indicator_name);


--
-- Name: index_product_nature_variant_readings_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variant_readings_on_updated_at ON public.product_nature_variant_readings USING btree (updated_at);


--
-- Name: index_product_nature_variant_readings_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variant_readings_on_updater_id ON public.product_nature_variant_readings USING btree (updater_id);


--
-- Name: index_product_nature_variant_readings_on_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variant_readings_on_variant_id ON public.product_nature_variant_readings USING btree (variant_id);


--
-- Name: index_product_nature_variants_on_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variants_on_category_id ON public.product_nature_variants USING btree (category_id);


--
-- Name: index_product_nature_variants_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variants_on_created_at ON public.product_nature_variants USING btree (created_at);


--
-- Name: index_product_nature_variants_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variants_on_creator_id ON public.product_nature_variants USING btree (creator_id);


--
-- Name: index_product_nature_variants_on_nature_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variants_on_nature_id ON public.product_nature_variants USING btree (nature_id);


--
-- Name: index_product_nature_variants_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_product_nature_variants_on_number ON public.product_nature_variants USING btree (number);


--
-- Name: index_product_nature_variants_on_stock_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variants_on_stock_account_id ON public.product_nature_variants USING btree (stock_account_id);


--
-- Name: index_product_nature_variants_on_stock_movement_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variants_on_stock_movement_account_id ON public.product_nature_variants USING btree (stock_movement_account_id);


--
-- Name: index_product_nature_variants_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variants_on_updated_at ON public.product_nature_variants USING btree (updated_at);


--
-- Name: index_product_nature_variants_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variants_on_updater_id ON public.product_nature_variants USING btree (updater_id);


--
-- Name: index_product_natures_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_natures_on_created_at ON public.product_natures USING btree (created_at);


--
-- Name: index_product_natures_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_natures_on_creator_id ON public.product_natures USING btree (creator_id);


--
-- Name: index_product_natures_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_natures_on_name ON public.product_natures USING btree (name);


--
-- Name: index_product_natures_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_product_natures_on_number ON public.product_natures USING btree (number);


--
-- Name: index_product_natures_on_subscription_nature_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_natures_on_subscription_nature_id ON public.product_natures USING btree (subscription_nature_id);


--
-- Name: index_product_natures_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_natures_on_updated_at ON public.product_natures USING btree (updated_at);


--
-- Name: index_product_natures_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_natures_on_updater_id ON public.product_natures USING btree (updater_id);


--
-- Name: index_product_ownerships_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_ownerships_on_created_at ON public.product_ownerships USING btree (created_at);


--
-- Name: index_product_ownerships_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_ownerships_on_creator_id ON public.product_ownerships USING btree (creator_id);


--
-- Name: index_product_ownerships_on_intervention_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_ownerships_on_intervention_id ON public.product_ownerships USING btree (intervention_id);


--
-- Name: index_product_ownerships_on_originator_type_and_originator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_ownerships_on_originator_type_and_originator_id ON public.product_ownerships USING btree (originator_type, originator_id);


--
-- Name: index_product_ownerships_on_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_ownerships_on_owner_id ON public.product_ownerships USING btree (owner_id);


--
-- Name: index_product_ownerships_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_ownerships_on_product_id ON public.product_ownerships USING btree (product_id);


--
-- Name: index_product_ownerships_on_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_ownerships_on_started_at ON public.product_ownerships USING btree (started_at);


--
-- Name: index_product_ownerships_on_stopped_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_ownerships_on_stopped_at ON public.product_ownerships USING btree (stopped_at);


--
-- Name: index_product_ownerships_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_ownerships_on_updated_at ON public.product_ownerships USING btree (updated_at);


--
-- Name: index_product_ownerships_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_ownerships_on_updater_id ON public.product_ownerships USING btree (updater_id);


--
-- Name: index_product_phases_on_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_phases_on_category_id ON public.product_phases USING btree (category_id);


--
-- Name: index_product_phases_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_phases_on_created_at ON public.product_phases USING btree (created_at);


--
-- Name: index_product_phases_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_phases_on_creator_id ON public.product_phases USING btree (creator_id);


--
-- Name: index_product_phases_on_intervention_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_phases_on_intervention_id ON public.product_phases USING btree (intervention_id);


--
-- Name: index_product_phases_on_nature_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_phases_on_nature_id ON public.product_phases USING btree (nature_id);


--
-- Name: index_product_phases_on_originator_type_and_originator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_phases_on_originator_type_and_originator_id ON public.product_phases USING btree (originator_type, originator_id);


--
-- Name: index_product_phases_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_phases_on_product_id ON public.product_phases USING btree (product_id);


--
-- Name: index_product_phases_on_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_phases_on_started_at ON public.product_phases USING btree (started_at);


--
-- Name: index_product_phases_on_stopped_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_phases_on_stopped_at ON public.product_phases USING btree (stopped_at);


--
-- Name: index_product_phases_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_phases_on_updated_at ON public.product_phases USING btree (updated_at);


--
-- Name: index_product_phases_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_phases_on_updater_id ON public.product_phases USING btree (updater_id);


--
-- Name: index_product_phases_on_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_phases_on_variant_id ON public.product_phases USING btree (variant_id);


--
-- Name: index_product_readings_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_readings_on_created_at ON public.product_readings USING btree (created_at);


--
-- Name: index_product_readings_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_readings_on_creator_id ON public.product_readings USING btree (creator_id);


--
-- Name: index_product_readings_on_indicator_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_readings_on_indicator_name ON public.product_readings USING btree (indicator_name);


--
-- Name: index_product_readings_on_originator; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_readings_on_originator ON public.product_readings USING btree (originator_id, originator_type);


--
-- Name: index_product_readings_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_readings_on_product_id ON public.product_readings USING btree (product_id);


--
-- Name: index_product_readings_on_read_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_readings_on_read_at ON public.product_readings USING btree (read_at);


--
-- Name: index_product_readings_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_readings_on_updated_at ON public.product_readings USING btree (updated_at);


--
-- Name: index_product_readings_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_readings_on_updater_id ON public.product_readings USING btree (updater_id);


--
-- Name: index_products_on_activity_production_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_activity_production_id ON public.products USING btree (activity_production_id);


--
-- Name: index_products_on_address_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_address_id ON public.products USING btree (address_id);


--
-- Name: index_products_on_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_category_id ON public.products USING btree (category_id);


--
-- Name: index_products_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_created_at ON public.products USING btree (created_at);


--
-- Name: index_products_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_creator_id ON public.products USING btree (creator_id);


--
-- Name: index_products_on_default_storage_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_default_storage_id ON public.products USING btree (default_storage_id);


--
-- Name: index_products_on_fixed_asset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_fixed_asset_id ON public.products USING btree (fixed_asset_id);


--
-- Name: index_products_on_initial_container_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_initial_container_id ON public.products USING btree (initial_container_id);


--
-- Name: index_products_on_initial_enjoyer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_initial_enjoyer_id ON public.products USING btree (initial_enjoyer_id);


--
-- Name: index_products_on_initial_father_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_initial_father_id ON public.products USING btree (initial_father_id);


--
-- Name: index_products_on_initial_mother_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_initial_mother_id ON public.products USING btree (initial_mother_id);


--
-- Name: index_products_on_initial_movement_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_initial_movement_id ON public.products USING btree (initial_movement_id);


--
-- Name: index_products_on_initial_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_initial_owner_id ON public.products USING btree (initial_owner_id);


--
-- Name: index_products_on_member_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_member_variant_id ON public.products USING btree (member_variant_id);


--
-- Name: index_products_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_name ON public.products USING btree (name);


--
-- Name: index_products_on_nature_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_nature_id ON public.products USING btree (nature_id);


--
-- Name: index_products_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_products_on_number ON public.products USING btree (number);


--
-- Name: index_products_on_originator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_originator_id ON public.products USING btree (originator_id);


--
-- Name: index_products_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_parent_id ON public.products USING btree (parent_id);


--
-- Name: index_products_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_team_id ON public.products USING btree (team_id);


--
-- Name: index_products_on_tracking_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_tracking_id ON public.products USING btree (tracking_id);


--
-- Name: index_products_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_type ON public.products USING btree (type);


--
-- Name: index_products_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_updated_at ON public.products USING btree (updated_at);


--
-- Name: index_products_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_updater_id ON public.products USING btree (updater_id);


--
-- Name: index_products_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_uuid ON public.products USING btree (uuid);


--
-- Name: index_products_on_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_variant_id ON public.products USING btree (variant_id);


--
-- Name: index_products_on_variety; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_variety ON public.products USING btree (variety);


--
-- Name: index_products_on_worker_group_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_worker_group_item_id ON public.products USING btree (worker_group_item_id);


--
-- Name: index_project_budgets_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_budgets_on_creator_id ON public.project_budgets USING btree (creator_id);


--
-- Name: index_project_budgets_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_budgets_on_updater_id ON public.project_budgets USING btree (updater_id);


--
-- Name: index_purchase_items_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_items_on_account_id ON public.purchase_items USING btree (account_id);


--
-- Name: index_purchase_items_on_activity_budget_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_items_on_activity_budget_id ON public.purchase_items USING btree (activity_budget_id);


--
-- Name: index_purchase_items_on_catalog_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_items_on_catalog_item_id ON public.purchase_items USING btree (catalog_item_id);


--
-- Name: index_purchase_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_items_on_created_at ON public.purchase_items USING btree (created_at);


--
-- Name: index_purchase_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_items_on_creator_id ON public.purchase_items USING btree (creator_id);


--
-- Name: index_purchase_items_on_depreciable_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_items_on_depreciable_product_id ON public.purchase_items USING btree (depreciable_product_id);


--
-- Name: index_purchase_items_on_fixed_asset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_items_on_fixed_asset_id ON public.purchase_items USING btree (fixed_asset_id);


--
-- Name: index_purchase_items_on_project_budget_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_items_on_project_budget_id ON public.purchase_items USING btree (project_budget_id);


--
-- Name: index_purchase_items_on_purchase_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_items_on_purchase_id ON public.purchase_items USING btree (purchase_id);


--
-- Name: index_purchase_items_on_tax_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_items_on_tax_id ON public.purchase_items USING btree (tax_id);


--
-- Name: index_purchase_items_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_items_on_team_id ON public.purchase_items USING btree (team_id);


--
-- Name: index_purchase_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_items_on_updated_at ON public.purchase_items USING btree (updated_at);


--
-- Name: index_purchase_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_items_on_updater_id ON public.purchase_items USING btree (updater_id);


--
-- Name: index_purchase_items_on_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_items_on_variant_id ON public.purchase_items USING btree (variant_id);


--
-- Name: index_purchase_natures_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_natures_on_created_at ON public.purchase_natures USING btree (created_at);


--
-- Name: index_purchase_natures_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_natures_on_creator_id ON public.purchase_natures USING btree (creator_id);


--
-- Name: index_purchase_natures_on_journal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_natures_on_journal_id ON public.purchase_natures USING btree (journal_id);


--
-- Name: index_purchase_natures_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_natures_on_updated_at ON public.purchase_natures USING btree (updated_at);


--
-- Name: index_purchase_natures_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_natures_on_updater_id ON public.purchase_natures USING btree (updater_id);


--
-- Name: index_purchases_on_accounted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchases_on_accounted_at ON public.purchases USING btree (accounted_at);


--
-- Name: index_purchases_on_affair_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchases_on_affair_id ON public.purchases USING btree (affair_id);


--
-- Name: index_purchases_on_contract_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchases_on_contract_id ON public.purchases USING btree (contract_id);


--
-- Name: index_purchases_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchases_on_created_at ON public.purchases USING btree (created_at);


--
-- Name: index_purchases_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchases_on_creator_id ON public.purchases USING btree (creator_id);


--
-- Name: index_purchases_on_currency; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchases_on_currency ON public.purchases USING btree (currency);


--
-- Name: index_purchases_on_delivery_address_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchases_on_delivery_address_id ON public.purchases USING btree (delivery_address_id);


--
-- Name: index_purchases_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchases_on_journal_entry_id ON public.purchases USING btree (journal_entry_id);


--
-- Name: index_purchases_on_nature_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchases_on_nature_id ON public.purchases USING btree (nature_id);


--
-- Name: index_purchases_on_quantity_gap_on_invoice_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchases_on_quantity_gap_on_invoice_journal_entry_id ON public.purchases USING btree (quantity_gap_on_invoice_journal_entry_id);


--
-- Name: index_purchases_on_responsible_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchases_on_responsible_id ON public.purchases USING btree (responsible_id);


--
-- Name: index_purchases_on_supplier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchases_on_supplier_id ON public.purchases USING btree (supplier_id);


--
-- Name: index_purchases_on_undelivered_invoice_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchases_on_undelivered_invoice_journal_entry_id ON public.purchases USING btree (undelivered_invoice_journal_entry_id);


--
-- Name: index_purchases_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchases_on_updated_at ON public.purchases USING btree (updated_at);


--
-- Name: index_purchases_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchases_on_updater_id ON public.purchases USING btree (updater_id);


--
-- Name: index_regularizations_on_affair_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_regularizations_on_affair_id ON public.regularizations USING btree (affair_id);


--
-- Name: index_regularizations_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_regularizations_on_created_at ON public.regularizations USING btree (created_at);


--
-- Name: index_regularizations_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_regularizations_on_creator_id ON public.regularizations USING btree (creator_id);


--
-- Name: index_regularizations_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_regularizations_on_journal_entry_id ON public.regularizations USING btree (journal_entry_id);


--
-- Name: index_regularizations_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_regularizations_on_updated_at ON public.regularizations USING btree (updated_at);


--
-- Name: index_regularizations_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_regularizations_on_updater_id ON public.regularizations USING btree (updater_id);


--
-- Name: index_ride_sets_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ride_sets_on_creator_id ON public.ride_sets USING btree (creator_id);


--
-- Name: index_ride_sets_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ride_sets_on_updater_id ON public.ride_sets USING btree (updater_id);


--
-- Name: index_rides_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rides_on_creator_id ON public.rides USING btree (creator_id);


--
-- Name: index_rides_on_intervention_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rides_on_intervention_id ON public.rides USING btree (intervention_id);


--
-- Name: index_rides_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rides_on_product_id ON public.rides USING btree (product_id);


--
-- Name: index_rides_on_ride_set_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rides_on_ride_set_id ON public.rides USING btree (ride_set_id);


--
-- Name: index_rides_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rides_on_updater_id ON public.rides USING btree (updater_id);


--
-- Name: index_roles_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_created_at ON public.roles USING btree (created_at);


--
-- Name: index_roles_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_creator_id ON public.roles USING btree (creator_id);


--
-- Name: index_roles_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_updated_at ON public.roles USING btree (updated_at);


--
-- Name: index_roles_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_updater_id ON public.roles USING btree (updater_id);


--
-- Name: index_sale_items_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_items_on_account_id ON public.sale_items USING btree (account_id);


--
-- Name: index_sale_items_on_activity_budget_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_items_on_activity_budget_id ON public.sale_items USING btree (activity_budget_id);


--
-- Name: index_sale_items_on_catalog_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_items_on_catalog_item_id ON public.sale_items USING btree (catalog_item_id);


--
-- Name: index_sale_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_items_on_created_at ON public.sale_items USING btree (created_at);


--
-- Name: index_sale_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_items_on_creator_id ON public.sale_items USING btree (creator_id);


--
-- Name: index_sale_items_on_credited_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_items_on_credited_item_id ON public.sale_items USING btree (credited_item_id);


--
-- Name: index_sale_items_on_fixed_asset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_items_on_fixed_asset_id ON public.sale_items USING btree (fixed_asset_id);


--
-- Name: index_sale_items_on_sale_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_items_on_sale_id ON public.sale_items USING btree (sale_id);


--
-- Name: index_sale_items_on_shipment_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_items_on_shipment_item_id ON public.sale_items USING btree (shipment_item_id);


--
-- Name: index_sale_items_on_tax_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_items_on_tax_id ON public.sale_items USING btree (tax_id);


--
-- Name: index_sale_items_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_items_on_team_id ON public.sale_items USING btree (team_id);


--
-- Name: index_sale_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_items_on_updated_at ON public.sale_items USING btree (updated_at);


--
-- Name: index_sale_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_items_on_updater_id ON public.sale_items USING btree (updater_id);


--
-- Name: index_sale_items_on_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_items_on_variant_id ON public.sale_items USING btree (variant_id);


--
-- Name: index_sale_natures_on_catalog_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_natures_on_catalog_id ON public.sale_natures USING btree (catalog_id);


--
-- Name: index_sale_natures_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_natures_on_created_at ON public.sale_natures USING btree (created_at);


--
-- Name: index_sale_natures_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_natures_on_creator_id ON public.sale_natures USING btree (creator_id);


--
-- Name: index_sale_natures_on_journal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_natures_on_journal_id ON public.sale_natures USING btree (journal_id);


--
-- Name: index_sale_natures_on_payment_mode_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_natures_on_payment_mode_id ON public.sale_natures USING btree (payment_mode_id);


--
-- Name: index_sale_natures_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_natures_on_updated_at ON public.sale_natures USING btree (updated_at);


--
-- Name: index_sale_natures_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_natures_on_updater_id ON public.sale_natures USING btree (updater_id);


--
-- Name: index_sales_on_accounted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_accounted_at ON public.sales USING btree (accounted_at);


--
-- Name: index_sales_on_address_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_address_id ON public.sales USING btree (address_id);


--
-- Name: index_sales_on_affair_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_affair_id ON public.sales USING btree (affair_id);


--
-- Name: index_sales_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_client_id ON public.sales USING btree (client_id);


--
-- Name: index_sales_on_codes; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_codes ON public.sales USING btree (codes);


--
-- Name: index_sales_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_created_at ON public.sales USING btree (created_at);


--
-- Name: index_sales_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_creator_id ON public.sales USING btree (creator_id);


--
-- Name: index_sales_on_credited_sale_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_credited_sale_id ON public.sales USING btree (credited_sale_id);


--
-- Name: index_sales_on_currency; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_currency ON public.sales USING btree (currency);


--
-- Name: index_sales_on_delivery_address_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_delivery_address_id ON public.sales USING btree (delivery_address_id);


--
-- Name: index_sales_on_invoice_address_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_invoice_address_id ON public.sales USING btree (invoice_address_id);


--
-- Name: index_sales_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_journal_entry_id ON public.sales USING btree (journal_entry_id);


--
-- Name: index_sales_on_nature_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_nature_id ON public.sales USING btree (nature_id);


--
-- Name: index_sales_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_sales_on_number ON public.sales USING btree (number);


--
-- Name: index_sales_on_quantity_gap_on_invoice_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_quantity_gap_on_invoice_journal_entry_id ON public.sales USING btree (quantity_gap_on_invoice_journal_entry_id);


--
-- Name: index_sales_on_responsible_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_responsible_id ON public.sales USING btree (responsible_id);


--
-- Name: index_sales_on_transporter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_transporter_id ON public.sales USING btree (transporter_id);


--
-- Name: index_sales_on_undelivered_invoice_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_undelivered_invoice_journal_entry_id ON public.sales USING btree (undelivered_invoice_journal_entry_id);


--
-- Name: index_sales_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_updated_at ON public.sales USING btree (updated_at);


--
-- Name: index_sales_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_updater_id ON public.sales USING btree (updater_id);


--
-- Name: index_sensors_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sensors_on_created_at ON public.sensors USING btree (created_at);


--
-- Name: index_sensors_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sensors_on_creator_id ON public.sensors USING btree (creator_id);


--
-- Name: index_sensors_on_host_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sensors_on_host_id ON public.sensors USING btree (host_id);


--
-- Name: index_sensors_on_model_euid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sensors_on_model_euid ON public.sensors USING btree (model_euid);


--
-- Name: index_sensors_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sensors_on_name ON public.sensors USING btree (name);


--
-- Name: index_sensors_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sensors_on_product_id ON public.sensors USING btree (product_id);


--
-- Name: index_sensors_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sensors_on_updated_at ON public.sensors USING btree (updated_at);


--
-- Name: index_sensors_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sensors_on_updater_id ON public.sensors USING btree (updater_id);


--
-- Name: index_sensors_on_vendor_euid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sensors_on_vendor_euid ON public.sensors USING btree (vendor_euid);


--
-- Name: index_sequences_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sequences_on_created_at ON public.sequences USING btree (created_at);


--
-- Name: index_sequences_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sequences_on_creator_id ON public.sequences USING btree (creator_id);


--
-- Name: index_sequences_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sequences_on_updated_at ON public.sequences USING btree (updated_at);


--
-- Name: index_sequences_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sequences_on_updater_id ON public.sequences USING btree (updater_id);


--
-- Name: index_subscription_natures_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscription_natures_on_created_at ON public.subscription_natures USING btree (created_at);


--
-- Name: index_subscription_natures_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscription_natures_on_creator_id ON public.subscription_natures USING btree (creator_id);


--
-- Name: index_subscription_natures_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscription_natures_on_updated_at ON public.subscription_natures USING btree (updated_at);


--
-- Name: index_subscription_natures_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscription_natures_on_updater_id ON public.subscription_natures USING btree (updater_id);


--
-- Name: index_subscriptions_on_address_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_address_id ON public.subscriptions USING btree (address_id);


--
-- Name: index_subscriptions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_created_at ON public.subscriptions USING btree (created_at);


--
-- Name: index_subscriptions_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_creator_id ON public.subscriptions USING btree (creator_id);


--
-- Name: index_subscriptions_on_nature_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_nature_id ON public.subscriptions USING btree (nature_id);


--
-- Name: index_subscriptions_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_parent_id ON public.subscriptions USING btree (parent_id);


--
-- Name: index_subscriptions_on_sale_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_sale_item_id ON public.subscriptions USING btree (sale_item_id);


--
-- Name: index_subscriptions_on_started_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_started_on ON public.subscriptions USING btree (started_on);


--
-- Name: index_subscriptions_on_stopped_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_stopped_on ON public.subscriptions USING btree (stopped_on);


--
-- Name: index_subscriptions_on_subscriber_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_subscriber_id ON public.subscriptions USING btree (subscriber_id);


--
-- Name: index_subscriptions_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_updated_at ON public.subscriptions USING btree (updated_at);


--
-- Name: index_subscriptions_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_updater_id ON public.subscriptions USING btree (updater_id);


--
-- Name: index_supervision_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_supervision_items_on_created_at ON public.supervision_items USING btree (created_at);


--
-- Name: index_supervision_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_supervision_items_on_creator_id ON public.supervision_items USING btree (creator_id);


--
-- Name: index_supervision_items_on_sensor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_supervision_items_on_sensor_id ON public.supervision_items USING btree (sensor_id);


--
-- Name: index_supervision_items_on_supervision_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_supervision_items_on_supervision_id ON public.supervision_items USING btree (supervision_id);


--
-- Name: index_supervision_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_supervision_items_on_updated_at ON public.supervision_items USING btree (updated_at);


--
-- Name: index_supervision_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_supervision_items_on_updater_id ON public.supervision_items USING btree (updater_id);


--
-- Name: index_supervisions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_supervisions_on_created_at ON public.supervisions USING btree (created_at);


--
-- Name: index_supervisions_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_supervisions_on_creator_id ON public.supervisions USING btree (creator_id);


--
-- Name: index_supervisions_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_supervisions_on_name ON public.supervisions USING btree (name);


--
-- Name: index_supervisions_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_supervisions_on_updated_at ON public.supervisions USING btree (updated_at);


--
-- Name: index_supervisions_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_supervisions_on_updater_id ON public.supervisions USING btree (updater_id);


--
-- Name: index_synchronization_operations_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_synchronization_operations_on_created_at ON public.synchronization_operations USING btree (created_at);


--
-- Name: index_synchronization_operations_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_synchronization_operations_on_creator_id ON public.synchronization_operations USING btree (creator_id);


--
-- Name: index_synchronization_operations_on_operation_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_synchronization_operations_on_operation_name ON public.synchronization_operations USING btree (operation_name);


--
-- Name: index_synchronization_operations_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_synchronization_operations_on_updated_at ON public.synchronization_operations USING btree (updated_at);


--
-- Name: index_synchronization_operations_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_synchronization_operations_on_updater_id ON public.synchronization_operations USING btree (updater_id);


--
-- Name: index_target_distributions_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_target_distributions_on_activity_id ON public.target_distributions USING btree (activity_id);


--
-- Name: index_target_distributions_on_activity_production_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_target_distributions_on_activity_production_id ON public.target_distributions USING btree (activity_production_id);


--
-- Name: index_target_distributions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_target_distributions_on_created_at ON public.target_distributions USING btree (created_at);


--
-- Name: index_target_distributions_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_target_distributions_on_creator_id ON public.target_distributions USING btree (creator_id);


--
-- Name: index_target_distributions_on_target_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_target_distributions_on_target_id ON public.target_distributions USING btree (target_id);


--
-- Name: index_target_distributions_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_target_distributions_on_updated_at ON public.target_distributions USING btree (updated_at);


--
-- Name: index_target_distributions_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_target_distributions_on_updater_id ON public.target_distributions USING btree (updater_id);


--
-- Name: index_tasks_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tasks_on_created_at ON public.tasks USING btree (created_at);


--
-- Name: index_tasks_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tasks_on_creator_id ON public.tasks USING btree (creator_id);


--
-- Name: index_tasks_on_entity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tasks_on_entity_id ON public.tasks USING btree (entity_id);


--
-- Name: index_tasks_on_executor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tasks_on_executor_id ON public.tasks USING btree (executor_id);


--
-- Name: index_tasks_on_sale_opportunity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tasks_on_sale_opportunity_id ON public.tasks USING btree (sale_opportunity_id);


--
-- Name: index_tasks_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tasks_on_updated_at ON public.tasks USING btree (updated_at);


--
-- Name: index_tasks_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tasks_on_updater_id ON public.tasks USING btree (updater_id);


--
-- Name: index_tax_declaration_item_parts_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declaration_item_parts_on_account_id ON public.tax_declaration_item_parts USING btree (account_id);


--
-- Name: index_tax_declaration_item_parts_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declaration_item_parts_on_created_at ON public.tax_declaration_item_parts USING btree (created_at);


--
-- Name: index_tax_declaration_item_parts_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declaration_item_parts_on_creator_id ON public.tax_declaration_item_parts USING btree (creator_id);


--
-- Name: index_tax_declaration_item_parts_on_direction; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declaration_item_parts_on_direction ON public.tax_declaration_item_parts USING btree (direction);


--
-- Name: index_tax_declaration_item_parts_on_journal_entry_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declaration_item_parts_on_journal_entry_item_id ON public.tax_declaration_item_parts USING btree (journal_entry_item_id);


--
-- Name: index_tax_declaration_item_parts_on_tax_declaration_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declaration_item_parts_on_tax_declaration_item_id ON public.tax_declaration_item_parts USING btree (tax_declaration_item_id);


--
-- Name: index_tax_declaration_item_parts_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declaration_item_parts_on_updated_at ON public.tax_declaration_item_parts USING btree (updated_at);


--
-- Name: index_tax_declaration_item_parts_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declaration_item_parts_on_updater_id ON public.tax_declaration_item_parts USING btree (updater_id);


--
-- Name: index_tax_declaration_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declaration_items_on_created_at ON public.tax_declaration_items USING btree (created_at);


--
-- Name: index_tax_declaration_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declaration_items_on_creator_id ON public.tax_declaration_items USING btree (creator_id);


--
-- Name: index_tax_declaration_items_on_tax_declaration_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declaration_items_on_tax_declaration_id ON public.tax_declaration_items USING btree (tax_declaration_id);


--
-- Name: index_tax_declaration_items_on_tax_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declaration_items_on_tax_id ON public.tax_declaration_items USING btree (tax_id);


--
-- Name: index_tax_declaration_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declaration_items_on_updated_at ON public.tax_declaration_items USING btree (updated_at);


--
-- Name: index_tax_declaration_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declaration_items_on_updater_id ON public.tax_declaration_items USING btree (updater_id);


--
-- Name: index_tax_declarations_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declarations_on_created_at ON public.tax_declarations USING btree (created_at);


--
-- Name: index_tax_declarations_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declarations_on_creator_id ON public.tax_declarations USING btree (creator_id);


--
-- Name: index_tax_declarations_on_financial_year_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declarations_on_financial_year_id ON public.tax_declarations USING btree (financial_year_id);


--
-- Name: index_tax_declarations_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declarations_on_journal_entry_id ON public.tax_declarations USING btree (journal_entry_id);


--
-- Name: index_tax_declarations_on_responsible_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declarations_on_responsible_id ON public.tax_declarations USING btree (responsible_id);


--
-- Name: index_tax_declarations_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declarations_on_updated_at ON public.tax_declarations USING btree (updated_at);


--
-- Name: index_tax_declarations_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declarations_on_updater_id ON public.tax_declarations USING btree (updater_id);


--
-- Name: index_taxes_on_collect_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taxes_on_collect_account_id ON public.taxes USING btree (collect_account_id);


--
-- Name: index_taxes_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taxes_on_created_at ON public.taxes USING btree (created_at);


--
-- Name: index_taxes_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taxes_on_creator_id ON public.taxes USING btree (creator_id);


--
-- Name: index_taxes_on_deduction_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taxes_on_deduction_account_id ON public.taxes USING btree (deduction_account_id);


--
-- Name: index_taxes_on_fixed_asset_collect_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taxes_on_fixed_asset_collect_account_id ON public.taxes USING btree (fixed_asset_collect_account_id);


--
-- Name: index_taxes_on_fixed_asset_deduction_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taxes_on_fixed_asset_deduction_account_id ON public.taxes USING btree (fixed_asset_deduction_account_id);


--
-- Name: index_taxes_on_intracommunity_payable_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taxes_on_intracommunity_payable_account_id ON public.taxes USING btree (intracommunity_payable_account_id);


--
-- Name: index_taxes_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taxes_on_updated_at ON public.taxes USING btree (updated_at);


--
-- Name: index_taxes_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taxes_on_updater_id ON public.taxes USING btree (updater_id);


--
-- Name: index_teams_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_on_created_at ON public.teams USING btree (created_at);


--
-- Name: index_teams_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_on_creator_id ON public.teams USING btree (creator_id);


--
-- Name: index_teams_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_on_parent_id ON public.teams USING btree (parent_id);


--
-- Name: index_teams_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_on_updated_at ON public.teams USING btree (updated_at);


--
-- Name: index_teams_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_on_updater_id ON public.teams USING btree (updater_id);


--
-- Name: index_technical_itineraries_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_technical_itineraries_on_activity_id ON public.technical_itineraries USING btree (activity_id);


--
-- Name: index_technical_itineraries_on_campaign_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_technical_itineraries_on_campaign_id ON public.technical_itineraries USING btree (campaign_id);


--
-- Name: index_tokens_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tokens_on_created_at ON public.tokens USING btree (created_at);


--
-- Name: index_tokens_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tokens_on_creator_id ON public.tokens USING btree (creator_id);


--
-- Name: index_tokens_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tokens_on_name ON public.tokens USING btree (name);


--
-- Name: index_tokens_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tokens_on_updated_at ON public.tokens USING btree (updated_at);


--
-- Name: index_tokens_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tokens_on_updater_id ON public.tokens USING btree (updater_id);


--
-- Name: index_trackings_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trackings_on_created_at ON public.trackings USING btree (created_at);


--
-- Name: index_trackings_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trackings_on_creator_id ON public.trackings USING btree (creator_id);


--
-- Name: index_trackings_on_producer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trackings_on_producer_id ON public.trackings USING btree (producer_id);


--
-- Name: index_trackings_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trackings_on_product_id ON public.trackings USING btree (product_id);


--
-- Name: index_trackings_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trackings_on_updated_at ON public.trackings USING btree (updated_at);


--
-- Name: index_trackings_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trackings_on_updater_id ON public.trackings USING btree (updater_id);


--
-- Name: index_units_on_base_unit_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_units_on_base_unit_id ON public.units USING btree (base_unit_id);


--
-- Name: index_units_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_units_on_creator_id ON public.units USING btree (creator_id);


--
-- Name: index_units_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_units_on_updater_id ON public.units USING btree (updater_id);


--
-- Name: index_users_on_authentication_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_authentication_token ON public.users USING btree (authentication_token);


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON public.users USING btree (confirmation_token);


--
-- Name: index_users_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_created_at ON public.users USING btree (created_at);


--
-- Name: index_users_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_creator_id ON public.users USING btree (creator_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_invitation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_invitation_token ON public.users USING btree (invitation_token);


--
-- Name: index_users_on_invitations_count; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_invitations_count ON public.users USING btree (invitations_count);


--
-- Name: index_users_on_invited_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_invited_by_id ON public.users USING btree (invited_by_id);


--
-- Name: index_users_on_person_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_person_id ON public.users USING btree (person_id);


--
-- Name: index_users_on_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_provider ON public.users USING btree (provider);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: index_users_on_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_role_id ON public.users USING btree (role_id);


--
-- Name: index_users_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_team_id ON public.users USING btree (team_id);


--
-- Name: index_users_on_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_uid ON public.users USING btree (uid);


--
-- Name: index_users_on_unlock_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_unlock_token ON public.users USING btree (unlock_token);


--
-- Name: index_users_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_updated_at ON public.users USING btree (updated_at);


--
-- Name: index_users_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_updater_id ON public.users USING btree (updater_id);


--
-- Name: index_versions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_created_at ON public.versions USING btree (created_at);


--
-- Name: index_versions_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_creator_id ON public.versions USING btree (creator_id);


--
-- Name: index_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_item_type_and_item_id ON public.versions USING btree (item_type, item_id);


--
-- Name: index_wice_grid_serialized_queries_on_grid_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wice_grid_serialized_queries_on_grid_name ON public.wice_grid_serialized_queries USING btree (grid_name);


--
-- Name: index_wice_grid_serialized_queries_on_grid_name_and_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wice_grid_serialized_queries_on_grid_name_and_id ON public.wice_grid_serialized_queries USING btree (grid_name, id);


--
-- Name: index_wine_incoming_harvest_inputs_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wine_incoming_harvest_inputs_on_created_at ON public.wine_incoming_harvest_inputs USING btree (created_at);


--
-- Name: index_wine_incoming_harvest_inputs_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wine_incoming_harvest_inputs_on_creator_id ON public.wine_incoming_harvest_inputs USING btree (creator_id);


--
-- Name: index_wine_incoming_harvest_inputs_on_input_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wine_incoming_harvest_inputs_on_input_id ON public.wine_incoming_harvest_inputs USING btree (input_id);


--
-- Name: index_wine_incoming_harvest_inputs_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wine_incoming_harvest_inputs_on_updated_at ON public.wine_incoming_harvest_inputs USING btree (updated_at);


--
-- Name: index_wine_incoming_harvest_inputs_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wine_incoming_harvest_inputs_on_updater_id ON public.wine_incoming_harvest_inputs USING btree (updater_id);


--
-- Name: index_wine_incoming_harvest_plants_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wine_incoming_harvest_plants_on_created_at ON public.wine_incoming_harvest_plants USING btree (created_at);


--
-- Name: index_wine_incoming_harvest_plants_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wine_incoming_harvest_plants_on_creator_id ON public.wine_incoming_harvest_plants USING btree (creator_id);


--
-- Name: index_wine_incoming_harvest_plants_on_plant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wine_incoming_harvest_plants_on_plant_id ON public.wine_incoming_harvest_plants USING btree (plant_id);


--
-- Name: index_wine_incoming_harvest_plants_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wine_incoming_harvest_plants_on_updated_at ON public.wine_incoming_harvest_plants USING btree (updated_at);


--
-- Name: index_wine_incoming_harvest_plants_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wine_incoming_harvest_plants_on_updater_id ON public.wine_incoming_harvest_plants USING btree (updater_id);


--
-- Name: index_wine_incoming_harvest_presses_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wine_incoming_harvest_presses_on_created_at ON public.wine_incoming_harvest_presses USING btree (created_at);


--
-- Name: index_wine_incoming_harvest_presses_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wine_incoming_harvest_presses_on_creator_id ON public.wine_incoming_harvest_presses USING btree (creator_id);


--
-- Name: index_wine_incoming_harvest_presses_on_press_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wine_incoming_harvest_presses_on_press_id ON public.wine_incoming_harvest_presses USING btree (press_id);


--
-- Name: index_wine_incoming_harvest_presses_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wine_incoming_harvest_presses_on_updated_at ON public.wine_incoming_harvest_presses USING btree (updated_at);


--
-- Name: index_wine_incoming_harvest_presses_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wine_incoming_harvest_presses_on_updater_id ON public.wine_incoming_harvest_presses USING btree (updater_id);


--
-- Name: index_wine_incoming_harvest_presses_on_wine_incoming_harvest_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wine_incoming_harvest_presses_on_wine_incoming_harvest_id ON public.wine_incoming_harvest_presses USING btree (wine_incoming_harvest_id);


--
-- Name: index_wine_incoming_harvest_storages_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wine_incoming_harvest_storages_on_created_at ON public.wine_incoming_harvest_storages USING btree (created_at);


--
-- Name: index_wine_incoming_harvest_storages_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wine_incoming_harvest_storages_on_creator_id ON public.wine_incoming_harvest_storages USING btree (creator_id);


--
-- Name: index_wine_incoming_harvest_storages_on_storage_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wine_incoming_harvest_storages_on_storage_id ON public.wine_incoming_harvest_storages USING btree (storage_id);


--
-- Name: index_wine_incoming_harvest_storages_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wine_incoming_harvest_storages_on_updated_at ON public.wine_incoming_harvest_storages USING btree (updated_at);


--
-- Name: index_wine_incoming_harvest_storages_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wine_incoming_harvest_storages_on_updater_id ON public.wine_incoming_harvest_storages USING btree (updater_id);


--
-- Name: index_wine_incoming_harvests_on_analysis_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wine_incoming_harvests_on_analysis_id ON public.wine_incoming_harvests USING btree (analysis_id);


--
-- Name: index_wine_incoming_harvests_on_campaign_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wine_incoming_harvests_on_campaign_id ON public.wine_incoming_harvests USING btree (campaign_id);


--
-- Name: index_wine_incoming_harvests_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wine_incoming_harvests_on_created_at ON public.wine_incoming_harvests USING btree (created_at);


--
-- Name: index_wine_incoming_harvests_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wine_incoming_harvests_on_creator_id ON public.wine_incoming_harvests USING btree (creator_id);


--
-- Name: index_wine_incoming_harvests_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wine_incoming_harvests_on_number ON public.wine_incoming_harvests USING btree (number);


--
-- Name: index_wine_incoming_harvests_on_ticket_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wine_incoming_harvests_on_ticket_number ON public.wine_incoming_harvests USING btree (ticket_number);


--
-- Name: index_wine_incoming_harvests_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wine_incoming_harvests_on_updated_at ON public.wine_incoming_harvests USING btree (updated_at);


--
-- Name: index_wine_incoming_harvests_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wine_incoming_harvests_on_updater_id ON public.wine_incoming_harvests USING btree (updater_id);


--
-- Name: index_worker_contracts_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_worker_contracts_on_created_at ON public.worker_contracts USING btree (created_at);


--
-- Name: index_worker_contracts_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_worker_contracts_on_creator_id ON public.worker_contracts USING btree (creator_id);


--
-- Name: index_worker_contracts_on_entity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_worker_contracts_on_entity_id ON public.worker_contracts USING btree (entity_id);


--
-- Name: index_worker_contracts_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_worker_contracts_on_updated_at ON public.worker_contracts USING btree (updated_at);


--
-- Name: index_worker_contracts_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_worker_contracts_on_updater_id ON public.worker_contracts USING btree (updater_id);


--
-- Name: index_worker_group_items_on_worker_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_worker_group_items_on_worker_group_id ON public.worker_group_items USING btree (worker_group_id);


--
-- Name: index_worker_group_items_on_worker_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_worker_group_items_on_worker_id ON public.worker_group_items USING btree (worker_id);


--
-- Name: index_worker_group_labellings_on_label_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_worker_group_labellings_on_label_id ON public.worker_group_labellings USING btree (label_id);


--
-- Name: index_worker_group_labellings_on_worker_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_worker_group_labellings_on_worker_group_id ON public.worker_group_labellings USING btree (worker_group_id);


--
-- Name: index_worker_groups_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_worker_groups_on_created_at ON public.worker_groups USING btree (created_at);


--
-- Name: index_worker_groups_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_worker_groups_on_creator_id ON public.worker_groups USING btree (creator_id);


--
-- Name: index_worker_groups_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_worker_groups_on_updated_at ON public.worker_groups USING btree (updated_at);


--
-- Name: index_worker_groups_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_worker_groups_on_updater_id ON public.worker_groups USING btree (updater_id);


--
-- Name: index_worker_time_indicators_on_start_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_worker_time_indicators_on_start_at ON public.worker_time_indicators USING btree (start_at);


--
-- Name: index_worker_time_indicators_on_stop_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_worker_time_indicators_on_stop_at ON public.worker_time_indicators USING btree (stop_at);


--
-- Name: index_worker_time_indicators_on_worker_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_worker_time_indicators_on_worker_id ON public.worker_time_indicators USING btree (worker_id);


--
-- Name: index_worker_time_logs_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_worker_time_logs_on_created_at ON public.worker_time_logs USING btree (created_at);


--
-- Name: index_worker_time_logs_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_worker_time_logs_on_creator_id ON public.worker_time_logs USING btree (creator_id);


--
-- Name: index_worker_time_logs_on_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_worker_time_logs_on_started_at ON public.worker_time_logs USING btree (started_at);


--
-- Name: index_worker_time_logs_on_stopped_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_worker_time_logs_on_stopped_at ON public.worker_time_logs USING btree (stopped_at);


--
-- Name: index_worker_time_logs_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_worker_time_logs_on_updated_at ON public.worker_time_logs USING btree (updated_at);


--
-- Name: index_worker_time_logs_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_worker_time_logs_on_updater_id ON public.worker_time_logs USING btree (updater_id);


--
-- Name: index_worker_time_logs_on_worker_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_worker_time_logs_on_worker_id ON public.worker_time_logs USING btree (worker_id);


--
-- Name: intervention_product_nature_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX intervention_product_nature_variant_id ON public.intervention_proposal_parameters USING btree (product_nature_variant_id);


--
-- Name: intervention_proposal_activity_production_irregular_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX intervention_proposal_activity_production_irregular_batch_id ON public.intervention_proposals USING btree (activity_production_irregular_batch_id);


--
-- Name: intervention_proposal_parameter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX intervention_proposal_parameter_id ON public.intervention_proposal_parameters USING btree (intervention_proposal_id);


--
-- Name: intervention_provider_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX intervention_provider_index ON public.interventions USING gin (((provider -> 'vendor'::text)), ((provider -> 'name'::text)), ((provider -> 'id'::text)));


--
-- Name: intervention_template_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX intervention_template_activity_id ON public.intervention_template_activities USING btree (intervention_template_id);


--
-- Name: intervention_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX intervention_template_id ON public.intervention_template_product_parameters USING btree (intervention_template_id);


--
-- Name: intervention_template_product_parameter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX intervention_template_product_parameter_id ON public.daily_charges USING btree (intervention_template_product_parameter_id);


--
-- Name: itinerary_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX itinerary_template_id ON public.technical_itinerary_intervention_templates USING btree (intervention_template_id);


--
-- Name: journal_entries_compliance_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journal_entries_compliance_index ON public.journal_entries USING gin (((compliance -> 'vendor'::text)), ((compliance -> 'name'::text)));


--
-- Name: journal_entry_provider_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journal_entry_provider_index ON public.journal_entries USING gin (((provider -> 'vendor'::text)), ((provider -> 'name'::text)), ((provider -> 'id'::text)));


--
-- Name: journal_provider_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journal_provider_index ON public.journals USING gin (((provider -> 'vendor'::text)), ((provider -> 'name'::text)), ((provider -> 'id'::text)));


--
-- Name: loan_provider_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX loan_provider_index ON public.loans USING gin (((provider -> 'vendor'::text)), ((provider -> 'name'::text)), ((provider -> 'id'::text)));


--
-- Name: pfi_intervention_parameters_campaign_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pfi_intervention_parameters_campaign_id ON public.pfi_intervention_parameters USING btree (campaign_id);


--
-- Name: pfi_intervention_parameters_input_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pfi_intervention_parameters_input_id ON public.pfi_intervention_parameters USING btree (input_id);


--
-- Name: pfi_intervention_parameters_target_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pfi_intervention_parameters_target_id ON public.pfi_intervention_parameters USING btree (target_id);


--
-- Name: product_nature_category_provider_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_nature_category_provider_index ON public.product_nature_categories USING gin (((provider -> 'vendor'::text)), ((provider -> 'name'::text)), ((provider -> 'id'::text)));


--
-- Name: product_nature_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_nature_id ON public.intervention_template_product_parameters USING btree (product_nature_id);


--
-- Name: product_nature_provider_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_nature_provider_index ON public.product_natures USING gin (((provider -> 'vendor'::text)), ((provider -> 'name'::text)), ((provider -> 'id'::text)));


--
-- Name: product_nature_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_nature_variant_id ON public.intervention_template_product_parameters USING btree (product_nature_variant_id);


--
-- Name: product_nature_variant_provider_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_nature_variant_provider_index ON public.product_nature_variants USING gin (((provider -> 'vendor'::text)), ((provider -> 'name'::text)), ((provider -> 'id'::text)));


--
-- Name: sale_nature_provider_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sale_nature_provider_index ON public.sale_natures USING gin (((provider -> 'vendor'::text)), ((provider -> 'name'::text)), ((provider -> 'id'::text)));


--
-- Name: sale_provider_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sale_provider_index ON public.sales USING gin (((provider -> 'vendor'::text)), ((provider -> 'name'::text)), ((provider -> 'id'::text)));


--
-- Name: tax_provider_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tax_provider_index ON public.taxes USING gin (((provider -> 'vendor'::text)), ((provider -> 'name'::text)), ((provider -> 'id'::text)));


--
-- Name: technical_itinerary_intervention_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX technical_itinerary_intervention_template_id ON public.intervention_proposals USING btree (technical_itinerary_intervention_template_id);


--
-- Name: template_itinerary_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX template_itinerary_id ON public.technical_itinerary_intervention_templates USING btree (technical_itinerary_id);


--
-- Name: product_populations _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE OR REPLACE VIEW public.product_populations AS
 SELECT DISTINCT ON (movements.started_at, movements.product_id) movements.product_id,
    movements.started_at,
    sum(precedings.delta) AS value,
    max(movements.creator_id) AS creator_id,
    max(movements.created_at) AS created_at,
    max(movements.updated_at) AS updated_at,
    max(movements.updater_id) AS updater_id,
    min(movements.id) AS id,
    1 AS lock_version
   FROM (public.product_movements movements
     LEFT JOIN ( SELECT sum(product_movements.delta) AS delta,
            product_movements.product_id,
            product_movements.started_at
           FROM public.product_movements
          GROUP BY product_movements.product_id, product_movements.started_at) precedings ON (((movements.started_at >= precedings.started_at) AND (movements.product_id = precedings.product_id))))
  GROUP BY movements.id;


--
-- Name: pfi_campaigns_activities_interventions _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE OR REPLACE VIEW public.pfi_campaigns_activities_interventions AS
 SELECT pip.campaign_id,
    a.id AS activity_id,
    ap.id AS activity_production_id,
    p.id AS crop_id,
    pip.segment_code,
    sum(pip.pfi_value) AS crop_pfi_value,
    ap.size_value AS activity_production_surface_area,
    p.initial_population AS crop_surface_area,
    round((sum(pip.pfi_value) * round((COALESCE(p.initial_population, (0)::numeric) / COALESCE(ap.size_value, (1)::numeric)), 2)), 2) AS activity_production_pfi_value,
    round((round((sum(pip.pfi_value) * round((COALESCE(p.initial_population, (0)::numeric) / COALESCE(ap.size_value, (1)::numeric)), 2)), 2) * (ap.size_value / ( SELECT sum(aps.size_value) AS sum
           FROM public.activity_productions aps
          WHERE ((aps.activity_id = a.id) AND (aps.id IN ( SELECT activity_productions_campaigns.activity_production_id
                   FROM public.activity_productions_campaigns
                  WHERE (activity_productions_campaigns.campaign_id = pip.campaign_id))))))), 2) AS activity_pfi_value
   FROM ((((public.pfi_intervention_parameters pip
     JOIN public.intervention_parameters ip ON ((pip.target_id = ip.id)))
     JOIN public.products p ON ((ip.product_id = p.id)))
     JOIN public.activity_productions ap ON ((p.activity_production_id = ap.id)))
     JOIN public.activities a ON ((ap.activity_id = a.id)))
  WHERE ((pip.nature)::text = 'crop'::text)
  GROUP BY pip.campaign_id, a.id, ap.id, ap.size_value, p.id, pip.segment_code
  ORDER BY pip.campaign_id, a.id, ap.id, pip.segment_code;


--
-- Name: activities_campaigns delete_activities_campaigns; Type: RULE; Schema: public; Owner: -
--

CREATE RULE delete_activities_campaigns AS
    ON DELETE TO public.activities_campaigns DO INSTEAD NOTHING;


--
-- Name: activities_interventions delete_activities_interventions; Type: RULE; Schema: public; Owner: -
--

CREATE RULE delete_activities_interventions AS
    ON DELETE TO public.activities_interventions DO INSTEAD NOTHING;


--
-- Name: activity_productions_campaigns delete_activity_productions_campaigns; Type: RULE; Schema: public; Owner: -
--

CREATE RULE delete_activity_productions_campaigns AS
    ON DELETE TO public.activity_productions_campaigns DO INSTEAD NOTHING;


--
-- Name: activity_productions_interventions delete_activity_productions_interventions; Type: RULE; Schema: public; Owner: -
--

CREATE RULE delete_activity_productions_interventions AS
    ON DELETE TO public.activity_productions_interventions DO INSTEAD NOTHING;


--
-- Name: activity_productions_interventions_costs delete_activity_productions_interventions_costs; Type: RULE; Schema: public; Owner: -
--

CREATE RULE delete_activity_productions_interventions_costs AS
    ON DELETE TO public.activity_productions_interventions_costs DO INSTEAD NOTHING;


--
-- Name: campaigns_interventions delete_campaigns_interventions; Type: RULE; Schema: public; Owner: -
--

CREATE RULE delete_campaigns_interventions AS
    ON DELETE TO public.campaigns_interventions DO INSTEAD NOTHING;


--
-- Name: product_populations delete_product_populations; Type: RULE; Schema: public; Owner: -
--

CREATE RULE delete_product_populations AS
    ON DELETE TO public.product_populations DO INSTEAD NOTHING;


--
-- Name: journal_entries compute_journal_entries_continuous_number_on_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER compute_journal_entries_continuous_number_on_insert BEFORE INSERT ON public.journal_entries FOR EACH ROW WHEN (((new.state)::text <> 'draft'::text)) EXECUTE FUNCTION public.compute_journal_entry_continuous_number();


--
-- Name: journal_entries compute_journal_entries_continuous_number_on_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER compute_journal_entries_continuous_number_on_update BEFORE UPDATE ON public.journal_entries FOR EACH ROW WHEN ((((old.state)::text <> (new.state)::text) AND ((old.state)::text = 'draft'::text))) EXECUTE FUNCTION public.compute_journal_entry_continuous_number();


--
-- Name: journal_entry_items compute_partial_isacompta_lettering; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER compute_partial_isacompta_lettering AFTER UPDATE OF letter ON public.journal_entry_items FOR EACH ROW EXECUTE FUNCTION public.compute_partial_isacompta_lettering();


--
-- Name: journal_entry_items compute_partial_lettering_status_insert_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER compute_partial_lettering_status_insert_delete AFTER INSERT OR DELETE ON public.journal_entry_items FOR EACH ROW EXECUTE FUNCTION public.compute_partial_lettering();


--
-- Name: journal_entry_items compute_partial_lettering_status_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER compute_partial_lettering_status_update AFTER UPDATE OF credit, debit, account_id, letter ON public.journal_entry_items FOR EACH ROW WHEN (((pg_trigger_depth() = 0) AND (((COALESCE(old.letter, ''::character varying))::text <> (COALESCE(new.letter, ''::character varying))::text) OR (old.account_id <> new.account_id) OR (old.credit <> new.credit) OR (old.debit <> new.debit)))) EXECUTE FUNCTION public.compute_partial_lettering();


--
-- Name: outgoing_payments outgoing_payment_list_cache; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER outgoing_payment_list_cache AFTER INSERT OR DELETE OR UPDATE OF list_id, amount ON public.outgoing_payments FOR EACH ROW EXECUTE FUNCTION public.compute_outgoing_payment_list_cache();


--
-- Name: journal_entry_items synchronize_jei_with_entry; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER synchronize_jei_with_entry AFTER INSERT OR UPDATE ON public.journal_entry_items FOR EACH ROW EXECUTE FUNCTION public.synchronize_jei_with_entry('jei');


--
-- Name: journal_entries synchronize_jeis_of_entry; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER synchronize_jeis_of_entry AFTER INSERT OR UPDATE ON public.journal_entries FOR EACH ROW EXECUTE FUNCTION public.synchronize_jei_with_entry('entry');


--
-- Name: activity_production_batches fk_rails_00e34d02e0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_production_batches
    ADD CONSTRAINT fk_rails_00e34d02e0 FOREIGN KEY (activity_production_id) REFERENCES public.activity_productions(id);


--
-- Name: payslips fk_rails_02f6ec2213; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payslips
    ADD CONSTRAINT fk_rails_02f6ec2213 FOREIGN KEY (nature_id) REFERENCES public.payslip_natures(id);


--
-- Name: products fk_rails_0627b13271; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT fk_rails_0627b13271 FOREIGN KEY (conditioning_unit_id) REFERENCES public.units(id);


--
-- Name: crop_group_labellings fk_rails_07865fc029; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crop_group_labellings
    ADD CONSTRAINT fk_rails_07865fc029 FOREIGN KEY (label_id) REFERENCES public.labels(id);


--
-- Name: cvi_cadastral_plant_cvi_land_parcels fk_rails_0e970be37a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cvi_cadastral_plant_cvi_land_parcels
    ADD CONSTRAINT fk_rails_0e970be37a FOREIGN KEY (cvi_land_parcel_id) REFERENCES public.cvi_land_parcels(id);


--
-- Name: wine_incoming_harvests fk_rails_10884b32e0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wine_incoming_harvests
    ADD CONSTRAINT fk_rails_10884b32e0 FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- Name: parcel_items fk_rails_10aa40af5e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_items
    ADD CONSTRAINT fk_rails_10aa40af5e FOREIGN KEY (purchase_order_to_close_id) REFERENCES public.purchases(id);


--
-- Name: technical_itinerary_intervention_templates fk_rails_12463de838; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.technical_itinerary_intervention_templates
    ADD CONSTRAINT fk_rails_12463de838 FOREIGN KEY (intervention_template_id) REFERENCES public.intervention_templates(id);


--
-- Name: worker_contracts fk_rails_13690625da; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_contracts
    ADD CONSTRAINT fk_rails_13690625da FOREIGN KEY (entity_id) REFERENCES public.entities(id) ON DELETE CASCADE;


--
-- Name: outgoing_payments fk_rails_15244a5c09; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outgoing_payments
    ADD CONSTRAINT fk_rails_15244a5c09 FOREIGN KEY (mode_id) REFERENCES public.outgoing_payment_modes(id) ON DELETE RESTRICT;


--
-- Name: parcel_item_storings fk_rails_182d7ce6a7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_item_storings
    ADD CONSTRAINT fk_rails_182d7ce6a7 FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: intervention_template_product_parameters fk_rails_18932007aa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_template_product_parameters
    ADD CONSTRAINT fk_rails_18932007aa FOREIGN KEY (product_nature_id) REFERENCES public.product_natures(id);


--
-- Name: planning_scenario_activity_plots fk_rails_195f383786; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planning_scenario_activity_plots
    ADD CONSTRAINT fk_rails_195f383786 FOREIGN KEY (technical_itinerary_id) REFERENCES public.technical_itineraries(id);


--
-- Name: interventions fk_rails_1f3a6ab6a0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interventions
    ADD CONSTRAINT fk_rails_1f3a6ab6a0 FOREIGN KEY (intervention_proposal_id) REFERENCES public.intervention_proposals(id);


--
-- Name: outgoing_payments fk_rails_1facec8a15; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outgoing_payments
    ADD CONSTRAINT fk_rails_1facec8a15 FOREIGN KEY (list_id) REFERENCES public.outgoing_payment_lists(id);


--
-- Name: products fk_rails_20cb1a9318; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT fk_rails_20cb1a9318 FOREIGN KEY (worker_group_item_id) REFERENCES public.worker_group_items(id);


--
-- Name: outgoing_payments fk_rails_214eda6f83; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outgoing_payments
    ADD CONSTRAINT fk_rails_214eda6f83 FOREIGN KEY (payee_id) REFERENCES public.entities(id) ON DELETE RESTRICT;


--
-- Name: activity_budget_items fk_rails_25adc2f766; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_budget_items
    ADD CONSTRAINT fk_rails_25adc2f766 FOREIGN KEY (product_parameter_id) REFERENCES public.intervention_template_product_parameters(id);


--
-- Name: cvi_statements fk_rails_2b0908cb44; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cvi_statements
    ADD CONSTRAINT fk_rails_2b0908cb44 FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- Name: activity_tactics fk_rails_2b4070027b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_tactics
    ADD CONSTRAINT fk_rails_2b4070027b FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- Name: technical_itineraries fk_rails_2dfb0af7d3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.technical_itineraries
    ADD CONSTRAINT fk_rails_2dfb0af7d3 FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- Name: journal_entry_items fk_rails_3143e6e260; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_entry_items
    ADD CONSTRAINT fk_rails_3143e6e260 FOREIGN KEY (variant_id) REFERENCES public.product_nature_variants(id);


--
-- Name: activity_production_irregular_batches fk_rails_31b5c93b13; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_production_irregular_batches
    ADD CONSTRAINT fk_rails_31b5c93b13 FOREIGN KEY (activity_production_batch_id) REFERENCES public.activity_production_batches(id);


--
-- Name: crop_group_labellings fk_rails_36924e7b4a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crop_group_labellings
    ADD CONSTRAINT fk_rails_36924e7b4a FOREIGN KEY (crop_group_id) REFERENCES public.crop_groups(id);


--
-- Name: intervention_crop_groups fk_rails_396140bcc0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_crop_groups
    ADD CONSTRAINT fk_rails_396140bcc0 FOREIGN KEY (crop_group_id) REFERENCES public.crop_groups(id);


--
-- Name: intervention_template_activities fk_rails_39759d6fe4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_template_activities
    ADD CONSTRAINT fk_rails_39759d6fe4 FOREIGN KEY (activity_id) REFERENCES public.activities(id);


--
-- Name: worker_group_labellings fk_rails_3aae8cba7d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_group_labellings
    ADD CONSTRAINT fk_rails_3aae8cba7d FOREIGN KEY (label_id) REFERENCES public.labels(id);


--
-- Name: sale_items fk_rails_3ed1a3f84a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_items
    ADD CONSTRAINT fk_rails_3ed1a3f84a FOREIGN KEY (depreciable_product_id) REFERENCES public.products(id);


--
-- Name: parcel_items fk_rails_41a9d1c170; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_items
    ADD CONSTRAINT fk_rails_41a9d1c170 FOREIGN KEY (project_budget_id) REFERENCES public.project_budgets(id);


--
-- Name: activity_productions fk_rails_42b3d2f5a8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_productions
    ADD CONSTRAINT fk_rails_42b3d2f5a8 FOREIGN KEY (technical_itinerary_id) REFERENCES public.technical_itineraries(id);


--
-- Name: crumbs fk_rails_434e943648; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crumbs
    ADD CONSTRAINT fk_rails_434e943648 FOREIGN KEY (intervention_participation_id) REFERENCES public.intervention_participations(id);


--
-- Name: intervention_proposals fk_rails_4491a90f0b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_proposals
    ADD CONSTRAINT fk_rails_4491a90f0b FOREIGN KEY (activity_production_irregular_batch_id) REFERENCES public.activity_production_irregular_batches(id);


--
-- Name: wine_incoming_harvest_presses fk_rails_45a09dccce; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wine_incoming_harvest_presses
    ADD CONSTRAINT fk_rails_45a09dccce FOREIGN KEY (press_id) REFERENCES public.products(id);


--
-- Name: parcels fk_rails_47f94280b8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcels
    ADD CONSTRAINT fk_rails_47f94280b8 FOREIGN KEY (sale_nature_id) REFERENCES public.sale_natures(id);


--
-- Name: wine_incoming_harvest_inputs fk_rails_4ba0624d55; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wine_incoming_harvest_inputs
    ADD CONSTRAINT fk_rails_4ba0624d55 FOREIGN KEY (wine_incoming_harvest_id) REFERENCES public.wine_incoming_harvests(id);


--
-- Name: purchase_items fk_rails_4cc3eb3f99; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_items
    ADD CONSTRAINT fk_rails_4cc3eb3f99 FOREIGN KEY (conditioning_unit_id) REFERENCES public.units(id);


--
-- Name: journal_entries fk_rails_5076105ec1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_entries
    ADD CONSTRAINT fk_rails_5076105ec1 FOREIGN KEY (financial_year_exchange_id) REFERENCES public.financial_year_exchanges(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: intervention_setting_items fk_rails_5764cea836; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_setting_items
    ADD CONSTRAINT fk_rails_5764cea836 FOREIGN KEY (intervention_parameter_setting_id) REFERENCES public.intervention_parameter_settings(id);


--
-- Name: cvi_cadastral_plants fk_rails_5a05077b24; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cvi_cadastral_plants
    ADD CONSTRAINT fk_rails_5a05077b24 FOREIGN KEY (cvi_statement_id) REFERENCES public.cvi_statements(id);


--
-- Name: tax_declaration_item_parts fk_rails_5be0cd019c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tax_declaration_item_parts
    ADD CONSTRAINT fk_rails_5be0cd019c FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: products fk_rails_5e587cedec; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT fk_rails_5e587cedec FOREIGN KEY (activity_production_id) REFERENCES public.activity_productions(id) ON DELETE CASCADE;


--
-- Name: technical_itinerary_intervention_templates fk_rails_5f0371c42a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.technical_itinerary_intervention_templates
    ADD CONSTRAINT fk_rails_5f0371c42a FOREIGN KEY (technical_itinerary_id) REFERENCES public.technical_itineraries(id);


--
-- Name: pfi_intervention_parameters fk_rails_5f6f882536; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pfi_intervention_parameters
    ADD CONSTRAINT fk_rails_5f6f882536 FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- Name: activity_budgets fk_rails_60e5867b44; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_budgets
    ADD CONSTRAINT fk_rails_60e5867b44 FOREIGN KEY (technical_itinerary_id) REFERENCES public.technical_itineraries(id);


--
-- Name: purchase_items fk_rails_62e7d4b959; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_items
    ADD CONSTRAINT fk_rails_62e7d4b959 FOREIGN KEY (project_budget_id) REFERENCES public.project_budgets(id);


--
-- Name: intervention_proposals fk_rails_655e10510a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_proposals
    ADD CONSTRAINT fk_rails_655e10510a FOREIGN KEY (technical_itinerary_intervention_template_id) REFERENCES public.technical_itinerary_intervention_templates(id);


--
-- Name: intervention_template_product_parameters fk_rails_65829c9376; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_template_product_parameters
    ADD CONSTRAINT fk_rails_65829c9376 FOREIGN KEY (product_nature_variant_id) REFERENCES public.product_nature_variants(id);


--
-- Name: cvi_cadastral_plants fk_rails_65b7099078; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cvi_cadastral_plants
    ADD CONSTRAINT fk_rails_65b7099078 FOREIGN KEY (cvi_cultivable_zone_id) REFERENCES public.cvi_cultivable_zones(id);


--
-- Name: worker_time_logs fk_rails_664c16001e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_time_logs
    ADD CONSTRAINT fk_rails_664c16001e FOREIGN KEY (worker_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: activity_budget_items fk_rails_66b3183944; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_budget_items
    ADD CONSTRAINT fk_rails_66b3183944 FOREIGN KEY (unit_id) REFERENCES public.units(id);


--
-- Name: payslip_natures fk_rails_6835dfa420; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payslip_natures
    ADD CONSTRAINT fk_rails_6835dfa420 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: parcel_item_storings fk_rails_69ea98eb15; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_item_storings
    ADD CONSTRAINT fk_rails_69ea98eb15 FOREIGN KEY (conditioning_unit_id) REFERENCES public.units(id);


--
-- Name: crumbs fk_rails_6b230b689c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crumbs
    ADD CONSTRAINT fk_rails_6b230b689c FOREIGN KEY (ride_id) REFERENCES public.rides(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: analytic_segments fk_rails_6f90f51e24; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.analytic_segments
    ADD CONSTRAINT fk_rails_6f90f51e24 FOREIGN KEY (analytic_sequence_id) REFERENCES public.analytic_sequences(id);


--
-- Name: parcel_items fk_rails_7010820bb4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_items
    ADD CONSTRAINT fk_rails_7010820bb4 FOREIGN KEY (purchase_order_item_id) REFERENCES public.purchase_items(id);


--
-- Name: cvi_land_parcels fk_rails_71a1e59459; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cvi_land_parcels
    ADD CONSTRAINT fk_rails_71a1e59459 FOREIGN KEY (activity_id) REFERENCES public.activities(id);


--
-- Name: intervention_proposal_parameters fk_rails_73168818a2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_proposal_parameters
    ADD CONSTRAINT fk_rails_73168818a2 FOREIGN KEY (product_nature_variant_id) REFERENCES public.product_nature_variants(id);


--
-- Name: intervention_parameter_settings fk_rails_739cf87a8f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_parameter_settings
    ADD CONSTRAINT fk_rails_739cf87a8f FOREIGN KEY (intervention_parameter_id) REFERENCES public.intervention_parameters(id);


--
-- Name: intervention_template_product_parameters fk_rails_75bd15f71d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_template_product_parameters
    ADD CONSTRAINT fk_rails_75bd15f71d FOREIGN KEY (intervention_template_id) REFERENCES public.intervention_templates(id);


--
-- Name: intervention_template_activities fk_rails_7699df6bd9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_template_activities
    ADD CONSTRAINT fk_rails_7699df6bd9 FOREIGN KEY (intervention_template_id) REFERENCES public.intervention_templates(id);


--
-- Name: interventions fk_rails_76eca6ee87; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interventions
    ADD CONSTRAINT fk_rails_76eca6ee87 FOREIGN KEY (purchase_id) REFERENCES public.purchases(id);


--
-- Name: journals fk_rails_790552b64c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journals
    ADD CONSTRAINT fk_rails_790552b64c FOREIGN KEY (financial_year_exchange_id) REFERENCES public.financial_year_exchanges(id);


--
-- Name: alert_phases fk_rails_7a9749733c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_phases
    ADD CONSTRAINT fk_rails_7a9749733c FOREIGN KEY (alert_id) REFERENCES public.alerts(id);


--
-- Name: cvi_cultivable_zones fk_rails_7b06059434; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cvi_cultivable_zones
    ADD CONSTRAINT fk_rails_7b06059434 FOREIGN KEY (cvi_statement_id) REFERENCES public.cvi_statements(id);


--
-- Name: planning_scenario_activity_plots fk_rails_7c7488bbdc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planning_scenario_activity_plots
    ADD CONSTRAINT fk_rails_7c7488bbdc FOREIGN KEY (planning_scenario_activity_id) REFERENCES public.planning_scenario_activities(id);


--
-- Name: regularizations fk_rails_8043b7d279; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regularizations
    ADD CONSTRAINT fk_rails_8043b7d279 FOREIGN KEY (affair_id) REFERENCES public.affairs(id);


--
-- Name: intervention_template_product_parameters fk_rails_810325206c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_template_product_parameters
    ADD CONSTRAINT fk_rails_810325206c FOREIGN KEY (activity_id) REFERENCES public.activities(id);


--
-- Name: crop_group_items fk_rails_819f6e41b9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crop_group_items
    ADD CONSTRAINT fk_rails_819f6e41b9 FOREIGN KEY (crop_group_id) REFERENCES public.crop_groups(id);


--
-- Name: rides fk_rails_81dbf669e7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rides
    ADD CONSTRAINT fk_rails_81dbf669e7 FOREIGN KEY (ride_set_id) REFERENCES public.ride_sets(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: payslip_natures fk_rails_82e76fb89d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payslip_natures
    ADD CONSTRAINT fk_rails_82e76fb89d FOREIGN KEY (journal_id) REFERENCES public.journals(id);


--
-- Name: inventories fk_rails_86687e98ce; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventories
    ADD CONSTRAINT fk_rails_86687e98ce FOREIGN KEY (journal_id) REFERENCES public.journals(id);


--
-- Name: worker_group_labellings fk_rails_87473cbb34; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_group_labellings
    ADD CONSTRAINT fk_rails_87473cbb34 FOREIGN KEY (worker_group_id) REFERENCES public.worker_groups(id);


--
-- Name: planning_scenarios fk_rails_88d915988d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planning_scenarios
    ADD CONSTRAINT fk_rails_88d915988d FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- Name: intervention_working_periods fk_rails_8903897a2c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_working_periods
    ADD CONSTRAINT fk_rails_8903897a2c FOREIGN KEY (intervention_id) REFERENCES public.interventions(id);


--
-- Name: cvi_land_parcels fk_rails_8fb9a09c07; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cvi_land_parcels
    ADD CONSTRAINT fk_rails_8fb9a09c07 FOREIGN KEY (cvi_cultivable_zone_id) REFERENCES public.cvi_cultivable_zones(id);


--
-- Name: wine_incoming_harvest_presses fk_rails_90e5ef87c9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wine_incoming_harvest_presses
    ADD CONSTRAINT fk_rails_90e5ef87c9 FOREIGN KEY (wine_incoming_harvest_id) REFERENCES public.wine_incoming_harvests(id);


--
-- Name: intervention_participations fk_rails_930f08f448; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_participations
    ADD CONSTRAINT fk_rails_930f08f448 FOREIGN KEY (intervention_id) REFERENCES public.interventions(id);


--
-- Name: parcel_items fk_rails_995fb20943; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_items
    ADD CONSTRAINT fk_rails_995fb20943 FOREIGN KEY (activity_budget_id) REFERENCES public.activity_budgets(id);


--
-- Name: loans fk_rails_99bed64435; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loans
    ADD CONSTRAINT fk_rails_99bed64435 FOREIGN KEY (activity_id) REFERENCES public.activities(id);


--
-- Name: cvi_cadastral_plant_cvi_land_parcels fk_rails_9a5a14882f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cvi_cadastral_plant_cvi_land_parcels
    ADD CONSTRAINT fk_rails_9a5a14882f FOREIGN KEY (cvi_cadastral_plant_id) REFERENCES public.cvi_cadastral_plants(id);


--
-- Name: tax_declaration_item_parts fk_rails_9d08cd4dc8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tax_declaration_item_parts
    ADD CONSTRAINT fk_rails_9d08cd4dc8 FOREIGN KEY (tax_declaration_item_id) REFERENCES public.tax_declaration_items(id);


--
-- Name: alerts fk_rails_a31061effa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT fk_rails_a31061effa FOREIGN KEY (sensor_id) REFERENCES public.sensors(id);


--
-- Name: intervention_crop_groups fk_rails_a38943f4fc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_crop_groups
    ADD CONSTRAINT fk_rails_a38943f4fc FOREIGN KEY (intervention_id) REFERENCES public.interventions(id);


--
-- Name: rides fk_rails_a61c5540a1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rides
    ADD CONSTRAINT fk_rails_a61c5540a1 FOREIGN KEY (intervention_id) REFERENCES public.interventions(id);


--
-- Name: parcel_items fk_rails_a6cf16ef60; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_items
    ADD CONSTRAINT fk_rails_a6cf16ef60 FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- Name: intervention_working_periods fk_rails_a9b45798a3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_working_periods
    ADD CONSTRAINT fk_rails_a9b45798a3 FOREIGN KEY (intervention_participation_id) REFERENCES public.intervention_participations(id);


--
-- Name: rides fk_rails_abdfefd04a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rides
    ADD CONSTRAINT fk_rails_abdfefd04a FOREIGN KEY (product_id) REFERENCES public.products(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: planning_scenario_activities fk_rails_ac0835e4dc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planning_scenario_activities
    ADD CONSTRAINT fk_rails_ac0835e4dc FOREIGN KEY (activity_id) REFERENCES public.activities(id);


--
-- Name: payslips fk_rails_ac1b8c6e79; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payslips
    ADD CONSTRAINT fk_rails_ac1b8c6e79 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: pfi_intervention_parameters fk_rails_ac83b72aeb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pfi_intervention_parameters
    ADD CONSTRAINT fk_rails_ac83b72aeb FOREIGN KEY (target_id) REFERENCES public.intervention_parameters(id);


--
-- Name: product_nature_variants fk_rails_accfad6712; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_nature_variants
    ADD CONSTRAINT fk_rails_accfad6712 FOREIGN KEY (default_unit_id) REFERENCES public.units(id);


--
-- Name: daily_charges fk_rails_ad496091e3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_charges
    ADD CONSTRAINT fk_rails_ad496091e3 FOREIGN KEY (intervention_template_product_parameter_id) REFERENCES public.intervention_template_product_parameters(id);


--
-- Name: tax_declaration_item_parts fk_rails_adb1cc875c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tax_declaration_item_parts
    ADD CONSTRAINT fk_rails_adb1cc875c FOREIGN KEY (journal_entry_item_id) REFERENCES public.journal_entry_items(id);


--
-- Name: financial_years fk_rails_b170b89c1e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.financial_years
    ADD CONSTRAINT fk_rails_b170b89c1e FOREIGN KEY (accountant_id) REFERENCES public.entities(id);


--
-- Name: fixed_assets fk_rails_b2e478cdb7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fixed_assets
    ADD CONSTRAINT fk_rails_b2e478cdb7 FOREIGN KEY (activity_id) REFERENCES public.activities(id);


--
-- Name: parcel_items fk_rails_b3a1a4f578; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_items
    ADD CONSTRAINT fk_rails_b3a1a4f578 FOREIGN KEY (purchase_invoice_item_id) REFERENCES public.purchase_items(id);


--
-- Name: intervention_templates fk_rails_b5c0e91173; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_templates
    ADD CONSTRAINT fk_rails_b5c0e91173 FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- Name: activity_production_batches fk_rails_b82e55b5c6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_production_batches
    ADD CONSTRAINT fk_rails_b82e55b5c6 FOREIGN KEY (planning_scenario_activity_plot_id) REFERENCES public.planning_scenario_activity_plots(id);


--
-- Name: idea_diagnostics fk_rails_bccf84a1b0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.idea_diagnostics
    ADD CONSTRAINT fk_rails_bccf84a1b0 FOREIGN KEY (auditor_id) REFERENCES public.entities(id);


--
-- Name: journals fk_rails_be4d04c726; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journals
    ADD CONSTRAINT fk_rails_be4d04c726 FOREIGN KEY (accountant_id) REFERENCES public.entities(id);


--
-- Name: inventories fk_rails_c0930210fb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventories
    ADD CONSTRAINT fk_rails_c0930210fb FOREIGN KEY (product_nature_category_id) REFERENCES public.product_nature_categories(id);


--
-- Name: payslips fk_rails_c0e66eeaff; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payslips
    ADD CONSTRAINT fk_rails_c0e66eeaff FOREIGN KEY (employee_id) REFERENCES public.entities(id);


--
-- Name: intervention_parameter_settings fk_rails_c2a2d75e30; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_parameter_settings
    ADD CONSTRAINT fk_rails_c2a2d75e30 FOREIGN KEY (intervention_id) REFERENCES public.interventions(id);


--
-- Name: payslips fk_rails_c3bf0a90b6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payslips
    ADD CONSTRAINT fk_rails_c3bf0a90b6 FOREIGN KEY (affair_id) REFERENCES public.affairs(id);


--
-- Name: parcels fk_rails_c4b289405e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcels
    ADD CONSTRAINT fk_rails_c4b289405e FOREIGN KEY (intervention_id) REFERENCES public.interventions(id);


--
-- Name: regularizations fk_rails_ca9854019b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regularizations
    ADD CONSTRAINT fk_rails_ca9854019b FOREIGN KEY (journal_entry_id) REFERENCES public.journal_entries(id);


--
-- Name: technical_itineraries fk_rails_d02ebd3a2f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.technical_itineraries
    ADD CONSTRAINT fk_rails_d02ebd3a2f FOREIGN KEY (activity_id) REFERENCES public.activities(id);


--
-- Name: intervention_proposal_parameters fk_rails_d0715348b7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_proposal_parameters
    ADD CONSTRAINT fk_rails_d0715348b7 FOREIGN KEY (intervention_proposal_id) REFERENCES public.intervention_proposals(id);


--
-- Name: parcel_items fk_rails_d32d74cbd9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_items
    ADD CONSTRAINT fk_rails_d32d74cbd9 FOREIGN KEY (conditioning_unit_id) REFERENCES public.units(id);


--
-- Name: pfi_intervention_parameters fk_rails_d40f37781b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pfi_intervention_parameters
    ADD CONSTRAINT fk_rails_d40f37781b FOREIGN KEY (input_id) REFERENCES public.intervention_parameters(id);


--
-- Name: daily_charges fk_rails_d667b81248; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_charges
    ADD CONSTRAINT fk_rails_d667b81248 FOREIGN KEY (activity_id) REFERENCES public.activities(id);


--
-- Name: wine_incoming_harvest_storages fk_rails_daff0b6d0c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wine_incoming_harvest_storages
    ADD CONSTRAINT fk_rails_daff0b6d0c FOREIGN KEY (wine_incoming_harvest_id) REFERENCES public.wine_incoming_harvests(id);


--
-- Name: wine_incoming_harvest_plants fk_rails_e2e8a6aba3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wine_incoming_harvest_plants
    ADD CONSTRAINT fk_rails_e2e8a6aba3 FOREIGN KEY (wine_incoming_harvest_id) REFERENCES public.wine_incoming_harvests(id);


--
-- Name: payslips fk_rails_e319c31e6b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payslips
    ADD CONSTRAINT fk_rails_e319c31e6b FOREIGN KEY (journal_entry_id) REFERENCES public.journal_entries(id);


--
-- Name: intervention_proposals fk_rails_e3758de3f6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_proposals
    ADD CONSTRAINT fk_rails_e3758de3f6 FOREIGN KEY (activity_production_id) REFERENCES public.activity_productions(id);


--
-- Name: intervention_proposal_parameters fk_rails_e4aa584bc6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_proposal_parameters
    ADD CONSTRAINT fk_rails_e4aa584bc6 FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: sale_items fk_rails_e68fe22f2a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_items
    ADD CONSTRAINT fk_rails_e68fe22f2a FOREIGN KEY (conditioning_unit_id) REFERENCES public.units(id);


--
-- Name: intervention_participations fk_rails_e81467e70f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_participations
    ADD CONSTRAINT fk_rails_e81467e70f FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: wine_incoming_harvests fk_rails_eb0e85e775; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wine_incoming_harvests
    ADD CONSTRAINT fk_rails_eb0e85e775 FOREIGN KEY (analysis_id) REFERENCES public.analyses(id);


--
-- Name: outgoing_payments fk_rails_ee973f6d0f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outgoing_payments
    ADD CONSTRAINT fk_rails_ee973f6d0f FOREIGN KEY (journal_entry_id) REFERENCES public.journal_entries(id);


--
-- Name: financial_year_exchanges fk_rails_f0120f1957; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.financial_year_exchanges
    ADD CONSTRAINT fk_rails_f0120f1957 FOREIGN KEY (financial_year_id) REFERENCES public.financial_years(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: journal_entry_items fk_rails_f46de3d8ed; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_entry_items
    ADD CONSTRAINT fk_rails_f46de3d8ed FOREIGN KEY (project_budget_id) REFERENCES public.project_budgets(id);


--
-- Name: planning_scenario_activities fk_rails_f51c3ee30d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planning_scenario_activities
    ADD CONSTRAINT fk_rails_f51c3ee30d FOREIGN KEY (planning_scenario_id) REFERENCES public.planning_scenarios(id);


--
-- Name: activity_budget_items fk_rails_f53bdb334e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_budget_items
    ADD CONSTRAINT fk_rails_f53bdb334e FOREIGN KEY (transfered_activity_budget_id) REFERENCES public.activity_budgets(id);


--
-- Name: daily_charges fk_rails_f713d67210; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_charges
    ADD CONSTRAINT fk_rails_f713d67210 FOREIGN KEY (activity_production_id) REFERENCES public.activity_productions(id);


--
-- Name: cap_neutral_areas fk_rails_f9fd6a9e09; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cap_neutral_areas
    ADD CONSTRAINT fk_rails_f9fd6a9e09 FOREIGN KEY (cap_statement_id) REFERENCES public.cap_statements(id);


--
-- Name: intervention_setting_items fk_rails_fb2f506f44; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervention_setting_items
    ADD CONSTRAINT fk_rails_fb2f506f44 FOREIGN KEY (intervention_id) REFERENCES public.interventions(id);


--
-- Name: products fk_rails_fb915499a4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT fk_rails_fb915499a4 FOREIGN KEY (category_id) REFERENCES public.product_nature_categories(id);


--
-- Name: financial_years fk_rails_fe34e6ff17; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.financial_years
    ADD CONSTRAINT fk_rails_fe34e6ff17 FOREIGN KEY (closer_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "public", "postgis", "lexicon";

INSERT INTO "schema_migrations" (version) VALUES
('20121212122000'),
('20140407091156'),
('20140415075729'),
('20140428085206'),
('20140429184401'),
('20140507065135'),
('20140509084901'),
('20140516084901'),
('20140528161301'),
('20140602145001'),
('20140611084801'),
('20140717071149'),
('20140717154544'),
('20140806082909'),
('20140813215326'),
('20140831135204'),
('20140912131515'),
('20140918155113'),
('20140923153017'),
('20140925090818'),
('20140925091652'),
('20140925220644'),
('20141021082742'),
('20141120134356'),
('20141223102001'),
('20141224091401'),
('20150109085549'),
('20150110223621'),
('20150114074551'),
('20150114093417'),
('20150114144130'),
('20150116152730'),
('20150206104748'),
('20150208093000'),
('20150212214601'),
('20150215210401'),
('20150225112858'),
('20150225142832'),
('20150313100824'),
('20150315115732'),
('20150319084703'),
('20150418013301'),
('20150418225701'),
('20150421185537'),
('20150423095929'),
('20150430095404'),
('20150507135310'),
('20150518133024'),
('20150526101330'),
('20150529080607'),
('20150530123724'),
('20150530123845'),
('20150530193726'),
('20150605211111'),
('20150605225025'),
('20150605225026'),
('20150606185500'),
('20150613084318'),
('20150613103941'),
('20150624224705'),
('20150713153906'),
('20150813223705'),
('20150813223710'),
('20150814095555'),
('20150821235105'),
('20150822190206'),
('20150904144552'),
('20150905114009'),
('20150907134647'),
('20150907163339'),
('20150908084329'),
('20150908214101'),
('20150909120000'),
('20150909121646'),
('20150909145831'),
('20150909161528'),
('20150918151337'),
('20150919135830'),
('20150920094748'),
('20150922091317'),
('20150923120603'),
('20150926110217'),
('20151027085923'),
('20151107080001'),
('20151107135008'),
('20151108001401'),
('20160112135638'),
('20160113212017'),
('20160128123152'),
('20160202143716'),
('20160203104038'),
('20160206212413'),
('20160207143859'),
('20160207171458'),
('20160209070523'),
('20160210083955'),
('20160224221201'),
('20160323151501'),
('20160324082737'),
('20160330074338'),
('20160331142401'),
('20160407141401'),
('20160408225701'),
('20160420121330'),
('20160421141812'),
('20160425212301'),
('20160427133601'),
('20160502125101'),
('20160503125501'),
('20160512182701'),
('20160517070433'),
('20160517074938'),
('20160518061327'),
('20160619102723'),
('20160619105233'),
('20160619130247'),
('20160619155843'),
('20160620092810'),
('20160621084836'),
('20160630091845'),
('20160706132116'),
('20160712195829'),
('20160718095119'),
('20160718110335'),
('20160718133147'),
('20160718150935'),
('20160721122006'),
('20160725090113'),
('20160725182008'),
('20160726082348'),
('20160726112542'),
('20160726181305'),
('20160726184811'),
('20160727094402'),
('20160727201017'),
('20160728162003'),
('20160728192642'),
('20160729080926'),
('20160730070743'),
('20160817133216'),
('20160822225001'),
('20160824160125'),
('20160825161606'),
('20160826125039'),
('20160831144010'),
('20160906112630'),
('20160910200730'),
('20160910224234'),
('20160911140029'),
('20160913133355'),
('20160913133407'),
('20160915094302'),
('20160916220901'),
('20160918152301'),
('20160919141500'),
('20160920083312'),
('20160921144623'),
('20160921185801'),
('20160922161801'),
('20160923233801'),
('20160927192301'),
('20160928121727'),
('20160930111020'),
('20160930142110'),
('20161007151444'),
('20161010205901'),
('20161012145400'),
('20161012145500'),
('20161012145600'),
('20161012145700'),
('20161013023259'),
('20161018162500'),
('20161019235101'),
('20161020191401'),
('20161026094401'),
('20161026102134'),
('20161105212807'),
('20161106140253'),
('20161107065331'),
('20161108140009'),
('20161114091835'),
('20161114101401'),
('20161114112858'),
('20161115163443'),
('20161118150610'),
('20161120153801'),
('20161121033801'),
('20161121171401'),
('20161122155003'),
('20161122161646'),
('20161122203438'),
('20161124093205'),
('20161201142213'),
('20161205185328'),
('20161212183910'),
('20161214091911'),
('20161216171308'),
('20161219092100'),
('20161219131051'),
('20161231180401'),
('20161231200612'),
('20161231223002'),
('20161231233003'),
('20161231234533'),
('20170101110136'),
('20170110083324'),
('20170124133351'),
('20170125162958'),
('20170203135031'),
('20170203181700'),
('20170207131958'),
('20170208150219'),
('20170209151943'),
('20170209191230'),
('20170209205737'),
('20170209212237'),
('20170209224614'),
('20170209235705'),
('20170210132452'),
('20170210145316'),
('20170210153841'),
('20170210174219'),
('20170210175448'),
('20170214130330'),
('20170215155700'),
('20170215171400'),
('20170220123437'),
('20170220164259'),
('20170220171804'),
('20170220192042'),
('20170222100614'),
('20170222222222'),
('20170227143414'),
('20170307103213'),
('20170307171442'),
('20170312183557'),
('20170313090000'),
('20170315221501'),
('20170316085711'),
('20170328125742'),
('20170407143621'),
('20170408094408'),
('20170413073501'),
('20170413185630'),
('20170413211525'),
('20170413222518'),
('20170413222519'),
('20170413222520'),
('20170413222521'),
('20170414071529'),
('20170414092904'),
('20170415141801'),
('20170415163650'),
('20170421131536'),
('20170425145302'),
('20170530002312'),
('20170602144753'),
('20170804101025'),
('20170818134454'),
('20170831071726'),
('20170831180835'),
('20171010075206'),
('20171122125351'),
('20171210080901'),
('20171211091817'),
('20171212100101'),
('20180112135843'),
('20180112144429'),
('20180112151052'),
('20180115135241'),
('20180116133217'),
('20180124113015'),
('20180124130951'),
('20180126094309'),
('20180130090052'),
('20180212101416'),
('20180214161453'),
('20180222160026'),
('20180226104505'),
('20180227140040'),
('20180306085858'),
('20180328094106'),
('20180404145130'),
('20180405123945'),
('20180417083701'),
('20180419140723'),
('20180419152744'),
('20180423074302'),
('20180502102741'),
('20180503081248'),
('20180516080155'),
('20180518124733'),
('20180523153734'),
('20180531092556'),
('20180626121433'),
('20180629093901'),
('20180702115000'),
('20180702115500'),
('20180702115600'),
('20180702115700'),
('20180702115800'),
('20180702115900'),
('20180702120000'),
('20180702120100'),
('20180702120200'),
('20180702120300'),
('20180702120400'),
('20180702120500'),
('20180702120600'),
('20180702120800'),
('20180702120900'),
('20180702121000'),
('20180702121100'),
('20180702121200'),
('20180702121300'),
('20180702121400'),
('20180702121500'),
('20180702121600'),
('20180702121700'),
('20180702121800'),
('20180702121900'),
('20180702122000'),
('20180702122100'),
('20180702122200'),
('20180702122300'),
('20180702122400'),
('20180702122500'),
('20180702122600'),
('20180702122700'),
('20180702122800'),
('20180702122900'),
('20180702123000'),
('20180702123100'),
('20180702123200'),
('20180702123300'),
('20180702123400'),
('20180702123500'),
('20180702123600'),
('20180702123700'),
('20180702123800'),
('20180702123900'),
('20180702124000'),
('20180702124100'),
('20180702124200'),
('20180702124300'),
('20180702124400'),
('20180702124500'),
('20180702124600'),
('20180702124700'),
('20180702124800'),
('20180702124900'),
('20180702131326'),
('20180704145001'),
('20180709083205'),
('20180711133214'),
('20180711145501'),
('20180712091619'),
('20180712133721'),
('20180730150532'),
('20180801143320'),
('20180821145715'),
('20180830120145'),
('20180918182905'),
('20180920121004'),
('20180920134223'),
('20180921092835'),
('20181002130036'),
('20181003092024'),
('20181003153602'),
('20181012145914'),
('20181019164555'),
('20181022152412'),
('20181023083957'),
('20181031091651'),
('20181106100439'),
('20181125122238'),
('20181126152417'),
('20190104105501'),
('20190207094545'),
('20190313140443'),
('20190313201333'),
('20190325145542'),
('20190329164621'),
('20190429111001'),
('20190502082326'),
('20190514125010'),
('20190520152229'),
('20190528093045'),
('20190529095536'),
('20190606134257'),
('20190611101828'),
('20190614122154'),
('20190614123521'),
('20190617200314'),
('20190619021714'),
('20190703060513'),
('20190705094729'),
('20190705143350'),
('20190710002904'),
('20190712124724'),
('20190715104422'),
('20190715114422'),
('20190715114423'),
('20190716125202'),
('20190716162315'),
('20190717151612'),
('20190718133342'),
('20190719140916'),
('20190726092304'),
('20190807075910'),
('20190808123912'),
('20190808152235'),
('20190911153350'),
('20190912085925'),
('20190912144103'),
('20190916124521'),
('20190917120742'),
('20190917120743'),
('20190927133802'),
('20190929224101'),
('20191002104944'),
('20191007122201'),
('20191010143350'),
('20191010151901'),
('20191011155512'),
('20191023172248'),
('20191025074617'),
('20191025074824'),
('20191029083202'),
('20191101162901'),
('20191115191501'),
('20191126103235'),
('20191127162609'),
('20191204160657'),
('20191205085059'),
('20191205123841'),
('20191206080450'),
('20191206102525'),
('20191223092535'),
('20200107092243'),
('20200108090053'),
('20200110142108'),
('20200115164203'),
('20200122100513'),
('20200128133347'),
('20200207105103'),
('20200213102154'),
('20200225093814'),
('20200311100650'),
('20200312163243'),
('20200312163701'),
('20200313161422'),
('20200316151202'),
('20200317155452'),
('20200317163950'),
('20200317174840'),
('20200320143401'),
('20200320154251'),
('20200323084937'),
('20200324010101'),
('20200330133607'),
('20200403091907'),
('20200403123414'),
('20200406105101'),
('20200407075511'),
('20200407090249'),
('20200407172801'),
('20200409094501'),
('20200410183701'),
('20200412125000'),
('20200413131000'),
('20200413131001'),
('20200414074218'),
('20200415162701'),
('20200415163115'),
('20200417183101'),
('20200419152901'),
('20200422084439'),
('20200428152738'),
('20200428162128'),
('20200428162212'),
('20200428162256'),
('20200504102804'),
('20200505114024'),
('20200507094001'),
('20200512091803'),
('20200515092158'),
('20200518095801'),
('20200611090747'),
('20200622101923'),
('20200730114601'),
('20200805080622'),
('20200807065809'),
('20200807083737'),
('20200811133320'),
('20200817101012'),
('20200819083947'),
('20200819085052'),
('20200820094522'),
('20200820095810'),
('20200824133243'),
('20200902094919'),
('20200917092443'),
('20200918144501'),
('20200922092535'),
('20200922144601'),
('20200923130701'),
('20200925150810'),
('20200925170636'),
('20200926150810'),
('20200928073618'),
('20200930105801'),
('20201001095904'),
('20201001133625'),
('20201005090447'),
('20201005093406'),
('20201005150456'),
('20201007121011'),
('20201008122920'),
('20201009073905'),
('20201009163401'),
('20201014085806'),
('20201015095353'),
('20201020100820'),
('20201027103331'),
('20201030083414'),
('20201103092521'),
('20201112132347'),
('20201118153001'),
('20201202090824'),
('20201209161246'),
('20201215085433'),
('20210119103725'),
('20210119151601'),
('20210202093448'),
('20210204145215'),
('20210205105359'),
('20210208182000'),
('20210209135343'),
('20210209154545'),
('20210211162023'),
('20210211193300'),
('20210215114312'),
('20210215133318'),
('20210215144700'),
('20210215153434'),
('20210216111920'),
('20210217082925'),
('20210217112010'),
('20210219092100'),
('20210219172016'),
('20210222103208'),
('20210222181700'),
('20210301101012'),
('20210301131307'),
('20210302081408'),
('20210302110649'),
('20210302134031'),
('20210304145448'),
('20210304154300'),
('20210310135449'),
('20210311143508'),
('20210312110155'),
('20210312110510'),
('20210317102544'),
('20210325083800'),
('20210326163132'),
('20210329135015'),
('20210329151703'),
('20210402133741'),
('20210414100801'),
('20210416084101'),
('20210421142541'),
('20210421171901'),
('20210427233001'),
('20210510075720'),
('20210511132348'),
('20210512161201'),
('20210514062916'),
('20210514142217'),
('20210520085721'),
('20210521130856'),
('20210525135938'),
('20210526142601'),
('20210526233101'),
('20210527160150'),
('20210531184001'),
('20210614114001'),
('20210614123501'),
('20210615191101'),
('20210616133301'),
('20210622125501'),
('20210628091421'),
('20210629145426'),
('20210630123148'),
('20210630145843'),
('20210712151057'),
('20210715121401'),
('20210715123101'),
('20210715125301'),
('20210715142101'),
('20210723151251'),
('20210825155901'),
('20210902151057'),
('20210907154701'),
('20210915100201'),
('20210916133539'),
('20210927184701'),
('20210930110901'),
('20210930150701'),
('20211005214401'),
('20211007145301'),
('20211008165101'),
('20211012164201'),
('20211020205526'),
('20211025191201'),
('20211108090701'),
('20211109153301'),
('20211112154901'),
('20211124110921'),
('20211125181101'),
('20211206150144'),
('20211209142107'),
('20211220140042'),
('20220120092001'),
('20220204085501'),
('20220204185601'),
('20220208175301'),
('20220209183201'),
('20220308153250'),
('20220318165450'),
('20220328131305'),
('20220328132211'),
('20220328232801'),
('20220414120300'),
('20220414120336');


