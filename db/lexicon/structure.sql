CREATE TABLE cadastral_land_parcel_zones (
  id character varying PRIMARY KEY NOT NULL,
  section character varying,
  work_number character varying,
  net_surface_area integer,
  shape postgis.geometry(MultiPolygon,4326) NOT NULL,
  centroid postgis.geometry(Point,4326)
);
CREATE INDEX cadastral_land_parcel_zones_id ON cadastral_land_parcel_zones(id);
CREATE INDEX cadastral_land_parcel_zones_shape ON cadastral_land_parcel_zones USING GIST (shape);
CREATE INDEX cadastral_land_parcel_zones_centroid ON cadastral_land_parcel_zones USING GIST (centroid);

CREATE TABLE registered_chart_of_accounts (
  id character varying PRIMARY KEY NOT NULL,
  account_number character varying NOT NULL,
  chart_id character varying NOT NULL,
  reference_name character varying,
  previous_reference_name character varying,
  name jsonb
);
CREATE INDEX registered_chart_of_accounts_id ON registered_chart_of_accounts(id);
CREATE INDEX registered_chart_of_accounts_account_number ON registered_chart_of_accounts(account_number);

CREATE TABLE intervention_models (
  id character varying PRIMARY KEY NOT NULL,
  name jsonb,
  category_name jsonb,
  number character varying,
  procedure_reference character varying NOT NULL,
  working_flow numeric(19,4),
  working_flow_unit character varying
);

CREATE INDEX intervention_models_id ON intervention_models(id);
CREATE INDEX intervention_models_name ON intervention_models(name);
CREATE INDEX intervention_models_procedure_reference ON intervention_models(procedure_reference);

CREATE TABLE intervention_model_items (
  id character varying PRIMARY KEY NOT NULL,
  procedure_item_reference character varying NOT NULL,
  article_reference character varying,
  indicator_name character varying,
  indicator_value numeric(19,4),
  indicator_unit character varying,
  intervention_model_id character varying
);

CREATE INDEX intervention_model_items_id ON intervention_model_items(id);
CREATE INDEX intervention_model_items_procedure_item_reference ON intervention_model_items(procedure_item_reference);
CREATE INDEX intervention_model_items_article_reference ON intervention_model_items(article_reference);
CREATE INDEX intervention_model_items_intervention_model_id ON intervention_model_items(intervention_model_id);

CREATE TABLE master_production_natures (
  id integer PRIMARY KEY NOT NULL,
  specie character varying NOT NULL,
  human_name JSONB,
  human_name_fra character varying,
  started_on DATE NOT NULL,
  stopped_on DATE NOT NULL,
  agroedi_crop_code character varying,
  season character varying,
  pfi_crop_code character varying,
  cap_2017_crop_code character varying,
  cap_2018_crop_code character varying,
  cap_2019_crop_code character varying
);
CREATE INDEX master_production_natures_specie ON master_production_natures(specie);
CREATE INDEX master_production_natures_human_name ON master_production_natures(human_name);
CREATE INDEX master_production_natures_human_name_fra ON master_production_natures(human_name_fra);
CREATE INDEX master_production_natures_agroedi_crop_code ON master_production_natures(agroedi_crop_code);
CREATE INDEX master_production_natures_pfi_crop_code ON master_production_natures(pfi_crop_code);
CREATE INDEX master_production_natures_cap_2017_crop_code ON master_production_natures(cap_2017_crop_code);
CREATE INDEX master_production_natures_cap_2018_crop_code ON master_production_natures(cap_2018_crop_code);
CREATE INDEX master_production_natures_cap_2019_crop_code ON master_production_natures(cap_2019_crop_code);

CREATE TABLE master_production_outputs (
  production_nature_id INTEGER NOT NULL,
  production_system_name VARCHAR NOT NULL,
  name VARCHAR NOT NULL,
  average_yield NUMERIC(19,4),
  main BOOLEAN NOT NULL DEFAULT FALSE,
  analysis_items VARCHAR[],
  PRIMARY KEY (production_nature_id, production_system_name, name)
);
CREATE INDEX master_production_outputs_nature_id ON master_production_outputs(production_nature_id);
CREATE INDEX master_production_outputs_system_name ON master_production_outputs(production_system_name);
CREATE INDEX master_production_outputs_name ON master_production_outputs(name);

CREATE TABLE master_vine_varieties (
  id character varying NOT NULL,
  specie_name character varying NOT NULL,
  specie_long_name character varying,
  category_name character varying NOT NULL,
  fr_validated character varying,
  utility character varying,
  color character varying,
  customs_code character varying
);
CREATE INDEX master_vine_varieties_id ON master_vine_varieties(id);

