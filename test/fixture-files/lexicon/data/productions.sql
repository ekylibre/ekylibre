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

COPY lexicon__3_0_0.master_production_natures FROM stdin;
154	vitis	{"fra": "Vigne - raisins de cuve en production"}	Vigne - raisins de cuve en production	2000-11-01	2001-10-31	ZMO		1194	VRC	VRC	VRC	VRC	{"3": "n_3_4_leaf", "2": "n_2_3_leaf", "4": "n_4_5_leaf"}	30.00
\.

COPY lexicon__3_0_0.master_production_outputs (production_nature_id, production_system_name, name, average_yield, main, analysis_items) FROM stdin;
30	intensive_farming	grain	4.5000	t	{impurity_concentration,water_content_rate}
31	intensive_farming	grain	4.5000	t	{impurity_concentration,water_content_rate}
50	intensive_farming	grain	5.2000	t	{impurity_concentration,water_content_rate}
51	intensive_farming	grain	6.2000	t	{impurity_concentration,water_content_rate}
193	intensive_farming	grain	0.0000	t	{impurity_concentration,water_content_rate}
194	intensive_farming	grain	0.0000	t	{impurity_concentration,water_content_rate}
37	intensive_farming	grain	2.3000	t	{impurity_concentration,water_content_rate}
36	intensive_farming	grain	1.5000	t	{impurity_concentration,water_content_rate}
347	intensive_farming	grain	1.5000	t	{impurity_concentration,water_content_rate}
263	intensive_farming	grain	2.5000	t	{impurity_concentration,water_content_rate}
264	intensive_farming	grain	2.5000	t	{impurity_concentration,water_content_rate}
350	intensive_farming	grain	\N	t	{impurity_concentration,water_content_rate}
26	intensive_farming	grain	5.3000	t	{impurity_concentration,water_content_rate}
27	intensive_farming	grain	4.1000	t	{impurity_concentration,water_content_rate}
181	intensive_farming	grain	0.0000	t	{impurity_concentration,water_content_rate}
182	intensive_farming	grain	0.0000	t	{impurity_concentration,water_content_rate}
24	intensive_farming	grain	6.5000	t	{impurity_concentration,water_content_rate}
25	intensive_farming	grain	5.5000	t	{impurity_concentration,water_content_rate}
175	intensive_farming	grain	4.0000	t	{impurity_concentration,water_content_rate}
23	intensive_farming	grain	2.5000	t	{impurity_concentration,water_content_rate}
22	intensive_farming	grain	3.5000	t	{impurity_concentration,water_content_rate}
17	intensive_farming	grain	5.5000	t	{impurity_concentration,water_content_rate}
168	intensive_farming	grain	4.0000	t	{impurity_concentration,water_content_rate}
15	intensive_farming	grain	5.0000	t	{impurity_concentration,water_content_rate}
16	intensive_farming	grain	5.0000	t	{impurity_concentration,water_content_rate}
14	intensive_farming	grain	1.2000	t	{impurity_concentration,water_content_rate}
13	intensive_farming	grain	5.7000	t	{impurity_concentration,water_content_rate}
18	intensive_farming	grain	5.6000	t	{hagberg_falling_number,impurity_concentration,specific_weight,water_content_rate,protein_concentration}
19	intensive_farming	grain	5.6000	t	{hagberg_falling_number,impurity_concentration,specific_weight,water_content_rate,protein_concentration}
7	intensive_farming	grain	7.7000	t	{hagberg_falling_number,impurity_concentration,specific_weight,water_content_rate,protein_concentration}
5	intensive_farming	grain	7.2000	t	{hagberg_falling_number,impurity_concentration,specific_weight,water_content_rate,protein_concentration}
6	intensive_farming	grain	7.2000	t	{hagberg_falling_number,impurity_concentration,specific_weight,water_content_rate,protein_concentration}
10	intensive_farming	grain	8.7000	t	{impurity_concentration,water_content_rate}
8	intensive_farming	grain	17.0000	t	{impurity_concentration,water_content_rate,break_grain_rate,expansion_rate}
3	intensive_farming	grain	4.9000	t	{hagberg_falling_number,impurity_concentration,specific_weight,water_content_rate,protein_concentration,grade}
4	intensive_farming	grain	4.9000	t	{hagberg_falling_number,impurity_concentration,specific_weight,water_content_rate,protein_concentration,grade}
1	intensive_farming	plant	4.5000	t	{impurity_concentration,water_content_rate,insane_oat_rate}
2	intensive_farming	grain	4.5000	t	{impurity_concentration,water_content_rate,insane_oat_rate}
20	intensive_farming	grain	3.7000	t	{impurity_concentration,water_content_rate,oil_rate,protein_concentration}
21	intensive_farming	grain	3.7000	t	{impurity_concentration,water_content_rate,oil_rate,protein_concentration}
33	intensive_farming	hay	12.0000	t	{dry_matter_rate}
40	intensive_farming	hay	12.0000	t	{dry_matter_rate}
201	intensive_farming	hay	0.0000	t	{dry_matter_rate}
32	intensive_farming	hay	6.0000	t	{dry_matter_rate}
199	intensive_farming	hay	0.0000	t	{dry_matter_rate}
313	intensive_farming	hay	6.0000	t	{dry_matter_rate}
29	intensive_farming	hay	5.0000	t	{dry_matter_rate}
39	intensive_farming	hay	5.0000	t	{dry_matter_rate}
185	intensive_farming	hay	0.0000	t	{dry_matter_rate}
28	intensive_farming	hay	3.5000	t	{dry_matter_rate}
38	intensive_farming	hay	3.5000	t	{dry_matter_rate}
183	intensive_farming	hay	0.0000	t	{dry_matter_rate}
9	intensive_farming	silage	18.0000	t	{dry_matter_rate,protein_concentration}
121	intensive_farming	fruit	0.0000	t	\N
71	intensive_farming	vegetable	33.0000	t	\N
328	intensive_farming	fruit	0.0000	t	\N
329	intensive_farming	fruit	0.0000	t	\N
330	intensive_farming	fruit	0.0000	t	\N
332	intensive_farming	leaves	0.0000	t	\N
108	intensive_farming	leaves	3.0000	t	\N
267	intensive_farming	salt	0.0000	t	\N
135	intensive_farming	vegetable	0.0000	t	\N
53	intensive_farming	vegetable	10.0000	t	\N
54	intensive_farming	vegetable	10.0000	t	\N
155	intensive_farming	vegetable	10.0000	t	\N
352	intensive_farming	vegetable	\N	t	\N
66	intensive_farming	vegetable	25.0000	t	\N
41	intensive_farming	plant	100.0000	t	\N
117	intensive_farming	fruit	25.0000	t	\N
223	intensive_farming	fruit	0.0000	t	\N
88	intensive_farming	vegetable	54.0000	t	\N
1	intensive_farming	vegetable	27.5000	t	\N
145	intensive_farming	plant	0.0000	t	\N
152	intensive_farming	plant	0.0000	t	\N
159	intensive_farming	grain	4.0000	t	\N
169	intensive_farming	grain	4.0000	t	\N
125	intensive_farming	leaves	0.0000	t	\N
96	intensive_farming	vegetable	10.0000	t	\N
188	intensive_farming	grain	0.0000	t	\N
191	intensive_farming	grain	0.0000	t	\N
167	intensive_farming	grain	4.0000	t	\N
1	intensive_farming	grain	6.5000	t	\N
12	intensive_farming	grain	6.5000	t	\N
119	intensive_farming	plant	0.0000	t	\N
353	intensive_farming	vegetable	\N	t	\N
49	intensive_farming	plant	5.9000	t	\N
\.
