--
-- PostgreSQL database dump
--

-- Dumped from database version 11.2
-- Dumped by pg_dump version 11.6 (Debian 11.6-0+deb10u1)

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


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: cadastral_land_parcel_zones; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.cadastral_land_parcel_zones (
    id character varying NOT NULL,
    section character varying,
    work_number character varying,
    net_surface_area integer,
    shape postgis.geometry(MultiPolygon,4326) NOT NULL,
    centroid postgis.geometry(Point,4326)
);


--
-- Name: ephy_cropsets; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.ephy_cropsets (
    id character varying NOT NULL,
    name character varying NOT NULL,
    label jsonb,
    crop_names text[],
    crop_labels jsonb,
    record_checksum integer
);


--
-- Name: eu_market_prices; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.eu_market_prices (
    id character varying NOT NULL,
    category character varying,
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
-- Name: master_production_natures; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.master_production_natures (
    id integer NOT NULL,
    specie character varying NOT NULL,
    human_name jsonb,
    human_name_fra character varying NOT NULL,
    started_on date NOT NULL,
    stopped_on date NOT NULL,
    agroedi_crop_code character varying,
    season character varying,
    pfi_crop_code character varying,
    cap_2017_crop_code character varying,
    cap_2018_crop_code character varying,
    cap_2019_crop_code character varying
);


--
-- Name: master_production_outputs; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.master_production_outputs (
    production_nature_id integer NOT NULL,
    production_system_name character varying NOT NULL,
    name character varying NOT NULL,
    average_yield numeric(19,4),
    main boolean DEFAULT false NOT NULL,
    analysis_items character varying[]
);


--
-- Name: master_vine_varieties; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.master_vine_varieties (
    id character varying NOT NULL,
    specie_name character varying NOT NULL,
    specie_long_name character varying,
    category_name character varying NOT NULL,
    fr_validated character varying,
    utility character varying,
    color character varying,
    customs_code character varying
);


--
-- Name: phenological_stages; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.phenological_stages (
    id integer NOT NULL,
    bbch character varying,
    biaggiolini character varying,
    eichhorn_lorenz character varying,
    chasselas_date date,
    label jsonb,
    description jsonb
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
-- Name: registered_building_zones; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.registered_building_zones (
    nature character varying,
    shape postgis.geometry(MultiPolygon,4326) NOT NULL,
    centroid postgis.geometry(Point,4326)
);


--
-- Name: registered_chart_of_accounts; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.registered_chart_of_accounts (
    id character varying NOT NULL,
    account_number character varying NOT NULL,
    chart_id character varying NOT NULL,
    reference_name character varying,
    previous_reference_name character varying,
    name jsonb
);


--
-- Name: registered_crop_zones; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.registered_crop_zones (
    id character varying NOT NULL,
    city_name character varying,
    shape postgis.geometry(Polygon,4326) NOT NULL,
    centroid postgis.geometry(Point,4326)
);


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
-- Name: registered_hydro_items; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.registered_hydro_items (
    id character varying NOT NULL,
    name jsonb,
    nature character varying,
    point postgis.geometry(Point,4326),
    shape postgis.geometry(MultiPolygonZM,4326),
    lines postgis.geometry(MultiLineStringZM,4326)
);


--
-- Name: registered_legal_positions; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.registered_legal_positions (
    id integer NOT NULL,
    name jsonb,
    nature character varying NOT NULL,
    country character varying NOT NULL,
    code character varying NOT NULL,
    insee_code character varying NOT NULL,
    fiscal_positions text[]
);


--
-- Name: registered_pfi_crops; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.registered_pfi_crops (
    id integer NOT NULL,
    reference_label_fra character varying
);


--
-- Name: registered_pfi_doses; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.registered_pfi_doses (
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


--
-- Name: registered_pfi_targets; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.registered_pfi_targets (
    id integer NOT NULL,
    reference_label_fra character varying
);


--
-- Name: registered_phytosanitary_products; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.registered_phytosanitary_products (
    id integer NOT NULL,
    reference_name character varying NOT NULL,
    name character varying NOT NULL,
    other_name character varying,
    nature character varying,
    active_compounds character varying,
    france_maaid character varying NOT NULL,
    mix_category_code character varying NOT NULL,
    in_field_reentry_delay integer,
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
    pre_harvest_delay integer,
    pre_harvest_delay_bbch integer,
    applications_count integer,
    applications_frequency integer,
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
-- Name: registered_postal_zones; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.registered_postal_zones (
    id character varying NOT NULL,
    country character varying NOT NULL,
    code character varying NOT NULL,
    city_name character varying NOT NULL,
    postal_code character varying NOT NULL,
    city_delivery_name character varying,
    city_delivery_detail character varying,
    city_centroid postgis.geometry(Point,4326)
);


--
-- Name: registered_protected_designation_of_origins; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.registered_protected_designation_of_origins (
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
-- Name: registered_seeds; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.registered_seeds (
    number integer NOT NULL,
    specie character varying NOT NULL,
    name jsonb,
    complete_name jsonb
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
    id character varying NOT NULL,
    technical_workflow_sequence_id character varying NOT NULL,
    name jsonb NOT NULL,
    family character varying,
    specie character varying,
    production_system character varying,
    year_start integer,
    year_stop integer,
    technical_workflow_id character varying NOT NULL
);


--
-- Name: technical_workflows; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.technical_workflows (
    id character varying NOT NULL,
    name jsonb NOT NULL,
    family character varying,
    specie character varying,
    production_system character varying,
    start_day integer,
    start_month integer,
    unit character varying,
    life_state character varying,
    life_cycle character varying
);


--
-- Name: user_roles; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.user_roles (
    id integer NOT NULL,
    reference_name character varying,
    name jsonb,
    label_fra character varying,
    accesses text[]
);


--
-- Name: variant_categories; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.variant_categories (
    id integer NOT NULL,
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


--
-- Name: variant_doer_contracts; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.variant_doer_contracts (
    id character varying NOT NULL,
    reference_name character varying NOT NULL,
    name jsonb,
    duration character varying,
    weekly_working_time character varying,
    gross_hourly_wage numeric(19,4),
    net_hourly_wage numeric(19,4),
    coefficient_total_cost numeric(19,4),
    variant_id character varying
);


--
-- Name: variant_natures; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.variant_natures (
    id integer NOT NULL,
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


--
-- Name: variant_prices; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.variant_prices (
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
-- Name: variant_units; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.variant_units (
    id character varying NOT NULL,
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


--
-- Name: variants; Type: TABLE; Schema: lexicon; Owner: -
--

CREATE TABLE lexicon.variants (
    id character varying NOT NULL,
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


--
-- Name: cadastral_land_parcel_zones cadastral_land_parcel_zones_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.cadastral_land_parcel_zones
    ADD CONSTRAINT cadastral_land_parcel_zones_pkey PRIMARY KEY (id);


--
-- Name: ephy_cropsets ephy_cropsets_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.ephy_cropsets
    ADD CONSTRAINT ephy_cropsets_pkey PRIMARY KEY (id);


--
-- Name: eu_market_prices eu_market_prices_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.eu_market_prices
    ADD CONSTRAINT eu_market_prices_pkey PRIMARY KEY (id);


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
-- Name: master_production_natures master_production_natures_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.master_production_natures
    ADD CONSTRAINT master_production_natures_pkey PRIMARY KEY (id);


--
-- Name: master_production_outputs master_production_outputs_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.master_production_outputs
    ADD CONSTRAINT master_production_outputs_pkey PRIMARY KEY (production_nature_id, production_system_name, name);


--
-- Name: phenological_stages phenological_stages_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.phenological_stages
    ADD CONSTRAINT phenological_stages_pkey PRIMARY KEY (id);


--
-- Name: registered_agroedi_codes registered_agroedi_codes_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.registered_agroedi_codes
    ADD CONSTRAINT registered_agroedi_codes_pkey PRIMARY KEY (id);


--
-- Name: registered_chart_of_accounts registered_chart_of_accounts_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.registered_chart_of_accounts
    ADD CONSTRAINT registered_chart_of_accounts_pkey PRIMARY KEY (id);


--
-- Name: registered_enterprises registered_enterprises_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.registered_enterprises
    ADD CONSTRAINT registered_enterprises_pkey PRIMARY KEY (establishment_number);


--
-- Name: registered_hydro_items registered_hydro_items_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.registered_hydro_items
    ADD CONSTRAINT registered_hydro_items_pkey PRIMARY KEY (id);


--
-- Name: registered_legal_positions registered_legal_positions_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.registered_legal_positions
    ADD CONSTRAINT registered_legal_positions_pkey PRIMARY KEY (id);


--
-- Name: registered_pfi_crops registered_pfi_crops_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.registered_pfi_crops
    ADD CONSTRAINT registered_pfi_crops_pkey PRIMARY KEY (id);


--
-- Name: registered_pfi_targets registered_pfi_targets_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.registered_pfi_targets
    ADD CONSTRAINT registered_pfi_targets_pkey PRIMARY KEY (id);


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
-- Name: registered_phytosanitary_usages registered_phytosanitary_usages_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.registered_phytosanitary_usages
    ADD CONSTRAINT registered_phytosanitary_usages_pkey PRIMARY KEY (id);


--
-- Name: registered_postal_zones registered_postal_zones_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.registered_postal_zones
    ADD CONSTRAINT registered_postal_zones_pkey PRIMARY KEY (id);


--
-- Name: registered_protected_designation_of_origins registered_protected_designation_of_origins_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.registered_protected_designation_of_origins
    ADD CONSTRAINT registered_protected_designation_of_origins_pkey PRIMARY KEY (id);


--
-- Name: registered_seeds registered_seeds_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.registered_seeds
    ADD CONSTRAINT registered_seeds_pkey PRIMARY KEY (number);


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
-- Name: technical_workflow_sequences technical_workflow_sequences_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.technical_workflow_sequences
    ADD CONSTRAINT technical_workflow_sequences_pkey PRIMARY KEY (id);


--
-- Name: technical_workflows technical_workflows_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.technical_workflows
    ADD CONSTRAINT technical_workflows_pkey PRIMARY KEY (id);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- Name: variant_categories variant_categories_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.variant_categories
    ADD CONSTRAINT variant_categories_pkey PRIMARY KEY (id);


--
-- Name: variant_doer_contracts variant_doer_contracts_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.variant_doer_contracts
    ADD CONSTRAINT variant_doer_contracts_pkey PRIMARY KEY (id);


--
-- Name: variant_natures variant_natures_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.variant_natures
    ADD CONSTRAINT variant_natures_pkey PRIMARY KEY (id);


--
-- Name: variant_prices variant_prices_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.variant_prices
    ADD CONSTRAINT variant_prices_pkey PRIMARY KEY (id);


--
-- Name: variant_units variant_units_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.variant_units
    ADD CONSTRAINT variant_units_pkey PRIMARY KEY (id);


--
-- Name: variants variants_pkey; Type: CONSTRAINT; Schema: lexicon; Owner: -
--

ALTER TABLE ONLY lexicon.variants
    ADD CONSTRAINT variants_pkey PRIMARY KEY (id);


--
-- Name: cadastral_land_parcel_zones_centroid; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX cadastral_land_parcel_zones_centroid ON lexicon.cadastral_land_parcel_zones USING gist (centroid);


--
-- Name: cadastral_land_parcel_zones_shape; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX cadastral_land_parcel_zones_shape ON lexicon.cadastral_land_parcel_zones USING gist (shape);


--
-- Name: ephy_cropsets_crop_names; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX ephy_cropsets_crop_names ON lexicon.ephy_cropsets USING btree (crop_names);


--
-- Name: eu_market_prices_category; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX eu_market_prices_category ON lexicon.eu_market_prices USING btree (category);


--
-- Name: eu_market_prices_id; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX eu_market_prices_id ON lexicon.eu_market_prices USING btree (id);


--
-- Name: eu_market_prices_product_code; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX eu_market_prices_product_code ON lexicon.eu_market_prices USING btree (product_code);


--
-- Name: eu_market_prices_sector_code; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX eu_market_prices_sector_code ON lexicon.eu_market_prices USING btree (sector_code);


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
-- Name: master_production_natures_agroedi_crop_code; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_production_natures_agroedi_crop_code ON lexicon.master_production_natures USING btree (agroedi_crop_code);


--
-- Name: master_production_natures_cap_2017_crop_code; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_production_natures_cap_2017_crop_code ON lexicon.master_production_natures USING btree (cap_2017_crop_code);


--
-- Name: master_production_natures_cap_2018_crop_code; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_production_natures_cap_2018_crop_code ON lexicon.master_production_natures USING btree (cap_2018_crop_code);


--
-- Name: master_production_natures_cap_2019_crop_code; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_production_natures_cap_2019_crop_code ON lexicon.master_production_natures USING btree (cap_2019_crop_code);


--
-- Name: master_production_natures_human_name; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_production_natures_human_name ON lexicon.master_production_natures USING btree (human_name);


--
-- Name: master_production_natures_human_name_fra; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_production_natures_human_name_fra ON lexicon.master_production_natures USING btree (human_name_fra);


--
-- Name: master_production_natures_pfi_crop_code; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_production_natures_pfi_crop_code ON lexicon.master_production_natures USING btree (pfi_crop_code);


--
-- Name: master_production_natures_specie; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_production_natures_specie ON lexicon.master_production_natures USING btree (specie);


--
-- Name: master_production_outputs_name; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_production_outputs_name ON lexicon.master_production_outputs USING btree (name);


--
-- Name: master_production_outputs_nature_id; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_production_outputs_nature_id ON lexicon.master_production_outputs USING btree (production_nature_id);


--
-- Name: master_production_outputs_system_name; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_production_outputs_system_name ON lexicon.master_production_outputs USING btree (production_system_name);


--
-- Name: master_vine_varieties_id; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX master_vine_varieties_id ON lexicon.master_vine_varieties USING btree (id);


--
-- Name: registered_agroedi_codes_reference_code; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_agroedi_codes_reference_code ON lexicon.registered_agroedi_codes USING btree (reference_code);


--
-- Name: registered_building_zones_centroid; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_building_zones_centroid ON lexicon.registered_building_zones USING gist (centroid);


--
-- Name: registered_building_zones_shape; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_building_zones_shape ON lexicon.registered_building_zones USING gist (shape);


--
-- Name: registered_chart_of_accounts_account_number; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_chart_of_accounts_account_number ON lexicon.registered_chart_of_accounts USING btree (account_number);


--
-- Name: registered_crop_zones_centroid; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_crop_zones_centroid ON lexicon.registered_crop_zones USING gist (centroid);


--
-- Name: registered_crop_zones_id_idx; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_crop_zones_id_idx ON lexicon.registered_crop_zones USING btree (id);


--
-- Name: registered_crop_zones_shape; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_crop_zones_shape ON lexicon.registered_crop_zones USING gist (shape);


--
-- Name: registered_enterprises_french_main_activity_code; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_enterprises_french_main_activity_code ON lexicon.registered_enterprises USING btree (french_main_activity_code);


--
-- Name: registered_enterprises_name; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_enterprises_name ON lexicon.registered_enterprises USING btree (name);


--
-- Name: registered_hydro_items_nature; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_hydro_items_nature ON lexicon.registered_hydro_items USING btree (nature);


--
-- Name: registered_pfi_doses_crop_id; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_pfi_doses_crop_id ON lexicon.registered_pfi_doses USING btree (crop_id);


--
-- Name: registered_pfi_doses_france_maaid; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_pfi_doses_france_maaid ON lexicon.registered_pfi_doses USING btree (france_maaid);


--
-- Name: registered_pfi_doses_harvest_year; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_pfi_doses_harvest_year ON lexicon.registered_pfi_doses USING btree (harvest_year);


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
-- Name: registered_phytosanitary_products_nature; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_phytosanitary_products_nature ON lexicon.registered_phytosanitary_products USING btree (nature);


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
-- Name: registered_phytosanitary_usages_product_id; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_phytosanitary_usages_product_id ON lexicon.registered_phytosanitary_usages USING btree (product_id);


--
-- Name: registered_phytosanitary_usages_species; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_phytosanitary_usages_species ON lexicon.registered_phytosanitary_usages USING btree (species);


--
-- Name: registered_postal_zones_centroid; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_postal_zones_centroid ON lexicon.registered_postal_zones USING gist (city_centroid);


--
-- Name: registered_postal_zones_city_name; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_postal_zones_city_name ON lexicon.registered_postal_zones USING btree (city_name);


--
-- Name: registered_postal_zones_country; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_postal_zones_country ON lexicon.registered_postal_zones USING btree (country);


--
-- Name: registered_postal_zones_postal_code; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_postal_zones_postal_code ON lexicon.registered_postal_zones USING btree (postal_code);


--
-- Name: registered_seeds_specie; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX registered_seeds_specie ON lexicon.registered_seeds USING btree (specie);


--
-- Name: technical_workflow_procedure_items_procedure_reference; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX technical_workflow_procedure_items_procedure_reference ON lexicon.technical_workflow_procedure_items USING btree (procedure_reference);


--
-- Name: technical_workflow_procedure_items_technical_workflow_pro_id; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX technical_workflow_procedure_items_technical_workflow_pro_id ON lexicon.technical_workflow_procedure_items USING btree (technical_workflow_procedure_id);


--
-- Name: technical_workflow_sequences_family; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX technical_workflow_sequences_family ON lexicon.technical_workflow_sequences USING btree (family);


--
-- Name: technical_workflow_sequences_specie; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX technical_workflow_sequences_specie ON lexicon.technical_workflow_sequences USING btree (specie);


--
-- Name: technical_workflow_sequences_technical_workflow_id; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX technical_workflow_sequences_technical_workflow_id ON lexicon.technical_workflow_sequences USING btree (technical_workflow_id);


--
-- Name: technical_workflow_sequences_technical_workflow_sequence_id; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX technical_workflow_sequences_technical_workflow_sequence_id ON lexicon.technical_workflow_sequences USING btree (technical_workflow_sequence_id);


--
-- Name: technical_workflows_procedures_procedure_reference; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX technical_workflows_procedures_procedure_reference ON lexicon.technical_workflow_procedures USING btree (procedure_reference);


--
-- Name: technical_workflows_procedures_technical_workflow_id; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX technical_workflows_procedures_technical_workflow_id ON lexicon.technical_workflow_procedures USING btree (technical_workflow_id);


--
-- Name: variant_categories_reference_name; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX variant_categories_reference_name ON lexicon.variant_categories USING btree (reference_name);


--
-- Name: variant_natures_reference_name; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX variant_natures_reference_name ON lexicon.variant_natures USING btree (reference_name);


--
-- Name: variant_natures_variety; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX variant_natures_variety ON lexicon.variant_natures USING btree (variety);


--
-- Name: variant_prices_reference_article_name; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX variant_prices_reference_article_name ON lexicon.variant_prices USING btree (reference_article_name);


--
-- Name: variant_prices_reference_name; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX variant_prices_reference_name ON lexicon.variant_prices USING btree (reference_name);


--
-- Name: variant_prices_reference_packaging_name; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX variant_prices_reference_packaging_name ON lexicon.variant_prices USING btree (reference_packaging_name);


--
-- Name: variant_units_reference_name; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX variant_units_reference_name ON lexicon.variant_units USING btree (reference_name);


--
-- Name: variant_units_unit_id; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX variant_units_unit_id ON lexicon.variant_units USING btree (unit_id);


--
-- Name: variants_category; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX variants_category ON lexicon.variants USING btree (category);


--
-- Name: variants_nature; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX variants_nature ON lexicon.variants USING btree (nature);


--
-- Name: variants_reference_name; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX variants_reference_name ON lexicon.variants USING btree (reference_name);


--
-- Name: variants_variant_category_id; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX variants_variant_category_id ON lexicon.variants USING btree (variant_category_id);


--
-- Name: variants_variant_nature_id; Type: INDEX; Schema: lexicon; Owner: -
--

CREATE INDEX variants_variant_nature_id ON lexicon.variants USING btree (variant_nature_id);


--
-- PostgreSQL database dump complete
--