CREATE TABLE registered_postal_zones (
  country character varying NOT NULL,
  code character varying NOT NULL,
  city_name character varying NOT NULL,
  postal_code character varying NOT NULL,
  city_delivery_name character varying,
  city_delivery_detail character varying,
  city_centroid postgis.geometry(Point,4326)
);
CREATE INDEX registered_postal_zones_country ON registered_postal_zones(country);
CREATE INDEX registered_postal_zones_city_name ON registered_postal_zones(city_name);
CREATE INDEX registered_postal_zones_postal_code ON registered_postal_zones(postal_code);
CREATE INDEX registered_postal_zones_centroid ON registered_postal_zones USING GIST (city_centroid);

CREATE TABLE registered_agroedi_codes (
  id integer PRIMARY KEY NOT NULL,
  repository_id character varying,
  reference_id character varying,
  reference_code character varying,
  reference_label character varying,
  ekylibre_scope character varying,
  ekylibre_value character varying
);
CREATE INDEX registered_agroedi_codes_reference_code ON registered_agroedi_codes(reference_code);

CREATE TABLE registered_building_zones (
  nature character varying,
  shape postgis.geometry(MultiPolygon,4326) NOT NULL,
  centroid postgis.geometry(Point,4326)
);
CREATE INDEX registered_building_zones_shape ON registered_building_zones USING GIST (shape);
CREATE INDEX registered_building_zones_centroid ON registered_building_zones USING GIST (centroid);

CREATE TABLE registered_crop_zones (
  id character varying NOT NULL,
  city_name character varying,
  shape postgis.geometry(Polygon,4326) NOT NULL,
  centroid postgis.geometry(Point,4326)
);
CREATE INDEX registered_crop_zones_id ON registered_crop_zones(id);
CREATE INDEX registered_crop_zones_shape ON registered_crop_zones USING GIST (shape);
CREATE INDEX registered_crop_zones_centroid ON registered_crop_zones USING GIST (centroid);

CREATE TABLE registered_enterprises (
  establishment_number character varying PRIMARY KEY NOT NULL,
  french_main_activity_code character varying NOT NULL,
  name character varying,
  address character varying,
  postal_code character varying,
  city character varying,
  country character varying
);

CREATE TABLE registered_legal_positions (
  id integer PRIMARY KEY NOT NULL,
  name jsonb,
  nature character varying NOT NULL,
  country character varying NOT NULL,
  code character varying NOT NULL,
  insee_code character varying NOT NULL,
  fiscal_positions text[]
);
CREATE INDEX registered_legal_positions_id ON registered_legal_positions(id);

CREATE TABLE registered_pfi_crops (
  id integer PRIMARY KEY NOT NULL,
  reference_label_fra character varying
);
CREATE INDEX registered_pfi_crops_id ON registered_pfi_crops(id);

CREATE TABLE registered_pfi_doses (
  maaid integer NOT NULL,
  pesticide_name character varying,
  harvest_year integer NOT NULL,
  active integer NOT NULL,
  crop_id integer NOT NULL,
  target_id integer,
  functions character varying,
  dose_unity character varying,
  dose_quantity numeric(19,4)
);
CREATE INDEX registered_pfi_doses_maaid ON registered_pfi_doses(maaid);
CREATE INDEX registered_pfi_doses_harvest_year ON registered_pfi_doses(harvest_year);
CREATE INDEX registered_pfi_doses_crop_id ON registered_pfi_doses(crop_id);

CREATE TABLE registered_pfi_targets (
  id integer PRIMARY KEY NOT NULL,
  reference_label_fra character varying
);
CREATE INDEX registered_pfi_targets_id ON registered_pfi_targets(id);

CREATE TABLE registered_phytosanitary_products (
  id integer PRIMARY KEY NOT NULL,
    name character varying NOT NULL,
    other_name character varying,
    nature character varying,
    active_compounds character varying,
    maaid character varying NOT NULL,
    mix_category_code character varying NOT NULL,
    in_field_reentry_delay integer,
    state character varying NOT NULL,
    started_on date,
    stopped_on date,
    allowed_mentions jsonb,
    restricted_mentions character varying,
    operator_protection_mentions text,
    firm_name character varying,
    product_type character varying
);
CREATE INDEX registered_phytosanitary_products_name ON registered_phytosanitary_products(name);
CREATE INDEX registered_phytosanitary_products_nature ON registered_phytosanitary_products(nature);
CREATE INDEX registered_phytosanitary_products_maaid ON registered_phytosanitary_products(maaid);
CREATE INDEX registered_phytosanitary_products_id ON registered_phytosanitary_products(id);
CREATE INDEX registered_phytosanitary_products_firm_name ON registered_phytosanitary_products(firm_name);

