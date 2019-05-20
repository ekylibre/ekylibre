CREATE TABLE cadastral_land_parcel_zones (
  id character varying,
  section character varying,
  work_number character varying,
  net_surface_area integer,
  shape postgis.geometry(MultiPolygon,4326) NOT NULL,
  centroid postgis.geometry(Point,4326)
);
CREATE INDEX cadastral_land_parcel_zones_shape ON cadastral_land_parcel_zones USING GIST (shape);
CREATE INDEX cadastral_land_parcel_zones_centroid ON cadastral_land_parcel_zones USING GIST (centroid);

CREATE TABLE master_accountancy_profiles (
  id integer PRIMARY KEY,
  nature character varying NOT NULL,
  revenue_account character varying,
  charge_account character varying,
  stock_account character varying,
  stock_movement_account character varying,
  fixed_asset_account character varying,
  fixed_asset_allocation_account character varying,
  fixed_asset_expenses_account character varying,
  depreciation_percentage integer
);

CREATE TABLE master_fertilizers (
  id integer PRIMARY KEY NOT NULL,
  name character varying NOT NULL,
  label_fra character varying NOT NULL,
  variant character varying NOT NULL,
  variety character varying NOT NULL,
  derivative_of character varying,
  nature character varying NOT NULL,
  nitrogen_concentration numeric(19,4),
  phosphorus_concentration numeric(19,4),
  potassium_concentration numeric(19,4),
  sulfur_trioxyde_concentration numeric(19,4)
);
CREATE INDEX master_fertilizers_name ON master_fertilizers(name);
CREATE INDEX master_fertilizers_nature ON master_fertilizers(nature);

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

CREATE TABLE master_equipment_natures (
  id integer PRIMARY KEY NOT NULL,
  name jsonb,
  nature character varying UNIQUE NOT NULL,
  main_frozen_indicator_name character varying,
  main_frozen_indicator_unit character varying,
  other_frozen_indicator_name character varying
);
CREATE INDEX master_equipment_natures_name ON master_equipment_natures(name);
CREATE INDEX master_equipment_natures_nature ON master_equipment_natures(nature);

CREATE TABLE master_equipment_costs (
  id integer PRIMARY KEY NOT NULL,
  equipment_nature_id integer NOT NULL,
  indicator_name character varying,
  minimal_value numeric(19,4),
  maximal_value numeric(19,4),
  indicator_unit character varying,
  unit character varying NOT NULL,
  segment_1_threshold numeric(19,4),
  segment_1_amount numeric(19,4),
  segment_2_threshold numeric(19,4),
  segment_2_amount numeric(19,4),
  segment_3_threshold numeric(19,4),
  segment_3_amount numeric(19,4),
  segment_average_amount numeric(19,4) NOT NULL,
  currency character varying NOT NULL
);
CREATE INDEX master_equipment_costs_nature_id ON master_equipment_costs(equipment_nature_id);

CREATE TABLE master_equipment_flows (
  id integer PRIMARY KEY NOT NULL,
  equipment_nature_id integer NOT NULL,
  indicator_name character varying,
  indicator_value numeric(19,4),
  indicator_unit character varying,
  procedure_name character varying,
  intervention_flow numeric(19,4)
);
CREATE INDEX master_equipment_flows_nature_id ON master_equipment_flows(equipment_nature_id);

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
  nature character varying NOT NULL,
  maaid character varying NOT NULL,
  mix_category_code character varying NOT NULL,
  in_field_reentry_delay integer NOT NULL,
  firm_name character varying NOT NULL
);
CREATE INDEX registered_phytosanitary_products_name ON registered_phytosanitary_products(name);
CREATE INDEX registered_phytosanitary_products_nature ON registered_phytosanitary_products(nature);
CREATE INDEX registered_phytosanitary_products_maaid ON registered_phytosanitary_products(maaid);
CREATE INDEX registered_phytosanitary_products_id ON registered_phytosanitary_products(id);
CREATE INDEX registered_phytosanitary_products_firm_name ON registered_phytosanitary_products(firm_name);

CREATE TABLE registered_phytosanitary_usages (
  product_id integer NOT NULL,
  specie character varying NOT NULL,
  target_name jsonb,
  description jsonb,
  treatment jsonb,
  untreated_buffer_distance integer,
  dose_quantity numeric(19,4) NOT NULL,
  dose_unit character varying,
  dose_unit_name character varying,
  pre_harvest_delay integer NOT NULL,
  applications_count integer NOT NULL,
  applications_frequency jsonb
);
CREATE INDEX registered_phytosanitary_usages_product_id ON registered_phytosanitary_usages(product_id);
CREATE INDEX registered_phytosanitary_usages_specie ON registered_phytosanitary_usages(specie);

CREATE TABLE registered_phytosanitary_risks (
  product_id integer NOT NULL,
  risk_code character varying NOT NULL
);
CREATE INDEX registered_phytosanitary_risks_product_id ON registered_phytosanitary_risks(product_id);

CREATE TABLE registered_phytosanitary_phrases (
  product_id integer NOT NULL,
  phrase_code character varying NOT NULL
);
CREATE INDEX registered_phytosanitary_phrases_product_id ON registered_phytosanitary_phrases(product_id);

CREATE TABLE registered_seeds (
  number integer PRIMARY KEY NOT NULL,
  specie character varying NOT NULL,
  name jsonb,
  complete_name jsonb
);
CREATE INDEX registered_seeds_specie ON registered_seeds(specie);
CREATE INDEX registered_seeds_number ON registered_seeds(number);

CREATE TABLE registered_water_rivers (
  name character varying,
  shape postgis.geometry(LineString,4326) NOT NULL
);
CREATE INDEX registered_water_rivers_shape ON registered_water_rivers USING GIST (shape);

CREATE TABLE registered_water_lakes (
  name character varying,
  shape postgis.geometry(Polygon,4326) NOT NULL
);
CREATE INDEX registered_water_lakes_shape ON registered_water_lakes USING GIST (shape);
