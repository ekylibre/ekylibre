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

COPY lexicon__3_0_0.variant_natures (id, reference_name, name, label_fra, nature, population_counting, indicators, abilities, variety, derivative_of) FROM stdin;
1	acidifier	{"fra": "Acidifiant"}	Acidifiant	article	decimal	{net_mass,net_volume}	{acidify(fermented_juice)}	matter	\N
2	agricultural_service	{"fra": "Prestation de service agricole"}	Prestation de service agricole	fee_and_service	decimal	{usage_duration,net_surface_area,net_mass,net_volume,members_count}	{}	service	\N
3	air_compressor	{"fra": "Compresseur"}	Compresseur	equipment	unitary	{motor_power,nominal_storable_net_volume}	{blow}	equipment	\N
11	bird_band	{"fra": "Groupe d'oiseaux"}	Groupe d'oiseaux	animal	integer	{reproductor,sex}	{move,consume(water),consume(plant),consume(preparation),produce(excrement),produce(egg)}	animal	aves
12	zone	{"fra": "Zone"}	Zone	zone	unitary	{net_surface_area,nominal_storable_net_mass,nominal_storable_net_volume,shape}	{store(matter)}	zone	\N
21	crop	{"fra": "Culture"}	Culture	crop	decimal	{certification,fresh_mass,plants_count,plants_interval,plant_life_state,plant_reproduction_state,shape,tiller_count,rows_interval}	{consume(water),consume(preparation),produce(grain),produce(straw),produce(flower),produce(fruit),produce(vegetable)}	plant	plant
27	fee_and_external_service	{"fra": "Frais et service extérieur"}	Frais et service extérieur	fee_and_service	decimal	{}	{}	service	\N
54	material	{"fra": "Matériel"}	Matériel	article	decimal	{diameter,height,length}	{}	matter	\N
64	organic_fertilizer	{"fra": "Engrais organique"}	Engrais organique	article	decimal	{net_mass,net_volume,mass_volume_density,nitrogen_concentration,phosphorus_concentration,potassium_concentration,sulfur_dioxide_concentration,magnesium_concentration,manganese_concentration,calcium_concentration,zinc_concentration,sodium_concentration,copper_concentration}	{fertilize}	matter	animal
69	plant_medicine	{"fra": "Produit phytosanitaire"}	Produit phytosanitaire	article	decimal	{net_mass,net_volume,approved_input_dose,untreated_zone_length,wait_before_entering_period,wait_before_harvest_period}	{care(plant)}	preparation	\N
79	seed	{"fra": "Semence"}	Semence	article	decimal	{net_mass,thousand_grains_mass}	{grow}	matter	plant
106	water_spreader	{"fra": "Pulvérisateur d'eau"}	Pulvérisateur d'eau	equipment	unitary	{application_width,diameter,length,volume_flow,spans_count}	{spread(water)}	equipment	\N
111	worker	{"fra": "Travailleur"}	Travailleur	worker	unitary	{}	{drive(equipment),move,milk(mammalia),repair(equipment),administer_care(animal)}	worker	\N
\.