CREATE TABLE registered_phytosanitary_usages (
    id character varying PRIMARY KEY NOT NULL,
    product_id integer NOT NULL,
    ephy_usage_phrase character varying NOT NULL,
    specie character varying,
    target_name jsonb,
    description jsonb,
    treatment jsonb,
    untreated_buffer_distance integer,
    dose_quantity numeric(19,4),
    dose_unit character varying,
    dose_unit_name character varying,
    dose_unit_factor real,
    pre_harvest_delay integer,
    pre_harvest_delay_bbch integer,
    applications_count integer,
    applications_frequency jsonb,
    development_stage_min integer,
    development_stage_max integer,
    usage_conditions character varying,
    untreated_buffer_aquatic integer,
    untreated_buffer_arthropod integer,
    untreated_buffer_plants integer,
    decision_date date
);
CREATE INDEX registered_phytosanitary_usages_id ON registered_phytosanitary_usages(id);
CREATE INDEX registered_phytosanitary_usages_product_id ON registered_phytosanitary_usages(product_id);
CREATE INDEX registered_phytosanitary_usages_specie ON registered_phytosanitary_usages(specie);

CREATE TABLE registered_phytosanitary_risks (
  product_id integer NOT NULL,
  risk_code character varying NOT NULL,
  risk_phrase character varying NOT NULL
);
CREATE INDEX registered_phytosanitary_risks_product_id ON registered_phytosanitary_risks(product_id);

CREATE TABLE registred_protected_designation_of_origins (
  ida integer NOT NULL,
  geographic_area character varying,
  fr_sign character varying,
  eu_sign character varying,
  product_human_name JSONB,
  product_human_name_fra character varying,
  reference_number character varying
);
CREATE INDEX registred_protected_designation_of_origins_ida ON registred_protected_designation_of_origins(ida);

CREATE TABLE registered_seeds (
  number integer PRIMARY KEY NOT NULL,
  specie character varying NOT NULL,
  name jsonb,
  complete_name jsonb
);
CREATE INDEX registered_seeds_specie ON registered_seeds(specie);
CREATE INDEX registered_seeds_number ON registered_seeds(number);

CREATE TABLE registered_hydro_items (
  id character varying PRIMARY KEY NOT NULL,
  name jsonb,
  nature character varying,
  point postgis.geometry(Point,4326),
  shape postgis.geometry(MultiPolygonZM,4326),
  lines postgis.geometry(MultiLineStringZM,4326)
);
CREATE INDEX registered_hydro_items_id ON registered_hydro_items(id);
CREATE INDEX registered_hydro_items_nature ON registered_hydro_items(nature);

CREATE TABLE technical_worflows (
  id character varying PRIMARY KEY NOT NULL,
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

CREATE INDEX technical_worflows_id ON technical_worflows(id);

CREATE TABLE technical_worflow_procedures (
  id character varying PRIMARY KEY NOT NULL,
  position integer NOT NULL,
  name jsonb NOT NULL,
  repetition integer,
  frequency character varying,
  period character varying,
  procedure_reference character varying NOT NULL,
  technical_worflow_id character varying NOT NULL
);

CREATE INDEX technical_worflows_procedures_id ON technical_worflow_procedures(id);
CREATE INDEX technical_worflows_procedures_technical_worflow_id ON technical_worflow_procedures(technical_worflow_id);
CREATE INDEX technical_worflows_procedures_procedure_reference ON technical_worflow_procedures(procedure_reference);

CREATE TABLE technical_worflow_procedure_items (
  id character varying PRIMARY KEY NOT NULL,
  actor_reference character varying,
  procedure_item_reference character varying,
  article_reference character varying,
  quantity numeric(19,4),
  unit character varying,
  procedure_reference character varying NOT NULL,
  technical_worflow_procedure_id character varying NOT NULL
);

CREATE INDEX technical_worflow_procedure_items_id ON technical_worflow_procedure_items(id);
CREATE INDEX technical_worflow_procedure_items_technical_worflow_pro_id ON technical_worflow_procedure_items(technical_worflow_procedure_id);
CREATE INDEX technical_worflow_procedure_items_procedure_reference ON technical_worflow_procedure_items(procedure_reference);

CREATE TABLE technical_worflow_sequences (
  id character varying PRIMARY KEY NOT NULL,
  technical_worflow_sequence_id character varying NOT NULL,
  name jsonb NOT NULL,
  family character varying,
  specie character varying,
  production_system character varying,
  year_start integer,
  year_stop integer,
  technical_worflow_id character varying NOT NULL
);

CREATE INDEX technical_worflow_sequences_id ON technical_worflow_sequences(id);
CREATE INDEX technical_worflow_sequences_technical_worflow_sequence_id ON technical_worflow_sequences(technical_worflow_sequence_id);
CREATE INDEX technical_worflow_sequences_family ON technical_worflow_sequences(family);
CREATE INDEX technical_worflow_sequences_specie ON technical_worflow_sequences(specie);
CREATE INDEX technical_worflow_sequences_technical_worflow_id ON technical_worflow_sequences(technical_worflow_id);
