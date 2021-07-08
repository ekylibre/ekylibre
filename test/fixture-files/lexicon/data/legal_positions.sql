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

--
-- Data for Name: master_legal_positions; Type: TABLE DATA; Schema: lexicon; Owner: -
--

COPY lexicon__5_0_0.master_legal_positions (code, name, nature, country, insee_code, fiscal_positions) FROM stdin;
EI	{"fra": "Entreprise individuelle (ou micro-entreprise)"}	individual	fra	1000	{fr_ba_ir,fr_ba_is,fr_bic_ir,fr_bic_is,fr_bnc_ir,fr_bnc_is}
GAEC	{"fra": "Groupement Agricole d'Exploitation en Commun"}	person	fra	6533	{fr_ba_ir,fr_ba_is}
EARL	{"fra": "Exploitation agricole à responsabilité limitée"}	person	fra	6598	{fr_ba_ir,fr_ba_is}
GFA	{"fra": "Groupement foncier agricole"}	person	fra	6534	{fr_ba_ir,fr_ba_is}
SCEA	{"fra": "Société civile d'exploitation agricole"}	person	fra	6597	{fr_ba_ir,fr_ba_is}
SARL	{"fra": "Société à responsabilité limitée"}	capital	fra	5499	{fr_bic_ir,fr_bic_is,fr_bnc_ir,fr_bnc_is}
EURL	{"fra": "Entreprise unipersonnelle à responsabilité limitée"}	person	fra	5498	{fr_bic_ir,fr_bic_is,fr_bnc_ir,fr_bnc_is}
SA	{"fra": "Société anonyme"}	capital	fra	5510	{fr_bic_ir,fr_bic_is,fr_bnc_ir,fr_bnc_is}
SAS	{"fra": "Société par actions simplifiées"}	capital	fra	5710	{fr_bic_ir,fr_bic_is,fr_bnc_ir,fr_bnc_is}
SNC	{"fra": "Société en nom collectif"}	person	fra	5202	{fr_bic_ir,fr_bic_is,fr_bnc_ir,fr_bnc_is}
EIRL	{"fra": "Entreprise individuelle à responsabilité limitée"}	capital	fra	5498	{fr_bic_ir,fr_bic_is,fr_bnc_ir,fr_bnc_is}
SASU	{"fra": "Société par actions simplifiées unipersonnelle"}	capital	fra	5720	{fr_bic_ir,fr_bic_is,fr_bnc_ir,fr_bnc_is}
SEP	{"fra": "Société en participation"}	person	fra	2310	{fr_bic_ir,fr_bic_is,fr_bnc_ir,fr_bnc_is}
SCI	{"fra": "Société civile immobilière"}	person	fra	6540	{fr_bic_ir,fr_bic_is,fr_bnc_ir,fr_bnc_is}
ASSO	{"fra": "Association"}	person	fra	9220	{fr_bic_ir,fr_bic_is,fr_bnc_ir,fr_bnc_is}
SICA	{"fra": "Société civile d'intérêt collectif agricole"}	person	fra	6532	{fr_bic_ir,fr_bic_is,fr_bnc_ir,fr_bnc_is}
SCA	{"fra": "Société en commandite par actions"}	capital	fra	5308	{fr_bic_ir,fr_bic_is,fr_bnc_ir,fr_bnc_is}
SCS	{"fra": "Société en commandite simple"}	person	fra	5306	{fr_bic_ir,fr_bic_is,fr_bnc_ir,fr_bnc_is}
COOP	{"fra": "Coopérative"}	person	fra	6317	{fr_ba_ir,fr_ba_is,fr_bic_ir,fr_bic_is,fr_bnc_ir,fr_bnc_is}
CUMA	{"fra": "Coopérative d'utilisation de matériel agricole en commun"}	person	fra	6316	{fr_ba_ir,fr_ba_is}
GIE	{"fra": "Groupement d'intérêt économique"}	person	fra	6220	{fr_ba_ir,fr_ba_is,fr_bic_ir,fr_bic_is,fr_bnc_ir,fr_bnc_is}
\.