COPY lexicon__3_0_0.variant_categories (id, reference_name, name, label_fra, nature, fixed_asset_account, fixed_asset_allocation_account, fixed_asset_expenses_account, depreciation_percentage, purchase_account, sale_account, stock_account, stock_movement_account, purchasable, saleable, depreciable, storable, default_vat_rate, payment_frequency_value, payment_frequency_unit) FROM stdin;
1	additional_activity	{"fra": "Activité annexe"}	Activité annexe	fee_and_service				0		product_accessory_revenues			f	t	f	f	20.00	1	per_year
2	adult_large_specie_animal	{"fra": "Animal de grande espèce adulte"}	Animal de grande espèce adulte	animal	adult_animal_assets	adult_animal_asset_depreciations	corporeal_depreciations_inputations_expenses_living_goods	20	animal_expenses	tangible_fixed_assets_revenues_livestock			t	t	t	f	10.00	1	per_year
5	amortized_installation	{"fra": "Installation amortissable"}	Installation amortissable	zone	general_installation_assets	general_installation_assets_amortization	corporeal_depreciations_inputations_expenses	10	other_supply_expenses	tangible_fixed_assets_revenues_without_livestock			t	t	t	f	20.00	1	per_year
6	amortized_office_equipment	{"fra": "Matériel de bureau amortissable"}	Matériel de bureau amortissable	article	office_equipment_assets	office_equipment_asset_depreciations	corporeal_depreciations_inputations_expenses	20	livestock_feed_matter_expenses	tangible_fixed_assets_revenues_without_livestock			t	t	t	f	20.00	1	per_year
8	amortized_plant	{"fra": "Plantation pérenne"}	Plantation pérenne	crop	sustainables_plants_assets	sustainables_plants_asset_depreciations	corporeal_depreciations_inputations_expenses_living_goods	5	products_specials_taxes_for_animal_products	tangible_fixed_assets_revenues_livestock			t	t	t	f	20.00	1	per_year
17	associate	{"fra": "Associé d'exploitation"}	Associé d'exploitation	worker				0	co_ownership_and_locative_expenses				f	f	f	f	20.00	1	per_month
23	depreciable_tool	{"fra": "Outillage amortissable"}	Outillage amortissable	equipment	tools_assets	tools_assets_amortization	corporeal_depreciations_inputations_expenses	20	other_supply_expenses	tangible_fixed_assets_revenues_without_livestock			t	t	t	f	20.00	1	per_year
26	equipment	{"fra": "Équipement"}	Équipement	equipment	equipment_assets	equipment_assets_amortization	corporeal_depreciations_inputations_expenses	15	other_supply_expenses	tangible_fixed_assets_revenues_without_livestock			t	t	t	f	20.00	1	per_year
33	fertilizer	{"fra": "Engrais et amendement"}	Engrais et amendement	article				0	fertilizer_expenses		fertilizer_stock	fertilizer_stocks_variation	t	f	f	t	20.00	1	per_year
53	material	{"fra": "Matériau"}	Matériau	article				0	materials_expenses		other_materials_stock	materials_stocks_variation	t	f	f	t	20.00	1	per_year
67	permanent_worker	{"fra": "Personnel permanent"}	Personnel permanent	worker				0	permanent_staff_salary				f	f	f	f	20.00	1	per_month
68	plant_medicine	{"fra": "Produit phytosanitaire"}	Produit phytosanitaire	article				0	plant_medicine_matter_expenses		plant_medicine_stock	plant_medicine_stocks_variation	t	f	f	t	20.00	1	per_year
76	seed_and_plant	{"fra": "Semence et plant"}	Semence et plant	article				0	seed_expenses	plant_derivatives_revenues	seed_stock	seed_stocks_variation	t	t	f	t	10.00	1	per_year
\.

COPY lexicon__3_0_0.variants (id, class_name, reference_name, name, label_fra, category, nature, sub_nature, default_unit, target_specie, specie, eu_product_code, indicators, variant_category_id, variant_nature_id) FROM stdin;
E27	equipment	hose_reel	{"fra": "Enrouleur"}	Enrouleur	equipment	water_spreader	\N	unity	\N	\N	\N	\N	26	106
A101	article	stake	{"fra": "Piquet"}	Piquet	material	material		unity				{}	53	54
A23	article	soft_wheat_herbicide	{"fra": "Herbicide pour blé tendre"}	Herbicide pour blé tendre	plant_medicine	plant_medicine	plant_medicine	liter	triticum_aestivum			{}	68	69
AFO58	article	horse_manure	{"fra": "Fumier de chevaux"}	Fumier de chevaux	fertilizer	organic_fertilizer	fertilizer	ton	\N	equus	\N	{"nitrogen_concentration": "0.82percent"}	33	64
S1	fee_and_service	additional_activity	{"fra": "Activité annexe"}	Activité annexe	additional_activity	fee_and_external_service	\N	unity	\N	\N	\N	\N	1	27
D1	worker	permanent	{"fra": "CDI"}	CDI	permanent_worker	worker	\N	hour	\N	\N	\N	\N	67	111
A4	article	soft_wheat_seed	{"fra": "Semence de blé tendre"}	Semence de blé tendre	seed_and_plant	seed	seed_and_plant	kilogram	triticum_aestivum	triticum_aestivum		{"thousand_grains_mass": "50.0gram"}	76	79
\.
