--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.10
-- Dumped by pg_dump version 9.5.10

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

SET search_path = lexicon, pg_catalog;

--
-- Data for Name: registered_legal_positions; Type: TABLE DATA; Schema: lexicon; Owner: -
--

COPY registered_legal_positions (id, name, nature, country, code, insee_code, fiscal_positions) FROM stdin;
1	{"fra": "Entreprise individuelle (ou micro-entreprise)"}	individual	fra	EI	1000	{fr_bic_ir,fr_bic_is,fr_bnc_ir,fr_bnc_is}
2	{"fra": "Groupement Agricole d'Exploitation en Commun"}	person	fra	GAEC	6533	{fr_ba_ir,fr_ba_is}
3	{"fra": "Exploitation agricole à responsabilité limitée"}	person	fra	EARL	6598	{fr_ba_ir,fr_ba_is}
4	{"fra": "Groupement foncier agricole"}	person	fra	GFA	6534	{fr_ba_ir,fr_ba_is}
5	{"fra": "Société civile d'exploitation agricole"}	person	fra	SCEA	6597	{fr_ba_ir,fr_ba_is}
6	{"fra": "Société à responsabilité limitée"}	capital	fra	SARL	5499	{fr_bic_ir,fr_bic_is,fr_bnc_ir,fr_bnc_is}
7	{"fra": "Entreprise unipersonnelle à responsabilité limitée"}	person	fra	EURL	5498	{fr_bic_ir,fr_bic_is,fr_bnc_ir,fr_bnc_is}
8	{"fra": "Société anonyme"}	capital	fra	SA	5510	{fr_bic_ir,fr_bic_is,fr_bnc_ir,fr_bnc_is}
9	{"fra": "Société par actions simplifiées"}	capital	fra	SAS	5710	{fr_bic_ir,fr_bic_is,fr_bnc_ir,fr_bnc_is}
10	{"fra": "Société en nom collectif"}	person	fra	SNC	5202	{fr_bic_ir,fr_bic_is,fr_bnc_ir,fr_bnc_is}
11	{"fra": "Entreprise individuelle à responsabilité limitée"}	capital	fra	EIRL	5498	{fr_bic_ir,fr_bic_is,fr_bnc_ir,fr_bnc_is}
12	{"fra": "Société par actions simplifiées unipersonnelle"}	capital	fra	SASU	5720	{fr_bic_ir,fr_bic_is,fr_bnc_ir,fr_bnc_is}
13	{"fra": "Société en participation"}	person	fra	SEP	2310	{fr_bic_ir,fr_bic_is,fr_bnc_ir,fr_bnc_is}
14	{"fra": "Société civile immobilière"}	person	fra	SCI	6540	{fr_bic_ir,fr_bic_is,fr_bnc_ir,fr_bnc_is}
15	{"fra": "Association"}	person	fra	ASSO	9220	{fr_bic_ir,fr_bic_is,fr_bnc_ir,fr_bnc_is}
16	{"fra": "Société civile d'intérêt collectif agricole "}	person	fra	SICA	6532	{fr_bic_ir,fr_bic_is,fr_bnc_ir,fr_bnc_is}
17	{"fra": "Société en commandite par actions"}	capital	fra	SCA	5308	{fr_bic_ir,fr_bic_is,fr_bnc_ir,fr_bnc_is}
18	{"fra": "Société en commandite simple"}	person	fra	SCS	5306	{fr_bic_ir,fr_bic_is,fr_bnc_ir,fr_bnc_is}
19	{"fra": "Coopérative"}	person	fra	COOP	6317	{fr_ba_ir,fr_ba_is,fr_bic_ir,fr_bic_is,fr_bnc_ir,fr_bnc_is}
20	{"fra": "Coopérative d'utilisation de matériel agricole en commun"}	person	fra	CUMA	6316	{fr_ba_ir,fr_ba_is}
21	{"fra": "Groupement d'intérêt économique"}	person	fra	GIE	6220	{fr_ba_ir,fr_ba_is,fr_bic_ir,fr_bic_is,fr_bnc_ir,fr_bnc_is}
\.

--
-- PostgreSQL database dump complete
--
