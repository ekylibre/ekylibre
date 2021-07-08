--
-- PostgreSQL database dump
--

-- Dumped from database version 11.2
-- Dumped by pg_dump version 11.7 (Debian 11.7-0+deb10u1)

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

COPY lexicon__5_0_0.master_variant_categories (reference_name, family, fixed_asset_account, fixed_asset_allocation_account, fixed_asset_expenses_account, depreciation_percentage, purchase_account, sale_account, stock_account, stock_movement_account, default_vat_rate, payment_frequency_value, payment_frequency_unit, translation_id) FROM stdin;
additional_activity	service	\N	\N	\N	\N	\N	product_accessory_revenues	\N	\N	20.00	\N	\N	categories_additional_activity
adult_breeding_animal	animal	adult_animal_assets	adult_animal_asset_depreciations	corporeal_depreciations_inputations_expenses_living_goods	20.00	outstanding_adult_animal_assets	tangible_fixed_assets_revenues_livestock	long_time_animal_stock	adult_reproductor_animals_inventory_variations	10.00	\N	\N	categories_adult_breeding_animal
installation	zone	general_installation_assets	general_installation_assets_amortization	corporeal_depreciations_inputations_expenses	10.00	outstanding_land_parcel_construction_assets	tangible_fixed_assets_revenues_without_livestock	\N	\N	20.00	\N	\N	categories_installation
depreciable_office_equipment	equipment	office_equipment_assets	office_equipment_asset_depreciations	corporeal_depreciations_inputations_expenses	20.00	outstanding_equipment_assets	tangible_fixed_assets_revenues_without_livestock	\N	\N	20.00	\N	\N	categories_depreciable_office_equipment
perennial_crop	crop	sustainables_plants_assets	sustainables_plants_asset_depreciations	corporeal_depreciations_inputations_expenses_living_goods	5.00	outstanding_sustainables_plants_assets	tangible_fixed_assets_revenues_livestock	long_cycle_vegetals_stock	long_cycle_vegetals_inventory_variations	20.00	\N	\N	categories_perennial_crop
associate	worker	\N	\N	\N	\N	associates_salary	\N	\N	\N	20.00	1	per_month	categories_associate
depreciable_tool	equipment	tools_assets	tools_assets_amortization	corporeal_depreciations_inputations_expenses	20.00	outstanding_equipment_assets	tangible_fixed_assets_revenues_without_livestock	\N	\N	20.00	\N	\N	categories_depreciable_tool
equipment	equipment	equipment_assets	equipment_assets_amortization	corporeal_depreciations_inputations_expenses	15.00	outstanding_equipment_assets	tangible_fixed_assets_revenues_without_livestock	\N	\N	20.00	\N	\N	categories_equipment
fertilizer	article	\N	\N	\N	\N	fertilizer_expenses	\N	fertilizer_stock	fertilizer_stocks_variation	20.00	\N	\N	categories_fertilizer
material	article	\N	\N	\N	\N	materials_expenses	\N	other_materials_stock	materials_stocks_variation	20.00	\N	\N	categories_material
permanent_worker	worker	\N	\N	\N	\N	permanent_staff_salary	\N	\N	\N	20.00	1	per_month	categories_permanent_worker
plant_medicine	article	\N	\N	\N	\N	plant_medicine_matter_expenses	\N	plant_medicine_stock	plant_medicine_stocks_variation	20.00	\N	\N	categories_plant_medicine
seed_and_plant	article	\N	\N	\N	\N	seed_expenses	\N	seed_stock	seed_stocks_variation	10.00	\N	\N	categories_seed_and_plant
\.

COPY lexicon__5_0_0.master_variant_natures (reference_name, family, population_counting, frozen_indicators, variable_indicators, abilities, variety, derivative_of, translation_id) FROM stdin;
acidifier	article	decimal	{net_mass,net_volume}	{}	{acidify(fermented_juice),transform(wine)}	preparation	\N	natures_acidifier
agricultural_service	service	decimal	{usage_duration,net_surface_area,net_mass,net_volume,members_count}	{}	{}	service	\N	natures_agricultural_service
blower	equipment	unitary	{nominal_storable_net_volume}	{motor_power,geolocation}	{blow}	trailed_equipment	\N	natures_blower
bird_band	animal	integer	{reproductor,sex}	{}	{consume(water),consume(plant),consume(preparation),produce(excrement),produce(egg)}	aves	\N	natures_bird_band
building_division	zone	unitary	{net_surface_area}	{nominal_storable_net_mass,nominal_storable_net_volume,shape}	{store(preparation),store(equipment)}	building_division	\N	natures_building_division
crop	crop	decimal	{net_surface_area}	{fresh_mass,plant_life_state,plant_reproduction_state,plants_count,shape,tiller_count}	{consume(water),consume(preparation),produce(straw)}	plant	\N	natures_crop
fee_and_external_service	service	decimal	{usage_duration,net_surface_area,net_mass,net_volume,energy}	{}	{}	service	\N	natures_fee_and_external_service
material	article	decimal	{}	{diameter,height,length}	{}	preparation	\N	natures_material
organic_fertilizer	article	decimal	{net_mass,net_volume}	{mass_volume_density,nitrogen_concentration,phosphorus_concentration,potassium_concentration,sulfur_dioxide_concentration,magnesium_concentration,manganese_concentration,calcium_concentration,zinc_concentration,sodium_concentration,copper_concentration}	{fertilize}	excrement	bioproduct	natures_organic_fertilizer
plant_medicine	article	decimal	{net_mass,net_volume}	{}	{care(plant)}	preparation	\N	natures_plant_medicine
seed	article	decimal	{net_mass,thousand_grains_mass,grains_count}	{}	{grow}	seed	plant	natures_seed
water_spreader	equipment	unitary	{application_width,spans_count,length,volume_flow}	{diameter}	{spread(water)}	fixed_equipment	\N	natures_water_spreader
worker	worker	unitary	{}	{}	{administer_care(animal),drive(equipment),milk(mammalia),repair(equipment),move}	worker	\N	natures_worker
stake	article	integer	{}	{}	{enclose}	stake	\N	natures_stake
connected_object	equipment	unitary	{}	{geolocation}	{}	connected_object	\N	natures_connected_object
\.

COPY lexicon__5_0_0.master_variants (reference_name, family, category, nature, sub_family, default_unit, target_specie, specie, indicators, translation_id) FROM stdin;
hose_reel	equipment	equipment	water_spreader	fixed_equipment	unity	\N	\N	{}	variants_hose_reel
stake	article	material	stake	\N	unity	\N	\N	{}	variants_stake
horse_manure	article	fertilizer	organic_fertilizer	fertilizer	ton	equus_caballus	\N	{"nitrogen_concentration": "0.82percent"}	variants_horse_manure
additional_activity	service	additional_activity	fee_and_external_service	\N	unity	\N	\N	{}	variants_additional_activity
permanent_worker	worker	permanent_worker	worker	\N	unity	\N	\N	{}	variants_permanent_worker
common_wheat_seed	article	seed_and_plant	seed	seed_and_plant	kilogram	triticum_aestivum	\N	{}	variants_common_wheat_seed
geolocation_box	equipment	equipment	connected_object	\N	unity	\N	\N	{}	variants_geolocation_box
\.
