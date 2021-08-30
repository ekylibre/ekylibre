--
-- PostgreSQL database dump
--

-- Dumped from database version 11.2
-- Dumped by pg_dump version 11.9 (Debian 11.9-0+deb10u1)

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
-- Data for Name: datasource_credits; Type: TABLE DATA; Schema: lexicon__5_0_0; Owner: lexicon
--

COPY lexicon__5_0_0.datasource_credits (datasource, name, url, provider, licence, licence_url, updated_at) FROM stdin;
vine_varieties	vine varieties	https://www.franceagrimer.fr/filieres-Vin-et-cidre/Vin/Accompagner/Dispositifs-par-filiere/Normalisation-Qualite/Bois-et-plants-de-vigne/Catalogue-officiel-des-varietes-de-vigne	FranceAgriMer	NC-BY-SA 4.0	https://creativecommons.org/licenses/by-nc-sa/4.0/	2020-10-19 00:00:00+00
phenological_stages	phenological stages	https://ekylibre.com	Ekylibre SAS	CC-BY-SA 4.0	https://creativecommons.org/licenses/by-sa/4.0/deed.fr	2020-02-12 00:00:00+00
productions	productions	https://ekylibre.com	Ekylibre SAS	CC-BY-SA 4.0	https://creativecommons.org/licenses/by-sa/4.0/deed.fr	2021-01-27 00:00:00+00
enterprises	enterprises	https://www.data.gouv.fr/fr/datasets/base-sirene-des-entreprises-et-de-leurs-etablissements-siren-siret/	INSEE	Open Licence 2.0	https://www.etalab.gouv.fr/licence-ouverte-open-licence	2020-09-01 00:00:00+00
user_roles	default users and roles	https://ekylibre.com	Ekylibre SAS	CC-BY-SA 4.0	https://creativecommons.org/licenses/by-sa/4.0/deed.fr	2021-01-27 00:00:00+00
graphic_parcels	graphic parcels	https://geoservices.ign.fr/documentation/diffusion/telechargement-donnees-libres.html#rpg	IGN	Open Licence	https://www.etalab.gouv.fr/wp-content/uploads/2014/05/Licence_Ouverte.pdf	2019-01-15 00:00:00+00
eu_market_prices	eu market prices	https://ec.europa.eu/info/food-farming-fisheries/farming/facts-and-figures/markets/prices/price-monitoring-sector/eu-prices-selected-representative-products_fr	European Union			2020-06-18 00:00:00+00
pesticide_frequency_indicator	ift	https://alim.agriculture.gouv.fr/ift/	DGPE	Open Licence 2.0	https://www.etalab.gouv.fr/licence-ouverte-open-licence	2020-09-24 00:00:00+00
intervention_models	intervention models	https://ekylibre.com	Ekylibre SAS	CC-BY-SA 4.0	https://creativecommons.org/licenses/by-sa/4.0/deed.fr	2020-02-12 00:00:00+00
technical_workflow_sequences	technical workflow sequence	https://ekylibre.com	Ekylibre SAS	CC-BY-SA 4.0	https://creativecommons.org/licenses/by-sa/4.0/deed.fr	2020-02-12 00:00:00+00
open_nomenclature	open nomenclature	https://open-nomenclature.org/	Ekylibre SAS	CC-BY-SA 4.0	https://creativecommons.org/licenses/by-sa/4.0/deed.fr	2020-02-12 00:00:00+00
technical_workflows	technical workflow	https://ekylibre.com	Ekylibre SAS	CC-BY-SA 4.0	https://creativecommons.org/licenses/by-sa/4.0/deed.fr	2020-02-12 00:00:00+00
taxonomy	taxonomy	https://ekylibre.com	Ekylibre SAS	CC-BY-SA 4.0	https://creativecommons.org/licenses/by-sa/4.0/deed.fr	2021-01-27 00:00:00+00
units	units	https://ekylibre.com	Ekylibre SAS	CC-BY-SA 4.0	https://creativecommons.org/licenses/by-sa/4.0/deed.fr	2021-01-28 00:00:00+00
seed_varieties	seed varieties	https://www.gnis.fr/catalogue-varietes/base-varietes-gnis/	GNIS			2020-07-24 00:00:00+00
agroedi	agroedi	https://agroedieurope.fr/	AgroEDI	proprietary		2018-01-01 00:00:00+00
phytosanitary	phytosanitary	https://www.data.gouv.fr/fr/datasets/donnees-ouvertes-du-catalogue-e-phy-des-produits-phytopharmaceutiques-matieres-fertilisantes-et-supports-de-culture-adjuvants-produits-mixtes-et-melanges/	ANSES	Open Licence	https://www.etalab.gouv.fr/wp-content/uploads/2014/05/Licence_Ouverte.pdf	2021-01-29 00:00:00+00
chart_of_accounts	chart of accounts	https://ekylibre.com	Ekylibre SAS	CC-BY-SA 4.0	https://creativecommons.org/licenses/by-sa/4.0/deed.fr	2020-02-12 00:00:00+00
legal_positions	legal positions	https://ekylibre.com	Ekylibre SAS	CC-BY-SA 4.0	https://creativecommons.org/licenses/by-sa/4.0/deed.fr	2020-02-12 00:00:00+00
cadastre	cadastre	https://cadastre.data.gouv.fr/	Etalab	Open Licence 2.0	https://www.etalab.gouv.fr/wp-content/uploads/2017/04/ETALAB-Licence-Ouverte-v2.0.pdf	2020-09-07 00:00:00+00
postal_codes	postal codes	https://www.data.gouv.fr/fr/datasets/base-officielle-des-codes-postaux/	Groupe La Poste	ODbl	https://opendatacommons.org/licenses/odbl/summary/	2020-09-24 00:00:00+00
quality_and_origin_signs	quality and origin signs	https://www.data.gouv.fr/fr/datasets/aires-et-produits-aoc-aop-et-igp/	INAO	Open Licence	https://www.etalab.gouv.fr/wp-content/uploads/2014/05/Licence_Ouverte.pdf	2020-11-05 00:00:00+00
hydrography	hydrography	https://geoservices.ign.fr/documentation/diffusion/telechargement-donnees-libres.html#bd-topo	IGN	Open Licence	https://www.etalab.gouv.fr/wp-content/uploads/2014/05/Licence_Ouverte.pdf	2020-09-15 00:00:00+00
translations	translations	https://ekylibre.com	Ekylibre SAS	CC-BY-SA 4.0	https://creativecommons.org/licenses/by-sa/4.0/deed.fr	2021-01-27 00:00:00+00
variants	variants	https://ekylibre.com	Ekylibre SAS	CC-BY-SA 4.0	https://creativecommons.org/licenses/by-sa/4.0/deed.fr	2021-01-28 00:00:00+00
prices	prices	https://ekylibre.com	Ekylibre SAS	CC-BY-SA 4.0	https://creativecommons.org/licenses/by-sa/4.0/deed.fr	2021-01-28 00:00:00+00
\.


--
-- PostgreSQL database dump complete
--

