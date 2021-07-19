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
-- Data for Name: registered_quality_and_origin_signs; Type: TABLE DATA; Schema: lexicon__5_0_0; Owner: lexicon
--

COPY lexicon__5_0_0.registered_quality_and_origin_signs (id, ida, geographic_area, fr_sign, eu_sign, product_human_name, product_human_name_fra, reference_number) FROM stdin;
4184	1645	-------	\N	IGP -	{"fra": "Pâté de Campagne Breton"}	Pâté de Campagne Breton	\N
7784	1645	-------	\N	STG -	{"fra": "Moules de bouchot"}	Moules de bouchot	STG7784
15431	1645	-------	\N	STG -	{"fra": "Berthoud"}	Berthoud	STG15431
3585	1645	-------	LR - 	\N	{"fra": "Sardines et filets de sardines pêchées à la bolinche"}	Sardines et filets de sardines pêchées à la bolinche	LA/02/06
3586	1645	-------	LR - 	\N	{"fra": "Ail rose"}	Ail rose	LA/02/66
3617	1645	-------	LR - 	\N	{"fra": "Betteraves rouges"}	Betteraves rouges	LA/03/03
3640	1645	-------	LR - 	\N	{"fra": "Abricot"}	Abricot	LA/04/01
3642	1645	-------	LR - 	\N	{"fra": "Fromage à raclette"}	Fromage à raclette	LA/04/03
3645	1645	-------	LR - 	\N	{"fra": "Pain de tradition française"}	Pain de tradition française	LA/04/05
3647	1645	-------	LR - 	\N	{"fra": "Pommes de terre"}	Pommes de terre	LA/04/68
3687	1645	-------	LR - 	\N	{"fra": "Gazon de haute qualité"}	Gazon de haute qualité	LA/05/87
3709	1645	-------	LR - 	\N	{"fra": "Sel marin de l'Atlantique"}	Sel marin de l'Atlantique	LA/06/91
3760	1645	-------	LR - 	\N	{"fra": "Veau fermier lourd élevé sous la mère et complémenté aux céréales"}	Veau fermier lourd élevé sous la mère et complémenté aux céréales	LA/08/93
3770	1645	-------	LR - 	\N	{"fra": "Farine de froment"}	Farine de froment	LA/09/05
3771	1645	-------	LR - 	\N	{"fra": "Truite de source"}	Truite de source	LA/09/06
3788	1645	-------	LR - 	\N	{"fra": "Pomme de terre à chair ferme Belle de Fontenay"}	Pomme de terre à chair ferme Belle de Fontenay	LA/09/99
3800	1645	-------	LR - 	\N	{"fra": "Pêches et nectarines"}	Pêches et nectarines	LA/10/87
3801	1645	-------	LR - 	\N	{"fra": "Crème fluide"}	Crème fluide	LA/10/89
3813	1645	-------	LR - 	\N	{"fra": "Coquille Saint-Jacques entière et fraîche"}	Coquille Saint-Jacques entière et fraîche	LA/11/02
3861	1645	-------	LR - 	\N	{"fra": "Miel toutes fleurs"}	Miel toutes fleurs	LA/13/94
3951	1645	-------	LR - 	\N	{"fra": "Haricot"}	Haricot	LA/19/97
3973	1645	-------	LR - 	\N	{"fra": "Pintadeau"}	Pintadeau	LA/21/98
3975	1645	-------	LR - 	\N	{"fra": "Baguette de pain de tradition française"}	Baguette de pain de tradition française	LA/22/01
3981	1645	-------	LR - 	\N	{"fra": "Huîtres pousse en claire"}	Huîtres pousse en claire	LA/22/98
3992	1645	-------	LR - 	\N	{"fra": "Miel de lavande et de lavandin"}	Miel de lavande et de lavandin	LA/24/89
3999	1645	-------	LR - 	\N	{"fra": "Cabécou"}	Cabécou	LA/25/05
4000	1645	-------	LR - 	\N	{"fra": "Farine type 45 label rouge pour pâtisserie"}	Farine type 45 label rouge pour pâtisserie	LA/25/06
4016	1645	-------	LR - 	\N	{"fra": "Conserves de thon"}	Conserves de thon	LA/27/06
4023	1645	-------	LR - 	\N	{"fra": "Truite fumée"}	Truite fumée	LA/28/06
4046	1645	-------	LR - 	\N	{"fra": "Noix de coquilles Saint-Jacques surgelées (Pecten maximus)"}	Noix de coquilles Saint-Jacques surgelées (Pecten maximus)	LA/06/13
4057	1645	-------	LR - 	\N	{"fra": "Viandes hachées et préparation de viande de veau fermier lourd élevé sous la mère et complémenté aux céréales"}	Viandes hachées et préparation de viande de veau fermier lourd élevé sous la mère et complémenté aux céréales	LA/34/99
4069	1645	-------	LR - 	\N	{"fra": "Filets de maquereaux marinés au Muscadet AOC et aux aromates"}	Filets de maquereaux marinés au Muscadet AOC et aux aromates	LA/01/10
4118	1645	-------	LR - 	\N	{"fra": "Pomme de terre Manon, spéciale frites"}	Pomme de terre Manon, spéciale frites	LA/11/09
4124	1645	-------	LR - 	\N	{"fra": "Marron"}	Marron	LA/02/15
4222	1645	-------	LR - 	\N	{"fra": "Escargots préparés frais et surgelé"}	Escargots préparés frais et surgelé	LA/04/83
4478	1645	-------	LR - 	\N	{"fra": "Betteraves rouges cuites sous vide"}	Betteraves rouges cuites sous vide	LA/05/97
4481	1645	-------	LR - 	\N	{"fra": "Brie au lait thermisé, crème et protéines de lait pasteurisées"}	Brie au lait thermisé, crème et protéines de lait pasteurisées	LA/28/99
4484	1645	-------	LR - 	\N	{"fra": "Miel de sapin"}	Miel de sapin	LA/06/94
4570	1645	-------	LR - 	\N	{"fra": "Betteraves rouges cuites sous vide"}	Betteraves rouges cuites sous vide	LA/08/98
4580	1645	-------	LR - 	\N	{"fra": "Lentilles vertes"}	Lentilles vertes	LA/01/96
4607	1645	-------	LR - 	\N	{"fra": "Kiwi Hayward"}	Kiwi Hayward	LA/35/90
5275	1645	-------	LR - 	\N	{"fra": "Cidre de variété Guillevic"}	Cidre de variété Guillevic	LA/15/99
7086	1645	-------	LR - 	\N	{"fra": "Plants de pomme de terre"}	Plants de pomme de terre	LA/14/99
12211	1645	-------	LR - 	\N	{"fra": "Brioche"}	Brioche	LA/02/02
12253	1645	-------	LR - 	\N	{"fra": "Ravioles"}	Ravioles	LA/14/97
12593	1645	-------	LR - 	\N	{"fra": "Viande bovine d'animaux jeunes de race limousine"}	Viande bovine d'animaux jeunes de race limousine	LA/23/88
12969	1645	-------	LR - 	\N	{"fra": "Saumon farci, farce aux petits légumes"}	Saumon farci, farce aux petits légumes	LA/07/14
12985	1645	-------	LR - 	\N	{"fra": "Fraise"}	Fraise	LA/16/08
13007	1645	-------	LR - 	\N	{"fra": "Melon"}	Melon	LA/05/91
13080	1645	-------	LR - 	\N	{"fra": "Huîtres fines de claires vertes"}	Huîtres fines de claires vertes	LA/25/89
13110	1645	-------	LR - 	\N	{"fra": "Crevette d'élevage Penaeus monodon présentée entière crue surgelée ou entière crue surgelée "}	Crevette d'élevage Penaeus monodon présentée entière crue surgelée ou entière crue surgelée 	LA/05/03
13157	1645	-------	LR - 	\N	{"fra": "Noix surgelées de pectinidés Placopecten magellanicus"}	Noix surgelées de pectinidés Placopecten magellanicus	LA/09/13
13196	1645	-------	LR - 	\N	{"fra": "Reine-Claude"}	Reine-Claude	LA/10/98
13303	1645	-------	LR - 	\N	{"fra": "Bar d'aquaculture marine "}	Bar d'aquaculture marine 	LA/01/11
13304	1645	-------	LR - 	\N	{"fra": "Daurade d’aquaculture marine"}	Daurade d’aquaculture marine	LA/02/11
13305	1645	-------	LR - 	\N	{"fra": "Maigre d’aquaculture marine"}	Maigre d’aquaculture marine	LA/03/11
13351	1645	-------	LR - 	\N	{"fra": "Conserves de sardines pêchées à la bolinche"}	Conserves de sardines pêchées à la bolinche	LA/01/03
13355	1645	-------	LR - 	\N	{"fra": "Herbes de Provence"}	Herbes de Provence	LA/02/03
13384	1645	-------	LR - 	\N	{"fra": "Mimolette vieille et extra-vieille"}	Mimolette vieille et extra-vieille	LA/26/89
13431	1645	-------	LR - 	\N	{"fra": "Turbot et découpes de turbot d'aquaculture marine"}	Turbot et découpes de turbot d'aquaculture marine	LA/15/02
13451	1645	-------	LR - 	\N	{"fra": "Soupe rouge de la mer"}	Soupe rouge de la mer	LA/08/10
13465	1645	-------	LR - 	\N	{"fra": "Noix de Saint-Jacques (Pecten maximus) fraîches ou surgelées"}	Noix de Saint-Jacques (Pecten maximus) fraîches ou surgelées	LA/07/09
13519	1645	-------	LR - 	\N	{"fra": "Cassoulet au porc appertisé"}	Cassoulet au porc appertisé	LA/03/15
13525	1645	-------	LR - 	\N	{"fra": "Lapin"}	Lapin	LA/13/97
13770	1645	-------	LR - 	\N	{"fra": "Saumon Atlantique"}	Saumon Atlantique	LA/31/05
13791	1645	-------	LR - 	\N	{"fra": "Pâtes farcies pur bœuf appertisées"}	Pâtes farcies pur bœuf appertisées	LA/05/15
13953	1645	-------	LR - 	\N	{"fra": "Haricots blancs"}	Haricots blancs	LA/27/05
13965	1645	-------	LR - 	\N	{"fra": "Soupe de poissons"}	Soupe de poissons	LA/04/09
13977	1645	-------	LR - 	\N	{"fra": "Piment doux"}	Piment doux	LA/04/16 
13978	1645	-------	LR - 	\N	{"fra": "Conserves de maquereaux"}	Conserves de maquereaux	LA/02/16 
13992	1645	-------	LR - 	\N	{"fra": "Choucroute"}	Choucroute	LA/01/09
13998	1645	-------	LR - 	\N	{"fra": "Betteraves rouges cuites sous vide"}	Betteraves rouges cuites sous vide	LA/21/99
14002	1645	-------	LR - 	\N	{"fra": "Pâté de foie de volaille supérieur"}	Pâté de foie de volaille supérieur	LA/01/16
14035	1645	-------	LR - 	\N	{"fra": "Flageolet vert"}	Flageolet vert	LA/19/06
14147	1645	-------	LR - 	\N	{"fra": "Rillettes de saumon"}	Rillettes de saumon	LA/07/16
14168	1645	-------	LR - 	\N	{"fra": "Farine pour pain de tradition française"}	Farine pour pain de tradition française	LA/11/04
14170	1645	-------	LR - 	\N	{"fra": "Farine panifiable pour pain courant"}	Farine panifiable pour pain courant	LA/20/06
14203	1645	-------	LR - 	\N	{"fra": "Fraises"}	Fraises	LA/01/17
14205	1645	-------	LR - 	\N	{"fra": "Cassoulet appertisé"}	Cassoulet appertisé	LA/02/12
14429	1645	-------	LR - 	\N	{"fra": "Saumon fumé"}	Saumon fumé	LA/04/94
14431	1645	-------	LR - 	\N	{"fra": "Pintade fermière élevée en plein air, entière et découpes, fraîche ou surgelée"}	Pintade fermière élevée en plein air, entière et découpes, fraîche ou surgelée	LA/10/77
14437	1645	-------	LR - 	\N	{"fra": "Pintade jaune fermière élevée en plein air, entière et découpes, fraîche ou surgelée"}	Pintade jaune fermière élevée en plein air, entière et découpes, fraîche ou surgelée	LA/09/94
14438	1645	-------	LR - 	\N	{"fra": "Chapon de pintade fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon de pintade fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/04/07
14450	1645	-------	LR - 	\N	{"fra": "Jambon cuit supérieur"}	Jambon cuit supérieur	LA/07/17
14451	1645	-------	LR - 	\N	{"fra": "Véritable merguez "}	Véritable merguez 	LA/06/17
14470	1645	-------	LR - 	\N	{"fra": "Viande, abats et gras de coche"}	Viande, abats et gras de coche	LA/04/15
14471	1645	-------	LR - 	\N	{"fra": "Viande fraîche et surgelée d'agneau de plus de 13 kg de carcasse, nourri par tétée au pis au moins 60 jours"}	Viande fraîche et surgelée d'agneau de plus de 13 kg de carcasse, nourri par tétée au pis au moins 60 jours	LA/05/85
14473	1645	-------	LR - 	\N	{"fra": "Viande et abats frais et surgelés d'agneau de plus de 14 kg de carcasse, nourri par tétée au pis au moins 60 jours"}	Viande et abats frais et surgelés d'agneau de plus de 14 kg de carcasse, nourri par tétée au pis au moins 60 jours	LA/31/90
14474	1645	-------	LR - 	\N	{"fra": "Viande et abats frais et surgelés d'agneau nourri exclusivement au lait maternel"}	Viande et abats frais et surgelés d'agneau nourri exclusivement au lait maternel	LA/19/92
14475	1645	-------	LR - 	\N	{"fra": "Viande fraîche et surgelée, et abats frais d'agneau de plus de 14 kg carcasse, nourri par tétée au pis au moins 60 jours"}	Viande fraîche et surgelée, et abats frais d'agneau de plus de 14 kg carcasse, nourri par tétée au pis au moins 60 jours	LA/17/93
14478	1645	-------	LR - 	\N	{"fra": "Viande fraîche et surgelée d'agneau de plus de 13 kg de carcasse, nourri par tétée au pis au moins 60 jours"}	Viande fraîche et surgelée d'agneau de plus de 13 kg de carcasse, nourri par tétée au pis au moins 60 jours	LA/09/95
14479	1645	-------	LR - 	\N	{"fra": "Viande fraîche d'agneau nourri essentiellement au lait maternel, par tétée au pis, non sevré, pouvant recevoir une complémentation par un aliment concentré"}	Viande fraîche d'agneau nourri essentiellement au lait maternel, par tétée au pis, non sevré, pouvant recevoir une complémentation par un aliment concentré	LA/16/99
14481	1645	-------	LR - 	\N	{"fra": " Viande et abats frais et surgelées d'agneau de 14 à 22 kg de carcasse, nourri par tétée au pis au moins 90 jours ou jusqu'à abattage si abattu entre 70 et 89 jours "}	 Viande et abats frais et surgelées d'agneau de 14 à 22 kg de carcasse, nourri par tétée au pis au moins 90 jours ou jusqu'à abattage si abattu entre 70 et 89 jours 	LA/05/07
14482	1645	-------	LR - 	\N	{"fra": " Viande et abats frais et surgelés d'agneau de 13 à 22 kg de carcasse, nourri par tétée au pis au moins 70 jours ou jusqu'à abattage si abattu entre 60 et 69 jours"}	 Viande et abats frais et surgelés d'agneau de 13 à 22 kg de carcasse, nourri par tétée au pis au moins 70 jours ou jusqu'à abattage si abattu entre 60 et 69 jours	LA/07/07
14483	1645	-------	LR - 	\N	{"fra": "Viande et abats frais et surgelés d'agneau nourri exclusivement au lait maternel"}	Viande et abats frais et surgelés d'agneau nourri exclusivement au lait maternel	LA/11/08
14491	1645	-------	LR - 	\N	{"fra": "Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/08/80
14492	1645	-------	LR - 	\N	{"fra": "Dinde de Noël fermière élevée en plein air, entière, fraîche ou surgelée"}	Dinde de Noël fermière élevée en plein air, entière, fraîche ou surgelée	LA/08/84
14493	1645	-------	LR - 	\N	{"fra": "Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/02/86
14494	1645	-------	LR - 	\N	{"fra": "Pintade fermière élevée en plein air, entière et découpes, fraîche ou surgelée"}	Pintade fermière élevée en plein air, entière et découpes, fraîche ou surgelée	LA/09/87
14496	1645	-------	LR - 	\N	{"fra": "Chapon blanc fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon blanc fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/29/88
14688	1483	Roquefort	AOC -	AOP -	{"fra": "Roquefort"}	Roquefort	\N
14497	1645	-------	LR - 	\N	{"fra": "Poularde fermière élevée en plein air, entière et découpes, fraîche ou surgelée"}	Poularde fermière élevée en plein air, entière et découpes, fraîche ou surgelée	LA/15/91
14498	1645	-------	LR - 	\N	{"fra": "Chapon jaune fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon jaune fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/18/02
14499	1645	-------	LR - 	\N	{"fra": "Poulet noir fermier élevé en plein air, entier et découpes, frais"}	Poulet noir fermier élevé en plein air, entier et découpes, frais	LA/21/01
14500	1645	-------	LR - 	\N	{"fra": "Dinde fermière élevée en plein air, entière, fraîche"}	Dinde fermière élevée en plein air, entière, fraîche	LA/19/87
14501	1645	-------	LR - 	\N	{"fra": "Poulet noir fermier élevé en plein air, entier et découpes, frais"}	Poulet noir fermier élevé en plein air, entier et découpes, frais	LA/10/81
14502	1645	-------	LR - 	\N	{"fra": "Poulet blanc fermier élevé en plein air, entier et découpes, frais"}	Poulet blanc fermier élevé en plein air, entier et découpes, frais	LA/04/84
14503	1645	-------	LR - 	\N	{"fra": "Poulet jaune fermier élevé en plein air, entier et découpes, frais"}	Poulet jaune fermier élevé en plein air, entier et découpes, frais	LA/14/01
14504	1645	-------	LR - 	\N	{"fra": "Poulet blanc fermier élevé en plein air, entier et découpes, frais"}	Poulet blanc fermier élevé en plein air, entier et découpes, frais	LA/01/85
14505	1645	-------	LR - 	\N	{"fra": "Pintade fermière élevée en plein air, entière et découpes, fraîche"}	Pintade fermière élevée en plein air, entière et découpes, fraîche	LA/11/97
14506	1645	-------	LR - 	\N	{"fra": "Poularde fermière élevée en plein air, entière et découpes, fraîche"}	Poularde fermière élevée en plein air, entière et découpes, fraîche	LA/25/99
14507	1645	-------	LR - 	\N	{"fra": "Chapon fermier élevé en plein air, entier et découpes, frais"}	Chapon fermier élevé en plein air, entier et découpes, frais	LA/17/97
14508	1645	-------	LR - 	\N	{"fra": "Dinde de Noël fermière élevée en plein air, entière, fraîche"}	Dinde de Noël fermière élevée en plein air, entière, fraîche	LA/05/79
14509	1645	-------	LR - 	\N	{"fra": "Chapon noir fermier élevé en plein air, entier et découpes, frais"}	Chapon noir fermier élevé en plein air, entier et découpes, frais	LA/18/06
14510	1645	-------	LR - 	\N	{"fra": " Découpes et morceaux de poulet fermier aromatisés ou condimentés ou marinés"}	 Découpes et morceaux de poulet fermier aromatisés ou condimentés ou marinés	LA/32/99
14511	1645	-------	LR - 	\N	{"fra": "Produits cuits de dinde fermière élevée en plein air"}	Produits cuits de dinde fermière élevée en plein air	LA/01/00
14512	1645	-------	LR - 	\N	{"fra": "Poulet fermier rôti et découpes cuites de poulet fermier"}	Poulet fermier rôti et découpes cuites de poulet fermier	LA/30/01
14513	1645	-------	LR - 	\N	{"fra": "Produits cuits de poulet fermier élevé en liberté"}	Produits cuits de poulet fermier élevé en liberté	LA/10/08
14514	1645	-------	LR - 	\N	{"fra": "Blanc de poulet cuit"}	Blanc de poulet cuit	LA/03/07
14515	1645	-------	LR - 	\N	{"fra": "Dinde de Noël fermière élevée en plein air, entière, fraîche"}	Dinde de Noël fermière élevée en plein air, entière, fraîche	LA/08/82
14516	1645	-------	LR - 	\N	{"fra": "Chapon blanc fermier élevé en plein air entier et découpes, frais ou surgelé"}	Chapon blanc fermier élevé en plein air entier et découpes, frais ou surgelé	LA/55/88
14517	1645	-------	LR - 	\N	{"fra": " Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé"}	 Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/22/92
14518	1645	-------	LR - 	\N	{"fra": "Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/23/92
14519	1645	-------	LR - 	\N	{"fra": "Pintade fermière élevée en plein air, entière et découpes, fraîche ou surgelée "}	Pintade fermière élevée en plein air, entière et découpes, fraîche ou surgelée 	LA/06/93
14520	1645	-------	LR - 	\N	{"fra": "Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/11/01
14521	1645	-------	LR - 	\N	{"fra": "Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/03/04
14522	1645	-------	LR - 	\N	{"fra": " Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé"}	 Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/04/04
14523	1645	-------	LR - 	\N	{"fra": "Dinde de Noël fermière élevée en plein air, entière, fraîche ou surgelée "}	Dinde de Noël fermière élevée en plein air, entière, fraîche ou surgelée 	LA/06/71
14524	1645	-------	LR - 	\N	{"fra": "Poulet gris fermier élevé en plein air, entier et découpes, frais ou surgelé "}	Poulet gris fermier élevé en plein air, entier et découpes, frais ou surgelé 	LA/12/77
14525	1645	-------	LR - 	\N	{"fra": "Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/01/81
14526	1645	-------	LR - 	\N	{"fra": "Poulet noir fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet noir fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/08/85
14527	1645	-------	LR - 	\N	{"fra": "Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/07/86
14528	1645	-------	LR - 	\N	{"fra": "Poularde fermière élevée en plein air, entière et découpes, fraîche ou surgelée"}	Poularde fermière élevée en plein air, entière et découpes, fraîche ou surgelée	LA/10/91
14529	1645	-------	LR - 	\N	{"fra": " Chapon fermier élevé en plein air, entier et découpes, frais ou surgelé"}	 Chapon fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/14/88
14530	1645	-------	LR - 	\N	{"fra": "Chapon de pintade fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon de pintade fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/16/94
14531	1645	-------	LR - 	\N	{"fra": "Dinde fermière de Noël élevée en plein air, entière, fraîche"}	Dinde fermière de Noël élevée en plein air, entière, fraîche	LA/04/88
14533	1645	-------	LR - 	\N	{"fra": "Poulet blanc fermier élevé en plein air, entier et découpes, frais"}	Poulet blanc fermier élevé en plein air, entier et découpes, frais	LA/22/90
14534	1645	-------	LR - 	\N	{"fra": "Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/50/88
14536	1645	-------	LR - 	\N	{"fra": " Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé "}	 Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé 	LA/16/92
14537	1645	-------	LR - 	\N	{"fra": "Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/18/01
14739	1645	-------	LR - 	\N	{"fra": "Pâté de tête issu de porc fermier "}	Pâté de tête issu de porc fermier 	LA/03/06
14538	1645	-------	LR - 	\N	{"fra": "Chapon blanc fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon blanc fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/11/06
14539	1645	-------	LR - 	\N	{"fra": "Chapon jaune fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon jaune fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/12/06
14540	1645	-------	LR - 	\N	{"fra": "Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/02/91
14541	1645	-------	LR - 	\N	{"fra": "Poulet noir fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet noir fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/05/98
14542	1645	-------	LR - 	\N	{"fra": "Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/11/80
14545	1645	-------	LR - 	\N	{"fra": "Chapon blanc fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon blanc fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/32/88
14546	1645	-------	LR - 	\N	{"fra": "Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/57/88
14547	1645	-------	LR - 	\N	{"fra": "Dinde de Noël fermière élevée en plein air, entière, fraîche"}	Dinde de Noël fermière élevée en plein air, entière, fraîche	LA/15/92
14548	1645	-------	LR - 	\N	{"fra": "Chapon jaune fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon jaune fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/19/00
14549	1645	-------	LR - 	\N	{"fra": "Poulet noir fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet noir fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/01/15
14550	1645	-------	LR - 	\N	{"fra": "Pintade fermière élevée en plein air, entière et découpes, fraîche ou surgelée"}	Pintade fermière élevée en plein air, entière et découpes, fraîche ou surgelée	LA/08/94
14551	1645	-------	LR - 	\N	{"fra": "Chapon de pintade fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon de pintade fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/01/14
14552	1645	-------	LR - 	\N	{"fra": "Poulet noir fermier élevé en plein air, entier et découpes, frais"}	Poulet noir fermier élevé en plein air, entier et découpes, frais	LA/02/75
14553	1645	-------	LR - 	\N	{"fra": "Poulet blanc fermier élevé en plein air, entier et découpes, frais"}	Poulet blanc fermier élevé en plein air, entier et découpes, frais	LA/02/82
14554	1645	-------	LR - 	\N	{"fra": "Dinde de Noël fermière élevée en plein air, entière, fraîche ou surgelée"}	Dinde de Noël fermière élevée en plein air, entière, fraîche ou surgelée	LA/11/86
14555	1645	-------	LR - 	\N	{"fra": "Chapon fermier élevé en plein air, entier et découpes, frais"}	Chapon fermier élevé en plein air, entier et découpes, frais	LA/28/88
14556	1645	-------	LR - 	\N	{"fra": "Pintade fermière élevée en plein air, entière et découpes, fraîche"}	Pintade fermière élevée en plein air, entière et découpes, fraîche	LA/59/88
14557	1645	-------	LR - 	\N	{"fra": "Poulet noir fermier élevé en plein air, entier et découpes, surgelé"}	Poulet noir fermier élevé en plein air, entier et découpes, surgelé	LA/19/89
14558	1645	-------	LR - 	\N	{"fra": "Poulet blanc fermier élevé en plein air, entier et découpes, surgelé"}	Poulet blanc fermier élevé en plein air, entier et découpes, surgelé	LA/14/90
14559	1645	-------	LR - 	\N	{"fra": "Chapon fermier élevé en plein air, entier et découpes, surgelé"}	Chapon fermier élevé en plein air, entier et découpes, surgelé	LA/14/91
14560	1645	-------	LR - 	\N	{"fra": "Pintade fermière élevée en plein air, entière et découpes, surgelée"}	Pintade fermière élevée en plein air, entière et découpes, surgelée	LA/06/92
14562	1645	-------	LR - 	\N	{"fra": "Poularde fermière élevée en plein air, entière et découpes, fraîche"}	Poularde fermière élevée en plein air, entière et découpes, fraîche	LA/13/92
14563	1645	-------	LR - 	\N	{"fra": "Poularde fermière élevée en plein air, entière et découpes, surgelée"}	Poularde fermière élevée en plein air, entière et découpes, surgelée	LA/14/92
14564	1645	-------	LR - 	\N	{"fra": "Chapon de pintade fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon de pintade fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/08/95
14565	1645	-------	LR - 	\N	{"fra": "Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/08/01
14566	1645	-------	LR - 	\N	{"fra": "Poulet noir fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet noir fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/01/06
14567	1645	-------	LR - 	\N	{"fra": "Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/07/85
14568	1645	-------	LR - 	\N	{"fra": "Soupe de poisson - Petite pêche de moins de 24 heures"}	Soupe de poisson - Petite pêche de moins de 24 heures	LA/05/10
14569	1645	-------	LR - 	\N	{"fra": "Poulet noir fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet noir fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/02/79
14570	1645	-------	LR - 	\N	{"fra": "Poulet noir fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet noir fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/03/83
14572	1645	-------	LR - 	\N	{"fra": "Dinde de Noël fermière élevée en plein air, entière, fraîche"}	Dinde de Noël fermière élevée en plein air, entière, fraîche	LA/06/87
14581	1645	-------	LR - 	\N	{"fra": "Chapon noir fermier élevé en plein air, entier et découpes, frais"}	Chapon noir fermier élevé en plein air, entier et découpes, frais	LA/54/88
14582	1645	-------	LR - 	\N	{"fra": "Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/02/90
14583	1645	-------	LR - 	\N	{"fra": "Chapon blanc fermier élevé en plein air, entier et découpes, frais"}	Chapon blanc fermier élevé en plein air, entier et découpes, frais	LA/13/98
14584	1645	-------	LR - 	\N	{"fra": "Poularde blanche fermière élevée en plein air, entière et découpes, fraîche"}	Poularde blanche fermière élevée en plein air, entière et découpes, fraîche	LA/28/01
14585	1645	-------	LR - 	\N	{"fra": "Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/01/02
14587	1645	-------	LR - 	\N	{"fra": "Poularde blanche fermière élevée en plein air, entière, fraîche ou surgelée"}	Poularde blanche fermière élevée en plein air, entière, fraîche ou surgelée	LA/10/02
14588	1645	-------	LR - 	\N	{"fra": "Oie fermière élevée en plein air, entière, fraîche ou surgelée"}	Oie fermière élevée en plein air, entière, fraîche ou surgelée	LA/16/97
14589	1645	-------	LR - 	\N	{"fra": "Poulet blanc fermier élevé en plein air, entier et découpes, frais"}	Poulet blanc fermier élevé en plein air, entier et découpes, frais	LA/08/87
14590	1645	-------	LR - 	\N	{"fra": "Dinde de Noël fermière élevée en plein air, entière, fraîche"}	Dinde de Noël fermière élevée en plein air, entière, fraîche	LA/16/91
14591	1645	-------	LR - 	\N	{"fra": "Chapon blanc fermier élevé en plein air, entier et découpes, frais"}	Chapon blanc fermier élevé en plein air, entier et découpes, frais	LA/14/98
14592	1645	-------	LR - 	\N	{"fra": "Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/17/87
14593	1645	-------	LR - 	\N	{"fra": "Dinde de Noël fermière élevée en plein air, entière, fraîche ou surgelée"}	Dinde de Noël fermière élevée en plein air, entière, fraîche ou surgelée	LA/26/88
14594	1645	-------	LR - 	\N	{"fra": "Poulet noir fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet noir fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/03/90
14595	1645	-------	LR - 	\N	{"fra": "Pintade fermière élevée en plein air, entière et découpes, fraîche ou surgelée"}	Pintade fermière élevée en plein air, entière et découpes, fraîche ou surgelée	LA/04/90
14596	1645	-------	LR - 	\N	{"fra": "Chapon blanc fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon blanc fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/02/01
14597	1645	-------	LR - 	\N	{"fra": "Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/06/05
14599	1645	-------	LR - 	\N	{"fra": "Dinde de Noël fermière élevée en plein air, entière, fraîche ou surgelée"}	Dinde de Noël fermière élevée en plein air, entière, fraîche ou surgelée	LA/05/78
14600	1645	-------	LR - 	\N	{"fra": "Chapon fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/30/88
14601	1645	-------	LR - 	\N	{"fra": "Chapon blanc à pattes bleues fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon blanc à pattes bleues fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/06/04
14602	1645	-------	LR - 	\N	{"fra": "Viande fraîche de veau nourri par tétée au pis pouvant recevoir une alimentation complémentaire solide"}	Viande fraîche de veau nourri par tétée au pis pouvant recevoir une alimentation complémentaire solide	LA/08/13
14603	1645	-------	LR - 	\N	{"fra": "Viande fraîche de veau nourri par tétée au pis pouvant recevoir un aliment complémentaire liquide"}	Viande fraîche de veau nourri par tétée au pis pouvant recevoir un aliment complémentaire liquide	LA/03/81
14604	1645	-------	LR - 	\N	{"fra": " Viande fraîche de veau nourri par tétée au pis pouvant recevoir un aliment complémentaire liquide"}	 Viande fraîche de veau nourri par tétée au pis pouvant recevoir un aliment complémentaire liquide	LA/20/92
14605	1645	-------	LR - 	\N	{"fra": "Viandes et abats frais de porc fermier élevé en plein air"}	Viandes et abats frais de porc fermier élevé en plein air	LA/19/88
14606	1645	-------	LR - 	\N	{"fra": "Viandes fraîches ou surgelées et abats frais de porc fermier"}	Viandes fraîches ou surgelées et abats frais de porc fermier	LA/20/88
14607	1645	-------	LR - 	\N	{"fra": "Viandes fraîches ou surgelées et abats frais de porc"}	Viandes fraîches ou surgelées et abats frais de porc	LA/31/06
14608	1645	-------	LR - 	\N	{"fra": "Viandes et abats frais de porc"}	Viandes et abats frais de porc	LA/04/89
14610	1645	-------	LR - 	\N	{"fra": "Viandes et abats de porc fermier élevé en plein air, frais et surgelés"}	Viandes et abats de porc fermier élevé en plein air, frais et surgelés	LA/09/89
14611	1645	-------	LR - 	\N	{"fra": "Viandes et abats de porc frais et surgelés"}	Viandes et abats de porc frais et surgelés	LA/17/90
14612	1645	-------	LR - 	\N	{"fra": "Viandes et abats frais de porc fermier élevé en plein air"}	Viandes et abats frais de porc fermier élevé en plein air	LA/08/91
14613	1645	-------	LR - 	\N	{"fra": "Viandes fraîches de porc"}	Viandes fraîches de porc	LA/16/98
14614	1645	-------	LR - 	\N	{"fra": "Viande et abats frais de porc"}	Viande et abats frais de porc	LA/12/04
14615	1645	-------	LR - 	\N	{"fra": "Viandes et abats, frais ou surgelés, de porc"}	Viandes et abats, frais ou surgelés, de porc	LA/02/05
14616	1645	-------	LR - 	\N	{"fra": "Viandes fraîches et surgelées, préparations dérivées et abats frais de porc"}	Viandes fraîches et surgelées, préparations dérivées et abats frais de porc	LA/16/06
14617	1645	-------	LR - 	\N	{"fra": "Viandes et abats de porc, frais et surgelés"}	Viandes et abats de porc, frais et surgelés	LA/17/06
14618	1645	-------	LR - 	\N	{"fra": "Viandes fraîches et surgelées, préparations dérivées et abats frais de porc"}	Viandes fraîches et surgelées, préparations dérivées et abats frais de porc	LA/35/06
14619	1645	-------	LR - 	\N	{"fra": "Viande et abats frais et surgelés de gros bovins de race charolaise"}	Viande et abats frais et surgelés de gros bovins de race charolaise	LA/02/74
14620	1645	-------	LR - 	\N	{"fra": "Viande fraîche de gros bovins fermiers"}	Viande fraîche de gros bovins fermiers	LA/03/86
14621	1645	-------	LR - 	\N	{"fra": "Viande fraîche et surgelée de gros bovins de race limousine"}	Viande fraîche et surgelée de gros bovins de race limousine	LA/22/88
14622	1645	-------	LR - 	\N	{"fra": "Viande et abats frais et surgelés de gros bovins de race charolaise"}	Viande et abats frais et surgelés de gros bovins de race charolaise	LA/11/89
14624	1645	-------	LR - 	\N	{"fra": "Viande et abats, frais et surgelés de gros bovins de race blonde d'Aquitaine"}	Viande et abats, frais et surgelés de gros bovins de race blonde d'Aquitaine	LA/17/91
14625	1645	-------	LR - 	\N	{"fra": "Viande et abats frais de gros bovins de boucherie"}	Viande et abats frais de gros bovins de boucherie	LA/18/91
14626	1645	-------	LR - 	\N	{"fra": " Viande fraîche de gros bovins fermiers"}	 Viande fraîche de gros bovins fermiers	LA/16/93
14627	1645	-------	LR - 	\N	{"fra": "Viande fraîche de gros bovins de boucherie"}	Viande fraîche de gros bovins de boucherie	LA/02/94
14628	1645	-------	LR - 	\N	{"fra": "Viande fraîche de gros bovins de boucherie"}	Viande fraîche de gros bovins de boucherie	LA/12/97
14629	1645	-------	LR - 	\N	{"fra": "Viande et abats frais et surgelés de gros bovins de race gasconne"}	Viande et abats frais et surgelés de gros bovins de race gasconne	LA/18/97
14630	1645	-------	LR - 	\N	{"fra": "Viande et abats frais et surgelés de gros bovins fermiers de race Aubrac"}	Viande et abats frais et surgelés de gros bovins fermiers de race Aubrac	LA/01/99
14632	1645	-------	LR - 	\N	{"fra": "Viande et abats frais et surgelés de gros bovins de race Blonde d'Aquitaine"}	Viande et abats frais et surgelés de gros bovins de race Blonde d'Aquitaine	LA/09/02
14633	1645	-------	LR - 	\N	{"fra": "Viande et abats frais et surgelés de gros bovins de race Salers"}	Viande et abats frais et surgelés de gros bovins de race Salers	LA/08/04
14634	1645	-------	LR - 	\N	{"fra": "Viande fraîche de gros bovins de race Parthenaise"}	Viande fraîche de gros bovins de race Parthenaise	LA/26/05
14635	1645	-------	LR - 	\N	{"fra": "Viande fraîche de gros bovins de race Blonde d'Aquitaine"}	Viande fraîche de gros bovins de race Blonde d'Aquitaine	LA/05/11
14664	1645	-------	LR - 	\N	{"fra": "Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/01/78
14665	1645	-------	LR - 	\N	{"fra": "Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/09/82
14666	1645	-------	LR - 	\N	{"fra": " Poulet noir fermier élevé en plein air, entier et découpes, frais ou surgelé"}	 Poulet noir fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/07/71
14667	1645	-------	LR - 	\N	{"fra": "Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/06/88
14668	1645	-------	LR - 	\N	{"fra": "Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/03/00
14669	1645	-------	LR - 	\N	{"fra": "Chapon jaune fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon jaune fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/31/88
14670	1645	-------	LR - 	\N	{"fra": "Chapon jaune fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon jaune fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/21/94
14671	1645	-------	LR - 	\N	{"fra": "Chapon blanc fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon blanc fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/18/92
14672	1645	-------	LR - 	\N	{"fra": "Dinde de noël fermière élevée en plein air, entière, fraîche"}	Dinde de noël fermière élevée en plein air, entière, fraîche	LA/15/93
14673	1645	-------	LR - 	\N	{"fra": "Poularde jaune fermière élevée en plein air, entière et découpes, fraîche ou surgelée"}	Poularde jaune fermière élevée en plein air, entière et découpes, fraîche ou surgelée	LA/06/10
14676	1645	-------	LR - 	\N	{"fra": "Canard de Barbarie fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Canard de Barbarie fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/04/74
14684	1645	-------	LR - 	\N	{"fra": "Dinde de découpe fermière élevée en plein air"}	Dinde de découpe fermière élevée en plein air	LA/02/98
14691	1645	-------	LR - 	\N	{"fra": "Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/03/17
14692	1645	-------	LR - 	\N	{"fra": "Chapon jaune fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon jaune fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/04/17
14693	1645	-------	LR - 	\N	{"fra": "Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/05/17
14694	1645	-------	LR - 	\N	{"fra": "Jambons cuits supérieurs, entiers ou tranchés, préemballés"}	Jambons cuits supérieurs, entiers ou tranchés, préemballés	LA/29/99
14695	1645	-------	LR - 	\N	{"fra": "Pâtés en croûte supérieurs"}	Pâtés en croûte supérieurs	LA/23/05
14696	1645	-------	LR - 	\N	{"fra": "Saucissons cuits supérieurs"}	Saucissons cuits supérieurs	LA/20/05
14697	1645	-------	LR - 	\N	{"fra": "Produits de saucisserie à l'ancienne"}	Produits de saucisserie à l'ancienne	LA/17/05
14698	1645	-------	LR - 	\N	{"fra": "Rôti cuit supérieur"}	Rôti cuit supérieur	LA/14/06
14699	1645	-------	LR - 	\N	{"fra": "Rillettes pur porc"}	Rillettes pur porc	LA/18/05
14700	1645	-------	LR - 	\N	{"fra": "Pâtés supérieurs"}	Pâtés supérieurs	LA/19/05
14701	1645	-------	LR - 	\N	{"fra": "Salaisons sèches à base de viande de porc"}	Salaisons sèches à base de viande de porc	LA/05/08
14702	1645	-------	LR - 	\N	{"fra": "Salaisons sèches à base de viande de coche"}	Salaisons sèches à base de viande de coche	LA/06/08
14703	1645	-------	LR - 	\N	{"fra": "Jambon sec supérieur"}	Jambon sec supérieur	LA/07/08
14704	1645	-------	LR - 	\N	{"fra": "Coppa"}	Coppa	LA/08/09
14705	1645	-------	LR - 	\N	{"fra": "Pancetta"}	Pancetta	LA/09/09
14706	1645	-------	LR - 	\N	{"fra": "Rillettes pur porc"}	Rillettes pur porc	LA/02/10
14707	1645	-------	LR - 	\N	{"fra": "Pâté de campagne supérieur"}	Pâté de campagne supérieur	LA/03/10
12248	236	Arbois	AOC -	AOP -	{"fra": "Arbois vin jaune"}	Arbois vin jaune	\N
14709	1645	-------	LR - 	\N	{"fra": "Andouillette supérieure pur porc"}	Andouillette supérieure pur porc	LA/06/16
14710	1645	-------	LR - 	\N	{"fra": "Produits de saucisserie issus de viandes de porc"}	Produits de saucisserie issus de viandes de porc	LA/10/09
14711	1645	-------	LR - 	\N	{"fra": "Jambon cru de pays"}	Jambon cru de pays	LA/09/91
14724	1645	-------	LR - 	\N	{"fra": "Jambon cuit supérieur de porc fermier entier ou prétranché"}	Jambon cuit supérieur de porc fermier entier ou prétranché	LA/45/88
14725	1645	-------	LR - 	\N	{"fra": "Jambon sec supérieur"}	Jambon sec supérieur	LA/03/73
14726	1645	-------	LR - 	\N	{"fra": "Jambon sec supérieur de porc fermier"}	Jambon sec supérieur de porc fermier	LA/46/88
14727	1645	-------	LR - 	\N	{"fra": " Salaisons sèches à base de viande de porc"}	 Salaisons sèches à base de viande de porc	LA/07/91
14728	1645	-------	LR - 	\N	{"fra": "Pâté de campagne supérieur"}	Pâté de campagne supérieur	LA/29/05
14729	1645	-------	LR - 	\N	{"fra": "Poitrine sèche ou ventrèche"}	Poitrine sèche ou ventrèche	LA/01/08
14730	1645	-------	LR - 	\N	{"fra": "Saucisse fraîche et chair à saucisse"}	Saucisse fraîche et chair à saucisse	LA/12/08
14731	1645	-------	LR - 	\N	{"fra": "Rillettes pur porc"}	Rillettes pur porc	LA/05/09
14732	1645	-------	LR - 	\N	{"fra": "Salaisons sèches à base de viande de coche"}	Salaisons sèches à base de viande de coche	LA/01/13
14733	1645	-------	LR - 	\N	{"fra": "Pâté de porc fermier"}	Pâté de porc fermier	LA/02/13
14734	1645	-------	LR - 	\N	{"fra": "Saucisson sec supérieur, saucisse sèche supérieure de porc fermier "}	Saucisson sec supérieur, saucisse sèche supérieure de porc fermier 	LA/03/13
14735	1645	-------	LR - 	\N	{"fra": "Saucisse fraîche de porc fermier"}	Saucisse fraîche de porc fermier	LA/47/88
14736	1645	-------	LR - 	\N	{"fra": "Jambon cuit supérieur entier et pré-tranché"}	Jambon cuit supérieur entier et pré-tranché	LA/21/88
14738	1645	-------	LR - 	\N	{"fra": "Saucisse chevillée et Jésus chevillé"}	Saucisse chevillée et Jésus chevillé	LA/33/05
14740	1645	-------	LR - 	\N	{"fra": "Jambon persillé"}	Jambon persillé	LA/32/06
14741	1645	-------	LR - 	\N	{"fra": "Saucisse fraîche et chair à saucisse"}	Saucisse fraîche et chair à saucisse	LA/06/07
14742	1645	-------	LR - 	\N	{"fra": "Saucisses et saucissons secs, recette à base principalement de porc charcutier"}	Saucisses et saucissons secs, recette à base principalement de porc charcutier	LA/02/08
14743	1645	-------	LR - 	\N	{"fra": "Saucisses et saucissons secs, recette à base principalement de coche"}	Saucisses et saucissons secs, recette à base principalement de coche	LA/03/08
14744	1645	-------	LR - 	\N	{"fra": "Jambon sec supérieur"}	Jambon sec supérieur	LA/04/08
14745	1645	-------	LR - 	\N	{"fra": "Saucisse fraîche et chair à saucisse"}	Saucisse fraîche et chair à saucisse	LA/13/08
14746	1645	-------	LR - 	\N	{"fra": "Jambon sec supérieur"}	Jambon sec supérieur	LA/14/08
14747	1645	-------	LR - 	\N	{"fra": "Saucisson cuit à l'ail"}	Saucisson cuit à l'ail	LA/15/08
14748	1645	-------	LR - 	\N	{"fra": "Pâté de campagne"}	Pâté de campagne	LA/04/10
14751	1645	-------	LR - 	\N	{"fra": "Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/09/80
14752	1645	-------	LR - 	\N	{"fra": "Dinde de Noël fermière élevée en plein air, entière, fraîche et surgelée"}	Dinde de Noël fermière élevée en plein air, entière, fraîche et surgelée	LA/06/86
14754	1645	-------	LR - 	\N	{"fra": "Poulet noir fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet noir fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/18/89
14755	1645	-------	LR - 	\N	{"fra": "Chapon blanc fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon blanc fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/38/89
14756	1645	-------	LR - 	\N	{"fra": "Chapon noir fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon noir fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/23/90
14759	1645	-------	LR - 	\N	{"fra": "Dinde de Noël fermière élevée en plein air, entière, fraîche et surgelée"}	Dinde de Noël fermière élevée en plein air, entière, fraîche et surgelée	LA/13/95
14760	1645	-------	LR - 	\N	{"fra": "Chapon blanc fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon blanc fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/06/98
14761	1645	-------	LR - 	\N	{"fra": "Chapon blanc fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon blanc fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/13/00
14762	1645	-------	LR - 	\N	{"fra": "Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/06/11
14763	1645	-------	LR - 	\N	{"fra": "Poulet cou nu fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet cou nu fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/01/94
14765	1645	-------	LR - 	\N	{"fra": "Chapon jaune fermier élevé en plein air, entier, frais"}	Chapon jaune fermier élevé en plein air, entier, frais	LA/48/88
14766	1645	-------	LR - 	\N	{"fra": "Poulet jaune fermier élevé en plein air, entier et découpes, frais"}	Poulet jaune fermier élevé en plein air, entier et découpes, frais	LA/19/01
14767	1645	-------	LR - 	\N	{"fra": "Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/13/88
14768	1645	-------	LR - 	\N	{"fra": "Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/15/88
14769	1645	-------	LR - 	\N	{"fra": "Chapon jaune fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon jaune fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/28/89
14771	1645	-------	LR - 	\N	{"fra": "Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/22/99
14775	1645	-------	LR - 	\N	{"fra": "Lingot"}	Lingot	LA/15/98
14776	1645	-------	LR - 	\N	{"fra": "Pintade fermière élevée en plein air, entière et découpes, fraîche ou surgelée"}	Pintade fermière élevée en plein air, entière et découpes, fraîche ou surgelée	LA/25/88
14777	1645	-------	LR - 	\N	{"fra": "Poulet jaune fermier élevé en liberté, entier et découpes, frais ou surgelé"}	Poulet jaune fermier élevé en liberté, entier et découpes, frais ou surgelé	LA/01/65
14778	1645	-------	LR - 	\N	{"fra": "Poulet blanc fermier élevé en liberté, entier et découpes, frais ou surgelé"}	Poulet blanc fermier élevé en liberté, entier et découpes, frais ou surgelé	LA/02/71
14780	1645	-------	LR - 	\N	{"fra": "Dinde de Noël fermière élevée en plein air, entière, fraîche"}	Dinde de Noël fermière élevée en plein air, entière, fraîche	LA/14/77
14781	1645	-------	LR - 	\N	{"fra": "Poulet noir fermier élevé en liberté, entier et découpes, frais ou surgelé"}	Poulet noir fermier élevé en liberté, entier et découpes, frais ou surgelé	LA/01/79
14782	1645	-------	LR - 	\N	{"fra": "Chapon jaune fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon jaune fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/14/89
14783	1645	-------	LR - 	\N	{"fra": "Poularde jaune fermière élevée en plein air, entière et découpes, fraîche ou surgelée"}	Poularde jaune fermière élevée en plein air, entière et découpes, fraîche ou surgelée	LA/07/93
14784	1645	-------	LR - 	\N	{"fra": "Chapon blanc fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon blanc fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/16/00
14785	1645	-------	LR - 	\N	{"fra": "Poulet jaune fermier élevé en liberté, entier et découpes, frais ou surgelé"}	Poulet jaune fermier élevé en liberté, entier et découpes, frais ou surgelé	LA/07/11
14786	1645	-------	LR - 	\N	{"fra": "Poulet blanc fermier élevé en liberté, entier et découpes, frais ou surgelé"}	Poulet blanc fermier élevé en liberté, entier et découpes, frais ou surgelé	LA/08/11
14787	1645	-------	LR - 	\N	{"fra": "Mini-chapon fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Mini-chapon fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/08/14
14789	1645	-------	LR - 	\N	{"fra": "Pintade jaune fermière élevée en plein air, entière et découpes, fraîche ou surgelée"}	Pintade jaune fermière élevée en plein air, entière et découpes, fraîche ou surgelée	LA/09/66
14790	1645	-------	LR - 	\N	{"fra": "Chapon de pintade jaune fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon de pintade jaune fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/17/94
14792	1645	-------	LR - 	\N	{"fra": "Foie gras cru et produits de découpe d'oie gavée"}	Foie gras cru et produits de découpe d'oie gavée	LA/17/89
14793	1645	-------	LR - 	\N	{"fra": "Foie gras cru et produits de découpe de canard mulard gavé"}	Foie gras cru et produits de découpe de canard mulard gavé	LA/16/89
14794	1645	-------	LR - 	\N	{"fra": "Canard mulard gavé entier, foie gras cru et produits de découpes crus frais et magrets surgelés"}	Canard mulard gavé entier, foie gras cru et produits de découpes crus frais et magrets surgelés	LA/12/89
14798	1645	-------	LR - 	\N	{"fra": "Poule fermière, élevée en liberté, entière et découpes, fraîche ou surgelée"}	Poule fermière, élevée en liberté, entière et découpes, fraîche ou surgelée	LA/35/88
14801	1645	-------	LR - 	\N	{"fra": "Œufs fermiers de poules élevées en plein air"}	Œufs fermiers de poules élevées en plein air	LA/03/99
14802	1645	-------	LR - 	\N	{"fra": "Œufs fermiers"}	Œufs fermiers	LA/35/99
14803	1645	-------	LR - 	\N	{"fra": "Œufs de poules élevées en plein air"}	Œufs de poules élevées en plein air	LA/09/97
14804	1645	-------	LR - 	\N	{"fra": "Œufs de poules élevées en plein air"}	Œufs de poules élevées en plein air	LA/15/00
14805	1645	-------	LR - 	\N	{"fra": "Œufs de poules élevées en plein air"}	Œufs de poules élevées en plein air	LA/04/02
14806	1645	-------	LR - 	\N	{"fra": "Œufs de poules élevées en plein air"}	Œufs de poules élevées en plein air	LA/06/02
14807	1645	-------	LR - 	\N	{"fra": "Œufs de poules élevées en plein air"}	Œufs de poules élevées en plein air	LA/08/03
14808	1645	-------	LR - 	\N	{"fra": "Œufs de poules élevées en plein air"}	Œufs de poules élevées en plein air	LA/21/06
14809	1645	-------	LR - 	\N	{"fra": "Œufs de poules élevées en plein air"}	Œufs de poules élevées en plein air	LA/34/06
14810	1645	-------	LR - 	\N	{"fra": "Œufs de poules élevées en plein air"}	Œufs de poules élevées en plein air	LA/06/12
14811	1645	-------	LR - 	\N	{"fra": "Œufs de poules élevées en plein air"}	Œufs de poules élevées en plein air	LA/23/01
14813	1645	-------	LR - 	\N	{"fra": "Dinde de Noël fermière élevée en plein air, entière, fraîche ou surgelée"}	Dinde de Noël fermière élevée en plein air, entière, fraîche ou surgelée	LA/04/86
14814	1645	-------	LR - 	\N	{"fra": "Pintade fermière élevée en plein air, entière et découpes, fraîche ou surgelée"}	Pintade fermière élevée en plein air, entière et découpes, fraîche ou surgelée	LA/60/88
14815	1645	-------	LR - 	\N	{"fra": "Chapon blanc fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon blanc fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/29/89
14816	1645	-------	LR - 	\N	{"fra": "Poularde blanche fermière élevée en plein air, entière et découpes, fraîche ou surgelée"}	Poularde blanche fermière élevée en plein air, entière et découpes, fraîche ou surgelée	LA/12/91
14817	1645	-------	LR - 	\N	{"fra": "Poularde jaune fermière élevée en plein air, entière et découpes, fraîche ou surgelée "}	Poularde jaune fermière élevée en plein air, entière et découpes, fraîche ou surgelée 	LA/13/91
14818	1645	-------	LR - 	\N	{"fra": "Oie fermière élevée en plein air, entière, fraîche ou surgelée"}	Oie fermière élevée en plein air, entière, fraîche ou surgelée	LA/09/93
14820	1645	-------	LR - 	\N	{"fra": "Chapon de pintade fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon de pintade fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/02/97
15018	1645	-------	LR - 	\N	{"fra": "Produits de poitrine de porc nature ou fumés"}	Produits de poitrine de porc nature ou fumés	LA/05/18
14821	1645	-------	LR - 	\N	{"fra": "Chapon jaune fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon jaune fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/03/97
14822	1645	-------	LR - 	\N	{"fra": "Dinde de Noël fermière élevée en plein air, entière, fraîche ou surgelée "}	Dinde de Noël fermière élevée en plein air, entière, fraîche ou surgelée 	LA/04/97
14823	1645	-------	LR - 	\N	{"fra": "Canette et canard de Barbarie fermiers élevés en plein air, entiers et découpes, frais ou surgelés"}	Canette et canard de Barbarie fermiers élevés en plein air, entiers et découpes, frais ou surgelés	LA/09/04
14824	1645	-------	LR - 	\N	{"fra": "Mini-chapon blanc fermier élevé en plein air, entier et découpes, frais ou surgelé "}	Mini-chapon blanc fermier élevé en plein air, entier et découpes, frais ou surgelé 	LA/09/14
14830	1645	-------	LR - 	\N	{"fra": "Canard fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Canard fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/02/85
14831	1645	-------	LR - 	\N	{"fra": "Poulet jaune fermier élevé en liberté, entier et découpes, frais ou surgelé"}	Poulet jaune fermier élevé en liberté, entier et découpes, frais ou surgelé	LA/04/72
14832	1645	-------	LR - 	\N	{"fra": "Chapon noir fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon noir fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/17/88
14834	1645	-------	LR - 	\N	{"fra": "Caille fermière élevée en plein air, entière et découpes, fraîche ou surgelée"}	Caille fermière élevée en plein air, entière et découpes, fraîche ou surgelée	LA/20/90
14835	1645	-------	LR - 	\N	{"fra": "Poularde noire fermière élevée en plein air, entière et découpes, fraîche ou surgelée"}	Poularde noire fermière élevée en plein air, entière et découpes, fraîche ou surgelée	LA/10/92
14837	1645	-------	LR - 	\N	{"fra": "Oie fermière élevée en plein air, entière, fraîche ou surgelée"}	Oie fermière élevée en plein air, entière, fraîche ou surgelée	LA/20/97
14838	1645	-------	LR - 	\N	{"fra": "Chapon blanc fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon blanc fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/26/99
14839	1645	-------	LR - 	\N	{"fra": "Chapon jaune fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon jaune fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/17/00
14841	1645	-------	LR - 	\N	{"fra": "Chapon blanc fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon blanc fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/04/06
14842	1645	-------	LR - 	\N	{"fra": "Chapon jaune fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon jaune fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/05/06
14844	1645	-------	LR - 	\N	{"fra": "Poularde noire fermière élevée en plein air, entière et découpes, fraîche ou surgelée"}	Poularde noire fermière élevée en plein air, entière et découpes, fraîche ou surgelée	LA/03/12
14845	1645	-------	LR - 	\N	{"fra": "Poularde jaune fermière élevée en plein air, entière et découpes, fraîche ou surgelée"}	Poularde jaune fermière élevée en plein air, entière et découpes, fraîche ou surgelée	LA/04/13
14846	1645	-------	LR - 	\N	{"fra": "Mini-chapon fermier élevé en plein air, entier et découpes, frais et surgelé"}	Mini-chapon fermier élevé en plein air, entier et découpes, frais et surgelé	LA/10/14
14849	1645	-------	LR - 	\N	{"fra": "Pintade fermière élevée en plein air, entière et découpes, fraîche ou surgelée"}	Pintade fermière élevée en plein air, entière et découpes, fraîche ou surgelée	LA/03/82
14850	1645	-------	LR - 	\N	{"fra": "Pintade fermière élevée en plein air, entière et découpes, fraîche ou surgelée"}	Pintade fermière élevée en plein air, entière et découpes, fraîche ou surgelée	LA/02/84
14852	1645	-------	LR - 	\N	{"fra": "Chapon de pintade fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon de pintade fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/05/13
14853	1645	-------	LR - 	\N	{"fra": "Poulet noir fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet noir fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/25/98
14856	1645	-------	LR - 	\N	{"fra": "Pintade fermière élevée en plein air, entière et découpes, fraîche ou surgelée "}	Pintade fermière élevée en plein air, entière et découpes, fraîche ou surgelée 	LA/01/74
14858	1645	-------	LR - 	\N	{"fra": "Poularde fermière élevée en plein air, entière et découpes, fraîche ou surgelée"}	Poularde fermière élevée en plein air, entière et découpes, fraîche ou surgelée	LA/11/91
14859	1645	-------	LR - 	\N	{"fra": "Pintade fermière élevée en plein air, entière et découpes, fraîche ou surgelée"}	Pintade fermière élevée en plein air, entière et découpes, fraîche ou surgelée	LA/09/92
14860	1645	-------	LR - 	\N	{"fra": "Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/03/93
14861	1645	-------	LR - 	\N	{"fra": "Poulet noir fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet noir fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/18/93
14862	1645	-------	LR - 	\N	{"fra": "Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/03/95
14863	1645	-------	LR - 	\N	{"fra": "Poulet blanc à pattes bleues fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet blanc à pattes bleues fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/14/95
14864	1645	-------	LR - 	\N	{"fra": "Poularde blanche à pattes bleues fermière élevée en plein air, entière et découpes, fraîche ou surgelée"}	Poularde blanche à pattes bleues fermière élevée en plein air, entière et découpes, fraîche ou surgelée	LA/07/04
14865	1645	-------	LR - 	\N	{"fra": "Produits de saucisserie"}	Produits de saucisserie	LA/09/08
14868	1645	-------	LR - 	\N	{"fra": "Viande fraîche de veau nourri au lait entier"}	Viande fraîche de veau nourri au lait entier	LA/22/89
14869	1645	-------	LR - 	\N	{"fra": "Viande et abats frais de veau nourri au lait entier"}	Viande et abats frais de veau nourri au lait entier	LA/21/93
14870	1645	-------	LR - 	\N	{"fra": "Viande et abats frais de veau nourri au lait entier"}	Viande et abats frais de veau nourri au lait entier	LA/17/99
14871	1645	-------	LR - 	\N	{"fra": "Viande fraîche de veau nourri au lait entier"}	Viande fraîche de veau nourri au lait entier	LA/30/99
14872	1645	-------	LR - 	\N	{"fra": "Poulet blanc fermier élevé en liberté, entier et découpes, frais ou surgelé"}	Poulet blanc fermier élevé en liberté, entier et découpes, frais ou surgelé	LA/12/66
14873	1645	-------	LR - 	\N	{"fra": "Poulet jaune fermier élevé en liberté, entier et découpes, frais ou surgelé"}	Poulet jaune fermier élevé en liberté, entier et découpes, frais ou surgelé	LA/04/81
14874	1645	-------	LR - 	\N	{"fra": "Poulet blanc cou nu fermier élevé en liberté, entier et découpes, frais ou surgelé"}	Poulet blanc cou nu fermier élevé en liberté, entier et découpes, frais ou surgelé	LA/04/12
14887	1645	-------	LR - 	\N	{"fra": "Plants de géraniums"}	Plants de géraniums	LA/08/16
14908	1645	-------	LR - 	\N	{"fra": "Poulet noir fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet noir fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/01/18
14910	1645	-------	LR - 	\N	{"fra": "Pomme de terre primeur"}	Pomme de terre primeur	LA/02/18
14923	1645	-------	LR - 	\N	{"fra": "Saumon"}	Saumon	LA/33/90
14974	1645	-------	LR - 	\N	{"fra": "Dinde de Noël fermière élevée en plein air, entière, fraîche ou surgelée"}	Dinde de Noël fermière élevée en plein air, entière, fraîche ou surgelée	LA/10/80
14996	1645	-------	LR - 	\N	{"fra": "Dinde de Noël fermière élevée en plein air, entière, fraîche ou surgelée"}	Dinde de Noël fermière élevée en plein air, entière, fraîche ou surgelée	LA/03/72
14997	1645	-------	LR - 	\N	{"fra": "Poulet noir fermier élevé en liberté, entier et découpes, frais ou surgelé "}	Poulet noir fermier élevé en liberté, entier et découpes, frais ou surgelé 	LA/13/77
14998	1645	-------	LR - 	\N	{"fra": "Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/07/82
14999	1645	-------	LR - 	\N	{"fra": "Oie fermière élevée en plein air, entière, fraîche ou surgelée"}	Oie fermière élevée en plein air, entière, fraîche ou surgelée	LA/07/84
15000	1645	-------	LR - 	\N	{"fra": "Chapon blanc fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon blanc fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/16/88
15001	1645	-------	LR - 	\N	{"fra": "Poularde blanche fermière élevée en plein air, entière et découpes, fraîche ou surgelée"}	Poularde blanche fermière élevée en plein air, entière et découpes, fraîche ou surgelée	LA/51/88
15002	1645	-------	LR - 	\N	{"fra": "Poulet jaune fermier de 100 jours élevé en liberté, entier et découpes, frais ou surgelé"}	Poulet jaune fermier de 100 jours élevé en liberté, entier et découpes, frais ou surgelé	LA/05/12
15003	1645	-------	LR - 	\N	{"fra": "Mini-chapon fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Mini-chapon fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/01/07
15004	1645	-------	LR - 	\N	{"fra": "Poularde jaune fermière élevée en plein air, entière et découpes, fraîche ou surgelée"}	Poularde jaune fermière élevée en plein air, entière et découpes, fraîche ou surgelée	LA/13/02
15005	1645	-------	LR - 	\N	{"fra": "Chapon jaune fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon jaune fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/12/02
15006	1645	-------	LR - 	\N	{"fra": "Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet jaune fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/23/98
15007	1645	-------	LR - 	\N	{"fra": "Chapon de pintade fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon de pintade fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/19/94
15009	1645	-------	LR - 	\N	{"fra": "Poulet blanc fermier de 100 jours élevé en liberté, entier et découpes, frais ou surgelé"}	Poulet blanc fermier de 100 jours élevé en liberté, entier et découpes, frais ou surgelé	LA/52/88
15013	1645	-------	LR - 	\N	{"fra": "Lardons fumés supérieurs"}	Lardons fumés supérieurs	LA/06/18
15014	1645	-------	LR - 	\N	{"fra": "Faisselle"}	Faisselle	LA/04/18
15017	1645	-------	LR - 	\N	{"fra": "Crème anglaise"}	Crème anglaise	LA/03/18
15025	1645	-------	LR - 	\N	{"fra": "Sardines à l'huile d'olive vierge extra préparées à l'ancienne"}	Sardines à l'huile d'olive vierge extra préparées à l'ancienne	LA/33/99
15038	1645	-------	LR - 	\N	{"fra": "Saumon farci"}	Saumon farci	LA/02/17
15039	1645	-------	LR - 	\N	{"fra": "Pintade fermière élevée en plein air, entière et découpes, fraîche ou surgelée"}	Pintade fermière élevée en plein air, entière et découpes, fraîche ou surgelée	LA/01/89
15040	1645	-------	LR - 	\N	{"fra": "Chapon de pintade fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon de pintade fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/15/94
15041	1645	-------	LR - 	\N	{"fra": "Pommes"}	Pommes	LA/04/96
15042	1645	-------	LR - 	\N	{"fra": "Œufs fermiers de poules élevées en plein air"}	Œufs fermiers de poules élevées en plein air	LA/18/98
15043	1645	-------	LR - 	\N	{"fra": "Œufs de poules élevées en plein air"}	Œufs de poules élevées en plein air	LA/05/05
15175	1645	-------	LR - 	\N	{"fra": "Poularde blanche fermière élevée en plein air, entière et découpes, fraîche ou surgelée"}	Poularde blanche fermière élevée en plein air, entière et découpes, fraîche ou surgelée	LA/10/94
15176	1645	-------	LR - 	\N	{"fra": "Conserves de thon albacore"}	Conserves de thon albacore	LA/07/18
15177	1645	-------	LR - 	\N	{"fra": "Pommes de terre à chair ferme Pompadour"}	Pommes de terre à chair ferme Pompadour	LA/09/01
15218	1645	-------	LR - 	\N	{"fra": "Carottes des sables"}	Carottes des sables	LA/04/67
15307	1645	-------	LR - 	\N	{"fra": "Sapin de Noël coupé"}	Sapin de Noël coupé	LA/05/16
15308	1645	-------	LR - 	\N	{"fra": "Pizzas cuites au feu de bois surgelées"}	Pizzas cuites au feu de bois surgelées	LA/12/01
15310	1645	-------	LR - 	\N	{"fra": "Viande fraîche d'agneau de plus de 15 kg de carcasse, nourri par tétée au pis au moins 60 jours"}	Viande fraîche d'agneau de plus de 15 kg de carcasse, nourri par tétée au pis au moins 60 jours	LA/02/95
15320	1645	-------	LR - 	\N	{"fra": "Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/04/78
15321	1645	-------	LR - 	\N	{"fra": "Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/11/98
15327	1645	-------	LR - 	\N	{"fra": "Bulbes à fleurs de dahlias"}	Bulbes à fleurs de dahlias	LA/07/10
15328	1645	-------	LR - 	\N	{"fra": "Cerises"}	Cerises	LA/08/17
15329	1645	-------	LR - 	\N	{"fra": "Viande fraîche ou surgelée d'agneau de plus de 14 kg de carcasse, nourri par tétée au pis au moins 60 jours"}	Viande fraîche ou surgelée d'agneau de plus de 14 kg de carcasse, nourri par tétée au pis au moins 60 jours	LA/01/12
15433	1645	-------	LR - 	\N	{"fra": "Viande et abats frais et surgelés d'agneau de plus de 15 kg de carcasse, nourri par tétée au pis au moins 60 jours"}	Viande et abats frais et surgelés d'agneau de plus de 15 kg de carcasse, nourri par tétée au pis au moins 60 jours	LA/03/94
15434	1645	-------	LR - 	\N	{"fra": "Emmental"}	Emmental	LA/04/79
15435	1645	-------	LR - 	\N	{"fra": "Poulet blanc fermier élevé en plein air"}	Poulet blanc fermier élevé en plein air	LA/08/05
15436	1645	-------	LR - 	\N	{"fra": "Poulet jaune fermier élevé en plein air"}	Poulet jaune fermier élevé en plein air	LA/11/14
15437	1645	-------	LR - 	\N	{"fra": "poulet noir fermier élevé en plein air"}	poulet noir fermier élevé en plein air	LA/12/14
15578	1645	-------	LR - 	\N	{"fra": "Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/04/87
15932	1645	-------	LR - 	\N	{"fra": "Chapon de pintade fermier élevé en plein air, entier et découpes, frais ou surgelé"}	Chapon de pintade fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/14/94
15938	1645	-------	LR - 	\N	{"fra": "Poulet blanc fermier élevé en plein air"}	Poulet blanc fermier élevé en plein air	LA/08/76
15939	1645	-------	LR - 	\N	{"fra": "Poulet jaune fermier élevé en plein air"}	Poulet jaune fermier élevé en plein air	LA/14/87
15940	1645	-------	LR - 	\N	{"fra": "Poulet noir fermier élevé en plein air"}	Poulet noir fermier élevé en plein air	LA/01/97
15942	1645	-------	LR - 	\N	{"fra": "Poulet noir fermier élevé en plein air"}	Poulet noir fermier élevé en plein air	LA/05/69
15943	1645	-------	LR - 	\N	{"fra": "Poulet jaune fermier élevé en plein air"}	Poulet jaune fermier élevé en plein air	LA/01/84
15944	1645	-------	LR - 	\N	{"fra": "Poulet blanc fermier élevé en plein air"}	Poulet blanc fermier élevé en plein air	LA/05/84
15945	1645	-------	LR - 	\N	{"fra": "Poulet jaune fermier élevé en plein air"}	Poulet jaune fermier élevé en plein air	LA/56/88
15946	1645	-------	LR - 	\N	{"fra": "Poulet blanc fermier élevé en plein air"}	Poulet blanc fermier élevé en plein air	LA/02/93
15947	1645	-------	LR - 	\N	{"fra": "Poulet noir fermier élevé en plein air"}	Poulet noir fermier élevé en plein air	LA/23/06
15948	1645	-------	LR - 	\N	{"fra": "Caille jaune fermière élevée en plein air"}	Caille jaune fermière élevée en plein air	LA/13/78
15949	1645	-------	LR - 	\N	{"fra": "Plants de rosier de jardin"}	Plants de rosier de jardin	LA/06/15
15950	1645	-------	LR - 	\N	{"fra": "Produits transformés de canards mulards gavés"}	Produits transformés de canards mulards gavés	LA/19/02
16105	1645	-------	LR - 	\N	{"fra": "Viandes, et abats frais de porc fermier"}	Viandes, et abats frais de porc fermier	LA/05/89
16169	1645	-------	LR - 	\N	{"fra": " Viande, abats et viande hachée, frais et surgelés, de gros bovins de race charolaise"}	 Viande, abats et viande hachée, frais et surgelés, de gros bovins de race charolaise	LA/03/89
16170	1645	-------	LR - 	\N	{"fra": " Viande hachée fraîche et surgelée de gros bovins de boucherie"}	 Viande hachée fraîche et surgelée de gros bovins de boucherie	LA/29/01
16171	1645	-------	LR - 	\N	{"fra": "Filets de hareng fumé doux"}	Filets de hareng fumé doux	LA/04/11
13522	1454	Abondance	AOC -	AOP -	{"fra": "Abondance"}	Abondance	\N
14791	1454	Abondance	LR - 	\N	{"fra": "Pintade fermière élevée en plein air, entière et découpes, fraîche ou surgelée"}	Pintade fermière élevée en plein air, entière et découpes, fraîche ou surgelée	LA/02/87
4326	1735	Abricots rouges du Roussillon	AOC -	AOP -	{"fra": "Abricots rouges du Roussillon"}	Abricots rouges du Roussillon	\N
4329	1738	Absinthe de Pontarlier	\N	IG - 	{"fra": "Absinthe de Pontarlier"}	Absinthe de Pontarlier	\N
16013	2046	Agenais	\N	IGP -	{"fra": "Agenais blanc"}	Agenais blanc	\N
16014	2046	Agenais	\N	IGP -	{"fra": "Agenais primeur ou nouveau blanc"}	Agenais primeur ou nouveau blanc	\N
16015	2046	Agenais	\N	IGP -	{"fra": "Agenais primeur ou nouveau rosé"}	Agenais primeur ou nouveau rosé	\N
16016	2046	Agenais	\N	IGP -	{"fra": "Agenais primeur ou nouveau rouge"}	Agenais primeur ou nouveau rouge	\N
16017	2046	Agenais	\N	IGP -	{"fra": "Agenais rosé"}	Agenais rosé	\N
16018	2046	Agenais	\N	IGP -	{"fra": "Agenais rouge"}	Agenais rouge	\N
16019	2046	Agenais	\N	IGP -	{"fra": "Agenais surmûri blanc"}	Agenais surmûri blanc	\N
3390	1519	Agneau de l'Aveyron	\N	IGP -	{"fra": "Agneau de l'Aveyron"}	Agneau de l'Aveyron	IG/32/94
4142	1659	Agneau de lait des Pyrénées	\N	IGP -	{"fra": "Agneau de lait des Pyrénées"}	Agneau de lait des Pyrénées	IG/09/00
4134	1657	Agneau de Lozère	\N	IGP -	{"fra": "Agneau de Lozère"}	Agneau de Lozère	IG/06/00
13421	1602	Agneau de Pauillac	\N	IGP -	{"fra": "Agneau de Pauillac"}	Agneau de Pauillac	IG/16/97
3530	1648	Agneau de Sisteron	\N	IGP -	{"fra": "Agneau de Sisteron"}	Agneau de Sisteron	IG/01/02
3460	1589	Agneau du Bourbonnais	\N	IGP -	{"fra": "Agneau du Bourbonnais"}	Agneau du Bourbonnais	IG/33/94
3392	1520	Agneau du Limousin	\N	IGP -	{"fra": "Agneau du Limousin"}	Agneau du Limousin	IG/11/95
4132	1655	Agneau du Périgord	\N	IGP -	{"fra": "Agneau du Périgord"}	Agneau du Périgord	IG/17/01
3472	1603	Agneau du Poitou-Charentes	\N	IGP -	{"fra": "Agneau du Poitou-Charentes"}	Agneau du Poitou-Charentes	IG/03/98
3393	1521	Agneau du Quercy	\N	IGP -	{"fra": "Agneau du Quercy"}	Agneau du Quercy	IG/34/94
14207	1670	Ail blanc de Lomagne	\N	IGP -	{"fra": "Ail blanc de Lomagne"}	Ail blanc de Lomagne	IG/03/00
4133	1656	Ail de la Drôme	\N	IGP -	{"fra": "Ail de la Drôme"}	Ail de la Drôme	IG/01/98
14228	1775	Ail fumé d'Arleux	\N	IGP -	{"fra": "Ail fumé d'Arleux"}	Ail fumé d'Arleux	\N
3394	1522	Ail rose de Lautrec	\N	IGP -	{"fra": "Ail rose de Lautrec"}	Ail rose de Lautrec	IG/44/94
4186	2416	Ail violet de Cadours	AOC -	AOP -	{"fra": "Ail violet de Cadours"}	Ail violet de Cadours	\N
6421	1316	Ajaccio	AOC -	AOP -	{"fra": "Ajaccio blanc"}	Ajaccio blanc	\N
7936	1316	Ajaccio	AOC -	AOP -	{"fra": "Ajaccio rosé"}	Ajaccio rosé	\N
7937	1316	Ajaccio	AOC -	AOP -	{"fra": "Ajaccio rouge"}	Ajaccio rouge	\N
7695	220	Aloxe-Corton	AOC -	AOP -	{"fra": "Aloxe-Corton"}	Aloxe-Corton	\N
8263	220	Aloxe-Corton	AOC -	AOP -	{"fra": "Aloxe-Corton rouge"}	Aloxe-Corton rouge	\N
8233	235	Aloxe-Corton premier cru	AOC -	AOP -	{"fra": "Aloxe-Corton premier cru blanc"}	Aloxe-Corton premier cru blanc	\N
8262	235	Aloxe-Corton premier cru	AOC -	AOP -	{"fra": "Aloxe-Corton premier cru rouge"}	Aloxe-Corton premier cru rouge	\N
8234	221	Aloxe-Corton premier cru Clos des Maréchaudes	AOC -	AOP -	{"fra": "Aloxe-Corton premier cru Clos des Maréchaudes blanc"}	Aloxe-Corton premier cru Clos des Maréchaudes blanc	\N
8235	221	Aloxe-Corton premier cru Clos des Maréchaudes	AOC -	AOP -	{"fra": "Aloxe-Corton premier cru Clos des Maréchaudes rouge"}	Aloxe-Corton premier cru Clos des Maréchaudes rouge	\N
8236	222	Aloxe-Corton premier cru Clos du Chapitre	AOC -	AOP -	{"fra": "Aloxe-Corton premier cru Clos du Chapitre blanc"}	Aloxe-Corton premier cru Clos du Chapitre blanc	\N
8237	222	Aloxe-Corton premier cru Clos du Chapitre	AOC -	AOP -	{"fra": "Aloxe-Corton premier cru Clos du Chapitre rouge"}	Aloxe-Corton premier cru Clos du Chapitre rouge	\N
8238	223	Aloxe-Corton premier cru La Coutière	AOC -	AOP -	{"fra": "Aloxe-Corton premier cru La Coutière blanc"}	Aloxe-Corton premier cru La Coutière blanc	\N
8239	223	Aloxe-Corton premier cru La Coutière	AOC -	AOP -	{"fra": "Aloxe-Corton premier cru La Coutière rouge"}	Aloxe-Corton premier cru La Coutière rouge	\N
8240	224	Aloxe-Corton premier cru La Maréchaude	AOC -	AOP -	{"fra": "Aloxe-Corton premier cru La Maréchaude blanc"}	Aloxe-Corton premier cru La Maréchaude blanc	\N
8241	224	Aloxe-Corton premier cru La Maréchaude	AOC -	AOP -	{"fra": "Aloxe-Corton premier cru La Maréchaude rouge"}	Aloxe-Corton premier cru La Maréchaude rouge	\N
8242	225	Aloxe-Corton premier cru La Toppe au Vert	AOC -	AOP -	{"fra": "Aloxe-Corton premier cru La Toppe au Vert blanc"}	Aloxe-Corton premier cru La Toppe au Vert blanc	\N
8243	225	Aloxe-Corton premier cru La Toppe au Vert	AOC -	AOP -	{"fra": "Aloxe-Corton premier cru La Toppe au Vert rouge"}	Aloxe-Corton premier cru La Toppe au Vert rouge	\N
8244	226	Aloxe-Corton premier cru Les Chaillots	AOC -	AOP -	{"fra": "Aloxe-Corton premier cru Les Chaillots blanc"}	Aloxe-Corton premier cru Les Chaillots blanc	\N
8245	226	Aloxe-Corton premier cru Les Chaillots	AOC -	AOP -	{"fra": "Aloxe-Corton premier cru Les Chaillots rouge"}	Aloxe-Corton premier cru Les Chaillots rouge	\N
8246	227	Aloxe-Corton premier cru Les Fournières	AOC -	AOP -	{"fra": "Aloxe-Corton premier cru Les Fournières blanc"}	Aloxe-Corton premier cru Les Fournières blanc	\N
8247	227	Aloxe-Corton premier cru Les Fournières	AOC -	AOP -	{"fra": "Aloxe-Corton premier cru Les Fournières rouge"}	Aloxe-Corton premier cru Les Fournières rouge	\N
8248	228	Aloxe-Corton premier cru Les Guérets	AOC -	AOP -	{"fra": "Aloxe-Corton premier cru Les Guérets blanc"}	Aloxe-Corton premier cru Les Guérets blanc	\N
8249	228	Aloxe-Corton premier cru Les Guérets	AOC -	AOP -	{"fra": "Aloxe-Corton premier cru Les Guérets rouge"}	Aloxe-Corton premier cru Les Guérets rouge	\N
8250	229	Aloxe-Corton premier cru Les Maréchaudes	AOC -	AOP -	{"fra": "Aloxe-Corton premier cru Les Maréchaudes blanc"}	Aloxe-Corton premier cru Les Maréchaudes blanc	\N
8251	229	Aloxe-Corton premier cru Les Maréchaudes	AOC -	AOP -	{"fra": "Aloxe-Corton premier cru Les Maréchaudes rouge"}	Aloxe-Corton premier cru Les Maréchaudes rouge	\N
8252	230	Aloxe-Corton premier cru Les Moutottes	AOC -	AOP -	{"fra": "Aloxe-Corton premier cru Les Moutottes blanc"}	Aloxe-Corton premier cru Les Moutottes blanc	\N
8253	230	Aloxe-Corton premier cru Les Moutottes	AOC -	AOP -	{"fra": "Aloxe-Corton premier cru Les Moutottes rouge"}	Aloxe-Corton premier cru Les Moutottes rouge	\N
8254	231	Aloxe-Corton premier cru Les Paulands	AOC -	AOP -	{"fra": "Aloxe-Corton premier cru Les Paulands blanc"}	Aloxe-Corton premier cru Les Paulands blanc	\N
8255	231	Aloxe-Corton premier cru Les Paulands	AOC -	AOP -	{"fra": "Aloxe-Corton premier cru Les Paulands rouge"}	Aloxe-Corton premier cru Les Paulands rouge	\N
8256	232	Aloxe-Corton premier cru Les Petites Folières	AOC -	AOP -	{"fra": "Aloxe-Corton premier cru Les Petites Folières blanc"}	Aloxe-Corton premier cru Les Petites Folières blanc	\N
8257	232	Aloxe-Corton premier cru Les Petites Folières	AOC -	AOP -	{"fra": "Aloxe-Corton premier cru Les Petites Folières rouge"}	Aloxe-Corton premier cru Les Petites Folières rouge	\N
8258	233	Aloxe-Corton premier cru Les Valozières	AOC -	AOP -	{"fra": "Aloxe-Corton premier cru Les Valozières blanc"}	Aloxe-Corton premier cru Les Valozières blanc	\N
8259	233	Aloxe-Corton premier cru Les Valozières	AOC -	AOP -	{"fra": "Aloxe-Corton premier cru Les Valozières rouge"}	Aloxe-Corton premier cru Les Valozières rouge	\N
8260	234	Aloxe-Corton premier cru Les Vercots	AOC -	AOP -	{"fra": "Aloxe-Corton premier cru Les Vercots blanc"}	Aloxe-Corton premier cru Les Vercots blanc	\N
8261	234	Aloxe-Corton premier cru Les Vercots	AOC -	AOP -	{"fra": "Aloxe-Corton premier cru Les Vercots rouge"}	Aloxe-Corton premier cru Les Vercots rouge	\N
13530	1974	Alpes-de-Haute-Provence	\N	IGP -	{"fra": "Alpes-de-Haute-Provence blanc"}	Alpes-de-Haute-Provence blanc	\N
13531	1974	Alpes-de-Haute-Provence	\N	IGP -	{"fra": "Alpes-de-Haute-Provence rosé"}	Alpes-de-Haute-Provence rosé	\N
13532	1974	Alpes-de-Haute-Provence	\N	IGP -	{"fra": "Alpes-de-Haute-Provence rouge"}	Alpes-de-Haute-Provence rouge	\N
13533	1974	Alpes-de-Haute-Provence	\N	IGP -	{"fra": "Alpes-de-Haute-Provence primeur ou nouveau blanc"}	Alpes-de-Haute-Provence primeur ou nouveau blanc	\N
13534	1974	Alpes-de-Haute-Provence	\N	IGP -	{"fra": "Alpes-de-Haute-Provence primeur ou nouveau rosé"}	Alpes-de-Haute-Provence primeur ou nouveau rosé	\N
13535	1974	Alpes-de-Haute-Provence	\N	IGP -	{"fra": "Alpes-de-Haute-Provence primeur ou nouveau rouge"}	Alpes-de-Haute-Provence primeur ou nouveau rouge	\N
15956	1976	Alpes-Maritimes	\N	IGP -	{"fra": "Alpes-Maritimes blanc"}	Alpes-Maritimes blanc	\N
15957	1976	Alpes-Maritimes	\N	IGP -	{"fra": "Alpes-Maritimes mousseux de qualité blanc"}	Alpes-Maritimes mousseux de qualité blanc	\N
15958	1976	Alpes-Maritimes	\N	IGP -	{"fra": "Alpes-Maritimes mousseux de qualité rosé"}	Alpes-Maritimes mousseux de qualité rosé	\N
15959	1976	Alpes-Maritimes	\N	IGP -	{"fra": "Alpes-Maritimes mousseux de qualité rouge"}	Alpes-Maritimes mousseux de qualité rouge	\N
15960	1976	Alpes-Maritimes	\N	IGP -	{"fra": "Alpes-Maritimes primeur ou nouveau blanc"}	Alpes-Maritimes primeur ou nouveau blanc	\N
15961	1976	Alpes-Maritimes	\N	IGP -	{"fra": "Alpes-Maritimes primeur ou nouveau rosé"}	Alpes-Maritimes primeur ou nouveau rosé	\N
15962	1976	Alpes-Maritimes	\N	IGP -	{"fra": "Alpes-Maritimes primeur ou nouveau rouge"}	Alpes-Maritimes primeur ou nouveau rouge	\N
15963	1976	Alpes-Maritimes	\N	IGP -	{"fra": "Alpes-Maritimes rosé"}	Alpes-Maritimes rosé	\N
15964	1976	Alpes-Maritimes	\N	IGP -	{"fra": "Alpes-Maritimes rouge"}	Alpes-Maritimes rouge	\N
15579	1992	Alpilles	\N	IGP -	{"fra": "Alpilles blanc"}	Alpilles blanc	\N
15580	1992	Alpilles	\N	IGP -	{"fra": "Alpilles primeur ou nouveau blanc"}	Alpilles primeur ou nouveau blanc	\N
15581	1992	Alpilles	\N	IGP -	{"fra": "Alpilles primeur ou nouveau rouge"}	Alpilles primeur ou nouveau rouge	\N
15582	1992	Alpilles	\N	IGP -	{"fra": "Alpilles primeur ou nouveau rosé"}	Alpilles primeur ou nouveau rosé	\N
15583	1992	Alpilles	\N	IGP -	{"fra": "Alpilles rosé"}	Alpilles rosé	\N
15584	1992	Alpilles	\N	IGP -	{"fra": "Alpilles rouge"}	Alpilles rouge	\N
14653	2445	Alsace Bergheim	AOC -	AOP -	{"fra": "Alsace Bergheim sélection de grains nobles Gewurztraminer"}	Alsace Bergheim sélection de grains nobles Gewurztraminer	\N
14654	2445	Alsace Bergheim	AOC -	AOP -	{"fra": "Alsace Bergheim vendanges tardives Gewurztraminer"}	Alsace Bergheim vendanges tardives Gewurztraminer	\N
14655	2445	Alsace Bergheim	AOC -	AOP -	{"fra": "Alsace Bergheim blanc"}	Alsace Bergheim blanc	\N
14656	2445	Alsace Bergheim	AOC -	AOP -	{"fra": "Alsace Bergheim Gewurztraminer"}	Alsace Bergheim Gewurztraminer	\N
13227	2302	Alsace Blienschwiller	AOC -	AOP -	{"fra": "Alsace Blienschwiller blanc (Sylvaner)"}	Alsace Blienschwiller blanc (Sylvaner)	\N
13229	2309	Alsace Côte de Rouffach	AOC -	AOP -	{"fra": "Alsace Côte de Rouffach blanc"}	Alsace Côte de Rouffach blanc	\N
13230	2309	Alsace Côte de Rouffach	AOC -	AOP -	{"fra": "Alsace Côte de Rouffach Gewurztraminer"}	Alsace Côte de Rouffach Gewurztraminer	\N
13231	2309	Alsace Côte de Rouffach	AOC -	AOP -	{"fra": "Alsace Côte de Rouffach Pinot Gris"}	Alsace Côte de Rouffach Pinot Gris	\N
13232	2309	Alsace Côte de Rouffach	AOC -	AOP -	{"fra": "Alsace Côte de Rouffach Riesling"}	Alsace Côte de Rouffach Riesling	\N
13233	2309	Alsace Côte de Rouffach	AOC -	AOP -	{"fra": "Alsace Côte de Rouffach rouge"}	Alsace Côte de Rouffach rouge	\N
13234	2309	Alsace Côte de Rouffach	AOC -	AOP -	{"fra": "Alsace Côte de Rouffach sélection de grains nobles Gewurztraminer"}	Alsace Côte de Rouffach sélection de grains nobles Gewurztraminer	\N
13235	2309	Alsace Côte de Rouffach	AOC -	AOP -	{"fra": "Alsace Côte de Rouffach sélection de grains nobles Pinot Gris"}	Alsace Côte de Rouffach sélection de grains nobles Pinot Gris	\N
13236	2309	Alsace Côte de Rouffach	AOC -	AOP -	{"fra": "Alsace Côte de Rouffach sélection de grains nobles Riesling"}	Alsace Côte de Rouffach sélection de grains nobles Riesling	\N
13237	2309	Alsace Côte de Rouffach	AOC -	AOP -	{"fra": "Alsace Côte de Rouffach vendanges tardives Gewurztraminer"}	Alsace Côte de Rouffach vendanges tardives Gewurztraminer	\N
13238	2309	Alsace Côte de Rouffach	AOC -	AOP -	{"fra": "Alsace Côte de Rouffach vendanges tardives Pinot Gris"}	Alsace Côte de Rouffach vendanges tardives Pinot Gris	\N
13239	2309	Alsace Côte de Rouffach	AOC -	AOP -	{"fra": "Alsace Côte de Rouffach vendanges tardives Riesling"}	Alsace Côte de Rouffach vendanges tardives Riesling	\N
14657	2446	Alsace Coteaux du Haut Koenigsbourg	AOC -	AOP -	{"fra": "Alsace Coteaux du Haut Koenigsbourg sélection de grains nobles Gewurztraminer"}	Alsace Coteaux du Haut Koenigsbourg sélection de grains nobles Gewurztraminer	\N
14658	2446	Alsace Coteaux du Haut Koenigsbourg	AOC -	AOP -	{"fra": "Alsace Coteaux du Haut Koenigsbourg sélection de grains nobles Riesling"}	Alsace Coteaux du Haut Koenigsbourg sélection de grains nobles Riesling	\N
14659	2446	Alsace Coteaux du Haut Koenigsbourg	AOC -	AOP -	{"fra": "Alsace Coteaux du Haut Koenigsbourg vendanges tardives Gewurztraminer"}	Alsace Coteaux du Haut Koenigsbourg vendanges tardives Gewurztraminer	\N
14660	2446	Alsace Coteaux du Haut Koenigsbourg	AOC -	AOP -	{"fra": "Alsace Coteaux du Haut Koenigsbourg vendanges tardives Riesling"}	Alsace Coteaux du Haut Koenigsbourg vendanges tardives Riesling	\N
14661	2446	Alsace Coteaux du Haut Koenigsbourg	AOC -	AOP -	{"fra": "Alsace Coteaux du Haut Koenigsbourg blanc"}	Alsace Coteaux du Haut Koenigsbourg blanc	\N
14662	2446	Alsace Coteaux du Haut Koenigsbourg	AOC -	AOP -	{"fra": "Alsace Coteaux du Haut Koenigsbourg Gewurztraminer"}	Alsace Coteaux du Haut Koenigsbourg Gewurztraminer	\N
14663	2446	Alsace Coteaux du Haut Koenigsbourg	AOC -	AOP -	{"fra": "Alsace Coteaux du Haut Koenigsbourg Riesling"}	Alsace Coteaux du Haut Koenigsbourg Riesling	\N
13228	2306	Alsace Côtes de Barr	AOC -	AOP -	{"fra": "Alsace Côtes de Barr blanc (Sylvaner)"}	Alsace Côtes de Barr blanc (Sylvaner)	\N
10067	3	Alsace grand cru Altenberg de Bergbieten	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Bergbieten Gewurztraminer"}	Alsace grand cru Altenberg de Bergbieten Gewurztraminer	\N
10068	3	Alsace grand cru Altenberg de Bergbieten	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Bergbieten sélection de grains nobles Gewurztraminer"}	Alsace grand cru Altenberg de Bergbieten sélection de grains nobles Gewurztraminer	\N
10069	3	Alsace grand cru Altenberg de Bergbieten	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Bergbieten sélection de grains nobles Muscat"}	Alsace grand cru Altenberg de Bergbieten sélection de grains nobles Muscat	\N
10070	3	Alsace grand cru Altenberg de Bergbieten	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Bergbieten sélection de grains nobles Pinot gris"}	Alsace grand cru Altenberg de Bergbieten sélection de grains nobles Pinot gris	\N
10071	3	Alsace grand cru Altenberg de Bergbieten	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Bergbieten sélection de grains nobles Riesling"}	Alsace grand cru Altenberg de Bergbieten sélection de grains nobles Riesling	\N
10072	3	Alsace grand cru Altenberg de Bergbieten	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Bergbieten Muscat"}	Alsace grand cru Altenberg de Bergbieten Muscat	\N
10073	3	Alsace grand cru Altenberg de Bergbieten	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Bergbieten Pinot gris"}	Alsace grand cru Altenberg de Bergbieten Pinot gris	\N
10074	3	Alsace grand cru Altenberg de Bergbieten	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Bergbieten Riesling"}	Alsace grand cru Altenberg de Bergbieten Riesling	\N
10075	3	Alsace grand cru Altenberg de Bergbieten	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Bergbieten vendanges tardives Gewurztraminer"}	Alsace grand cru Altenberg de Bergbieten vendanges tardives Gewurztraminer	\N
10076	3	Alsace grand cru Altenberg de Bergbieten	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Bergbieten vendanges tardives Muscat"}	Alsace grand cru Altenberg de Bergbieten vendanges tardives Muscat	\N
10077	3	Alsace grand cru Altenberg de Bergbieten	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Bergbieten vendanges tardives Pinot gris"}	Alsace grand cru Altenberg de Bergbieten vendanges tardives Pinot gris	\N
10078	3	Alsace grand cru Altenberg de Bergbieten	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Bergbieten vendanges tardives Riesling"}	Alsace grand cru Altenberg de Bergbieten vendanges tardives Riesling	\N
11261	3	Alsace grand cru Altenberg de Bergbieten	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Bergbieten Muscat Ottonel"}	Alsace grand cru Altenberg de Bergbieten Muscat Ottonel	\N
11264	3	Alsace grand cru Altenberg de Bergbieten	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Bergbieten sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Altenberg de Bergbieten sélection de grains nobles Muscat Ottonel	\N
11266	3	Alsace grand cru Altenberg de Bergbieten	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Bergbieten vendanges tardives Muscat Ottonel"}	Alsace grand cru Altenberg de Bergbieten vendanges tardives Muscat Ottonel	\N
10079	4	Alsace grand cru Altenberg de Bergheim	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Bergheim"}	Alsace grand cru Altenberg de Bergheim	\N
10080	4	Alsace grand cru Altenberg de Bergheim	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Bergheim Gewurztraminer"}	Alsace grand cru Altenberg de Bergheim Gewurztraminer	\N
10081	4	Alsace grand cru Altenberg de Bergheim	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Bergheim Pinot gris"}	Alsace grand cru Altenberg de Bergheim Pinot gris	\N
10082	4	Alsace grand cru Altenberg de Bergheim	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Bergheim Riesling"}	Alsace grand cru Altenberg de Bergheim Riesling	\N
10083	4	Alsace grand cru Altenberg de Bergheim	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Bergheim sélection de grains nobles Gewurztraminer"}	Alsace grand cru Altenberg de Bergheim sélection de grains nobles Gewurztraminer	\N
10084	4	Alsace grand cru Altenberg de Bergheim	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Bergheim sélection de grains nobles Pinot gris"}	Alsace grand cru Altenberg de Bergheim sélection de grains nobles Pinot gris	\N
10085	4	Alsace grand cru Altenberg de Bergheim	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Bergheim sélection de grains nobles Riesling"}	Alsace grand cru Altenberg de Bergheim sélection de grains nobles Riesling	\N
10086	4	Alsace grand cru Altenberg de Bergheim	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Bergheim vendanges tardives Gewurztraminer"}	Alsace grand cru Altenberg de Bergheim vendanges tardives Gewurztraminer	\N
10087	4	Alsace grand cru Altenberg de Bergheim	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Bergheim vendanges tardives Pinot gris"}	Alsace grand cru Altenberg de Bergheim vendanges tardives Pinot gris	\N
10088	4	Alsace grand cru Altenberg de Bergheim	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Bergheim vendanges tardives Riesling"}	Alsace grand cru Altenberg de Bergheim vendanges tardives Riesling	\N
10089	5	Alsace grand cru Altenberg de Wolxheim	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Wolxheim Gewurztraminer"}	Alsace grand cru Altenberg de Wolxheim Gewurztraminer	\N
10090	5	Alsace grand cru Altenberg de Wolxheim	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Wolxheim Muscat"}	Alsace grand cru Altenberg de Wolxheim Muscat	\N
10091	5	Alsace grand cru Altenberg de Wolxheim	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Wolxheim Pinot gris"}	Alsace grand cru Altenberg de Wolxheim Pinot gris	\N
10092	5	Alsace grand cru Altenberg de Wolxheim	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Wolxheim Riesling"}	Alsace grand cru Altenberg de Wolxheim Riesling	\N
10093	5	Alsace grand cru Altenberg de Wolxheim	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Wolxheim sélection de grains nobles Gewurztraminer"}	Alsace grand cru Altenberg de Wolxheim sélection de grains nobles Gewurztraminer	\N
10094	5	Alsace grand cru Altenberg de Wolxheim	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Wolxheim sélection de grains nobles Muscat"}	Alsace grand cru Altenberg de Wolxheim sélection de grains nobles Muscat	\N
10095	5	Alsace grand cru Altenberg de Wolxheim	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Wolxheim sélection de grains nobles Pinot gris"}	Alsace grand cru Altenberg de Wolxheim sélection de grains nobles Pinot gris	\N
10096	5	Alsace grand cru Altenberg de Wolxheim	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Wolxheim sélection de grains nobles Riesling"}	Alsace grand cru Altenberg de Wolxheim sélection de grains nobles Riesling	\N
10097	5	Alsace grand cru Altenberg de Wolxheim	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Wolxheim vendanges tardives Gewurztraminer"}	Alsace grand cru Altenberg de Wolxheim vendanges tardives Gewurztraminer	\N
10098	5	Alsace grand cru Altenberg de Wolxheim	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Wolxheim vendanges tardives Muscat"}	Alsace grand cru Altenberg de Wolxheim vendanges tardives Muscat	\N
10099	5	Alsace grand cru Altenberg de Wolxheim	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Wolxheim vendanges tardives Pinot gris"}	Alsace grand cru Altenberg de Wolxheim vendanges tardives Pinot gris	\N
10100	5	Alsace grand cru Altenberg de Wolxheim	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Wolxheim vendanges tardives Riesling"}	Alsace grand cru Altenberg de Wolxheim vendanges tardives Riesling	\N
11271	5	Alsace grand cru Altenberg de Wolxheim	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Wolxheim Muscat Ottonel"}	Alsace grand cru Altenberg de Wolxheim Muscat Ottonel	\N
11272	5	Alsace grand cru Altenberg de Wolxheim	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Wolxheim vendanges tardives Muscat Ottonel"}	Alsace grand cru Altenberg de Wolxheim vendanges tardives Muscat Ottonel	\N
11273	5	Alsace grand cru Altenberg de Wolxheim	AOC -	AOP -	{"fra": "Alsace grand cru Altenberg de Wolxheim sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Altenberg de Wolxheim sélection de grains nobles Muscat Ottonel	\N
10101	6	Alsace grand cru Brand	AOC -	AOP -	{"fra": "Alsace grand cru Brand Gewurztraminer"}	Alsace grand cru Brand Gewurztraminer	\N
10102	6	Alsace grand cru Brand	AOC -	AOP -	{"fra": "Alsace grand cru Brand sélection de grains nobles Gewurztraminer"}	Alsace grand cru Brand sélection de grains nobles Gewurztraminer	\N
10103	6	Alsace grand cru Brand	AOC -	AOP -	{"fra": "Alsace grand cru Brand sélection de grains nobles Muscat"}	Alsace grand cru Brand sélection de grains nobles Muscat	\N
10104	6	Alsace grand cru Brand	AOC -	AOP -	{"fra": "Alsace grand cru Brand sélection de grains nobles Pinot gris"}	Alsace grand cru Brand sélection de grains nobles Pinot gris	\N
10105	6	Alsace grand cru Brand	AOC -	AOP -	{"fra": "Alsace grand cru Brand sélection de grains nobles Riesling"}	Alsace grand cru Brand sélection de grains nobles Riesling	\N
10106	6	Alsace grand cru Brand	AOC -	AOP -	{"fra": "Alsace grand cru Brand Muscat"}	Alsace grand cru Brand Muscat	\N
10107	6	Alsace grand cru Brand	AOC -	AOP -	{"fra": "Alsace grand cru Brand Pinot gris"}	Alsace grand cru Brand Pinot gris	\N
10108	6	Alsace grand cru Brand	AOC -	AOP -	{"fra": "Alsace grand cru Brand Riesling"}	Alsace grand cru Brand Riesling	\N
10109	6	Alsace grand cru Brand	AOC -	AOP -	{"fra": "Alsace grand cru Brand vendanges tardives Gewurztraminer"}	Alsace grand cru Brand vendanges tardives Gewurztraminer	\N
10110	6	Alsace grand cru Brand	AOC -	AOP -	{"fra": "Alsace grand cru Brand vendanges tardives Muscat"}	Alsace grand cru Brand vendanges tardives Muscat	\N
10111	6	Alsace grand cru Brand	AOC -	AOP -	{"fra": "Alsace grand cru Brand vendanges tardives Pinot gris"}	Alsace grand cru Brand vendanges tardives Pinot gris	\N
10112	6	Alsace grand cru Brand	AOC -	AOP -	{"fra": "Alsace grand cru Brand vendanges tardives Riesling"}	Alsace grand cru Brand vendanges tardives Riesling	\N
11278	6	Alsace grand cru Brand	AOC -	AOP -	{"fra": "Alsace grand cru Brand sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Brand sélection de grains nobles Muscat Ottonel	\N
11281	6	Alsace grand cru Brand	AOC -	AOP -	{"fra": "Alsace grand cru Brand Muscat Ottonel"}	Alsace grand cru Brand Muscat Ottonel	\N
11284	6	Alsace grand cru Brand	AOC -	AOP -	{"fra": "Alsace grand cru Brand vendanges tardives Muscat Ottonel"}	Alsace grand cru Brand vendanges tardives Muscat Ottonel	\N
10113	7	Alsace grand cru Bruderthal	AOC -	AOP -	{"fra": "Alsace grand cru Bruderthal Gewurztraminer"}	Alsace grand cru Bruderthal Gewurztraminer	\N
10114	7	Alsace grand cru Bruderthal	AOC -	AOP -	{"fra": "Alsace grand cru Bruderthal sélection de grains nobles Gewurztraminer"}	Alsace grand cru Bruderthal sélection de grains nobles Gewurztraminer	\N
10115	7	Alsace grand cru Bruderthal	AOC -	AOP -	{"fra": "Alsace grand cru Bruderthal sélection de grains nobles Muscat"}	Alsace grand cru Bruderthal sélection de grains nobles Muscat	\N
10116	7	Alsace grand cru Bruderthal	AOC -	AOP -	{"fra": "Alsace grand cru Bruderthal sélection de grains nobles Pinot gris"}	Alsace grand cru Bruderthal sélection de grains nobles Pinot gris	\N
10117	7	Alsace grand cru Bruderthal	AOC -	AOP -	{"fra": "Alsace grand cru Bruderthal sélection de grains nobles Riesling"}	Alsace grand cru Bruderthal sélection de grains nobles Riesling	\N
10118	7	Alsace grand cru Bruderthal	AOC -	AOP -	{"fra": "Alsace grand cru Bruderthal Muscat"}	Alsace grand cru Bruderthal Muscat	\N
10119	7	Alsace grand cru Bruderthal	AOC -	AOP -	{"fra": "Alsace grand cru Bruderthal Pinot gris"}	Alsace grand cru Bruderthal Pinot gris	\N
10120	7	Alsace grand cru Bruderthal	AOC -	AOP -	{"fra": "Alsace grand cru Bruderthal Riesling"}	Alsace grand cru Bruderthal Riesling	\N
10121	7	Alsace grand cru Bruderthal	AOC -	AOP -	{"fra": "Alsace grand cru Bruderthal vendanges tardives Gewurztraminer"}	Alsace grand cru Bruderthal vendanges tardives Gewurztraminer	\N
10122	7	Alsace grand cru Bruderthal	AOC -	AOP -	{"fra": "Alsace grand cru Bruderthal vendanges tardives Muscat"}	Alsace grand cru Bruderthal vendanges tardives Muscat	\N
10123	7	Alsace grand cru Bruderthal	AOC -	AOP -	{"fra": "Alsace grand cru Bruderthal vendanges tardives Pinot gris"}	Alsace grand cru Bruderthal vendanges tardives Pinot gris	\N
10124	7	Alsace grand cru Bruderthal	AOC -	AOP -	{"fra": "Alsace grand cru Bruderthal vendanges tardives Riesling"}	Alsace grand cru Bruderthal vendanges tardives Riesling	\N
11286	7	Alsace grand cru Bruderthal	AOC -	AOP -	{"fra": "Alsace grand cru Bruderthal Muscat Ottonel"}	Alsace grand cru Bruderthal Muscat Ottonel	\N
11288	7	Alsace grand cru Bruderthal	AOC -	AOP -	{"fra": "Alsace grand cru Bruderthal sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Bruderthal sélection de grains nobles Muscat Ottonel	\N
11290	7	Alsace grand cru Bruderthal	AOC -	AOP -	{"fra": "Alsace grand cru Bruderthal vendanges tardives Muscat Ottonel"}	Alsace grand cru Bruderthal vendanges tardives Muscat Ottonel	\N
10125	8	Alsace grand cru Eichberg	AOC -	AOP -	{"fra": "Alsace grand cru Eichberg Gewurztraminer"}	Alsace grand cru Eichberg Gewurztraminer	\N
10126	8	Alsace grand cru Eichberg	AOC -	AOP -	{"fra": "Alsace grand cru Eichberg sélection de grains nobles Gewurztraminer"}	Alsace grand cru Eichberg sélection de grains nobles Gewurztraminer	\N
10127	8	Alsace grand cru Eichberg	AOC -	AOP -	{"fra": "Alsace grand cru Eichberg sélection de grains nobles Muscat"}	Alsace grand cru Eichberg sélection de grains nobles Muscat	\N
10128	8	Alsace grand cru Eichberg	AOC -	AOP -	{"fra": "Alsace grand cru Eichberg sélection de grains nobles Pinot gris"}	Alsace grand cru Eichberg sélection de grains nobles Pinot gris	\N
10129	8	Alsace grand cru Eichberg	AOC -	AOP -	{"fra": "Alsace grand cru Eichberg sélection de grains nobles Riesling"}	Alsace grand cru Eichberg sélection de grains nobles Riesling	\N
10130	8	Alsace grand cru Eichberg	AOC -	AOP -	{"fra": "Alsace grand cru Eichberg Muscat"}	Alsace grand cru Eichberg Muscat	\N
10131	8	Alsace grand cru Eichberg	AOC -	AOP -	{"fra": "Alsace grand cru Eichberg Pinot gris"}	Alsace grand cru Eichberg Pinot gris	\N
10132	8	Alsace grand cru Eichberg	AOC -	AOP -	{"fra": "Alsace grand cru Eichberg Riesling"}	Alsace grand cru Eichberg Riesling	\N
10133	8	Alsace grand cru Eichberg	AOC -	AOP -	{"fra": "Alsace grand cru Eichberg vendanges tardives Gewurztraminer"}	Alsace grand cru Eichberg vendanges tardives Gewurztraminer	\N
10134	8	Alsace grand cru Eichberg	AOC -	AOP -	{"fra": "Alsace grand cru Eichberg vendanges tardives Muscat"}	Alsace grand cru Eichberg vendanges tardives Muscat	\N
10135	8	Alsace grand cru Eichberg	AOC -	AOP -	{"fra": "Alsace grand cru Eichberg vendanges tardives Pinot gris"}	Alsace grand cru Eichberg vendanges tardives Pinot gris	\N
10136	8	Alsace grand cru Eichberg	AOC -	AOP -	{"fra": "Alsace grand cru Eichberg vendanges tardives Riesling"}	Alsace grand cru Eichberg vendanges tardives Riesling	\N
11292	8	Alsace grand cru Eichberg	AOC -	AOP -	{"fra": "Alsace grand cru Eichberg Muscat Ottonel"}	Alsace grand cru Eichberg Muscat Ottonel	\N
11293	8	Alsace grand cru Eichberg	AOC -	AOP -	{"fra": "Alsace grand cru Eichberg sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Eichberg sélection de grains nobles Muscat Ottonel	\N
11294	8	Alsace grand cru Eichberg	AOC -	AOP -	{"fra": "Alsace grand cru Eichberg vendanges tardives Muscat Ottonel"}	Alsace grand cru Eichberg vendanges tardives Muscat Ottonel	\N
10137	9	Alsace grand cru Engelberg	AOC -	AOP -	{"fra": "Alsace grand cru Engelberg Gewurztraminer"}	Alsace grand cru Engelberg Gewurztraminer	\N
10138	9	Alsace grand cru Engelberg	AOC -	AOP -	{"fra": "Alsace grand cru Engelberg sélection de grains nobles Gewurztraminer"}	Alsace grand cru Engelberg sélection de grains nobles Gewurztraminer	\N
10139	9	Alsace grand cru Engelberg	AOC -	AOP -	{"fra": "Alsace grand cru Engelberg sélection de grains nobles Muscat"}	Alsace grand cru Engelberg sélection de grains nobles Muscat	\N
10140	9	Alsace grand cru Engelberg	AOC -	AOP -	{"fra": "Alsace grand cru Engelberg sélection de grains nobles Pinot gris"}	Alsace grand cru Engelberg sélection de grains nobles Pinot gris	\N
10141	9	Alsace grand cru Engelberg	AOC -	AOP -	{"fra": "Alsace grand cru Engelberg sélection de grains nobles Riesling"}	Alsace grand cru Engelberg sélection de grains nobles Riesling	\N
10142	9	Alsace grand cru Engelberg	AOC -	AOP -	{"fra": "Alsace grand cru Engelberg Muscat"}	Alsace grand cru Engelberg Muscat	\N
10143	9	Alsace grand cru Engelberg	AOC -	AOP -	{"fra": "Alsace grand cru Engelberg Pinot gris"}	Alsace grand cru Engelberg Pinot gris	\N
10144	9	Alsace grand cru Engelberg	AOC -	AOP -	{"fra": "Alsace grand cru Engelberg Riesling"}	Alsace grand cru Engelberg Riesling	\N
10145	9	Alsace grand cru Engelberg	AOC -	AOP -	{"fra": "Alsace grand cru Engelberg vendanges tardives Gewurztraminer"}	Alsace grand cru Engelberg vendanges tardives Gewurztraminer	\N
10146	9	Alsace grand cru Engelberg	AOC -	AOP -	{"fra": "Alsace grand cru Engelberg vendanges tardives Muscat"}	Alsace grand cru Engelberg vendanges tardives Muscat	\N
10147	9	Alsace grand cru Engelberg	AOC -	AOP -	{"fra": "Alsace grand cru Engelberg vendanges tardives Pinot gris"}	Alsace grand cru Engelberg vendanges tardives Pinot gris	\N
10148	9	Alsace grand cru Engelberg	AOC -	AOP -	{"fra": "Alsace grand cru Engelberg vendanges tardives Riesling"}	Alsace grand cru Engelberg vendanges tardives Riesling	\N
11295	9	Alsace grand cru Engelberg	AOC -	AOP -	{"fra": "Alsace grand cru Engelberg Muscat Ottonel"}	Alsace grand cru Engelberg Muscat Ottonel	\N
11296	9	Alsace grand cru Engelberg	AOC -	AOP -	{"fra": "Alsace grand cru Engelberg sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Engelberg sélection de grains nobles Muscat Ottonel	\N
11297	9	Alsace grand cru Engelberg	AOC -	AOP -	{"fra": "Alsace grand cru Engelberg vendanges tardives Muscat Ottonel"}	Alsace grand cru Engelberg vendanges tardives Muscat Ottonel	\N
10149	10	Alsace grand cru Florimont	AOC -	AOP -	{"fra": "Alsace grand cru Florimont Gewurztraminer"}	Alsace grand cru Florimont Gewurztraminer	\N
10150	10	Alsace grand cru Florimont	AOC -	AOP -	{"fra": "Alsace grand cru Florimont sélection de grains nobles Muscat"}	Alsace grand cru Florimont sélection de grains nobles Muscat	\N
10151	10	Alsace grand cru Florimont	AOC -	AOP -	{"fra": "Alsace grand cru Florimont sélection de grains nobles Gewurztraminer"}	Alsace grand cru Florimont sélection de grains nobles Gewurztraminer	\N
10152	10	Alsace grand cru Florimont	AOC -	AOP -	{"fra": "Alsace grand cru Florimont sélection de grains nobles Pinot gris"}	Alsace grand cru Florimont sélection de grains nobles Pinot gris	\N
10153	10	Alsace grand cru Florimont	AOC -	AOP -	{"fra": "Alsace grand cru Florimont sélection de grains nobles Riesling"}	Alsace grand cru Florimont sélection de grains nobles Riesling	\N
10154	10	Alsace grand cru Florimont	AOC -	AOP -	{"fra": "Alsace grand cru Florimont Muscat"}	Alsace grand cru Florimont Muscat	\N
10155	10	Alsace grand cru Florimont	AOC -	AOP -	{"fra": "Alsace grand cru Florimont Pinot gris"}	Alsace grand cru Florimont Pinot gris	\N
10156	10	Alsace grand cru Florimont	AOC -	AOP -	{"fra": "Alsace grand cru Florimont Riesling"}	Alsace grand cru Florimont Riesling	\N
10157	10	Alsace grand cru Florimont	AOC -	AOP -	{"fra": "Alsace grand cru Florimont vendanges tardives Gewurztraminer"}	Alsace grand cru Florimont vendanges tardives Gewurztraminer	\N
12247	236	Arbois	AOC -	AOP -	{"fra": "Arbois vin de paille"}	Arbois vin de paille	\N
10158	10	Alsace grand cru Florimont	AOC -	AOP -	{"fra": "Alsace grand cru Florimont vendanges tardives Muscat"}	Alsace grand cru Florimont vendanges tardives Muscat	\N
10159	10	Alsace grand cru Florimont	AOC -	AOP -	{"fra": "Alsace grand cru Florimont vendanges tardives Pinot gris"}	Alsace grand cru Florimont vendanges tardives Pinot gris	\N
10160	10	Alsace grand cru Florimont	AOC -	AOP -	{"fra": "Alsace grand cru Florimont vendanges tardives Riesling"}	Alsace grand cru Florimont vendanges tardives Riesling	\N
11298	10	Alsace grand cru Florimont	AOC -	AOP -	{"fra": "Alsace grand cru Florimont Muscat Ottonel"}	Alsace grand cru Florimont Muscat Ottonel	\N
11299	10	Alsace grand cru Florimont	AOC -	AOP -	{"fra": "Alsace grand cru Florimont sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Florimont sélection de grains nobles Muscat Ottonel	\N
11300	10	Alsace grand cru Florimont	AOC -	AOP -	{"fra": "Alsace grand cru Florimont vendanges tardives Muscat Ottonel"}	Alsace grand cru Florimont vendanges tardives Muscat Ottonel	\N
10161	11	Alsace grand cru Frankstein	AOC -	AOP -	{"fra": "Alsace grand cru Frankstein Gewurztraminer"}	Alsace grand cru Frankstein Gewurztraminer	\N
10162	11	Alsace grand cru Frankstein	AOC -	AOP -	{"fra": "Alsace grand cru Frankstein sélection de grains nobles Gewurztraminer"}	Alsace grand cru Frankstein sélection de grains nobles Gewurztraminer	\N
10163	11	Alsace grand cru Frankstein	AOC -	AOP -	{"fra": "Alsace grand cru Frankstein sélection de grains nobles Muscat"}	Alsace grand cru Frankstein sélection de grains nobles Muscat	\N
10164	11	Alsace grand cru Frankstein	AOC -	AOP -	{"fra": "Alsace grand cru Frankstein sélection de grains nobles Pinot gris"}	Alsace grand cru Frankstein sélection de grains nobles Pinot gris	\N
10165	11	Alsace grand cru Frankstein	AOC -	AOP -	{"fra": "Alsace grand cru Frankstein sélection de grains nobles Riesling"}	Alsace grand cru Frankstein sélection de grains nobles Riesling	\N
10166	11	Alsace grand cru Frankstein	AOC -	AOP -	{"fra": "Alsace grand cru Frankstein Muscat"}	Alsace grand cru Frankstein Muscat	\N
10167	11	Alsace grand cru Frankstein	AOC -	AOP -	{"fra": "Alsace grand cru Frankstein Pinot gris"}	Alsace grand cru Frankstein Pinot gris	\N
10168	11	Alsace grand cru Frankstein	AOC -	AOP -	{"fra": "Alsace grand cru Frankstein Riesling"}	Alsace grand cru Frankstein Riesling	\N
10169	11	Alsace grand cru Frankstein	AOC -	AOP -	{"fra": "Alsace grand cru Frankstein vendanges tardives Gewurztraminer"}	Alsace grand cru Frankstein vendanges tardives Gewurztraminer	\N
10170	11	Alsace grand cru Frankstein	AOC -	AOP -	{"fra": "Alsace grand cru Frankstein vendanges tardives Muscat"}	Alsace grand cru Frankstein vendanges tardives Muscat	\N
10171	11	Alsace grand cru Frankstein	AOC -	AOP -	{"fra": "Alsace grand cru Frankstein vendanges tardives Pinot gris"}	Alsace grand cru Frankstein vendanges tardives Pinot gris	\N
10172	11	Alsace grand cru Frankstein	AOC -	AOP -	{"fra": "Alsace grand cru Frankstein vendanges tardives Riesling"}	Alsace grand cru Frankstein vendanges tardives Riesling	\N
11303	11	Alsace grand cru Frankstein	AOC -	AOP -	{"fra": "Alsace grand cru Frankstein Muscat Ottonel"}	Alsace grand cru Frankstein Muscat Ottonel	\N
11306	11	Alsace grand cru Frankstein	AOC -	AOP -	{"fra": "Alsace grand cru Frankstein sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Frankstein sélection de grains nobles Muscat Ottonel	\N
11307	11	Alsace grand cru Frankstein	AOC -	AOP -	{"fra": "Alsace grand cru Frankstein vendanges tardives Muscat Ottonel"}	Alsace grand cru Frankstein vendanges tardives Muscat Ottonel	\N
10173	12	Alsace grand cru Froehn	AOC -	AOP -	{"fra": "Alsace grand cru Froehn Gewurztraminer"}	Alsace grand cru Froehn Gewurztraminer	\N
10174	12	Alsace grand cru Froehn	AOC -	AOP -	{"fra": "Alsace grand cru Froehn sélection de grains nobles Gewurztraminer"}	Alsace grand cru Froehn sélection de grains nobles Gewurztraminer	\N
10175	12	Alsace grand cru Froehn	AOC -	AOP -	{"fra": "Alsace grand cru Froehn sélection de grains nobles Muscat"}	Alsace grand cru Froehn sélection de grains nobles Muscat	\N
10176	12	Alsace grand cru Froehn	AOC -	AOP -	{"fra": "Alsace grand cru Froehn sélection de grains nobles Pinot gris"}	Alsace grand cru Froehn sélection de grains nobles Pinot gris	\N
10177	12	Alsace grand cru Froehn	AOC -	AOP -	{"fra": "Alsace grand cru Froehn sélection de grains nobles Riesling"}	Alsace grand cru Froehn sélection de grains nobles Riesling	\N
10178	12	Alsace grand cru Froehn	AOC -	AOP -	{"fra": "Alsace grand cru Froehn Muscat"}	Alsace grand cru Froehn Muscat	\N
10179	12	Alsace grand cru Froehn	AOC -	AOP -	{"fra": "Alsace grand cru Froehn Pinot gris"}	Alsace grand cru Froehn Pinot gris	\N
10180	12	Alsace grand cru Froehn	AOC -	AOP -	{"fra": "Alsace grand cru Froehn Riesling"}	Alsace grand cru Froehn Riesling	\N
10181	12	Alsace grand cru Froehn	AOC -	AOP -	{"fra": "Alsace grand cru Froehn vendanges tardives Gewurztraminer"}	Alsace grand cru Froehn vendanges tardives Gewurztraminer	\N
10182	12	Alsace grand cru Froehn	AOC -	AOP -	{"fra": "Alsace grand cru Froehn vendanges tardives Muscat"}	Alsace grand cru Froehn vendanges tardives Muscat	\N
10183	12	Alsace grand cru Froehn	AOC -	AOP -	{"fra": "Alsace grand cru Froehn vendanges tardives Pinot gris"}	Alsace grand cru Froehn vendanges tardives Pinot gris	\N
10184	12	Alsace grand cru Froehn	AOC -	AOP -	{"fra": "Alsace grand cru Froehn vendanges tardives Riesling"}	Alsace grand cru Froehn vendanges tardives Riesling	\N
11308	12	Alsace grand cru Froehn	AOC -	AOP -	{"fra": "Alsace grand cru Froehn Muscat Ottonel"}	Alsace grand cru Froehn Muscat Ottonel	\N
11310	12	Alsace grand cru Froehn	AOC -	AOP -	{"fra": "Alsace grand cru Froehn sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Froehn sélection de grains nobles Muscat Ottonel	\N
11311	12	Alsace grand cru Froehn	AOC -	AOP -	{"fra": "Alsace grand cru Froehn vendanges tardives Muscat Ottonel"}	Alsace grand cru Froehn vendanges tardives Muscat Ottonel	\N
10185	13	Alsace grand cru Furstentum	AOC -	AOP -	{"fra": "Alsace grand cru Furstentum Gewurztraminer"}	Alsace grand cru Furstentum Gewurztraminer	\N
10186	13	Alsace grand cru Furstentum	AOC -	AOP -	{"fra": "Alsace grand cru Furstentum sélection de grains nobles Gewurztraminer"}	Alsace grand cru Furstentum sélection de grains nobles Gewurztraminer	\N
10187	13	Alsace grand cru Furstentum	AOC -	AOP -	{"fra": "Alsace grand cru Furstentum sélection de grains nobles Muscat"}	Alsace grand cru Furstentum sélection de grains nobles Muscat	\N
10188	13	Alsace grand cru Furstentum	AOC -	AOP -	{"fra": "Alsace grand cru Furstentum sélection de grains nobles Pinot gris"}	Alsace grand cru Furstentum sélection de grains nobles Pinot gris	\N
10189	13	Alsace grand cru Furstentum	AOC -	AOP -	{"fra": "Alsace grand cru Furstentum sélection de grains nobles Riesling"}	Alsace grand cru Furstentum sélection de grains nobles Riesling	\N
10190	13	Alsace grand cru Furstentum	AOC -	AOP -	{"fra": "Alsace grand cru Furstentum Muscat"}	Alsace grand cru Furstentum Muscat	\N
10191	13	Alsace grand cru Furstentum	AOC -	AOP -	{"fra": "Alsace grand cru Furstentum Pinot gris"}	Alsace grand cru Furstentum Pinot gris	\N
10192	13	Alsace grand cru Furstentum	AOC -	AOP -	{"fra": "Alsace grand cru Furstentum Riesling"}	Alsace grand cru Furstentum Riesling	\N
10193	13	Alsace grand cru Furstentum	AOC -	AOP -	{"fra": "Alsace grand cru Furstentum vendanges tardives Gewurztraminer"}	Alsace grand cru Furstentum vendanges tardives Gewurztraminer	\N
10194	13	Alsace grand cru Furstentum	AOC -	AOP -	{"fra": "Alsace grand cru Furstentum vendanges tardives Muscat"}	Alsace grand cru Furstentum vendanges tardives Muscat	\N
10195	13	Alsace grand cru Furstentum	AOC -	AOP -	{"fra": "Alsace grand cru Furstentum vendanges tardives Pinot gris"}	Alsace grand cru Furstentum vendanges tardives Pinot gris	\N
10196	13	Alsace grand cru Furstentum	AOC -	AOP -	{"fra": "Alsace grand cru Furstentum vendanges tardives Riesling"}	Alsace grand cru Furstentum vendanges tardives Riesling	\N
11312	13	Alsace grand cru Furstentum	AOC -	AOP -	{"fra": "Alsace grand cru Furstentum Muscat Ottonel"}	Alsace grand cru Furstentum Muscat Ottonel	\N
11313	13	Alsace grand cru Furstentum	AOC -	AOP -	{"fra": "Alsace grand cru Furstentum sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Furstentum sélection de grains nobles Muscat Ottonel	\N
11315	13	Alsace grand cru Furstentum	AOC -	AOP -	{"fra": "Alsace grand cru Furstentum vendanges tardives Muscat Ottonel"}	Alsace grand cru Furstentum vendanges tardives Muscat Ottonel	\N
11185	14	Alsace grand cru Geisberg	AOC -	AOP -	{"fra": "Alsace grand cru Geisberg Gewurztraminer"}	Alsace grand cru Geisberg Gewurztraminer	\N
11186	14	Alsace grand cru Geisberg	AOC -	AOP -	{"fra": "Alsace grand cru Geisberg sélection de grains nobles Gewurztraminer"}	Alsace grand cru Geisberg sélection de grains nobles Gewurztraminer	\N
11187	14	Alsace grand cru Geisberg	AOC -	AOP -	{"fra": "Alsace grand cru Geisberg sélection de grains nobles Muscat"}	Alsace grand cru Geisberg sélection de grains nobles Muscat	\N
11188	14	Alsace grand cru Geisberg	AOC -	AOP -	{"fra": "Alsace grand cru Geisberg sélection de grains nobles Pinot gris"}	Alsace grand cru Geisberg sélection de grains nobles Pinot gris	\N
11189	14	Alsace grand cru Geisberg	AOC -	AOP -	{"fra": "Alsace grand cru Geisberg sélection de grains nobles Riesling"}	Alsace grand cru Geisberg sélection de grains nobles Riesling	\N
11190	14	Alsace grand cru Geisberg	AOC -	AOP -	{"fra": "Alsace grand cru Geisberg Muscat"}	Alsace grand cru Geisberg Muscat	\N
11191	14	Alsace grand cru Geisberg	AOC -	AOP -	{"fra": "Alsace grand cru Geisberg Pinot gris"}	Alsace grand cru Geisberg Pinot gris	\N
11192	14	Alsace grand cru Geisberg	AOC -	AOP -	{"fra": "Alsace grand cru Geisberg Riesling"}	Alsace grand cru Geisberg Riesling	\N
11193	14	Alsace grand cru Geisberg	AOC -	AOP -	{"fra": "Alsace grand cru Geisberg vendanges tardives Gewurztraminer"}	Alsace grand cru Geisberg vendanges tardives Gewurztraminer	\N
11194	14	Alsace grand cru Geisberg	AOC -	AOP -	{"fra": "Alsace grand cru Geisberg vendanges tardives Muscat"}	Alsace grand cru Geisberg vendanges tardives Muscat	\N
11195	14	Alsace grand cru Geisberg	AOC -	AOP -	{"fra": "Alsace grand cru Geisberg vendanges tardives Pinot gris"}	Alsace grand cru Geisberg vendanges tardives Pinot gris	\N
11196	14	Alsace grand cru Geisberg	AOC -	AOP -	{"fra": "Alsace grand cru Geisberg vendanges tardives Riesling"}	Alsace grand cru Geisberg vendanges tardives Riesling	\N
11326	14	Alsace grand cru Geisberg	AOC -	AOP -	{"fra": "Alsace grand cru Geisberg sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Geisberg sélection de grains nobles Muscat Ottonel	\N
11327	14	Alsace grand cru Geisberg	AOC -	AOP -	{"fra": "Alsace grand cru Geisberg Muscat Ottonel"}	Alsace grand cru Geisberg Muscat Ottonel	\N
11330	14	Alsace grand cru Geisberg	AOC -	AOP -	{"fra": "Alsace grand cru Geisberg vendanges tardives Muscat Ottonel"}	Alsace grand cru Geisberg vendanges tardives Muscat Ottonel	\N
11197	15	Alsace grand cru Gloeckelberg	AOC -	AOP -	{"fra": "Alsace grand cru Gloeckelberg Gewurztraminer"}	Alsace grand cru Gloeckelberg Gewurztraminer	\N
11198	15	Alsace grand cru Gloeckelberg	AOC -	AOP -	{"fra": "Alsace grand cru Gloeckelberg sélection de grains nobles Gewurztraminer"}	Alsace grand cru Gloeckelberg sélection de grains nobles Gewurztraminer	\N
11199	15	Alsace grand cru Gloeckelberg	AOC -	AOP -	{"fra": "Alsace grand cru Gloeckelberg sélection de grains nobles Muscat"}	Alsace grand cru Gloeckelberg sélection de grains nobles Muscat	\N
11200	15	Alsace grand cru Gloeckelberg	AOC -	AOP -	{"fra": "Alsace grand cru Gloeckelberg sélection de grains nobles Pinot gris"}	Alsace grand cru Gloeckelberg sélection de grains nobles Pinot gris	\N
11201	15	Alsace grand cru Gloeckelberg	AOC -	AOP -	{"fra": "Alsace grand cru Gloeckelberg sélection de grains nobles Riesling"}	Alsace grand cru Gloeckelberg sélection de grains nobles Riesling	\N
11202	15	Alsace grand cru Gloeckelberg	AOC -	AOP -	{"fra": "Alsace grand cru Gloeckelberg Muscat"}	Alsace grand cru Gloeckelberg Muscat	\N
11203	15	Alsace grand cru Gloeckelberg	AOC -	AOP -	{"fra": "Alsace grand cru Gloeckelberg Pinot gris"}	Alsace grand cru Gloeckelberg Pinot gris	\N
11204	15	Alsace grand cru Gloeckelberg	AOC -	AOP -	{"fra": "Alsace grand cru Gloeckelberg Riesling"}	Alsace grand cru Gloeckelberg Riesling	\N
11205	15	Alsace grand cru Gloeckelberg	AOC -	AOP -	{"fra": "Alsace grand cru Gloeckelberg vendanges tardives Gewurztraminer"}	Alsace grand cru Gloeckelberg vendanges tardives Gewurztraminer	\N
11206	15	Alsace grand cru Gloeckelberg	AOC -	AOP -	{"fra": "Alsace grand cru Gloeckelberg vendanges tardives Muscat"}	Alsace grand cru Gloeckelberg vendanges tardives Muscat	\N
11207	15	Alsace grand cru Gloeckelberg	AOC -	AOP -	{"fra": "Alsace grand cru Gloeckelberg vendanges tardives Pinot gris"}	Alsace grand cru Gloeckelberg vendanges tardives Pinot gris	\N
11208	15	Alsace grand cru Gloeckelberg	AOC -	AOP -	{"fra": "Alsace grand cru Gloeckelberg vendanges tardives Riesling"}	Alsace grand cru Gloeckelberg vendanges tardives Riesling	\N
11333	15	Alsace grand cru Gloeckelberg	AOC -	AOP -	{"fra": "Alsace grand cru Gloeckelberg sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Gloeckelberg sélection de grains nobles Muscat Ottonel	\N
11335	15	Alsace grand cru Gloeckelberg	AOC -	AOP -	{"fra": "Alsace grand cru Gloeckelberg Muscat Ottonel"}	Alsace grand cru Gloeckelberg Muscat Ottonel	\N
11337	15	Alsace grand cru Gloeckelberg	AOC -	AOP -	{"fra": "Alsace grand cru Gloeckelberg vendanges tardives Muscat Ottonel"}	Alsace grand cru Gloeckelberg vendanges tardives Muscat Ottonel	\N
11209	16	Alsace grand cru Goldert	AOC -	AOP -	{"fra": "Alsace grand cru Goldert Gewurztraminer"}	Alsace grand cru Goldert Gewurztraminer	\N
11210	16	Alsace grand cru Goldert	AOC -	AOP -	{"fra": "Alsace grand cru Goldert sélection de grains nobles Gewurztraminer"}	Alsace grand cru Goldert sélection de grains nobles Gewurztraminer	\N
11211	16	Alsace grand cru Goldert	AOC -	AOP -	{"fra": "Alsace grand cru Goldert sélection de grains nobles Muscat"}	Alsace grand cru Goldert sélection de grains nobles Muscat	\N
11212	16	Alsace grand cru Goldert	AOC -	AOP -	{"fra": "Alsace grand cru Goldert sélection de grains nobles Pinot gris"}	Alsace grand cru Goldert sélection de grains nobles Pinot gris	\N
11213	16	Alsace grand cru Goldert	AOC -	AOP -	{"fra": "Alsace grand cru Goldert sélection de grains nobles Riesling"}	Alsace grand cru Goldert sélection de grains nobles Riesling	\N
11214	16	Alsace grand cru Goldert	AOC -	AOP -	{"fra": "Alsace grand cru Goldert Muscat"}	Alsace grand cru Goldert Muscat	\N
11215	16	Alsace grand cru Goldert	AOC -	AOP -	{"fra": "Alsace grand cru Goldert Pinot gris"}	Alsace grand cru Goldert Pinot gris	\N
11216	16	Alsace grand cru Goldert	AOC -	AOP -	{"fra": "Alsace grand cru Goldert Riesling"}	Alsace grand cru Goldert Riesling	\N
11217	16	Alsace grand cru Goldert	AOC -	AOP -	{"fra": "Alsace grand cru Goldert vendanges tardives Gewurztraminer"}	Alsace grand cru Goldert vendanges tardives Gewurztraminer	\N
11218	16	Alsace grand cru Goldert	AOC -	AOP -	{"fra": "Alsace grand cru Goldert vendanges tardives Muscat"}	Alsace grand cru Goldert vendanges tardives Muscat	\N
11219	16	Alsace grand cru Goldert	AOC -	AOP -	{"fra": "Alsace grand cru Goldert vendanges tardives Pinot gris"}	Alsace grand cru Goldert vendanges tardives Pinot gris	\N
11220	16	Alsace grand cru Goldert	AOC -	AOP -	{"fra": "Alsace grand cru Goldert vendanges tardives Riesling"}	Alsace grand cru Goldert vendanges tardives Riesling	\N
11338	16	Alsace grand cru Goldert	AOC -	AOP -	{"fra": "Alsace grand cru Goldert sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Goldert sélection de grains nobles Muscat Ottonel	\N
11340	16	Alsace grand cru Goldert	AOC -	AOP -	{"fra": "Alsace grand cru Goldert Muscat Ottonel"}	Alsace grand cru Goldert Muscat Ottonel	\N
11341	16	Alsace grand cru Goldert	AOC -	AOP -	{"fra": "Alsace grand cru Goldert vendanges tardives Muscat Ottonel"}	Alsace grand cru Goldert vendanges tardives Muscat Ottonel	\N
11355	17	Alsace grand cru Hatschbourg	AOC -	AOP -	{"fra": "Alsace grand cru Hatschbourg Gewurztraminer"}	Alsace grand cru Hatschbourg Gewurztraminer	\N
11356	17	Alsace grand cru Hatschbourg	AOC -	AOP -	{"fra": "Alsace grand cru Hatschbourg sélection de grains nobles Gewurztraminer"}	Alsace grand cru Hatschbourg sélection de grains nobles Gewurztraminer	\N
11357	17	Alsace grand cru Hatschbourg	AOC -	AOP -	{"fra": "Alsace grand cru Hatschbourg sélection de grains nobles Muscat"}	Alsace grand cru Hatschbourg sélection de grains nobles Muscat	\N
11358	17	Alsace grand cru Hatschbourg	AOC -	AOP -	{"fra": "Alsace grand cru Hatschbourg sélection de grains nobles Pinot gris"}	Alsace grand cru Hatschbourg sélection de grains nobles Pinot gris	\N
13223	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace blanc Pinot Gris"}	Alsace blanc Pinot Gris	\N
11359	17	Alsace grand cru Hatschbourg	AOC -	AOP -	{"fra": "Alsace grand cru Hatschbourg sélection de grains nobles Riesling"}	Alsace grand cru Hatschbourg sélection de grains nobles Riesling	\N
11360	17	Alsace grand cru Hatschbourg	AOC -	AOP -	{"fra": "Alsace grand cru Hatschbourg Muscat"}	Alsace grand cru Hatschbourg Muscat	\N
11361	17	Alsace grand cru Hatschbourg	AOC -	AOP -	{"fra": "Alsace grand cru Hatschbourg Pinot gris"}	Alsace grand cru Hatschbourg Pinot gris	\N
11362	17	Alsace grand cru Hatschbourg	AOC -	AOP -	{"fra": "Alsace grand cru Hatschbourg Riesling"}	Alsace grand cru Hatschbourg Riesling	\N
11363	17	Alsace grand cru Hatschbourg	AOC -	AOP -	{"fra": "Alsace grand cru Hatschbourg vendanges tardives Gewurztraminer"}	Alsace grand cru Hatschbourg vendanges tardives Gewurztraminer	\N
11364	17	Alsace grand cru Hatschbourg	AOC -	AOP -	{"fra": "Alsace grand cru Hatschbourg vendanges tardives Muscat"}	Alsace grand cru Hatschbourg vendanges tardives Muscat	\N
11365	17	Alsace grand cru Hatschbourg	AOC -	AOP -	{"fra": "Alsace grand cru Hatschbourg vendanges tardives Pinot gris"}	Alsace grand cru Hatschbourg vendanges tardives Pinot gris	\N
11366	17	Alsace grand cru Hatschbourg	AOC -	AOP -	{"fra": "Alsace grand cru Hatschbourg vendanges tardives Riesling"}	Alsace grand cru Hatschbourg vendanges tardives Riesling	\N
11379	17	Alsace grand cru Hatschbourg	AOC -	AOP -	{"fra": "Alsace grand cru Hatschbourg Muscat Ottonel"}	Alsace grand cru Hatschbourg Muscat Ottonel	\N
11380	17	Alsace grand cru Hatschbourg	AOC -	AOP -	{"fra": "Alsace grand cru Hatschbourg vendanges tardives Muscat Ottonel"}	Alsace grand cru Hatschbourg vendanges tardives Muscat Ottonel	\N
11381	17	Alsace grand cru Hatschbourg	AOC -	AOP -	{"fra": "Alsace grand cru Hatschbourg sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Hatschbourg sélection de grains nobles Muscat Ottonel	\N
11367	18	Alsace grand cru Hengst	AOC -	AOP -	{"fra": "Alsace grand cru Hengst Gewurztraminer"}	Alsace grand cru Hengst Gewurztraminer	\N
11368	18	Alsace grand cru Hengst	AOC -	AOP -	{"fra": "Alsace grand cru Hengst sélection de grains nobles Gewurztraminer"}	Alsace grand cru Hengst sélection de grains nobles Gewurztraminer	\N
11369	18	Alsace grand cru Hengst	AOC -	AOP -	{"fra": "Alsace grand cru Hengst sélection de grains nobles Muscat"}	Alsace grand cru Hengst sélection de grains nobles Muscat	\N
11370	18	Alsace grand cru Hengst	AOC -	AOP -	{"fra": "Alsace grand cru Hengst sélection de grains nobles Pinot gris"}	Alsace grand cru Hengst sélection de grains nobles Pinot gris	\N
11371	18	Alsace grand cru Hengst	AOC -	AOP -	{"fra": "Alsace grand cru Hengst sélection de grains nobles Riesling"}	Alsace grand cru Hengst sélection de grains nobles Riesling	\N
11373	18	Alsace grand cru Hengst	AOC -	AOP -	{"fra": "Alsace grand cru Hengst Pinot gris"}	Alsace grand cru Hengst Pinot gris	\N
11374	18	Alsace grand cru Hengst	AOC -	AOP -	{"fra": "Alsace grand cru Hengst Riesling"}	Alsace grand cru Hengst Riesling	\N
11375	18	Alsace grand cru Hengst	AOC -	AOP -	{"fra": "Alsace grand cru Hengst vendanges tardives Gewurztraminer"}	Alsace grand cru Hengst vendanges tardives Gewurztraminer	\N
11376	18	Alsace grand cru Hengst	AOC -	AOP -	{"fra": "Alsace grand cru Hengst vendanges tardives Muscat"}	Alsace grand cru Hengst vendanges tardives Muscat	\N
11377	18	Alsace grand cru Hengst	AOC -	AOP -	{"fra": "Alsace grand cru Hengst vendanges tardives Pinot gris"}	Alsace grand cru Hengst vendanges tardives Pinot gris	\N
12240	237	Arbois Pupillin	AOC -	AOP -	{"fra": "Arbois Pupillin blanc"}	Arbois Pupillin blanc	\N
11378	18	Alsace grand cru Hengst	AOC -	AOP -	{"fra": "Alsace grand cru Hengst vendanges tardives Riesling"}	Alsace grand cru Hengst vendanges tardives Riesling	\N
11382	18	Alsace grand cru Hengst	AOC -	AOP -	{"fra": "Alsace grand cru Hengst Muscat"}	Alsace grand cru Hengst Muscat	\N
11383	18	Alsace grand cru Hengst	AOC -	AOP -	{"fra": "Alsace grand cru Hengst Muscat Ottonel"}	Alsace grand cru Hengst Muscat Ottonel	\N
11384	18	Alsace grand cru Hengst	AOC -	AOP -	{"fra": "Alsace grand cru Hengst sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Hengst sélection de grains nobles Muscat Ottonel	\N
11385	18	Alsace grand cru Hengst	AOC -	AOP -	{"fra": "Alsace grand cru Hengst vendanges tardives Muscat Ottonel"}	Alsace grand cru Hengst vendanges tardives Muscat Ottonel	\N
11454	1653	Alsace grand cru Kaefferkopf	AOC -	AOP -	{"fra": "Alsace grand cru Kaefferkopf"}	Alsace grand cru Kaefferkopf	\N
11455	1653	Alsace grand cru Kaefferkopf	AOC -	AOP -	{"fra": "Alsace grand cru Kaefferkopf Gewurztraminer"}	Alsace grand cru Kaefferkopf Gewurztraminer	\N
11456	1653	Alsace grand cru Kaefferkopf	AOC -	AOP -	{"fra": "Alsace grand cru Kaefferkopf Pinot gris"}	Alsace grand cru Kaefferkopf Pinot gris	\N
11457	1653	Alsace grand cru Kaefferkopf	AOC -	AOP -	{"fra": "Alsace grand cru Kaefferkopf Riesling"}	Alsace grand cru Kaefferkopf Riesling	\N
11458	1653	Alsace grand cru Kaefferkopf	AOC -	AOP -	{"fra": "Alsace grand cru Kaefferkopf sélection de grains nobles Gewurztraminer"}	Alsace grand cru Kaefferkopf sélection de grains nobles Gewurztraminer	\N
11459	1653	Alsace grand cru Kaefferkopf	AOC -	AOP -	{"fra": "Alsace grand cru Kaefferkopf sélection de grains nobles Riesling"}	Alsace grand cru Kaefferkopf sélection de grains nobles Riesling	\N
11460	1653	Alsace grand cru Kaefferkopf	AOC -	AOP -	{"fra": "Alsace grand cru Kaefferkopf vendanges tardives Gewurztraminer"}	Alsace grand cru Kaefferkopf vendanges tardives Gewurztraminer	\N
11461	1653	Alsace grand cru Kaefferkopf	AOC -	AOP -	{"fra": "Alsace grand cru Kaefferkopf vendanges tardives Riesling"}	Alsace grand cru Kaefferkopf vendanges tardives Riesling	\N
11452	19	Alsace grand cru Kanzlerberg	AOC -	AOP -	{"fra": "Alsace grand cru Kanzlerberg Gewurztraminer"}	Alsace grand cru Kanzlerberg Gewurztraminer	\N
11462	19	Alsace grand cru Kanzlerberg	AOC -	AOP -	{"fra": "Alsace grand cru Kanzlerberg sélection de grains nobles Gewurztraminer"}	Alsace grand cru Kanzlerberg sélection de grains nobles Gewurztraminer	\N
11463	19	Alsace grand cru Kanzlerberg	AOC -	AOP -	{"fra": "Alsace grand cru Kanzlerberg sélection de grains nobles Muscat"}	Alsace grand cru Kanzlerberg sélection de grains nobles Muscat	\N
11464	19	Alsace grand cru Kanzlerberg	AOC -	AOP -	{"fra": "Alsace grand cru Kanzlerberg sélection de grains nobles Pinot gris"}	Alsace grand cru Kanzlerberg sélection de grains nobles Pinot gris	\N
11465	19	Alsace grand cru Kanzlerberg	AOC -	AOP -	{"fra": "Alsace grand cru Kanzlerberg sélection de grains nobles Riesling"}	Alsace grand cru Kanzlerberg sélection de grains nobles Riesling	\N
11466	19	Alsace grand cru Kanzlerberg	AOC -	AOP -	{"fra": "Alsace grand cru Kanzlerberg Muscat"}	Alsace grand cru Kanzlerberg Muscat	\N
11467	19	Alsace grand cru Kanzlerberg	AOC -	AOP -	{"fra": "Alsace grand cru Kanzlerberg Pinot gris"}	Alsace grand cru Kanzlerberg Pinot gris	\N
11468	19	Alsace grand cru Kanzlerberg	AOC -	AOP -	{"fra": "Alsace grand cru Kanzlerberg vendanges tardives Gewurztraminer"}	Alsace grand cru Kanzlerberg vendanges tardives Gewurztraminer	\N
11469	19	Alsace grand cru Kanzlerberg	AOC -	AOP -	{"fra": "Alsace grand cru Kanzlerberg vendanges tardives Muscat"}	Alsace grand cru Kanzlerberg vendanges tardives Muscat	\N
11470	19	Alsace grand cru Kanzlerberg	AOC -	AOP -	{"fra": "Alsace grand cru Kanzlerberg vendanges tardives Pinot gris"}	Alsace grand cru Kanzlerberg vendanges tardives Pinot gris	\N
11471	19	Alsace grand cru Kanzlerberg	AOC -	AOP -	{"fra": "Alsace grand cru Kanzlerberg vendanges tardives Riesling"}	Alsace grand cru Kanzlerberg vendanges tardives Riesling	\N
11472	19	Alsace grand cru Kanzlerberg	AOC -	AOP -	{"fra": "Alsace grand cru Kanzlerberg Riesling"}	Alsace grand cru Kanzlerberg Riesling	\N
11473	19	Alsace grand cru Kanzlerberg	AOC -	AOP -	{"fra": "Alsace grand cru Kanzlerberg Muscat Ottonel"}	Alsace grand cru Kanzlerberg Muscat Ottonel	\N
11474	19	Alsace grand cru Kanzlerberg	AOC -	AOP -	{"fra": "Alsace grand cru Kanzlerberg sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Kanzlerberg sélection de grains nobles Muscat Ottonel	\N
11475	19	Alsace grand cru Kanzlerberg	AOC -	AOP -	{"fra": "Alsace grand cru Kanzlerberg vendanges tardives Muscat Ottonel"}	Alsace grand cru Kanzlerberg vendanges tardives Muscat Ottonel	\N
11496	20	Alsace grand cru Kastelberg	AOC -	AOP -	{"fra": "Alsace grand cru Kastelberg Gewurztraminer"}	Alsace grand cru Kastelberg Gewurztraminer	\N
11497	20	Alsace grand cru Kastelberg	AOC -	AOP -	{"fra": "Alsace grand cru Kastelberg sélection de grains nobles Gewurztraminer"}	Alsace grand cru Kastelberg sélection de grains nobles Gewurztraminer	\N
11498	20	Alsace grand cru Kastelberg	AOC -	AOP -	{"fra": "Alsace grand cru Kastelberg Pinot gris"}	Alsace grand cru Kastelberg Pinot gris	\N
11499	20	Alsace grand cru Kastelberg	AOC -	AOP -	{"fra": "Alsace grand cru Kastelberg Riesling"}	Alsace grand cru Kastelberg Riesling	\N
11500	20	Alsace grand cru Kastelberg	AOC -	AOP -	{"fra": "Alsace grand cru Kastelberg sélection de grains nobles Muscat"}	Alsace grand cru Kastelberg sélection de grains nobles Muscat	\N
11501	20	Alsace grand cru Kastelberg	AOC -	AOP -	{"fra": "Alsace grand cru Kastelberg sélection de grains nobles Pinot gris"}	Alsace grand cru Kastelberg sélection de grains nobles Pinot gris	\N
11502	20	Alsace grand cru Kastelberg	AOC -	AOP -	{"fra": "Alsace grand cru Kastelberg sélection de grains nobles Riesling"}	Alsace grand cru Kastelberg sélection de grains nobles Riesling	\N
11503	20	Alsace grand cru Kastelberg	AOC -	AOP -	{"fra": "Alsace grand cru Kastelberg vendanges tardives Gewurztraminer"}	Alsace grand cru Kastelberg vendanges tardives Gewurztraminer	\N
11504	20	Alsace grand cru Kastelberg	AOC -	AOP -	{"fra": "Alsace grand cru Kastelberg vendanges tardives Muscat"}	Alsace grand cru Kastelberg vendanges tardives Muscat	\N
11505	20	Alsace grand cru Kastelberg	AOC -	AOP -	{"fra": "Alsace grand cru Kastelberg vendanges tardives Pinot gris"}	Alsace grand cru Kastelberg vendanges tardives Pinot gris	\N
11506	20	Alsace grand cru Kastelberg	AOC -	AOP -	{"fra": "Alsace grand cru Kastelberg vendanges tardives Riesling"}	Alsace grand cru Kastelberg vendanges tardives Riesling	\N
11507	20	Alsace grand cru Kastelberg	AOC -	AOP -	{"fra": "Alsace grand cru Kastelberg vendanges tardives Muscat Ottonel"}	Alsace grand cru Kastelberg vendanges tardives Muscat Ottonel	\N
11508	20	Alsace grand cru Kastelberg	AOC -	AOP -	{"fra": "Alsace grand cru Kastelberg Muscat Ottonel"}	Alsace grand cru Kastelberg Muscat Ottonel	\N
11509	20	Alsace grand cru Kastelberg	AOC -	AOP -	{"fra": "Alsace grand cru Kastelberg sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Kastelberg sélection de grains nobles Muscat Ottonel	\N
11510	20	Alsace grand cru Kastelberg	AOC -	AOP -	{"fra": "Alsace grand cru Kastelberg Muscat"}	Alsace grand cru Kastelberg Muscat	\N
11511	21	Alsace grand cru Kessler	AOC -	AOP -	{"fra": "Alsace grand cru Kessler Gewurztraminer"}	Alsace grand cru Kessler Gewurztraminer	\N
11512	21	Alsace grand cru Kessler	AOC -	AOP -	{"fra": "Alsace grand cru Kessler Muscat"}	Alsace grand cru Kessler Muscat	\N
11513	21	Alsace grand cru Kessler	AOC -	AOP -	{"fra": "Alsace grand cru Kessler Muscat Ottonel"}	Alsace grand cru Kessler Muscat Ottonel	\N
11514	21	Alsace grand cru Kessler	AOC -	AOP -	{"fra": "Alsace grand cru Kessler Pinot gris"}	Alsace grand cru Kessler Pinot gris	\N
11515	21	Alsace grand cru Kessler	AOC -	AOP -	{"fra": "Alsace grand cru Kessler Riesling"}	Alsace grand cru Kessler Riesling	\N
11516	21	Alsace grand cru Kessler	AOC -	AOP -	{"fra": "Alsace grand cru Kessler sélection de grains nobles Gewurztraminer"}	Alsace grand cru Kessler sélection de grains nobles Gewurztraminer	\N
11517	21	Alsace grand cru Kessler	AOC -	AOP -	{"fra": "Alsace grand cru Kessler sélection de grains nobles Muscat"}	Alsace grand cru Kessler sélection de grains nobles Muscat	\N
11518	21	Alsace grand cru Kessler	AOC -	AOP -	{"fra": "Alsace grand cru Kessler sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Kessler sélection de grains nobles Muscat Ottonel	\N
11519	21	Alsace grand cru Kessler	AOC -	AOP -	{"fra": "Alsace grand cru Kessler sélection de grains nobles Pinot gris"}	Alsace grand cru Kessler sélection de grains nobles Pinot gris	\N
11520	21	Alsace grand cru Kessler	AOC -	AOP -	{"fra": "Alsace grand cru Kessler sélection de grains nobles Riesling"}	Alsace grand cru Kessler sélection de grains nobles Riesling	\N
11521	21	Alsace grand cru Kessler	AOC -	AOP -	{"fra": "Alsace grand cru Kessler vendanges tardives Gewurztraminer"}	Alsace grand cru Kessler vendanges tardives Gewurztraminer	\N
11522	21	Alsace grand cru Kessler	AOC -	AOP -	{"fra": "Alsace grand cru Kessler vendanges tardives Muscat"}	Alsace grand cru Kessler vendanges tardives Muscat	\N
11523	21	Alsace grand cru Kessler	AOC -	AOP -	{"fra": "Alsace grand cru Kessler vendanges tardives Muscat Ottonel"}	Alsace grand cru Kessler vendanges tardives Muscat Ottonel	\N
11524	21	Alsace grand cru Kessler	AOC -	AOP -	{"fra": "Alsace grand cru Kessler vendanges tardives Pinot gris"}	Alsace grand cru Kessler vendanges tardives Pinot gris	\N
11525	21	Alsace grand cru Kessler	AOC -	AOP -	{"fra": "Alsace grand cru Kessler vendanges tardives Riesling"}	Alsace grand cru Kessler vendanges tardives Riesling	\N
11526	22	Alsace grand cru Kirchberg de Barr	AOC -	AOP -	{"fra": "Alsace grand cru Kirchberg de Barr Gewurztraminer"}	Alsace grand cru Kirchberg de Barr Gewurztraminer	\N
11527	22	Alsace grand cru Kirchberg de Barr	AOC -	AOP -	{"fra": "Alsace grand cru Kirchberg de Barr Muscat"}	Alsace grand cru Kirchberg de Barr Muscat	\N
11604	25	Alsace grand cru Mambourg	AOC -	AOP -	{"fra": "Alsace grand cru Mambourg vendanges tardives Pinot gris"}	Alsace grand cru Mambourg vendanges tardives Pinot gris	\N
11528	22	Alsace grand cru Kirchberg de Barr	AOC -	AOP -	{"fra": "Alsace grand cru Kirchberg de Barr Muscat Ottonel"}	Alsace grand cru Kirchberg de Barr Muscat Ottonel	\N
11529	22	Alsace grand cru Kirchberg de Barr	AOC -	AOP -	{"fra": "Alsace grand cru Kirchberg de Barr Pinot gris"}	Alsace grand cru Kirchberg de Barr Pinot gris	\N
11530	22	Alsace grand cru Kirchberg de Barr	AOC -	AOP -	{"fra": "Alsace grand cru Kirchberg de Barr Riesling"}	Alsace grand cru Kirchberg de Barr Riesling	\N
11531	22	Alsace grand cru Kirchberg de Barr	AOC -	AOP -	{"fra": "Alsace grand cru Kirchberg de Barr sélection de grains nobles Gewurztraminer"}	Alsace grand cru Kirchberg de Barr sélection de grains nobles Gewurztraminer	\N
11532	22	Alsace grand cru Kirchberg de Barr	AOC -	AOP -	{"fra": "Alsace grand cru Kirchberg de Barr sélection de grains nobles Muscat"}	Alsace grand cru Kirchberg de Barr sélection de grains nobles Muscat	\N
11533	22	Alsace grand cru Kirchberg de Barr	AOC -	AOP -	{"fra": "Alsace grand cru Kirchberg de Barr sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Kirchberg de Barr sélection de grains nobles Muscat Ottonel	\N
11534	22	Alsace grand cru Kirchberg de Barr	AOC -	AOP -	{"fra": "Alsace grand cru Kirchberg de Barr sélection de grains nobles Pinot gris"}	Alsace grand cru Kirchberg de Barr sélection de grains nobles Pinot gris	\N
11535	22	Alsace grand cru Kirchberg de Barr	AOC -	AOP -	{"fra": "Alsace grand cru Kirchberg de Barr sélection de grains nobles Riesling"}	Alsace grand cru Kirchberg de Barr sélection de grains nobles Riesling	\N
11536	22	Alsace grand cru Kirchberg de Barr	AOC -	AOP -	{"fra": "Alsace grand cru Kirchberg de Barr vendanges tardives Gewurztraminer"}	Alsace grand cru Kirchberg de Barr vendanges tardives Gewurztraminer	\N
11537	22	Alsace grand cru Kirchberg de Barr	AOC -	AOP -	{"fra": "Alsace grand cru Kirchberg de Barr vendanges tardives Muscat"}	Alsace grand cru Kirchberg de Barr vendanges tardives Muscat	\N
11538	22	Alsace grand cru Kirchberg de Barr	AOC -	AOP -	{"fra": "Alsace grand cru Kirchberg de Barr vendanges tardives Muscat Ottonel"}	Alsace grand cru Kirchberg de Barr vendanges tardives Muscat Ottonel	\N
11539	22	Alsace grand cru Kirchberg de Barr	AOC -	AOP -	{"fra": "Alsace grand cru Kirchberg de Barr vendanges tardives Pinot gris"}	Alsace grand cru Kirchberg de Barr vendanges tardives Pinot gris	\N
11540	22	Alsace grand cru Kirchberg de Barr	AOC -	AOP -	{"fra": "Alsace grand cru Kirchberg de Barr vendanges tardives Riesling"}	Alsace grand cru Kirchberg de Barr vendanges tardives Riesling	\N
11541	23	Alsace grand cru Kirchberg de Ribeauvillé	AOC -	AOP -	{"fra": "Alsace grand cru Kirchberg de Ribeauvillé Gewurztraminer"}	Alsace grand cru Kirchberg de Ribeauvillé Gewurztraminer	\N
11542	23	Alsace grand cru Kirchberg de Ribeauvillé	AOC -	AOP -	{"fra": "Alsace grand cru Kirchberg de Ribeauvillé Muscat"}	Alsace grand cru Kirchberg de Ribeauvillé Muscat	\N
11543	23	Alsace grand cru Kirchberg de Ribeauvillé	AOC -	AOP -	{"fra": "Alsace grand cru Kirchberg de Ribeauvillé Muscat Ottonel"}	Alsace grand cru Kirchberg de Ribeauvillé Muscat Ottonel	\N
11544	23	Alsace grand cru Kirchberg de Ribeauvillé	AOC -	AOP -	{"fra": "Alsace grand cru Kirchberg de Ribeauvillé Pinot gris"}	Alsace grand cru Kirchberg de Ribeauvillé Pinot gris	\N
11545	23	Alsace grand cru Kirchberg de Ribeauvillé	AOC -	AOP -	{"fra": "Alsace grand cru Kirchberg de Ribeauvillé Riesling"}	Alsace grand cru Kirchberg de Ribeauvillé Riesling	\N
11546	23	Alsace grand cru Kirchberg de Ribeauvillé	AOC -	AOP -	{"fra": "Alsace grand cru Kirchberg de Ribeauvillé sélection de grains nobles Gewurztraminer"}	Alsace grand cru Kirchberg de Ribeauvillé sélection de grains nobles Gewurztraminer	\N
11547	23	Alsace grand cru Kirchberg de Ribeauvillé	AOC -	AOP -	{"fra": "Alsace grand cru Kirchberg de Ribeauvillé sélection de grains nobles Muscat"}	Alsace grand cru Kirchberg de Ribeauvillé sélection de grains nobles Muscat	\N
11548	23	Alsace grand cru Kirchberg de Ribeauvillé	AOC -	AOP -	{"fra": "Alsace grand cru Kirchberg de Ribeauvillé sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Kirchberg de Ribeauvillé sélection de grains nobles Muscat Ottonel	\N
11549	23	Alsace grand cru Kirchberg de Ribeauvillé	AOC -	AOP -	{"fra": "Alsace grand cru Kirchberg de Ribeauvillé sélection de grains nobles Pinot gris"}	Alsace grand cru Kirchberg de Ribeauvillé sélection de grains nobles Pinot gris	\N
11550	23	Alsace grand cru Kirchberg de Ribeauvillé	AOC -	AOP -	{"fra": "Alsace grand cru Kirchberg de Ribeauvillé sélection de grains nobles Riesling"}	Alsace grand cru Kirchberg de Ribeauvillé sélection de grains nobles Riesling	\N
11551	23	Alsace grand cru Kirchberg de Ribeauvillé	AOC -	AOP -	{"fra": "Alsace grand cru Kirchberg de Ribeauvillé vendanges tardives Gewurztraminer"}	Alsace grand cru Kirchberg de Ribeauvillé vendanges tardives Gewurztraminer	\N
11552	23	Alsace grand cru Kirchberg de Ribeauvillé	AOC -	AOP -	{"fra": "Alsace grand cru Kirchberg de Ribeauvillé vendanges tardives Muscat"}	Alsace grand cru Kirchberg de Ribeauvillé vendanges tardives Muscat	\N
11553	23	Alsace grand cru Kirchberg de Ribeauvillé	AOC -	AOP -	{"fra": "Alsace grand cru Kirchberg de Ribeauvillé vendanges tardives Muscat Ottonel"}	Alsace grand cru Kirchberg de Ribeauvillé vendanges tardives Muscat Ottonel	\N
11554	23	Alsace grand cru Kirchberg de Ribeauvillé	AOC -	AOP -	{"fra": "Alsace grand cru Kirchberg de Ribeauvillé vendanges tardives Pinot gris"}	Alsace grand cru Kirchberg de Ribeauvillé vendanges tardives Pinot gris	\N
11555	23	Alsace grand cru Kirchberg de Ribeauvillé	AOC -	AOP -	{"fra": "Alsace grand cru Kirchberg de Ribeauvillé vendanges tardives Riesling"}	Alsace grand cru Kirchberg de Ribeauvillé vendanges tardives Riesling	\N
11566	24	Alsace grand cru Kitterlé	AOC -	AOP -	{"fra": "Alsace grand cru Kitterlé Gewurztraminer"}	Alsace grand cru Kitterlé Gewurztraminer	\N
11567	24	Alsace grand cru Kitterlé	AOC -	AOP -	{"fra": "Alsace grand cru Kitterlé Muscat"}	Alsace grand cru Kitterlé Muscat	\N
11568	24	Alsace grand cru Kitterlé	AOC -	AOP -	{"fra": "Alsace grand cru Kitterlé Pinot gris"}	Alsace grand cru Kitterlé Pinot gris	\N
11569	24	Alsace grand cru Kitterlé	AOC -	AOP -	{"fra": "Alsace grand cru Kitterlé Muscat Ottonel"}	Alsace grand cru Kitterlé Muscat Ottonel	\N
11580	24	Alsace grand cru Kitterlé	AOC -	AOP -	{"fra": "Alsace grand cru Kitterlé Riesling"}	Alsace grand cru Kitterlé Riesling	\N
10360	1980	Ariège	\N	IGP -	{"fra": "Ariège primeur ou nouveau blanc"}	Ariège primeur ou nouveau blanc	\N
11581	24	Alsace grand cru Kitterlé	AOC -	AOP -	{"fra": "Alsace grand cru Kitterlé sélection de grains nobles Gewurztraminer"}	Alsace grand cru Kitterlé sélection de grains nobles Gewurztraminer	\N
11582	24	Alsace grand cru Kitterlé	AOC -	AOP -	{"fra": "Alsace grand cru Kitterlé sélection de grains nobles Muscat"}	Alsace grand cru Kitterlé sélection de grains nobles Muscat	\N
11583	24	Alsace grand cru Kitterlé	AOC -	AOP -	{"fra": "Alsace grand cru Kitterlé sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Kitterlé sélection de grains nobles Muscat Ottonel	\N
11584	24	Alsace grand cru Kitterlé	AOC -	AOP -	{"fra": "Alsace grand cru Kitterlé sélection de grains nobles Pinot gris"}	Alsace grand cru Kitterlé sélection de grains nobles Pinot gris	\N
11585	24	Alsace grand cru Kitterlé	AOC -	AOP -	{"fra": "Alsace grand cru Kitterlé sélection de grains nobles Riesling"}	Alsace grand cru Kitterlé sélection de grains nobles Riesling	\N
11586	24	Alsace grand cru Kitterlé	AOC -	AOP -	{"fra": "Alsace grand cru Kitterlé vendanges tardives Gewurztraminer"}	Alsace grand cru Kitterlé vendanges tardives Gewurztraminer	\N
11587	24	Alsace grand cru Kitterlé	AOC -	AOP -	{"fra": "Alsace grand cru Kitterlé vendanges tardives Muscat"}	Alsace grand cru Kitterlé vendanges tardives Muscat	\N
11588	24	Alsace grand cru Kitterlé	AOC -	AOP -	{"fra": "Alsace grand cru Kitterlé vendanges tardives Muscat Ottonel"}	Alsace grand cru Kitterlé vendanges tardives Muscat Ottonel	\N
11589	24	Alsace grand cru Kitterlé	AOC -	AOP -	{"fra": "Alsace grand cru Kitterlé vendanges tardives Pinot gris"}	Alsace grand cru Kitterlé vendanges tardives Pinot gris	\N
11590	24	Alsace grand cru Kitterlé	AOC -	AOP -	{"fra": "Alsace grand cru Kitterlé vendanges tardives Riesling"}	Alsace grand cru Kitterlé vendanges tardives Riesling	\N
11591	25	Alsace grand cru Mambourg	AOC -	AOP -	{"fra": "Alsace grand cru Mambourg Gewurztraminer"}	Alsace grand cru Mambourg Gewurztraminer	\N
11592	25	Alsace grand cru Mambourg	AOC -	AOP -	{"fra": "Alsace grand cru Mambourg Muscat"}	Alsace grand cru Mambourg Muscat	\N
11593	25	Alsace grand cru Mambourg	AOC -	AOP -	{"fra": "Alsace grand cru Mambourg Muscat Ottonel"}	Alsace grand cru Mambourg Muscat Ottonel	\N
11594	25	Alsace grand cru Mambourg	AOC -	AOP -	{"fra": "Alsace grand cru Mambourg Pinot gris"}	Alsace grand cru Mambourg Pinot gris	\N
11595	25	Alsace grand cru Mambourg	AOC -	AOP -	{"fra": "Alsace grand cru Mambourg Riesling"}	Alsace grand cru Mambourg Riesling	\N
11596	25	Alsace grand cru Mambourg	AOC -	AOP -	{"fra": "Alsace grand cru Mambourg sélection de grains nobles Gewurztraminer"}	Alsace grand cru Mambourg sélection de grains nobles Gewurztraminer	\N
11597	25	Alsace grand cru Mambourg	AOC -	AOP -	{"fra": "Alsace grand cru Mambourg sélection de grains nobles Muscat"}	Alsace grand cru Mambourg sélection de grains nobles Muscat	\N
11598	25	Alsace grand cru Mambourg	AOC -	AOP -	{"fra": "Alsace grand cru Mambourg sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Mambourg sélection de grains nobles Muscat Ottonel	\N
11599	25	Alsace grand cru Mambourg	AOC -	AOP -	{"fra": "Alsace grand cru Mambourg sélection de grains nobles Pinot gris"}	Alsace grand cru Mambourg sélection de grains nobles Pinot gris	\N
11600	25	Alsace grand cru Mambourg	AOC -	AOP -	{"fra": "Alsace grand cru Mambourg sélection de grains nobles Riesling"}	Alsace grand cru Mambourg sélection de grains nobles Riesling	\N
11601	25	Alsace grand cru Mambourg	AOC -	AOP -	{"fra": "Alsace grand cru Mambourg vendanges tardives Gewurztraminer"}	Alsace grand cru Mambourg vendanges tardives Gewurztraminer	\N
11602	25	Alsace grand cru Mambourg	AOC -	AOP -	{"fra": "Alsace grand cru Mambourg vendanges tardives Muscat"}	Alsace grand cru Mambourg vendanges tardives Muscat	\N
11603	25	Alsace grand cru Mambourg	AOC -	AOP -	{"fra": "Alsace grand cru Mambourg vendanges tardives Muscat Ottonel"}	Alsace grand cru Mambourg vendanges tardives Muscat Ottonel	\N
11605	25	Alsace grand cru Mambourg	AOC -	AOP -	{"fra": "Alsace grand cru Mambourg vendanges tardives Riesling"}	Alsace grand cru Mambourg vendanges tardives Riesling	\N
301	26	Alsace grand cru Mandelberg 	AOC -	AOP -	{"fra": "Alsace grand cru Mandelberg Muscat"}	Alsace grand cru Mandelberg Muscat	\N
11606	26	Alsace grand cru Mandelberg 	AOC -	AOP -	{"fra": "Alsace grand cru Mandelberg Gewurztraminer"}	Alsace grand cru Mandelberg Gewurztraminer	\N
11607	26	Alsace grand cru Mandelberg 	AOC -	AOP -	{"fra": "Alsace grand cru Mandelberg sélection de grains nobles Muscat"}	Alsace grand cru Mandelberg sélection de grains nobles Muscat	\N
11608	26	Alsace grand cru Mandelberg 	AOC -	AOP -	{"fra": "Alsace grand cru Mandelberg Muscat Ottonel"}	Alsace grand cru Mandelberg Muscat Ottonel	\N
11609	26	Alsace grand cru Mandelberg 	AOC -	AOP -	{"fra": "Alsace grand cru Mandelberg Pinot gris"}	Alsace grand cru Mandelberg Pinot gris	\N
11610	26	Alsace grand cru Mandelberg 	AOC -	AOP -	{"fra": "Alsace grand cru Mandelberg Riesling"}	Alsace grand cru Mandelberg Riesling	\N
11611	26	Alsace grand cru Mandelberg 	AOC -	AOP -	{"fra": "Alsace grand cru Mandelberg sélection de grains nobles Gewurztraminer"}	Alsace grand cru Mandelberg sélection de grains nobles Gewurztraminer	\N
11612	26	Alsace grand cru Mandelberg 	AOC -	AOP -	{"fra": "Alsace grand cru Mandelberg vendanges tardives Muscat"}	Alsace grand cru Mandelberg vendanges tardives Muscat	\N
11613	26	Alsace grand cru Mandelberg 	AOC -	AOP -	{"fra": "Alsace grand cru Mandelberg sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Mandelberg sélection de grains nobles Muscat Ottonel	\N
11614	26	Alsace grand cru Mandelberg 	AOC -	AOP -	{"fra": "Alsace grand cru Mandelberg sélection de grains nobles Pinot gris"}	Alsace grand cru Mandelberg sélection de grains nobles Pinot gris	\N
11615	26	Alsace grand cru Mandelberg 	AOC -	AOP -	{"fra": "Alsace grand cru Mandelberg sélection de grains nobles Riesling"}	Alsace grand cru Mandelberg sélection de grains nobles Riesling	\N
11616	26	Alsace grand cru Mandelberg 	AOC -	AOP -	{"fra": "Alsace grand cru Mandelberg vendanges tardives Gewurztraminer"}	Alsace grand cru Mandelberg vendanges tardives Gewurztraminer	\N
11617	26	Alsace grand cru Mandelberg 	AOC -	AOP -	{"fra": "Alsace grand cru Mandelberg vendanges tardives Muscat Ottonel"}	Alsace grand cru Mandelberg vendanges tardives Muscat Ottonel	\N
11618	26	Alsace grand cru Mandelberg 	AOC -	AOP -	{"fra": "Alsace grand cru Mandelberg vendanges tardives Pinot gris"}	Alsace grand cru Mandelberg vendanges tardives Pinot gris	\N
11619	26	Alsace grand cru Mandelberg 	AOC -	AOP -	{"fra": "Alsace grand cru Mandelberg vendanges tardives Riesling"}	Alsace grand cru Mandelberg vendanges tardives Riesling	\N
10361	1980	Ariège	\N	IGP -	{"fra": "Ariège primeur ou nouveau rosé"}	Ariège primeur ou nouveau rosé	\N
11620	27	Alsace grand cru Marckrain	AOC -	AOP -	{"fra": "Alsace grand cru Marckrain Gewurztraminer"}	Alsace grand cru Marckrain Gewurztraminer	\N
11621	27	Alsace grand cru Marckrain	AOC -	AOP -	{"fra": "Alsace grand cru Marckrain Muscat"}	Alsace grand cru Marckrain Muscat	\N
11622	27	Alsace grand cru Marckrain	AOC -	AOP -	{"fra": "Alsace grand cru Marckrain Muscat Ottonel"}	Alsace grand cru Marckrain Muscat Ottonel	\N
11623	27	Alsace grand cru Marckrain	AOC -	AOP -	{"fra": "Alsace grand cru Marckrain Pinot gris"}	Alsace grand cru Marckrain Pinot gris	\N
11624	27	Alsace grand cru Marckrain	AOC -	AOP -	{"fra": "Alsace grand cru Marckrain sélection de grains nobles Gewurztraminer"}	Alsace grand cru Marckrain sélection de grains nobles Gewurztraminer	\N
11625	27	Alsace grand cru Marckrain	AOC -	AOP -	{"fra": "Alsace grand cru Marckrain sélection de grains nobles Muscat"}	Alsace grand cru Marckrain sélection de grains nobles Muscat	\N
11626	27	Alsace grand cru Marckrain	AOC -	AOP -	{"fra": "Alsace grand cru Marckrain sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Marckrain sélection de grains nobles Muscat Ottonel	\N
11627	27	Alsace grand cru Marckrain	AOC -	AOP -	{"fra": "Alsace grand cru Marckrain sélection de grains nobles Pinot gris"}	Alsace grand cru Marckrain sélection de grains nobles Pinot gris	\N
11628	27	Alsace grand cru Marckrain	AOC -	AOP -	{"fra": "Alsace grand cru Marckrain sélection de grains nobles Riesling"}	Alsace grand cru Marckrain sélection de grains nobles Riesling	\N
11629	27	Alsace grand cru Marckrain	AOC -	AOP -	{"fra": "Alsace grand cru Marckrain Riesling"}	Alsace grand cru Marckrain Riesling	\N
11630	27	Alsace grand cru Marckrain	AOC -	AOP -	{"fra": "Alsace grand cru Marckrain vendanges tardives Gewurztraminer"}	Alsace grand cru Marckrain vendanges tardives Gewurztraminer	\N
11631	27	Alsace grand cru Marckrain	AOC -	AOP -	{"fra": "Alsace grand cru Marckrain vendanges tardives Muscat"}	Alsace grand cru Marckrain vendanges tardives Muscat	\N
11632	27	Alsace grand cru Marckrain	AOC -	AOP -	{"fra": "Alsace grand cru Marckrain vendanges tardives Muscat Ottonel"}	Alsace grand cru Marckrain vendanges tardives Muscat Ottonel	\N
11633	27	Alsace grand cru Marckrain	AOC -	AOP -	{"fra": "Alsace grand cru Marckrain vendanges tardives Pinot gris"}	Alsace grand cru Marckrain vendanges tardives Pinot gris	\N
11634	27	Alsace grand cru Marckrain	AOC -	AOP -	{"fra": "Alsace grand cru Marckrain vendanges tardives Riesling"}	Alsace grand cru Marckrain vendanges tardives Riesling	\N
11635	28	Alsace grand cru Moenchberg	AOC -	AOP -	{"fra": "Alsace grand cru Moenchberg Gewurztraminer"}	Alsace grand cru Moenchberg Gewurztraminer	\N
11636	28	Alsace grand cru Moenchberg	AOC -	AOP -	{"fra": "Alsace grand cru Moenchberg Muscat"}	Alsace grand cru Moenchberg Muscat	\N
11637	28	Alsace grand cru Moenchberg	AOC -	AOP -	{"fra": "Alsace grand cru Moenchberg Muscat Ottonel"}	Alsace grand cru Moenchberg Muscat Ottonel	\N
11638	28	Alsace grand cru Moenchberg	AOC -	AOP -	{"fra": "Alsace grand cru Moenchberg Pinot gris"}	Alsace grand cru Moenchberg Pinot gris	\N
11639	28	Alsace grand cru Moenchberg	AOC -	AOP -	{"fra": "Alsace grand cru Moenchberg Riesling"}	Alsace grand cru Moenchberg Riesling	\N
11640	28	Alsace grand cru Moenchberg	AOC -	AOP -	{"fra": "Alsace grand cru Moenchberg sélection de grains nobles Gewurztraminer"}	Alsace grand cru Moenchberg sélection de grains nobles Gewurztraminer	\N
11641	28	Alsace grand cru Moenchberg	AOC -	AOP -	{"fra": "Alsace grand cru Moenchberg sélection de grains nobles Muscat"}	Alsace grand cru Moenchberg sélection de grains nobles Muscat	\N
11642	28	Alsace grand cru Moenchberg	AOC -	AOP -	{"fra": "Alsace grand cru Moenchberg sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Moenchberg sélection de grains nobles Muscat Ottonel	\N
11643	28	Alsace grand cru Moenchberg	AOC -	AOP -	{"fra": "Alsace grand cru Moenchberg sélection de grains nobles Pinot gris"}	Alsace grand cru Moenchberg sélection de grains nobles Pinot gris	\N
11644	28	Alsace grand cru Moenchberg	AOC -	AOP -	{"fra": "Alsace grand cru Moenchberg sélection de grains nobles Riesling"}	Alsace grand cru Moenchberg sélection de grains nobles Riesling	\N
11645	28	Alsace grand cru Moenchberg	AOC -	AOP -	{"fra": "Alsace grand cru Moenchberg vendanges tardives Gewurztraminer"}	Alsace grand cru Moenchberg vendanges tardives Gewurztraminer	\N
11646	28	Alsace grand cru Moenchberg	AOC -	AOP -	{"fra": "Alsace grand cru Moenchberg vendanges tardives Muscat"}	Alsace grand cru Moenchberg vendanges tardives Muscat	\N
11647	28	Alsace grand cru Moenchberg	AOC -	AOP -	{"fra": "Alsace grand cru Moenchberg vendanges tardives Muscat Ottonel"}	Alsace grand cru Moenchberg vendanges tardives Muscat Ottonel	\N
11648	28	Alsace grand cru Moenchberg	AOC -	AOP -	{"fra": "Alsace grand cru Moenchberg vendanges tardives Pinot gris"}	Alsace grand cru Moenchberg vendanges tardives Pinot gris	\N
11649	28	Alsace grand cru Moenchberg	AOC -	AOP -	{"fra": "Alsace grand cru Moenchberg vendanges tardives Riesling"}	Alsace grand cru Moenchberg vendanges tardives Riesling	\N
11650	29	Alsace grand cru Muenchberg	AOC -	AOP -	{"fra": "Alsace grand cru Muenchberg Gewurztraminer"}	Alsace grand cru Muenchberg Gewurztraminer	\N
11651	29	Alsace grand cru Muenchberg	AOC -	AOP -	{"fra": "Alsace grand cru Muenchberg Muscat"}	Alsace grand cru Muenchberg Muscat	\N
11652	29	Alsace grand cru Muenchberg	AOC -	AOP -	{"fra": "Alsace grand cru Muenchberg Muscat Ottonel"}	Alsace grand cru Muenchberg Muscat Ottonel	\N
11653	29	Alsace grand cru Muenchberg	AOC -	AOP -	{"fra": "Alsace grand cru Muenchberg Pinot gris"}	Alsace grand cru Muenchberg Pinot gris	\N
11654	29	Alsace grand cru Muenchberg	AOC -	AOP -	{"fra": "Alsace grand cru Muenchberg Riesling"}	Alsace grand cru Muenchberg Riesling	\N
11655	29	Alsace grand cru Muenchberg	AOC -	AOP -	{"fra": "Alsace grand cru Muenchberg sélection de grains nobles Gewurztraminer"}	Alsace grand cru Muenchberg sélection de grains nobles Gewurztraminer	\N
11656	29	Alsace grand cru Muenchberg	AOC -	AOP -	{"fra": "Alsace grand cru Muenchberg sélection de grains nobles Muscat"}	Alsace grand cru Muenchberg sélection de grains nobles Muscat	\N
11657	29	Alsace grand cru Muenchberg	AOC -	AOP -	{"fra": "Alsace grand cru Muenchberg sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Muenchberg sélection de grains nobles Muscat Ottonel	\N
11658	29	Alsace grand cru Muenchberg	AOC -	AOP -	{"fra": "Alsace grand cru Muenchberg sélection de grains nobles Pinot gris"}	Alsace grand cru Muenchberg sélection de grains nobles Pinot gris	\N
11659	29	Alsace grand cru Muenchberg	AOC -	AOP -	{"fra": "Alsace grand cru Muenchberg sélection de grains nobles Riesling"}	Alsace grand cru Muenchberg sélection de grains nobles Riesling	\N
11660	29	Alsace grand cru Muenchberg	AOC -	AOP -	{"fra": "Alsace grand cru Muenchberg vendanges tardives Gewurztraminer"}	Alsace grand cru Muenchberg vendanges tardives Gewurztraminer	\N
11661	29	Alsace grand cru Muenchberg	AOC -	AOP -	{"fra": "Alsace grand cru Muenchberg vendanges tardives Muscat"}	Alsace grand cru Muenchberg vendanges tardives Muscat	\N
11662	29	Alsace grand cru Muenchberg	AOC -	AOP -	{"fra": "Alsace grand cru Muenchberg vendanges tardives Muscat Ottonel"}	Alsace grand cru Muenchberg vendanges tardives Muscat Ottonel	\N
11663	29	Alsace grand cru Muenchberg	AOC -	AOP -	{"fra": "Alsace grand cru Muenchberg vendanges tardives Pinot gris"}	Alsace grand cru Muenchberg vendanges tardives Pinot gris	\N
15955	2010	Gard	\N	IGP -	{"fra": "Gard rouge"}	Gard rouge	\N
11664	29	Alsace grand cru Muenchberg	AOC -	AOP -	{"fra": "Alsace grand cru Muenchberg vendanges tardives Riesling"}	Alsace grand cru Muenchberg vendanges tardives Riesling	\N
11665	30	Alsace grand cru Ollwiller	AOC -	AOP -	{"fra": "Alsace grand cru Ollwiller Gewurztraminer"}	Alsace grand cru Ollwiller Gewurztraminer	\N
11666	30	Alsace grand cru Ollwiller	AOC -	AOP -	{"fra": "Alsace grand cru Ollwiller Muscat"}	Alsace grand cru Ollwiller Muscat	\N
11667	30	Alsace grand cru Ollwiller	AOC -	AOP -	{"fra": "Alsace grand cru Ollwiller Muscat Ottonel"}	Alsace grand cru Ollwiller Muscat Ottonel	\N
11668	30	Alsace grand cru Ollwiller	AOC -	AOP -	{"fra": "Alsace grand cru Ollwiller Pinot gris"}	Alsace grand cru Ollwiller Pinot gris	\N
11669	30	Alsace grand cru Ollwiller	AOC -	AOP -	{"fra": "Alsace grand cru Ollwiller Riesling"}	Alsace grand cru Ollwiller Riesling	\N
11670	30	Alsace grand cru Ollwiller	AOC -	AOP -	{"fra": "Alsace grand cru Ollwiller vendanges tardives Gewurztraminer"}	Alsace grand cru Ollwiller vendanges tardives Gewurztraminer	\N
11671	30	Alsace grand cru Ollwiller	AOC -	AOP -	{"fra": "Alsace grand cru Ollwiller sélection de grains nobles Gewurztraminer"}	Alsace grand cru Ollwiller sélection de grains nobles Gewurztraminer	\N
11672	30	Alsace grand cru Ollwiller	AOC -	AOP -	{"fra": "Alsace grand cru Ollwiller sélection de grains nobles Muscat"}	Alsace grand cru Ollwiller sélection de grains nobles Muscat	\N
11673	30	Alsace grand cru Ollwiller	AOC -	AOP -	{"fra": "Alsace grand cru Ollwiller sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Ollwiller sélection de grains nobles Muscat Ottonel	\N
11674	30	Alsace grand cru Ollwiller	AOC -	AOP -	{"fra": "Alsace grand cru Ollwiller sélection de grains nobles Pinot gris"}	Alsace grand cru Ollwiller sélection de grains nobles Pinot gris	\N
11675	30	Alsace grand cru Ollwiller	AOC -	AOP -	{"fra": "Alsace grand cru Ollwiller sélection de grains nobles Riesling"}	Alsace grand cru Ollwiller sélection de grains nobles Riesling	\N
11676	30	Alsace grand cru Ollwiller	AOC -	AOP -	{"fra": "Alsace grand cru Ollwiller vendanges tardives Muscat"}	Alsace grand cru Ollwiller vendanges tardives Muscat	\N
11677	30	Alsace grand cru Ollwiller	AOC -	AOP -	{"fra": "Alsace grand cru Ollwiller vendanges tardives Muscat Ottonel"}	Alsace grand cru Ollwiller vendanges tardives Muscat Ottonel	\N
11678	30	Alsace grand cru Ollwiller	AOC -	AOP -	{"fra": "Alsace grand cru Ollwiller vendanges tardives Pinot gris"}	Alsace grand cru Ollwiller vendanges tardives Pinot gris	\N
11679	30	Alsace grand cru Ollwiller	AOC -	AOP -	{"fra": "Alsace grand cru Ollwiller vendanges tardives Riesling"}	Alsace grand cru Ollwiller vendanges tardives Riesling	\N
11680	31	Alsace grand cru Osterberg	AOC -	AOP -	{"fra": "Alsace grand cru Osterberg Gewurztraminer"}	Alsace grand cru Osterberg Gewurztraminer	\N
11681	31	Alsace grand cru Osterberg	AOC -	AOP -	{"fra": "Alsace grand cru Osterberg Muscat"}	Alsace grand cru Osterberg Muscat	\N
11682	31	Alsace grand cru Osterberg	AOC -	AOP -	{"fra": "Alsace grand cru Osterberg Muscat Ottonel"}	Alsace grand cru Osterberg Muscat Ottonel	\N
11684	31	Alsace grand cru Osterberg	AOC -	AOP -	{"fra": "Alsace grand cru Osterberg Pinot gris"}	Alsace grand cru Osterberg Pinot gris	\N
11685	31	Alsace grand cru Osterberg	AOC -	AOP -	{"fra": "Alsace grand cru Osterberg Riesling"}	Alsace grand cru Osterberg Riesling	\N
11686	31	Alsace grand cru Osterberg	AOC -	AOP -	{"fra": "Alsace grand cru Osterberg sélection de grains nobles Gewurztraminer"}	Alsace grand cru Osterberg sélection de grains nobles Gewurztraminer	\N
11687	31	Alsace grand cru Osterberg	AOC -	AOP -	{"fra": "Alsace grand cru Osterberg sélection de grains nobles Muscat"}	Alsace grand cru Osterberg sélection de grains nobles Muscat	\N
11688	31	Alsace grand cru Osterberg	AOC -	AOP -	{"fra": "Alsace grand cru Osterberg sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Osterberg sélection de grains nobles Muscat Ottonel	\N
11689	31	Alsace grand cru Osterberg	AOC -	AOP -	{"fra": "Alsace grand cru Osterberg sélection de grains nobles Pinot gris"}	Alsace grand cru Osterberg sélection de grains nobles Pinot gris	\N
11690	31	Alsace grand cru Osterberg	AOC -	AOP -	{"fra": "Alsace grand cru Osterberg sélection de grains nobles Riesling"}	Alsace grand cru Osterberg sélection de grains nobles Riesling	\N
11691	31	Alsace grand cru Osterberg	AOC -	AOP -	{"fra": "Alsace grand cru Osterberg vendanges tardives Gewurztraminer"}	Alsace grand cru Osterberg vendanges tardives Gewurztraminer	\N
11692	31	Alsace grand cru Osterberg	AOC -	AOP -	{"fra": "Alsace grand cru Osterberg vendanges tardives Muscat"}	Alsace grand cru Osterberg vendanges tardives Muscat	\N
11693	31	Alsace grand cru Osterberg	AOC -	AOP -	{"fra": "Alsace grand cru Osterberg vendanges tardives Muscat Ottonel"}	Alsace grand cru Osterberg vendanges tardives Muscat Ottonel	\N
11694	31	Alsace grand cru Osterberg	AOC -	AOP -	{"fra": "Alsace grand cru Osterberg vendanges tardives Pinot gris"}	Alsace grand cru Osterberg vendanges tardives Pinot gris	\N
11695	31	Alsace grand cru Osterberg	AOC -	AOP -	{"fra": "Alsace grand cru Osterberg vendanges tardives Riesling"}	Alsace grand cru Osterberg vendanges tardives Riesling	\N
11696	32	Alsace grand cru Pfersigberg	AOC -	AOP -	{"fra": "Alsace grand cru Pfersigberg Gewurztraminer"}	Alsace grand cru Pfersigberg Gewurztraminer	\N
11697	32	Alsace grand cru Pfersigberg	AOC -	AOP -	{"fra": "Alsace grand cru Pfersigberg Muscat"}	Alsace grand cru Pfersigberg Muscat	\N
11698	32	Alsace grand cru Pfersigberg	AOC -	AOP -	{"fra": "Alsace grand cru Pfersigberg Muscat Ottonel"}	Alsace grand cru Pfersigberg Muscat Ottonel	\N
11699	32	Alsace grand cru Pfersigberg	AOC -	AOP -	{"fra": "Alsace grand cru Pfersigberg Pinot gris"}	Alsace grand cru Pfersigberg Pinot gris	\N
11700	32	Alsace grand cru Pfersigberg	AOC -	AOP -	{"fra": "Alsace grand cru Pfersigberg Riesling"}	Alsace grand cru Pfersigberg Riesling	\N
11701	32	Alsace grand cru Pfersigberg	AOC -	AOP -	{"fra": "Alsace grand cru Pfersigberg sélection de grains nobles Gewurztraminer"}	Alsace grand cru Pfersigberg sélection de grains nobles Gewurztraminer	\N
11702	32	Alsace grand cru Pfersigberg	AOC -	AOP -	{"fra": "Alsace grand cru Pfersigberg sélection de grains nobles Muscat"}	Alsace grand cru Pfersigberg sélection de grains nobles Muscat	\N
11703	32	Alsace grand cru Pfersigberg	AOC -	AOP -	{"fra": "Alsace grand cru Pfersigberg sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Pfersigberg sélection de grains nobles Muscat Ottonel	\N
11704	32	Alsace grand cru Pfersigberg	AOC -	AOP -	{"fra": "Alsace grand cru Pfersigberg sélection de grains nobles Pinot gris"}	Alsace grand cru Pfersigberg sélection de grains nobles Pinot gris	\N
11705	32	Alsace grand cru Pfersigberg	AOC -	AOP -	{"fra": "Alsace grand cru Pfersigberg sélection de grains nobles Riesling"}	Alsace grand cru Pfersigberg sélection de grains nobles Riesling	\N
11706	32	Alsace grand cru Pfersigberg	AOC -	AOP -	{"fra": "Alsace grand cru Pfersigberg vendanges tardives Gewurztraminer"}	Alsace grand cru Pfersigberg vendanges tardives Gewurztraminer	\N
11707	32	Alsace grand cru Pfersigberg	AOC -	AOP -	{"fra": "Alsace grand cru Pfersigberg vendanges tardives Muscat"}	Alsace grand cru Pfersigberg vendanges tardives Muscat	\N
11708	32	Alsace grand cru Pfersigberg	AOC -	AOP -	{"fra": "Alsace grand cru Pfersigberg vendanges tardives Muscat Ottonel"}	Alsace grand cru Pfersigberg vendanges tardives Muscat Ottonel	\N
11709	32	Alsace grand cru Pfersigberg	AOC -	AOP -	{"fra": "Alsace grand cru Pfersigberg vendanges tardives Pinot gris"}	Alsace grand cru Pfersigberg vendanges tardives Pinot gris	\N
11710	32	Alsace grand cru Pfersigberg	AOC -	AOP -	{"fra": "Alsace grand cru Pfersigberg vendanges tardives Riesling"}	Alsace grand cru Pfersigberg vendanges tardives Riesling	\N
11711	33	Alsace grand cru Pfingstberg	AOC -	AOP -	{"fra": "Alsace grand cru Pfingstberg Gewurztraminer"}	Alsace grand cru Pfingstberg Gewurztraminer	\N
11712	33	Alsace grand cru Pfingstberg	AOC -	AOP -	{"fra": "Alsace grand cru Pfingstberg Muscat"}	Alsace grand cru Pfingstberg Muscat	\N
11713	33	Alsace grand cru Pfingstberg	AOC -	AOP -	{"fra": "Alsace grand cru Pfingstberg Muscat Ottonel"}	Alsace grand cru Pfingstberg Muscat Ottonel	\N
11714	33	Alsace grand cru Pfingstberg	AOC -	AOP -	{"fra": "Alsace grand cru Pfingstberg Pinot gris"}	Alsace grand cru Pfingstberg Pinot gris	\N
11715	33	Alsace grand cru Pfingstberg	AOC -	AOP -	{"fra": "Alsace grand cru Pfingstberg Riesling"}	Alsace grand cru Pfingstberg Riesling	\N
11716	33	Alsace grand cru Pfingstberg	AOC -	AOP -	{"fra": "Alsace grand cru Pfingstberg sélection de grains nobles Gewurztraminer"}	Alsace grand cru Pfingstberg sélection de grains nobles Gewurztraminer	\N
11717	33	Alsace grand cru Pfingstberg	AOC -	AOP -	{"fra": "Alsace grand cru Pfingstberg sélection de grains nobles Muscat"}	Alsace grand cru Pfingstberg sélection de grains nobles Muscat	\N
11718	33	Alsace grand cru Pfingstberg	AOC -	AOP -	{"fra": "Alsace grand cru Pfingstberg sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Pfingstberg sélection de grains nobles Muscat Ottonel	\N
11719	33	Alsace grand cru Pfingstberg	AOC -	AOP -	{"fra": "Alsace grand cru Pfingstberg sélection de grains nobles Pinot gris"}	Alsace grand cru Pfingstberg sélection de grains nobles Pinot gris	\N
11720	33	Alsace grand cru Pfingstberg	AOC -	AOP -	{"fra": "Alsace grand cru Pfingstberg sélection de grains nobles Riesling"}	Alsace grand cru Pfingstberg sélection de grains nobles Riesling	\N
11721	33	Alsace grand cru Pfingstberg	AOC -	AOP -	{"fra": "Alsace grand cru Pfingstberg vendanges tardives Gewurztraminer"}	Alsace grand cru Pfingstberg vendanges tardives Gewurztraminer	\N
11722	33	Alsace grand cru Pfingstberg	AOC -	AOP -	{"fra": "Alsace grand cru Pfingstberg vendanges tardives Muscat"}	Alsace grand cru Pfingstberg vendanges tardives Muscat	\N
11723	33	Alsace grand cru Pfingstberg	AOC -	AOP -	{"fra": "Alsace grand cru Pfingstberg vendanges tardives Pinot gris"}	Alsace grand cru Pfingstberg vendanges tardives Pinot gris	\N
11724	33	Alsace grand cru Pfingstberg	AOC -	AOP -	{"fra": "Alsace grand cru Pfingstberg vendanges tardives Muscat Ottonel"}	Alsace grand cru Pfingstberg vendanges tardives Muscat Ottonel	\N
11725	33	Alsace grand cru Pfingstberg	AOC -	AOP -	{"fra": "Alsace grand cru Pfingstberg vendanges tardives Riesling"}	Alsace grand cru Pfingstberg vendanges tardives Riesling	\N
11726	34	Alsace grand cru Praelatenberg	AOC -	AOP -	{"fra": "Alsace grand cru Praelatenberg Gewurztraminer"}	Alsace grand cru Praelatenberg Gewurztraminer	\N
11727	34	Alsace grand cru Praelatenberg	AOC -	AOP -	{"fra": "Alsace grand cru Praelatenberg Muscat"}	Alsace grand cru Praelatenberg Muscat	\N
11728	34	Alsace grand cru Praelatenberg	AOC -	AOP -	{"fra": "Alsace grand cru Praelatenberg Muscat Ottonel"}	Alsace grand cru Praelatenberg Muscat Ottonel	\N
11729	34	Alsace grand cru Praelatenberg	AOC -	AOP -	{"fra": "Alsace grand cru Praelatenberg Pinot gris"}	Alsace grand cru Praelatenberg Pinot gris	\N
11730	34	Alsace grand cru Praelatenberg	AOC -	AOP -	{"fra": "Alsace grand cru Praelatenberg Riesling"}	Alsace grand cru Praelatenberg Riesling	\N
11731	34	Alsace grand cru Praelatenberg	AOC -	AOP -	{"fra": "Alsace grand cru Praelatenberg sélection de grains nobles Gewurztraminer"}	Alsace grand cru Praelatenberg sélection de grains nobles Gewurztraminer	\N
11732	34	Alsace grand cru Praelatenberg	AOC -	AOP -	{"fra": "Alsace grand cru Praelatenberg sélection de grains nobles Muscat"}	Alsace grand cru Praelatenberg sélection de grains nobles Muscat	\N
11733	34	Alsace grand cru Praelatenberg	AOC -	AOP -	{"fra": "Alsace grand cru Praelatenberg sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Praelatenberg sélection de grains nobles Muscat Ottonel	\N
11734	34	Alsace grand cru Praelatenberg	AOC -	AOP -	{"fra": "Alsace grand cru Praelatenberg sélection de grains nobles Pinot gris"}	Alsace grand cru Praelatenberg sélection de grains nobles Pinot gris	\N
11735	34	Alsace grand cru Praelatenberg	AOC -	AOP -	{"fra": "Alsace grand cru Praelatenberg sélection de grains nobles Riesling"}	Alsace grand cru Praelatenberg sélection de grains nobles Riesling	\N
11736	34	Alsace grand cru Praelatenberg	AOC -	AOP -	{"fra": "Alsace grand cru Praelatenberg vendanges tardives Gewurztraminer"}	Alsace grand cru Praelatenberg vendanges tardives Gewurztraminer	\N
11737	34	Alsace grand cru Praelatenberg	AOC -	AOP -	{"fra": "Alsace grand cru Praelatenberg vendanges tardives Muscat"}	Alsace grand cru Praelatenberg vendanges tardives Muscat	\N
11738	34	Alsace grand cru Praelatenberg	AOC -	AOP -	{"fra": "Alsace grand cru Praelatenberg vendanges tardives Muscat Ottonel"}	Alsace grand cru Praelatenberg vendanges tardives Muscat Ottonel	\N
11739	34	Alsace grand cru Praelatenberg	AOC -	AOP -	{"fra": "Alsace grand cru Praelatenberg vendanges tardives Pinot gris"}	Alsace grand cru Praelatenberg vendanges tardives Pinot gris	\N
11740	34	Alsace grand cru Praelatenberg	AOC -	AOP -	{"fra": "Alsace grand cru Praelatenberg vendanges tardives Riesling"}	Alsace grand cru Praelatenberg vendanges tardives Riesling	\N
11741	35	Alsace grand cru Rangen	AOC -	AOP -	{"fra": "Alsace grand cru Rangen Gewurztraminer"}	Alsace grand cru Rangen Gewurztraminer	\N
11742	35	Alsace grand cru Rangen	AOC -	AOP -	{"fra": "Alsace grand cru Rangen Muscat"}	Alsace grand cru Rangen Muscat	\N
11743	35	Alsace grand cru Rangen	AOC -	AOP -	{"fra": "Alsace grand cru Rangen Muscat Ottonel"}	Alsace grand cru Rangen Muscat Ottonel	\N
11744	35	Alsace grand cru Rangen	AOC -	AOP -	{"fra": "Alsace grand cru Rangen Pinot gris"}	Alsace grand cru Rangen Pinot gris	\N
11745	35	Alsace grand cru Rangen	AOC -	AOP -	{"fra": "Alsace grand cru Rangen Riesling"}	Alsace grand cru Rangen Riesling	\N
11746	35	Alsace grand cru Rangen	AOC -	AOP -	{"fra": "Alsace grand cru Rangen sélection de grains nobles Gewurztraminer"}	Alsace grand cru Rangen sélection de grains nobles Gewurztraminer	\N
11747	35	Alsace grand cru Rangen	AOC -	AOP -	{"fra": "Alsace grand cru Rangen sélection de grains nobles Muscat"}	Alsace grand cru Rangen sélection de grains nobles Muscat	\N
11748	35	Alsace grand cru Rangen	AOC -	AOP -	{"fra": "Alsace grand cru Rangen sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Rangen sélection de grains nobles Muscat Ottonel	\N
11749	35	Alsace grand cru Rangen	AOC -	AOP -	{"fra": "Alsace grand cru Rangen sélection de grains nobles Pinot gris"}	Alsace grand cru Rangen sélection de grains nobles Pinot gris	\N
11750	35	Alsace grand cru Rangen	AOC -	AOP -	{"fra": "Alsace grand cru Rangen sélection de grains nobles Riesling"}	Alsace grand cru Rangen sélection de grains nobles Riesling	\N
11751	35	Alsace grand cru Rangen	AOC -	AOP -	{"fra": "Alsace grand cru Rangen vendanges tardives Gewurztraminer"}	Alsace grand cru Rangen vendanges tardives Gewurztraminer	\N
11752	35	Alsace grand cru Rangen	AOC -	AOP -	{"fra": "Alsace grand cru Rangen vendanges tardives Muscat"}	Alsace grand cru Rangen vendanges tardives Muscat	\N
11753	35	Alsace grand cru Rangen	AOC -	AOP -	{"fra": "Alsace grand cru Rangen vendanges tardives Muscat Ottonel"}	Alsace grand cru Rangen vendanges tardives Muscat Ottonel	\N
11754	35	Alsace grand cru Rangen	AOC -	AOP -	{"fra": "Alsace grand cru Rangen vendanges tardives Pinot gris"}	Alsace grand cru Rangen vendanges tardives Pinot gris	\N
11755	35	Alsace grand cru Rangen	AOC -	AOP -	{"fra": "Alsace grand cru Rangen vendanges tardives Riesling"}	Alsace grand cru Rangen vendanges tardives Riesling	\N
11756	36	Alsace grand cru Rosacker	AOC -	AOP -	{"fra": "Alsace grand cru Rosacker Gewurztraminer"}	Alsace grand cru Rosacker Gewurztraminer	\N
11758	36	Alsace grand cru Rosacker	AOC -	AOP -	{"fra": "Alsace grand cru Rosacker Muscat"}	Alsace grand cru Rosacker Muscat	\N
11759	36	Alsace grand cru Rosacker	AOC -	AOP -	{"fra": "Alsace grand cru Rosacker Muscat Ottonel"}	Alsace grand cru Rosacker Muscat Ottonel	\N
11760	36	Alsace grand cru Rosacker	AOC -	AOP -	{"fra": "Alsace grand cru Rosacker Pinot gris"}	Alsace grand cru Rosacker Pinot gris	\N
11761	36	Alsace grand cru Rosacker	AOC -	AOP -	{"fra": "Alsace grand cru Rosacker Riesling"}	Alsace grand cru Rosacker Riesling	\N
11762	36	Alsace grand cru Rosacker	AOC -	AOP -	{"fra": "Alsace grand cru Rosacker sélection de grains nobles Gewurztraminer"}	Alsace grand cru Rosacker sélection de grains nobles Gewurztraminer	\N
11763	36	Alsace grand cru Rosacker	AOC -	AOP -	{"fra": "Alsace grand cru Rosacker sélection de grains nobles Muscat"}	Alsace grand cru Rosacker sélection de grains nobles Muscat	\N
11764	36	Alsace grand cru Rosacker	AOC -	AOP -	{"fra": "Alsace grand cru Rosacker sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Rosacker sélection de grains nobles Muscat Ottonel	\N
11765	36	Alsace grand cru Rosacker	AOC -	AOP -	{"fra": "Alsace grand cru Rosacker sélection de grains nobles Pinot gris"}	Alsace grand cru Rosacker sélection de grains nobles Pinot gris	\N
11766	36	Alsace grand cru Rosacker	AOC -	AOP -	{"fra": "Alsace grand cru Rosacker sélection de grains nobles Riesling"}	Alsace grand cru Rosacker sélection de grains nobles Riesling	\N
11767	36	Alsace grand cru Rosacker	AOC -	AOP -	{"fra": "Alsace grand cru Rosacker vendanges tardives Gewurztraminer"}	Alsace grand cru Rosacker vendanges tardives Gewurztraminer	\N
11768	36	Alsace grand cru Rosacker	AOC -	AOP -	{"fra": "Alsace grand cru Rosacker vendanges tardives Muscat"}	Alsace grand cru Rosacker vendanges tardives Muscat	\N
11769	36	Alsace grand cru Rosacker	AOC -	AOP -	{"fra": "Alsace grand cru Rosacker vendanges tardives Muscat Ottonel"}	Alsace grand cru Rosacker vendanges tardives Muscat Ottonel	\N
11770	36	Alsace grand cru Rosacker	AOC -	AOP -	{"fra": "Alsace grand cru Rosacker vendanges tardives Pinot gris"}	Alsace grand cru Rosacker vendanges tardives Pinot gris	\N
11771	36	Alsace grand cru Rosacker	AOC -	AOP -	{"fra": "Alsace grand cru Rosacker vendanges tardives Riesling"}	Alsace grand cru Rosacker vendanges tardives Riesling	\N
11772	37	Alsace grand cru Saering	AOC -	AOP -	{"fra": "Alsace grand cru Saering Gewurztraminer"}	Alsace grand cru Saering Gewurztraminer	\N
11773	37	Alsace grand cru Saering	AOC -	AOP -	{"fra": "Alsace grand cru Saering Muscat"}	Alsace grand cru Saering Muscat	\N
11774	37	Alsace grand cru Saering	AOC -	AOP -	{"fra": "Alsace grand cru Saering Muscat Ottonel"}	Alsace grand cru Saering Muscat Ottonel	\N
11775	37	Alsace grand cru Saering	AOC -	AOP -	{"fra": "Alsace grand cru Saering Pinot gris"}	Alsace grand cru Saering Pinot gris	\N
11777	37	Alsace grand cru Saering	AOC -	AOP -	{"fra": "Alsace grand cru Saering sélection de grains nobles Gewurztraminer"}	Alsace grand cru Saering sélection de grains nobles Gewurztraminer	\N
11778	37	Alsace grand cru Saering	AOC -	AOP -	{"fra": "Alsace grand cru Saering sélection de grains nobles Muscat"}	Alsace grand cru Saering sélection de grains nobles Muscat	\N
11779	37	Alsace grand cru Saering	AOC -	AOP -	{"fra": "Alsace grand cru Saering sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Saering sélection de grains nobles Muscat Ottonel	\N
11780	37	Alsace grand cru Saering	AOC -	AOP -	{"fra": "Alsace grand cru Saering Riesling"}	Alsace grand cru Saering Riesling	\N
11781	37	Alsace grand cru Saering	AOC -	AOP -	{"fra": "Alsace grand cru Saering sélection de grains nobles Pinot gris"}	Alsace grand cru Saering sélection de grains nobles Pinot gris	\N
10362	1980	Ariège	\N	IGP -	{"fra": "Ariège primeur ou nouveau rouge"}	Ariège primeur ou nouveau rouge	\N
11782	37	Alsace grand cru Saering	AOC -	AOP -	{"fra": "Alsace grand cru Saering sélection de grains nobles Riesling"}	Alsace grand cru Saering sélection de grains nobles Riesling	\N
11783	37	Alsace grand cru Saering	AOC -	AOP -	{"fra": "Alsace grand cru Saering vendanges tardives Gewurztraminer"}	Alsace grand cru Saering vendanges tardives Gewurztraminer	\N
11784	37	Alsace grand cru Saering	AOC -	AOP -	{"fra": "Alsace grand cru Saering vendanges tardives Muscat"}	Alsace grand cru Saering vendanges tardives Muscat	\N
11785	37	Alsace grand cru Saering	AOC -	AOP -	{"fra": "Alsace grand cru Saering vendanges tardives Muscat Ottonel"}	Alsace grand cru Saering vendanges tardives Muscat Ottonel	\N
11786	37	Alsace grand cru Saering	AOC -	AOP -	{"fra": "Alsace grand cru Saering vendanges tardives Pinot gris"}	Alsace grand cru Saering vendanges tardives Pinot gris	\N
11787	37	Alsace grand cru Saering	AOC -	AOP -	{"fra": "Alsace grand cru Saering vendanges tardives Riesling"}	Alsace grand cru Saering vendanges tardives Riesling	\N
7869	2034	Isère	\N	IGP -	{"fra": "Isère blanc"}	Isère blanc	\N
11788	38	Alsace grand cru Schlossberg	AOC -	AOP -	{"fra": "Alsace grand cru Schlossberg Gewurztraminer"}	Alsace grand cru Schlossberg Gewurztraminer	\N
11789	38	Alsace grand cru Schlossberg	AOC -	AOP -	{"fra": "Alsace grand cru Schlossberg Muscat"}	Alsace grand cru Schlossberg Muscat	\N
11790	38	Alsace grand cru Schlossberg	AOC -	AOP -	{"fra": "Alsace grand cru Schlossberg Muscat Ottonel"}	Alsace grand cru Schlossberg Muscat Ottonel	\N
11791	38	Alsace grand cru Schlossberg	AOC -	AOP -	{"fra": "Alsace grand cru Schlossberg Pinot gris"}	Alsace grand cru Schlossberg Pinot gris	\N
11792	38	Alsace grand cru Schlossberg	AOC -	AOP -	{"fra": "Alsace grand cru Schlossberg Riesling"}	Alsace grand cru Schlossberg Riesling	\N
11793	38	Alsace grand cru Schlossberg	AOC -	AOP -	{"fra": "Alsace grand cru Schlossberg sélection de grains nobles Gewurztraminer"}	Alsace grand cru Schlossberg sélection de grains nobles Gewurztraminer	\N
11794	38	Alsace grand cru Schlossberg	AOC -	AOP -	{"fra": "Alsace grand cru Schlossberg sélection de grains nobles Muscat"}	Alsace grand cru Schlossberg sélection de grains nobles Muscat	\N
11795	38	Alsace grand cru Schlossberg	AOC -	AOP -	{"fra": "Alsace grand cru Schlossberg sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Schlossberg sélection de grains nobles Muscat Ottonel	\N
11796	38	Alsace grand cru Schlossberg	AOC -	AOP -	{"fra": "Alsace grand cru Schlossberg sélection de grains nobles Pinot gris"}	Alsace grand cru Schlossberg sélection de grains nobles Pinot gris	\N
11797	38	Alsace grand cru Schlossberg	AOC -	AOP -	{"fra": "Alsace grand cru Schlossberg sélection de grains nobles Riesling"}	Alsace grand cru Schlossberg sélection de grains nobles Riesling	\N
11798	38	Alsace grand cru Schlossberg	AOC -	AOP -	{"fra": "Alsace grand cru Schlossberg vendanges tardives Gewurztraminer"}	Alsace grand cru Schlossberg vendanges tardives Gewurztraminer	\N
11799	38	Alsace grand cru Schlossberg	AOC -	AOP -	{"fra": "Alsace grand cru Schlossberg vendanges tardives Muscat"}	Alsace grand cru Schlossberg vendanges tardives Muscat	\N
11800	38	Alsace grand cru Schlossberg	AOC -	AOP -	{"fra": "Alsace grand cru Schlossberg vendanges tardives Muscat Ottonel"}	Alsace grand cru Schlossberg vendanges tardives Muscat Ottonel	\N
11801	38	Alsace grand cru Schlossberg	AOC -	AOP -	{"fra": "Alsace grand cru Schlossberg vendanges tardives Pinot gris"}	Alsace grand cru Schlossberg vendanges tardives Pinot gris	\N
11802	38	Alsace grand cru Schlossberg	AOC -	AOP -	{"fra": "Alsace grand cru Schlossberg vendanges tardives Riesling"}	Alsace grand cru Schlossberg vendanges tardives Riesling	\N
11803	39	Alsace grand cru Schoenenbourg	AOC -	AOP -	{"fra": "Alsace grand cru Schoenenbourg Gewurztraminer"}	Alsace grand cru Schoenenbourg Gewurztraminer	\N
11804	39	Alsace grand cru Schoenenbourg	AOC -	AOP -	{"fra": "Alsace grand cru Schoenenbourg Muscat"}	Alsace grand cru Schoenenbourg Muscat	\N
11805	39	Alsace grand cru Schoenenbourg	AOC -	AOP -	{"fra": "Alsace grand cru Schoenenbourg Muscat Ottonel"}	Alsace grand cru Schoenenbourg Muscat Ottonel	\N
11806	39	Alsace grand cru Schoenenbourg	AOC -	AOP -	{"fra": "Alsace grand cru Schoenenbourg Pinot gris"}	Alsace grand cru Schoenenbourg Pinot gris	\N
11807	39	Alsace grand cru Schoenenbourg	AOC -	AOP -	{"fra": "Alsace grand cru Schoenenbourg Riesling"}	Alsace grand cru Schoenenbourg Riesling	\N
11808	39	Alsace grand cru Schoenenbourg	AOC -	AOP -	{"fra": "Alsace grand cru Schoenenbourg sélection de grains nobles Gewurztraminer"}	Alsace grand cru Schoenenbourg sélection de grains nobles Gewurztraminer	\N
11809	39	Alsace grand cru Schoenenbourg	AOC -	AOP -	{"fra": "Alsace grand cru Schoenenbourg sélection de grains nobles Muscat"}	Alsace grand cru Schoenenbourg sélection de grains nobles Muscat	\N
11810	39	Alsace grand cru Schoenenbourg	AOC -	AOP -	{"fra": "Alsace grand cru Schoenenbourg sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Schoenenbourg sélection de grains nobles Muscat Ottonel	\N
11811	39	Alsace grand cru Schoenenbourg	AOC -	AOP -	{"fra": "Alsace grand cru Schoenenbourg sélection de grains nobles Pinot gris"}	Alsace grand cru Schoenenbourg sélection de grains nobles Pinot gris	\N
11812	39	Alsace grand cru Schoenenbourg	AOC -	AOP -	{"fra": "Alsace grand cru Schoenenbourg sélection de grains nobles Riesling"}	Alsace grand cru Schoenenbourg sélection de grains nobles Riesling	\N
11813	39	Alsace grand cru Schoenenbourg	AOC -	AOP -	{"fra": "Alsace grand cru Schoenenbourg vendanges tardives Gewurztraminer"}	Alsace grand cru Schoenenbourg vendanges tardives Gewurztraminer	\N
11814	39	Alsace grand cru Schoenenbourg	AOC -	AOP -	{"fra": "Alsace grand cru Schoenenbourg vendanges tardives Muscat"}	Alsace grand cru Schoenenbourg vendanges tardives Muscat	\N
11815	39	Alsace grand cru Schoenenbourg	AOC -	AOP -	{"fra": "Alsace grand cru Schoenenbourg vendanges tardives Muscat Ottonel"}	Alsace grand cru Schoenenbourg vendanges tardives Muscat Ottonel	\N
11816	39	Alsace grand cru Schoenenbourg	AOC -	AOP -	{"fra": "Alsace grand cru Schoenenbourg vendanges tardives Pinot gris"}	Alsace grand cru Schoenenbourg vendanges tardives Pinot gris	\N
11817	39	Alsace grand cru Schoenenbourg	AOC -	AOP -	{"fra": "Alsace grand cru Schoenenbourg vendanges tardives Riesling"}	Alsace grand cru Schoenenbourg vendanges tardives Riesling	\N
11818	40	Alsace grand cru Sommerberg	AOC -	AOP -	{"fra": "Alsace grand cru Sommerberg Gewurztraminer"}	Alsace grand cru Sommerberg Gewurztraminer	\N
11819	40	Alsace grand cru Sommerberg	AOC -	AOP -	{"fra": "Alsace grand cru Sommerberg Muscat"}	Alsace grand cru Sommerberg Muscat	\N
11820	40	Alsace grand cru Sommerberg	AOC -	AOP -	{"fra": "Alsace grand cru Sommerberg Muscat Ottonel"}	Alsace grand cru Sommerberg Muscat Ottonel	\N
11821	40	Alsace grand cru Sommerberg	AOC -	AOP -	{"fra": "Alsace grand cru Sommerberg Pinot gris"}	Alsace grand cru Sommerberg Pinot gris	\N
11822	40	Alsace grand cru Sommerberg	AOC -	AOP -	{"fra": "Alsace grand cru Sommerberg Riesling"}	Alsace grand cru Sommerberg Riesling	\N
11823	40	Alsace grand cru Sommerberg	AOC -	AOP -	{"fra": "Alsace grand cru Sommerberg sélection de grains nobles Gewurztraminer"}	Alsace grand cru Sommerberg sélection de grains nobles Gewurztraminer	\N
11824	40	Alsace grand cru Sommerberg	AOC -	AOP -	{"fra": "Alsace grand cru Sommerberg sélection de grains nobles Muscat"}	Alsace grand cru Sommerberg sélection de grains nobles Muscat	\N
11825	40	Alsace grand cru Sommerberg	AOC -	AOP -	{"fra": "Alsace grand cru Sommerberg sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Sommerberg sélection de grains nobles Muscat Ottonel	\N
11826	40	Alsace grand cru Sommerberg	AOC -	AOP -	{"fra": "Alsace grand cru Sommerberg sélection de grains nobles Pinot gris"}	Alsace grand cru Sommerberg sélection de grains nobles Pinot gris	\N
11827	40	Alsace grand cru Sommerberg	AOC -	AOP -	{"fra": "Alsace grand cru Sommerberg sélection de grains nobles Riesling"}	Alsace grand cru Sommerberg sélection de grains nobles Riesling	\N
11828	40	Alsace grand cru Sommerberg	AOC -	AOP -	{"fra": "Alsace grand cru Sommerberg vendanges tardives Gewurztraminer"}	Alsace grand cru Sommerberg vendanges tardives Gewurztraminer	\N
11829	40	Alsace grand cru Sommerberg	AOC -	AOP -	{"fra": "Alsace grand cru Sommerberg vendanges tardives Muscat"}	Alsace grand cru Sommerberg vendanges tardives Muscat	\N
11830	40	Alsace grand cru Sommerberg	AOC -	AOP -	{"fra": "Alsace grand cru Sommerberg vendanges tardives Muscat Ottonel"}	Alsace grand cru Sommerberg vendanges tardives Muscat Ottonel	\N
11831	40	Alsace grand cru Sommerberg	AOC -	AOP -	{"fra": "Alsace grand cru Sommerberg vendanges tardives Pinot gris"}	Alsace grand cru Sommerberg vendanges tardives Pinot gris	\N
11832	40	Alsace grand cru Sommerberg	AOC -	AOP -	{"fra": "Alsace grand cru Sommerberg vendanges tardives Riesling"}	Alsace grand cru Sommerberg vendanges tardives Riesling	\N
11833	41	Alsace grand cru Sonnenglanz	AOC -	AOP -	{"fra": "Alsace grand cru Sonnenglanz Gewurztraminer"}	Alsace grand cru Sonnenglanz Gewurztraminer	\N
11834	41	Alsace grand cru Sonnenglanz	AOC -	AOP -	{"fra": "Alsace grand cru Sonnenglanz Muscat"}	Alsace grand cru Sonnenglanz Muscat	\N
11835	41	Alsace grand cru Sonnenglanz	AOC -	AOP -	{"fra": "Alsace grand cru Sonnenglanz Muscat Ottonel"}	Alsace grand cru Sonnenglanz Muscat Ottonel	\N
11836	41	Alsace grand cru Sonnenglanz	AOC -	AOP -	{"fra": "Alsace grand cru Sonnenglanz Pinot gris"}	Alsace grand cru Sonnenglanz Pinot gris	\N
11837	41	Alsace grand cru Sonnenglanz	AOC -	AOP -	{"fra": "Alsace grand cru Sonnenglanz Riesling"}	Alsace grand cru Sonnenglanz Riesling	\N
11838	41	Alsace grand cru Sonnenglanz	AOC -	AOP -	{"fra": "Alsace grand cru Sonnenglanz sélection de grains nobles Gewurztraminer"}	Alsace grand cru Sonnenglanz sélection de grains nobles Gewurztraminer	\N
11839	41	Alsace grand cru Sonnenglanz	AOC -	AOP -	{"fra": "Alsace grand cru Sonnenglanz sélection de grains nobles Muscat"}	Alsace grand cru Sonnenglanz sélection de grains nobles Muscat	\N
11840	41	Alsace grand cru Sonnenglanz	AOC -	AOP -	{"fra": "Alsace grand cru Sonnenglanz sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Sonnenglanz sélection de grains nobles Muscat Ottonel	\N
11841	41	Alsace grand cru Sonnenglanz	AOC -	AOP -	{"fra": "Alsace grand cru Sonnenglanz sélection de grains nobles Pinot gris"}	Alsace grand cru Sonnenglanz sélection de grains nobles Pinot gris	\N
11842	41	Alsace grand cru Sonnenglanz	AOC -	AOP -	{"fra": "Alsace grand cru Sonnenglanz sélection de grains nobles Riesling"}	Alsace grand cru Sonnenglanz sélection de grains nobles Riesling	\N
11843	41	Alsace grand cru Sonnenglanz	AOC -	AOP -	{"fra": "Alsace grand cru Sonnenglanz vendanges tardives Gewurztraminer"}	Alsace grand cru Sonnenglanz vendanges tardives Gewurztraminer	\N
11844	41	Alsace grand cru Sonnenglanz	AOC -	AOP -	{"fra": "Alsace grand cru Sonnenglanz vendanges tardives Muscat"}	Alsace grand cru Sonnenglanz vendanges tardives Muscat	\N
11845	41	Alsace grand cru Sonnenglanz	AOC -	AOP -	{"fra": "Alsace grand cru Sonnenglanz vendanges tardives Muscat Ottonel"}	Alsace grand cru Sonnenglanz vendanges tardives Muscat Ottonel	\N
11847	41	Alsace grand cru Sonnenglanz	AOC -	AOP -	{"fra": "Alsace grand cru Sonnenglanz vendanges tardives Riesling"}	Alsace grand cru Sonnenglanz vendanges tardives Riesling	\N
11848	42	Alsace grand cru Spiegel	AOC -	AOP -	{"fra": "Alsace grand cru Spiegel Gewurztraminer"}	Alsace grand cru Spiegel Gewurztraminer	\N
11849	42	Alsace grand cru Spiegel	AOC -	AOP -	{"fra": "Alsace grand cru Spiegel Muscat"}	Alsace grand cru Spiegel Muscat	\N
11850	42	Alsace grand cru Spiegel	AOC -	AOP -	{"fra": "Alsace grand cru Spiegel Muscat Ottonel"}	Alsace grand cru Spiegel Muscat Ottonel	\N
11851	42	Alsace grand cru Spiegel	AOC -	AOP -	{"fra": "Alsace grand cru Spiegel Pinot gris"}	Alsace grand cru Spiegel Pinot gris	\N
11852	42	Alsace grand cru Spiegel	AOC -	AOP -	{"fra": "Alsace grand cru Spiegel Riesling"}	Alsace grand cru Spiegel Riesling	\N
11853	42	Alsace grand cru Spiegel	AOC -	AOP -	{"fra": "Alsace grand cru Spiegel sélection de grains nobles Gewurztraminer"}	Alsace grand cru Spiegel sélection de grains nobles Gewurztraminer	\N
11854	42	Alsace grand cru Spiegel	AOC -	AOP -	{"fra": "Alsace grand cru Spiegel sélection de grains nobles Muscat"}	Alsace grand cru Spiegel sélection de grains nobles Muscat	\N
11855	42	Alsace grand cru Spiegel	AOC -	AOP -	{"fra": "Alsace grand cru Spiegel sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Spiegel sélection de grains nobles Muscat Ottonel	\N
11856	42	Alsace grand cru Spiegel	AOC -	AOP -	{"fra": "Alsace grand cru Spiegel sélection de grains nobles Pinot gris"}	Alsace grand cru Spiegel sélection de grains nobles Pinot gris	\N
11857	42	Alsace grand cru Spiegel	AOC -	AOP -	{"fra": "Alsace grand cru Spiegel sélection de grains nobles Riesling"}	Alsace grand cru Spiegel sélection de grains nobles Riesling	\N
11858	42	Alsace grand cru Spiegel	AOC -	AOP -	{"fra": "Alsace grand cru Spiegel vendanges tardives Gewurztraminer"}	Alsace grand cru Spiegel vendanges tardives Gewurztraminer	\N
11859	42	Alsace grand cru Spiegel	AOC -	AOP -	{"fra": "Alsace grand cru Spiegel vendanges tardives Muscat"}	Alsace grand cru Spiegel vendanges tardives Muscat	\N
11860	42	Alsace grand cru Spiegel	AOC -	AOP -	{"fra": "Alsace grand cru Spiegel vendanges tardives Muscat Ottonel"}	Alsace grand cru Spiegel vendanges tardives Muscat Ottonel	\N
11861	42	Alsace grand cru Spiegel	AOC -	AOP -	{"fra": "Alsace grand cru Spiegel vendanges tardives Pinot gris"}	Alsace grand cru Spiegel vendanges tardives Pinot gris	\N
11862	42	Alsace grand cru Spiegel	AOC -	AOP -	{"fra": "Alsace grand cru Spiegel vendanges tardives Riesling"}	Alsace grand cru Spiegel vendanges tardives Riesling	\N
11863	43	Alsace grand cru Sporen	AOC -	AOP -	{"fra": "Alsace grand cru Sporen Gewurztraminer"}	Alsace grand cru Sporen Gewurztraminer	\N
11864	43	Alsace grand cru Sporen	AOC -	AOP -	{"fra": "Alsace grand cru Sporen Muscat"}	Alsace grand cru Sporen Muscat	\N
11865	43	Alsace grand cru Sporen	AOC -	AOP -	{"fra": "Alsace grand cru Sporen Muscat Ottonel"}	Alsace grand cru Sporen Muscat Ottonel	\N
11866	43	Alsace grand cru Sporen	AOC -	AOP -	{"fra": "Alsace grand cru Sporen Pinot gris"}	Alsace grand cru Sporen Pinot gris	\N
11867	43	Alsace grand cru Sporen	AOC -	AOP -	{"fra": "Alsace grand cru Sporen Riesling"}	Alsace grand cru Sporen Riesling	\N
11868	43	Alsace grand cru Sporen	AOC -	AOP -	{"fra": "Alsace grand cru Sporen sélection de grains nobles Gewurztraminer"}	Alsace grand cru Sporen sélection de grains nobles Gewurztraminer	\N
11869	43	Alsace grand cru Sporen	AOC -	AOP -	{"fra": "Alsace grand cru Sporen sélection de grains nobles Muscat"}	Alsace grand cru Sporen sélection de grains nobles Muscat	\N
11870	43	Alsace grand cru Sporen	AOC -	AOP -	{"fra": "Alsace grand cru Sporen sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Sporen sélection de grains nobles Muscat Ottonel	\N
11871	43	Alsace grand cru Sporen	AOC -	AOP -	{"fra": "Alsace grand cru Sporen sélection de grains nobles Pinot gris"}	Alsace grand cru Sporen sélection de grains nobles Pinot gris	\N
11872	43	Alsace grand cru Sporen	AOC -	AOP -	{"fra": "Alsace grand cru Sporen sélection de grains nobles Riesling"}	Alsace grand cru Sporen sélection de grains nobles Riesling	\N
11873	43	Alsace grand cru Sporen	AOC -	AOP -	{"fra": "Alsace grand cru Sporen vendanges tardives Gewurztraminer"}	Alsace grand cru Sporen vendanges tardives Gewurztraminer	\N
11874	43	Alsace grand cru Sporen	AOC -	AOP -	{"fra": "Alsace grand cru Sporen vendanges tardives Muscat"}	Alsace grand cru Sporen vendanges tardives Muscat	\N
11875	43	Alsace grand cru Sporen	AOC -	AOP -	{"fra": "Alsace grand cru Sporen vendanges tardives Muscat Ottonel"}	Alsace grand cru Sporen vendanges tardives Muscat Ottonel	\N
11876	43	Alsace grand cru Sporen	AOC -	AOP -	{"fra": "Alsace grand cru Sporen vendanges tardives Pinot gris"}	Alsace grand cru Sporen vendanges tardives Pinot gris	\N
11877	43	Alsace grand cru Sporen	AOC -	AOP -	{"fra": "Alsace grand cru Sporen vendanges tardives Riesling"}	Alsace grand cru Sporen vendanges tardives Riesling	\N
11878	44	Alsace grand cru Steinert	AOC -	AOP -	{"fra": "Alsace grand cru Steinert Gewurztraminer"}	Alsace grand cru Steinert Gewurztraminer	\N
11879	44	Alsace grand cru Steinert	AOC -	AOP -	{"fra": "Alsace grand cru Steinert Muscat"}	Alsace grand cru Steinert Muscat	\N
11880	44	Alsace grand cru Steinert	AOC -	AOP -	{"fra": "Alsace grand cru Steinert Muscat Ottonel"}	Alsace grand cru Steinert Muscat Ottonel	\N
11881	44	Alsace grand cru Steinert	AOC -	AOP -	{"fra": "Alsace grand cru Steinert Pinot gris"}	Alsace grand cru Steinert Pinot gris	\N
11882	44	Alsace grand cru Steinert	AOC -	AOP -	{"fra": "Alsace grand cru Steinert Riesling"}	Alsace grand cru Steinert Riesling	\N
11883	44	Alsace grand cru Steinert	AOC -	AOP -	{"fra": "Alsace grand cru Steinert sélection de grains nobles Gewurztraminer"}	Alsace grand cru Steinert sélection de grains nobles Gewurztraminer	\N
11884	44	Alsace grand cru Steinert	AOC -	AOP -	{"fra": "Alsace grand cru Steinert sélection de grains nobles Muscat"}	Alsace grand cru Steinert sélection de grains nobles Muscat	\N
11885	44	Alsace grand cru Steinert	AOC -	AOP -	{"fra": "Alsace grand cru Steinert sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Steinert sélection de grains nobles Muscat Ottonel	\N
11886	44	Alsace grand cru Steinert	AOC -	AOP -	{"fra": "Alsace grand cru Steinert sélection de grains nobles Pinot gris"}	Alsace grand cru Steinert sélection de grains nobles Pinot gris	\N
11887	44	Alsace grand cru Steinert	AOC -	AOP -	{"fra": "Alsace grand cru Steinert sélection de grains nobles Riesling"}	Alsace grand cru Steinert sélection de grains nobles Riesling	\N
11888	44	Alsace grand cru Steinert	AOC -	AOP -	{"fra": "Alsace grand cru Steinert vendanges tardives Gewurztraminer"}	Alsace grand cru Steinert vendanges tardives Gewurztraminer	\N
11889	44	Alsace grand cru Steinert	AOC -	AOP -	{"fra": "Alsace grand cru Steinert vendanges tardives Muscat"}	Alsace grand cru Steinert vendanges tardives Muscat	\N
11890	44	Alsace grand cru Steinert	AOC -	AOP -	{"fra": "Alsace grand cru Steinert vendanges tardives Muscat Ottonel"}	Alsace grand cru Steinert vendanges tardives Muscat Ottonel	\N
11891	44	Alsace grand cru Steinert	AOC -	AOP -	{"fra": "Alsace grand cru Steinert vendanges tardives Pinot gris"}	Alsace grand cru Steinert vendanges tardives Pinot gris	\N
11892	44	Alsace grand cru Steinert	AOC -	AOP -	{"fra": "Alsace grand cru Steinert vendanges tardives Riesling"}	Alsace grand cru Steinert vendanges tardives Riesling	\N
11893	45	Alsace grand cru Steingrubler	AOC -	AOP -	{"fra": "Alsace grand cru Steingrubler Gewurztraminer"}	Alsace grand cru Steingrubler Gewurztraminer	\N
11894	45	Alsace grand cru Steingrubler	AOC -	AOP -	{"fra": "Alsace grand cru Steingrubler Muscat"}	Alsace grand cru Steingrubler Muscat	\N
11895	45	Alsace grand cru Steingrubler	AOC -	AOP -	{"fra": "Alsace grand cru Steingrubler Muscat Ottonel"}	Alsace grand cru Steingrubler Muscat Ottonel	\N
11896	45	Alsace grand cru Steingrubler	AOC -	AOP -	{"fra": "Alsace grand cru Steingrubler Pinot gris"}	Alsace grand cru Steingrubler Pinot gris	\N
11897	45	Alsace grand cru Steingrubler	AOC -	AOP -	{"fra": "Alsace grand cru Steingrubler Riesling"}	Alsace grand cru Steingrubler Riesling	\N
11898	45	Alsace grand cru Steingrubler	AOC -	AOP -	{"fra": "Alsace grand cru Steingrubler sélection de grains nobles Gewurztraminer"}	Alsace grand cru Steingrubler sélection de grains nobles Gewurztraminer	\N
11899	45	Alsace grand cru Steingrubler	AOC -	AOP -	{"fra": "Alsace grand cru Steingrubler sélection de grains nobles Muscat"}	Alsace grand cru Steingrubler sélection de grains nobles Muscat	\N
11900	45	Alsace grand cru Steingrubler	AOC -	AOP -	{"fra": "Alsace grand cru Steingrubler sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Steingrubler sélection de grains nobles Muscat Ottonel	\N
11901	45	Alsace grand cru Steingrubler	AOC -	AOP -	{"fra": "Alsace grand cru Steingrubler sélection de grains nobles Pinot gris"}	Alsace grand cru Steingrubler sélection de grains nobles Pinot gris	\N
11902	45	Alsace grand cru Steingrubler	AOC -	AOP -	{"fra": "Alsace grand cru Steingrubler sélection de grains nobles Riesling"}	Alsace grand cru Steingrubler sélection de grains nobles Riesling	\N
11903	45	Alsace grand cru Steingrubler	AOC -	AOP -	{"fra": "Alsace grand cru Steingrubler vendanges tardives Gewurztraminer"}	Alsace grand cru Steingrubler vendanges tardives Gewurztraminer	\N
11904	45	Alsace grand cru Steingrubler	AOC -	AOP -	{"fra": "Alsace grand cru Steingrubler vendanges tardives Muscat"}	Alsace grand cru Steingrubler vendanges tardives Muscat	\N
11905	45	Alsace grand cru Steingrubler	AOC -	AOP -	{"fra": "Alsace grand cru Steingrubler vendanges tardives Pinot gris"}	Alsace grand cru Steingrubler vendanges tardives Pinot gris	\N
11906	45	Alsace grand cru Steingrubler	AOC -	AOP -	{"fra": "Alsace grand cru Steingrubler vendanges tardives Muscat Ottonel"}	Alsace grand cru Steingrubler vendanges tardives Muscat Ottonel	\N
11907	45	Alsace grand cru Steingrubler	AOC -	AOP -	{"fra": "Alsace grand cru Steingrubler vendanges tardives Riesling"}	Alsace grand cru Steingrubler vendanges tardives Riesling	\N
11908	46	Alsace grand cru Steinklotz	AOC -	AOP -	{"fra": "Alsace grand cru Steinklotz Gewurztraminer"}	Alsace grand cru Steinklotz Gewurztraminer	\N
11909	46	Alsace grand cru Steinklotz	AOC -	AOP -	{"fra": "Alsace grand cru Steinklotz Muscat"}	Alsace grand cru Steinklotz Muscat	\N
11910	46	Alsace grand cru Steinklotz	AOC -	AOP -	{"fra": "Alsace grand cru Steinklotz Muscat Ottonel"}	Alsace grand cru Steinklotz Muscat Ottonel	\N
11911	46	Alsace grand cru Steinklotz	AOC -	AOP -	{"fra": "Alsace grand cru Steinklotz Pinot gris"}	Alsace grand cru Steinklotz Pinot gris	\N
11912	46	Alsace grand cru Steinklotz	AOC -	AOP -	{"fra": "Alsace grand cru Steinklotz sélection de grains nobles Gewurztraminer"}	Alsace grand cru Steinklotz sélection de grains nobles Gewurztraminer	\N
11913	46	Alsace grand cru Steinklotz	AOC -	AOP -	{"fra": "Alsace grand cru Steinklotz Riesling"}	Alsace grand cru Steinklotz Riesling	\N
11914	46	Alsace grand cru Steinklotz	AOC -	AOP -	{"fra": "Alsace grand cru Steinklotz sélection de grains nobles Muscat"}	Alsace grand cru Steinklotz sélection de grains nobles Muscat	\N
11915	46	Alsace grand cru Steinklotz	AOC -	AOP -	{"fra": "Alsace grand cru Steinklotz sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Steinklotz sélection de grains nobles Muscat Ottonel	\N
11916	46	Alsace grand cru Steinklotz	AOC -	AOP -	{"fra": "Alsace grand cru Steinklotz sélection de grains nobles Pinot gris"}	Alsace grand cru Steinklotz sélection de grains nobles Pinot gris	\N
11917	46	Alsace grand cru Steinklotz	AOC -	AOP -	{"fra": "Alsace grand cru Steinklotz sélection de grains nobles Riesling"}	Alsace grand cru Steinklotz sélection de grains nobles Riesling	\N
11918	46	Alsace grand cru Steinklotz	AOC -	AOP -	{"fra": "Alsace grand cru Steinklotz vendanges tardives Gewurztraminer"}	Alsace grand cru Steinklotz vendanges tardives Gewurztraminer	\N
11919	46	Alsace grand cru Steinklotz	AOC -	AOP -	{"fra": "Alsace grand cru Steinklotz vendanges tardives Muscat"}	Alsace grand cru Steinklotz vendanges tardives Muscat	\N
11920	46	Alsace grand cru Steinklotz	AOC -	AOP -	{"fra": "Alsace grand cru Steinklotz vendanges tardives Muscat Ottonel"}	Alsace grand cru Steinklotz vendanges tardives Muscat Ottonel	\N
11921	46	Alsace grand cru Steinklotz	AOC -	AOP -	{"fra": "Alsace grand cru Steinklotz vendanges tardives Pinot gris"}	Alsace grand cru Steinklotz vendanges tardives Pinot gris	\N
11922	46	Alsace grand cru Steinklotz	AOC -	AOP -	{"fra": "Alsace grand cru Steinklotz vendanges tardives Riesling"}	Alsace grand cru Steinklotz vendanges tardives Riesling	\N
11923	47	Alsace grand cru Vorbourg	AOC -	AOP -	{"fra": "Alsace grand cru Vorbourg Gewurztraminer"}	Alsace grand cru Vorbourg Gewurztraminer	\N
11924	47	Alsace grand cru Vorbourg	AOC -	AOP -	{"fra": "Alsace grand cru Vorbourg Muscat"}	Alsace grand cru Vorbourg Muscat	\N
11925	47	Alsace grand cru Vorbourg	AOC -	AOP -	{"fra": "Alsace grand cru Vorbourg Muscat Ottonel"}	Alsace grand cru Vorbourg Muscat Ottonel	\N
11926	47	Alsace grand cru Vorbourg	AOC -	AOP -	{"fra": "Alsace grand cru Vorbourg Pinot gris"}	Alsace grand cru Vorbourg Pinot gris	\N
11927	47	Alsace grand cru Vorbourg	AOC -	AOP -	{"fra": "Alsace grand cru Vorbourg sélection de grains nobles Gewurztraminer"}	Alsace grand cru Vorbourg sélection de grains nobles Gewurztraminer	\N
11928	47	Alsace grand cru Vorbourg	AOC -	AOP -	{"fra": "Alsace grand cru Vorbourg sélection de grains nobles Muscat"}	Alsace grand cru Vorbourg sélection de grains nobles Muscat	\N
11929	47	Alsace grand cru Vorbourg	AOC -	AOP -	{"fra": "Alsace grand cru Vorbourg Riesling"}	Alsace grand cru Vorbourg Riesling	\N
11930	47	Alsace grand cru Vorbourg	AOC -	AOP -	{"fra": "Alsace grand cru Vorbourg sélection de grains nobles Pinot gris"}	Alsace grand cru Vorbourg sélection de grains nobles Pinot gris	\N
11931	47	Alsace grand cru Vorbourg	AOC -	AOP -	{"fra": "Alsace grand cru Vorbourg sélection de grains nobles Riesling"}	Alsace grand cru Vorbourg sélection de grains nobles Riesling	\N
11932	47	Alsace grand cru Vorbourg	AOC -	AOP -	{"fra": "Alsace grand cru Vorbourg sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Vorbourg sélection de grains nobles Muscat Ottonel	\N
11933	47	Alsace grand cru Vorbourg	AOC -	AOP -	{"fra": "Alsace grand cru Vorbourg vendanges tardives Gewurztraminer"}	Alsace grand cru Vorbourg vendanges tardives Gewurztraminer	\N
11934	47	Alsace grand cru Vorbourg	AOC -	AOP -	{"fra": "Alsace grand cru Vorbourg vendanges tardives Muscat"}	Alsace grand cru Vorbourg vendanges tardives Muscat	\N
11935	47	Alsace grand cru Vorbourg	AOC -	AOP -	{"fra": "Alsace grand cru Vorbourg vendanges tardives Muscat Ottonel"}	Alsace grand cru Vorbourg vendanges tardives Muscat Ottonel	\N
11936	47	Alsace grand cru Vorbourg	AOC -	AOP -	{"fra": "Alsace grand cru Vorbourg vendanges tardives Pinot gris"}	Alsace grand cru Vorbourg vendanges tardives Pinot gris	\N
11937	47	Alsace grand cru Vorbourg	AOC -	AOP -	{"fra": "Alsace grand cru Vorbourg vendanges tardives Riesling"}	Alsace grand cru Vorbourg vendanges tardives Riesling	\N
11938	48	Alsace grand cru Wiebelsberg	AOC -	AOP -	{"fra": "Alsace grand cru Wiebelsberg Gewurztraminer"}	Alsace grand cru Wiebelsberg Gewurztraminer	\N
11939	48	Alsace grand cru Wiebelsberg	AOC -	AOP -	{"fra": "Alsace grand cru Wiebelsberg Muscat"}	Alsace grand cru Wiebelsberg Muscat	\N
11940	48	Alsace grand cru Wiebelsberg	AOC -	AOP -	{"fra": "Alsace grand cru Wiebelsberg Muscat Ottonel"}	Alsace grand cru Wiebelsberg Muscat Ottonel	\N
11941	48	Alsace grand cru Wiebelsberg	AOC -	AOP -	{"fra": "Alsace grand cru Wiebelsberg Pinot gris"}	Alsace grand cru Wiebelsberg Pinot gris	\N
11942	48	Alsace grand cru Wiebelsberg	AOC -	AOP -	{"fra": "Alsace grand cru Wiebelsberg Riesling"}	Alsace grand cru Wiebelsberg Riesling	\N
12395	255	Beaujolais Chânes	AOC -	AOP -	{"fra": "Beaujolais Chânes rosé"}	Beaujolais Chânes rosé	\N
11943	48	Alsace grand cru Wiebelsberg	AOC -	AOP -	{"fra": "Alsace grand cru Wiebelsberg sélection de grains nobles Gewurztraminer"}	Alsace grand cru Wiebelsberg sélection de grains nobles Gewurztraminer	\N
11944	48	Alsace grand cru Wiebelsberg	AOC -	AOP -	{"fra": "Alsace grand cru Wiebelsberg sélection de grains nobles Muscat"}	Alsace grand cru Wiebelsberg sélection de grains nobles Muscat	\N
11945	48	Alsace grand cru Wiebelsberg	AOC -	AOP -	{"fra": "Alsace grand cru Wiebelsberg sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Wiebelsberg sélection de grains nobles Muscat Ottonel	\N
11946	48	Alsace grand cru Wiebelsberg	AOC -	AOP -	{"fra": "Alsace grand cru Wiebelsberg sélection de grains nobles Pinot gris"}	Alsace grand cru Wiebelsberg sélection de grains nobles Pinot gris	\N
11947	48	Alsace grand cru Wiebelsberg	AOC -	AOP -	{"fra": "Alsace grand cru Wiebelsberg sélection de grains nobles Riesling"}	Alsace grand cru Wiebelsberg sélection de grains nobles Riesling	\N
11948	48	Alsace grand cru Wiebelsberg	AOC -	AOP -	{"fra": "Alsace grand cru Wiebelsberg vendanges tardives Gewurztraminer"}	Alsace grand cru Wiebelsberg vendanges tardives Gewurztraminer	\N
11949	48	Alsace grand cru Wiebelsberg	AOC -	AOP -	{"fra": "Alsace grand cru Wiebelsberg vendanges tardives Muscat"}	Alsace grand cru Wiebelsberg vendanges tardives Muscat	\N
11950	48	Alsace grand cru Wiebelsberg	AOC -	AOP -	{"fra": "Alsace grand cru Wiebelsberg vendanges tardives Muscat Ottonel"}	Alsace grand cru Wiebelsberg vendanges tardives Muscat Ottonel	\N
11951	48	Alsace grand cru Wiebelsberg	AOC -	AOP -	{"fra": "Alsace grand cru Wiebelsberg vendanges tardives Pinot gris"}	Alsace grand cru Wiebelsberg vendanges tardives Pinot gris	\N
11952	48	Alsace grand cru Wiebelsberg	AOC -	AOP -	{"fra": "Alsace grand cru Wiebelsberg vendanges tardives Riesling"}	Alsace grand cru Wiebelsberg vendanges tardives Riesling	\N
11953	49	Alsace grand cru Wineck-Schlossberg	AOC -	AOP -	{"fra": "Alsace grand cru Wineck-Schlossberg Gewurztraminer"}	Alsace grand cru Wineck-Schlossberg Gewurztraminer	\N
11954	49	Alsace grand cru Wineck-Schlossberg	AOC -	AOP -	{"fra": "Alsace grand cru Wineck-Schlossberg Muscat"}	Alsace grand cru Wineck-Schlossberg Muscat	\N
11955	49	Alsace grand cru Wineck-Schlossberg	AOC -	AOP -	{"fra": "Alsace grand cru Wineck-Schlossberg Muscat Ottonel"}	Alsace grand cru Wineck-Schlossberg Muscat Ottonel	\N
11956	49	Alsace grand cru Wineck-Schlossberg	AOC -	AOP -	{"fra": "Alsace grand cru Wineck-Schlossberg Pinot gris"}	Alsace grand cru Wineck-Schlossberg Pinot gris	\N
11957	49	Alsace grand cru Wineck-Schlossberg	AOC -	AOP -	{"fra": "Alsace grand cru Wineck-Schlossberg Riesling"}	Alsace grand cru Wineck-Schlossberg Riesling	\N
11958	49	Alsace grand cru Wineck-Schlossberg	AOC -	AOP -	{"fra": "Alsace grand cru Wineck-Schlossberg sélection de grains nobles Gewurztraminer"}	Alsace grand cru Wineck-Schlossberg sélection de grains nobles Gewurztraminer	\N
11959	49	Alsace grand cru Wineck-Schlossberg	AOC -	AOP -	{"fra": "Alsace grand cru Wineck-Schlossberg sélection de grains nobles Muscat"}	Alsace grand cru Wineck-Schlossberg sélection de grains nobles Muscat	\N
11960	49	Alsace grand cru Wineck-Schlossberg	AOC -	AOP -	{"fra": "Alsace grand cru Wineck-Schlossberg sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Wineck-Schlossberg sélection de grains nobles Muscat Ottonel	\N
11961	49	Alsace grand cru Wineck-Schlossberg	AOC -	AOP -	{"fra": "Alsace grand cru Wineck-Schlossberg sélection de grains nobles Pinot gris"}	Alsace grand cru Wineck-Schlossberg sélection de grains nobles Pinot gris	\N
11962	49	Alsace grand cru Wineck-Schlossberg	AOC -	AOP -	{"fra": "Alsace grand cru Wineck-Schlossberg sélection de grains nobles Riesling"}	Alsace grand cru Wineck-Schlossberg sélection de grains nobles Riesling	\N
11963	49	Alsace grand cru Wineck-Schlossberg	AOC -	AOP -	{"fra": "Alsace grand cru Wineck-Schlossberg vendanges tardives Gewurztraminer"}	Alsace grand cru Wineck-Schlossberg vendanges tardives Gewurztraminer	\N
11964	49	Alsace grand cru Wineck-Schlossberg	AOC -	AOP -	{"fra": "Alsace grand cru Wineck-Schlossberg vendanges tardives Muscat"}	Alsace grand cru Wineck-Schlossberg vendanges tardives Muscat	\N
11965	49	Alsace grand cru Wineck-Schlossberg	AOC -	AOP -	{"fra": "Alsace grand cru Wineck-Schlossberg vendanges tardives Muscat Ottonel"}	Alsace grand cru Wineck-Schlossberg vendanges tardives Muscat Ottonel	\N
11966	49	Alsace grand cru Wineck-Schlossberg	AOC -	AOP -	{"fra": "Alsace grand cru Wineck-Schlossberg vendanges tardives Pinot gris"}	Alsace grand cru Wineck-Schlossberg vendanges tardives Pinot gris	\N
11967	49	Alsace grand cru Wineck-Schlossberg	AOC -	AOP -	{"fra": "Alsace grand cru Wineck-Schlossberg vendanges tardives Riesling"}	Alsace grand cru Wineck-Schlossberg vendanges tardives Riesling	\N
8785	2034	Isère	\N	IGP -	{"fra": "Isère rosé"}	Isère rosé	\N
11968	50	Alsace grand cru Winzenberg	AOC -	AOP -	{"fra": "Alsace grand cru Winzenberg Gewurztraminer"}	Alsace grand cru Winzenberg Gewurztraminer	\N
11969	50	Alsace grand cru Winzenberg	AOC -	AOP -	{"fra": "Alsace grand cru Winzenberg Muscat"}	Alsace grand cru Winzenberg Muscat	\N
11970	50	Alsace grand cru Winzenberg	AOC -	AOP -	{"fra": "Alsace grand cru Winzenberg Muscat Ottonel"}	Alsace grand cru Winzenberg Muscat Ottonel	\N
11971	50	Alsace grand cru Winzenberg	AOC -	AOP -	{"fra": "Alsace grand cru Winzenberg Pinot gris"}	Alsace grand cru Winzenberg Pinot gris	\N
11972	50	Alsace grand cru Winzenberg	AOC -	AOP -	{"fra": "Alsace grand cru Winzenberg Riesling"}	Alsace grand cru Winzenberg Riesling	\N
11973	50	Alsace grand cru Winzenberg	AOC -	AOP -	{"fra": "Alsace grand cru Winzenberg sélection de grains nobles Gewurztraminer"}	Alsace grand cru Winzenberg sélection de grains nobles Gewurztraminer	\N
11974	50	Alsace grand cru Winzenberg	AOC -	AOP -	{"fra": "Alsace grand cru Winzenberg sélection de grains nobles Muscat"}	Alsace grand cru Winzenberg sélection de grains nobles Muscat	\N
11975	50	Alsace grand cru Winzenberg	AOC -	AOP -	{"fra": "Alsace grand cru Winzenberg sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Winzenberg sélection de grains nobles Muscat Ottonel	\N
11976	50	Alsace grand cru Winzenberg	AOC -	AOP -	{"fra": "Alsace grand cru Winzenberg sélection de grains nobles Pinot gris"}	Alsace grand cru Winzenberg sélection de grains nobles Pinot gris	\N
11977	50	Alsace grand cru Winzenberg	AOC -	AOP -	{"fra": "Alsace grand cru Winzenberg sélection de grains nobles Riesling"}	Alsace grand cru Winzenberg sélection de grains nobles Riesling	\N
11978	50	Alsace grand cru Winzenberg	AOC -	AOP -	{"fra": "Alsace grand cru Winzenberg vendanges tardives Gewurztraminer"}	Alsace grand cru Winzenberg vendanges tardives Gewurztraminer	\N
12465	265	Beaujolais Leynes	AOC -	AOP -	{"fra": "Beaujolais Leynes rouge"}	Beaujolais Leynes rouge	\N
11979	50	Alsace grand cru Winzenberg	AOC -	AOP -	{"fra": "Alsace grand cru Winzenberg vendanges tardives Muscat"}	Alsace grand cru Winzenberg vendanges tardives Muscat	\N
11980	50	Alsace grand cru Winzenberg	AOC -	AOP -	{"fra": "Alsace grand cru Winzenberg vendanges tardives Muscat Ottonel"}	Alsace grand cru Winzenberg vendanges tardives Muscat Ottonel	\N
11981	50	Alsace grand cru Winzenberg	AOC -	AOP -	{"fra": "Alsace grand cru Winzenberg vendanges tardives Pinot gris"}	Alsace grand cru Winzenberg vendanges tardives Pinot gris	\N
11982	50	Alsace grand cru Winzenberg	AOC -	AOP -	{"fra": "Alsace grand cru Winzenberg vendanges tardives Riesling"}	Alsace grand cru Winzenberg vendanges tardives Riesling	\N
11983	51	Alsace grand cru Zinnkoepfle	AOC -	AOP -	{"fra": "Alsace grand cru Zinnkoepfle Gewurztraminer"}	Alsace grand cru Zinnkoepfle Gewurztraminer	\N
11984	51	Alsace grand cru Zinnkoepfle	AOC -	AOP -	{"fra": "Alsace grand cru Zinnkoepfle Muscat"}	Alsace grand cru Zinnkoepfle Muscat	\N
11985	51	Alsace grand cru Zinnkoepfle	AOC -	AOP -	{"fra": "Alsace grand cru Zinnkoepfle Muscat Ottonel"}	Alsace grand cru Zinnkoepfle Muscat Ottonel	\N
11986	51	Alsace grand cru Zinnkoepfle	AOC -	AOP -	{"fra": "Alsace grand cru Zinnkoepfle Pinot gris"}	Alsace grand cru Zinnkoepfle Pinot gris	\N
11987	51	Alsace grand cru Zinnkoepfle	AOC -	AOP -	{"fra": "Alsace grand cru Zinnkoepfle Riesling"}	Alsace grand cru Zinnkoepfle Riesling	\N
11988	51	Alsace grand cru Zinnkoepfle	AOC -	AOP -	{"fra": "Alsace grand cru Zinnkoepfle sélection de grains nobles Gewurztraminer"}	Alsace grand cru Zinnkoepfle sélection de grains nobles Gewurztraminer	\N
11989	51	Alsace grand cru Zinnkoepfle	AOC -	AOP -	{"fra": "Alsace grand cru Zinnkoepfle sélection de grains nobles Muscat"}	Alsace grand cru Zinnkoepfle sélection de grains nobles Muscat	\N
11990	51	Alsace grand cru Zinnkoepfle	AOC -	AOP -	{"fra": "Alsace grand cru Zinnkoepfle sélection de grains nobles Muscat Ottonel"}	Alsace grand cru Zinnkoepfle sélection de grains nobles Muscat Ottonel	\N
11991	51	Alsace grand cru Zinnkoepfle	AOC -	AOP -	{"fra": "Alsace grand cru Zinnkoepfle sélection de grains nobles Pinot gris"}	Alsace grand cru Zinnkoepfle sélection de grains nobles Pinot gris	\N
11992	51	Alsace grand cru Zinnkoepfle	AOC -	AOP -	{"fra": "Alsace grand cru Zinnkoepfle sélection de grains nobles Riesling"}	Alsace grand cru Zinnkoepfle sélection de grains nobles Riesling	\N
11993	51	Alsace grand cru Zinnkoepfle	AOC -	AOP -	{"fra": "Alsace grand cru Zinnkoepfle vendanges tardives Gewurztraminer"}	Alsace grand cru Zinnkoepfle vendanges tardives Gewurztraminer	\N
11994	51	Alsace grand cru Zinnkoepfle	AOC -	AOP -	{"fra": "Alsace grand cru Zinnkoepfle vendanges tardives Muscat"}	Alsace grand cru Zinnkoepfle vendanges tardives Muscat	\N
11995	51	Alsace grand cru Zinnkoepfle	AOC -	AOP -	{"fra": "Alsace grand cru Zinnkoepfle vendanges tardives Pinot gris"}	Alsace grand cru Zinnkoepfle vendanges tardives Pinot gris	\N
11996	51	Alsace grand cru Zinnkoepfle	AOC -	AOP -	{"fra": "Alsace grand cru Zinnkoepfle vendanges tardives Muscat Ottonel"}	Alsace grand cru Zinnkoepfle vendanges tardives Muscat Ottonel	\N
11997	51	Alsace grand cru Zinnkoepfle	AOC -	AOP -	{"fra": "Alsace grand cru Zinnkoepfle vendanges tardives Riesling"}	Alsace grand cru Zinnkoepfle vendanges tardives Riesling	\N
11998	52	Alsace grand cru Zotzenberg	AOC -	AOP -	{"fra": "Alsace grand cru Zotzenberg Gewurztraminer"}	Alsace grand cru Zotzenberg Gewurztraminer	\N
11999	52	Alsace grand cru Zotzenberg	AOC -	AOP -	{"fra": "Alsace grand cru Zotzenberg Pinot gris"}	Alsace grand cru Zotzenberg Pinot gris	\N
12000	52	Alsace grand cru Zotzenberg	AOC -	AOP -	{"fra": "Alsace grand cru Zotzenberg Riesling"}	Alsace grand cru Zotzenberg Riesling	\N
12001	52	Alsace grand cru Zotzenberg	AOC -	AOP -	{"fra": "Alsace grand cru Zotzenberg sélection de grains nobles Gewurztraminer"}	Alsace grand cru Zotzenberg sélection de grains nobles Gewurztraminer	\N
12002	52	Alsace grand cru Zotzenberg	AOC -	AOP -	{"fra": "Alsace grand cru Zotzenberg sélection de grains nobles Pinot gris"}	Alsace grand cru Zotzenberg sélection de grains nobles Pinot gris	\N
12003	52	Alsace grand cru Zotzenberg	AOC -	AOP -	{"fra": "Alsace grand cru Zotzenberg sélection de grains nobles Riesling"}	Alsace grand cru Zotzenberg sélection de grains nobles Riesling	\N
12004	52	Alsace grand cru Zotzenberg	AOC -	AOP -	{"fra": "Alsace grand cru Zotzenberg Sylvaner"}	Alsace grand cru Zotzenberg Sylvaner	\N
12005	52	Alsace grand cru Zotzenberg	AOC -	AOP -	{"fra": "Alsace grand cru Zotzenberg vendanges tardives Gewurztraminer"}	Alsace grand cru Zotzenberg vendanges tardives Gewurztraminer	\N
12006	52	Alsace grand cru Zotzenberg	AOC -	AOP -	{"fra": "Alsace grand cru Zotzenberg vendanges tardives Pinot gris"}	Alsace grand cru Zotzenberg vendanges tardives Pinot gris	\N
12007	52	Alsace grand cru Zotzenberg	AOC -	AOP -	{"fra": "Alsace grand cru Zotzenberg vendanges tardives Riesling"}	Alsace grand cru Zotzenberg vendanges tardives Riesling	\N
13275	2	Alsace Klevener de Heiligenstein	AOC -	AOP -	{"fra": "Alsace Klevener de Heiligenstein (Klevener)"}	Alsace Klevener de Heiligenstein (Klevener)	\N
13276	2311	Alsace Ottrott	AOC -	AOP -	{"fra": "Alsace Ottrott rouge"}	Alsace Ottrott rouge	\N
13278	2312	Alsace Rodern	AOC -	AOP -	{"fra": "Alsace Rodern rouge"}	Alsace Rodern rouge	\N
13280	2313	Alsace Saint-Hippolyte	AOC -	AOP -	{"fra": "Alsace Saint-Hippolyte rouge"}	Alsace Saint-Hippolyte rouge	\N
13281	2314	Alsace Scherwiller	AOC -	AOP -	{"fra": "Alsace Scherwiller blanc (Riesling)"}	Alsace Scherwiller blanc (Riesling)	\N
13282	2314	Alsace Scherwiller	AOC -	AOP -	{"fra": "Alsace Scherwiller sélection de grains nobles (Riesling)"}	Alsace Scherwiller sélection de grains nobles (Riesling)	\N
13283	2314	Alsace Scherwiller	AOC -	AOP -	{"fra": "Alsace Scherwiller vendanges tardives (Riesling)"}	Alsace Scherwiller vendanges tardives (Riesling)	\N
13217	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace blanc Auxerrois"}	Alsace blanc Auxerrois	\N
13218	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace blanc Chasselas ou Gutedel"}	Alsace blanc Chasselas ou Gutedel	\N
13219	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace blanc Gewurztraminer"}	Alsace blanc Gewurztraminer	\N
13220	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace blanc Muscat"}	Alsace blanc Muscat	\N
13221	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace blanc Muscat Ottonel"}	Alsace blanc Muscat Ottonel	\N
13222	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace blanc Pinot blanc"}	Alsace blanc Pinot blanc	\N
13224	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace blanc Pinot ou Klevner"}	Alsace blanc Pinot ou Klevner	\N
13225	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace blanc Riesling"}	Alsace blanc Riesling	\N
13226	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace blanc Sylvaner"}	Alsace blanc Sylvaner	\N
13243	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace vendanges tardives Riesling"}	Alsace vendanges tardives Riesling	\N
13244	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace vendanges tardives Pinot gris"}	Alsace vendanges tardives Pinot gris	\N
13245	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace vendanges tardives Muscat Ottonel"}	Alsace vendanges tardives Muscat Ottonel	\N
13246	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace vendanges tardives Muscat"}	Alsace vendanges tardives Muscat	\N
13247	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace vendanges tardives Gewurztraminer"}	Alsace vendanges tardives Gewurztraminer	\N
8786	2034	Isère	\N	IGP -	{"fra": "Isère rouge"}	Isère rouge	\N
13264	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace suivi d'un nom de lieu-dit vendanges tardives Riesling"}	Alsace suivi d'un nom de lieu-dit vendanges tardives Riesling	\N
13265	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace suivi d'un nom de lieu-dit vendanges tardives Pinot Gris"}	Alsace suivi d'un nom de lieu-dit vendanges tardives Pinot Gris	\N
13266	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace suivi d'un nom de lieu-dit vendanges tardives Muscat Ottonel"}	Alsace suivi d'un nom de lieu-dit vendanges tardives Muscat Ottonel	\N
13267	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace suivi d'un nom de lieu-dit vendanges tardives Muscat"}	Alsace suivi d'un nom de lieu-dit vendanges tardives Muscat	\N
13268	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace suivi d'un nom de lieu-dit vendanges tardives Gewurztraminer"}	Alsace suivi d'un nom de lieu-dit vendanges tardives Gewurztraminer	\N
13269	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace suivi d'un nom de lieu-dit sélection de sélection de grains nobles Riesling"}	Alsace suivi d'un nom de lieu-dit sélection de sélection de grains nobles Riesling	\N
13270	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace suivi d'un nom de lieu-dit sélection de sélection de grains nobles Pinot Gris"}	Alsace suivi d'un nom de lieu-dit sélection de sélection de grains nobles Pinot Gris	\N
13271	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace suivi d'un nom de lieu-dit sélection de sélection de grains nobles Muscat Ottonel"}	Alsace suivi d'un nom de lieu-dit sélection de sélection de grains nobles Muscat Ottonel	\N
13272	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace suivi d'un nom de lieu-dit sélection de sélection de grains nobles Muscat"}	Alsace suivi d'un nom de lieu-dit sélection de sélection de grains nobles Muscat	\N
13273	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace suivi d'un nom de lieu-dit sélection de sélection de grains nobles Gewurztraminer"}	Alsace suivi d'un nom de lieu-dit sélection de sélection de grains nobles Gewurztraminer	\N
13274	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace suivi d'un nom de lieu-dit rouge (Pinot Noir)"}	Alsace suivi d'un nom de lieu-dit rouge (Pinot Noir)	\N
13277	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace rosé (Pinot noir)"}	Alsace rosé (Pinot noir)	\N
13279	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace rouge (Pinot noir)"}	Alsace rouge (Pinot noir)	\N
13284	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace sélection de grains nobles Gewurztraminer"}	Alsace sélection de grains nobles Gewurztraminer	\N
13285	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace sélection de grains nobles Muscat"}	Alsace sélection de grains nobles Muscat	\N
13286	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace sélection de grains nobles Muscat Ottonel"}	Alsace sélection de grains nobles Muscat Ottonel	\N
13287	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace sélection de grains nobles Pinot gris"}	Alsace sélection de grains nobles Pinot gris	\N
13288	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace sélection de grains nobles Riesling"}	Alsace sélection de grains nobles Riesling	\N
13289	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace suivi d'un nom de lieu-dit blanc (Edelzwicker)"}	Alsace suivi d'un nom de lieu-dit blanc (Edelzwicker)	\N
13290	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace suivi d'un nom de lieu-dit blanc Auxerrois"}	Alsace suivi d'un nom de lieu-dit blanc Auxerrois	\N
13291	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace suivi d'un nom de lieu-dit blanc Chasselas ou Gutedel"}	Alsace suivi d'un nom de lieu-dit blanc Chasselas ou Gutedel	\N
13292	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace suivi d'un nom de lieu-dit blanc Gewurztraminer"}	Alsace suivi d'un nom de lieu-dit blanc Gewurztraminer	\N
13293	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace suivi d'un nom de lieu-dit blanc Muscat"}	Alsace suivi d'un nom de lieu-dit blanc Muscat	\N
13294	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace suivi d'un nom de lieu-dit blanc Muscat Ottonel"}	Alsace suivi d'un nom de lieu-dit blanc Muscat Ottonel	\N
13295	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace suivi d'un nom de lieu-dit blanc Pinot Blanc"}	Alsace suivi d'un nom de lieu-dit blanc Pinot Blanc	\N
13296	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace suivi d'un nom de lieu-dit blanc Pinot Gris"}	Alsace suivi d'un nom de lieu-dit blanc Pinot Gris	\N
13297	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace suivi d'un nom de lieu-dit blanc Pinot ou Klevner"}	Alsace suivi d'un nom de lieu-dit blanc Pinot ou Klevner	\N
13298	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace suivi d'un nom de lieu-dit blanc Riesling"}	Alsace suivi d'un nom de lieu-dit blanc Riesling	\N
13299	1	Alsace suivi ou non d’un nom de lieu-dit	AOC -	AOP -	{"fra": "Alsace suivi d'un nom de lieu-dit blanc Sylvaner"}	Alsace suivi d'un nom de lieu-dit blanc Sylvaner	\N
9675	325	Beaune premier cru	AOC -	AOP -	{"fra": "Beaune premier cru rouge"}	Beaune premier cru rouge	\N
13258	2330	Alsace Val Saint Grégoire	AOC -	AOP -	{"fra": "Alsace Val Saint Grégoire vendanges tardives Pinot Gris"}	Alsace Val Saint Grégoire vendanges tardives Pinot Gris	\N
13259	2330	Alsace Val Saint Grégoire	AOC -	AOP -	{"fra": "Alsace Val Saint Grégoire sélection de grains nobles Pinot Gris"}	Alsace Val Saint Grégoire sélection de grains nobles Pinot Gris	\N
13260	2330	Alsace Val Saint Grégoire	AOC -	AOP -	{"fra": "Alsace Val Saint Grégoire Pinot Gris"}	Alsace Val Saint Grégoire Pinot Gris	\N
13261	2330	Alsace Val Saint Grégoire	AOC -	AOP -	{"fra": "Alsace Val Saint Grégoire Pinot Blanc"}	Alsace Val Saint Grégoire Pinot Blanc	\N
13262	2330	Alsace Val Saint Grégoire	AOC -	AOP -	{"fra": "Alsace Val Saint Grégoire blanc"}	Alsace Val Saint Grégoire blanc	\N
13263	2330	Alsace Val Saint Grégoire	AOC -	AOP -	{"fra": "Alsace Val Saint Grégoire Auxerrois"}	Alsace Val Saint Grégoire Auxerrois	\N
13248	2329	Alsace Vallée Noble	AOC -	AOP -	{"fra": "Alsace Vallée Noble vendanges tardives Riesling"}	Alsace Vallée Noble vendanges tardives Riesling	\N
13249	2329	Alsace Vallée Noble	AOC -	AOP -	{"fra": "Alsace Vallée Noble vendanges tardives Pinot Gris"}	Alsace Vallée Noble vendanges tardives Pinot Gris	\N
13250	2329	Alsace Vallée Noble	AOC -	AOP -	{"fra": "Alsace Vallée Noble vendanges tardives Gewurztraminer"}	Alsace Vallée Noble vendanges tardives Gewurztraminer	\N
13251	2329	Alsace Vallée Noble	AOC -	AOP -	{"fra": "Alsace Vallée Noble sélection de grains nobles Riesling"}	Alsace Vallée Noble sélection de grains nobles Riesling	\N
13252	2329	Alsace Vallée Noble	AOC -	AOP -	{"fra": "Alsace Vallée Noble sélection de grains nobles Pinot Gris"}	Alsace Vallée Noble sélection de grains nobles Pinot Gris	\N
13253	2329	Alsace Vallée Noble	AOC -	AOP -	{"fra": "Alsace Vallée Noble sélection de grains nobles Gewurztraminer"}	Alsace Vallée Noble sélection de grains nobles Gewurztraminer	\N
13254	2329	Alsace Vallée Noble	AOC -	AOP -	{"fra": "Alsace Vallée Noble Riesling"}	Alsace Vallée Noble Riesling	\N
13255	2329	Alsace Vallée Noble	AOC -	AOP -	{"fra": "Alsace Vallée Noble Pinot Gris"}	Alsace Vallée Noble Pinot Gris	\N
13256	2329	Alsace Vallée Noble	AOC -	AOP -	{"fra": "Alsace Vallée Noble Gewurztraminer"}	Alsace Vallée Noble Gewurztraminer	\N
13257	2329	Alsace Vallée Noble	AOC -	AOP -	{"fra": "Alsace Vallée Noble blanc"}	Alsace Vallée Noble blanc	\N
13240	2331	Alsace Wolxheim	AOC -	AOP -	{"fra": "Alsace Wolxheim vendanges tardives"}	Alsace Wolxheim vendanges tardives	\N
13241	2331	Alsace Wolxheim	AOC -	AOP -	{"fra": "Alsace Wolxheim sélection de grains nobles"}	Alsace Wolxheim sélection de grains nobles	\N
13242	2331	Alsace Wolxheim	AOC -	AOP -	{"fra": "Alsace Wolxheim blanc"}	Alsace Wolxheim blanc	\N
3477	1607	Anchois de Collioure	\N	IGP -	{"fra": "Anchois de Collioure"}	Anchois de Collioure	IG/23/96
15051	158	Anjou	AOC -	AOP -	{"fra": "Anjou blanc"}	Anjou blanc	\N
15054	158	Anjou	AOC -	AOP -	{"fra": "Anjou mousseux blanc"}	Anjou mousseux blanc	\N
15055	158	Anjou	AOC -	AOP -	{"fra": "Anjou mousseux rosé"}	Anjou mousseux rosé	\N
15056	158	Anjou	AOC -	AOP -	{"fra": "Anjou rouge"}	Anjou rouge	\N
15057	158	Anjou	AOC -	AOP -	{"fra": "Cabernet d'Anjou"}	Cabernet d'Anjou	\N
15058	158	Anjou	AOC -	AOP -	{"fra": "Cabernet d'Anjou nouveau ou primeur"}	Cabernet d'Anjou nouveau ou primeur	\N
15059	158	Anjou	AOC -	AOP -	{"fra": "Rosé d'Anjou"}	Rosé d'Anjou	\N
15060	158	Anjou	AOC -	AOP -	{"fra": "Rosé d'Anjou nouveau ou primeur"}	Rosé d'Anjou nouveau ou primeur	\N
16087	218	Anjou Brissac	AOC -	AOP -	{"fra": "Anjou Brissac"}	Anjou Brissac	\N
15052	159	Anjou gamay	AOC -	AOP -	{"fra": "Anjou gamay"}	Anjou gamay	\N
15053	159	Anjou gamay	AOC -	AOP -	{"fra": "Anjou gamay nouveau ou primeur"}	Anjou gamay nouveau ou primeur	\N
15124	161	Anjou Villages	AOC -	AOP -	{"fra": "Anjou Villages"}	Anjou Villages	\N
15162	160	Anjou-Coteaux de la Loire	AOC -	AOP -	{"fra": "Anjou-Coteaux de la Loire"}	Anjou-Coteaux de la Loire	\N
12239	236	Arbois	AOC -	AOP -	{"fra": "Arbois blanc"}	Arbois blanc	\N
12245	236	Arbois	AOC -	AOP -	{"fra": "Arbois rosé"}	Arbois rosé	\N
12246	236	Arbois	AOC -	AOP -	{"fra": "Arbois rouge"}	Arbois rouge	\N
12241	237	Arbois Pupillin	AOC -	AOP -	{"fra": "Arbois Pupillin rosé"}	Arbois Pupillin rosé	\N
12242	237	Arbois Pupillin	AOC -	AOP -	{"fra": "Arbois Pupillin rouge"}	Arbois Pupillin rouge	\N
12243	237	Arbois Pupillin	AOC -	AOP -	{"fra": "Arbois Pupillin vin de paille"}	Arbois Pupillin vin de paille	\N
12244	237	Arbois Pupillin	AOC -	AOP -	{"fra": "Arbois Pupillin vin jaune"}	Arbois Pupillin vin jaune	\N
13536	1977	Ardèche	\N	IGP -	{"fra": "Ardèche blanc"}	Ardèche blanc	\N
13537	1977	Ardèche	\N	IGP -	{"fra": "Ardèche rosé"}	Ardèche rosé	\N
13538	1977	Ardèche	\N	IGP -	{"fra": "Ardèche rouge"}	Ardèche rouge	\N
14105	1977	Ardèche	\N	IGP -	{"fra": "Ardèche primeur ou nouveau blanc"}	Ardèche primeur ou nouveau blanc	\N
14106	1977	Ardèche	\N	IGP -	{"fra": "Ardèche primeur ou nouveau rosé"}	Ardèche primeur ou nouveau rosé	\N
14107	1977	Ardèche	\N	IGP -	{"fra": "Ardèche primeur ou nouveau rouge"}	Ardèche primeur ou nouveau rouge	\N
14098	2292	Ardèche Coteaux de l'Ardèche	\N	IGP -	{"fra": "Ardèche Coteaux de l'Ardèche blanc"}	Ardèche Coteaux de l'Ardèche blanc	\N
14099	2292	Ardèche Coteaux de l'Ardèche	\N	IGP -	{"fra": "Ardèche Coteaux de l'Ardèche primeur ou nouveau blanc"}	Ardèche Coteaux de l'Ardèche primeur ou nouveau blanc	\N
14100	2292	Ardèche Coteaux de l'Ardèche	\N	IGP -	{"fra": "Ardèche Coteaux de l'Ardèche primeur ou nouveau rosé"}	Ardèche Coteaux de l'Ardèche primeur ou nouveau rosé	\N
14101	2292	Ardèche Coteaux de l'Ardèche	\N	IGP -	{"fra": "Ardèche Coteaux de l'Ardèche primeur ou nouveau rouge"}	Ardèche Coteaux de l'Ardèche primeur ou nouveau rouge	\N
14102	2292	Ardèche Coteaux de l'Ardèche	\N	IGP -	{"fra": "Ardèche Coteaux de l'Ardèche rosé"}	Ardèche Coteaux de l'Ardèche rosé	\N
14103	2292	Ardèche Coteaux de l'Ardèche	\N	IGP -	{"fra": "Ardèche Coteaux de l'Ardèche rouge"}	Ardèche Coteaux de l'Ardèche rouge	\N
7848	1980	Ariège	\N	IGP -	{"fra": "Ariège blanc"}	Ariège blanc	\N
8418	1980	Ariège	\N	IGP -	{"fra": "Ariège rosé"}	Ariège rosé	\N
8419	1980	Ariège	\N	IGP -	{"fra": "Ariège rouge"}	Ariège rouge	\N
10359	1980	Ariège	\N	IGP -	{"fra": "Ariège surmûri blanc"}	Ariège surmûri blanc	\N
10363	2293	Ariège Coteaux de la Lèze	\N	IGP -	{"fra": "Ariège Coteaux de la Lèze surmûri blanc"}	Ariège Coteaux de la Lèze surmûri blanc	\N
10364	2293	Ariège Coteaux de la Lèze	\N	IGP -	{"fra": "Ariège Coteaux de la Lèze blanc"}	Ariège Coteaux de la Lèze blanc	\N
10365	2293	Ariège Coteaux de la Lèze	\N	IGP -	{"fra": "Ariège Coteaux de la Lèze rosé"}	Ariège Coteaux de la Lèze rosé	\N
10366	2293	Ariège Coteaux de la Lèze	\N	IGP -	{"fra": "Ariège Coteaux de la Lèze rouge"}	Ariège Coteaux de la Lèze rouge	\N
10367	2293	Ariège Coteaux de la Lèze	\N	IGP -	{"fra": "Ariège Coteaux de la Lèze primeur ou nouveau blanc"}	Ariège Coteaux de la Lèze primeur ou nouveau blanc	\N
10368	2293	Ariège Coteaux de la Lèze	\N	IGP -	{"fra": "Ariège Coteaux de la Lèze primeur ou nouveau rosé"}	Ariège Coteaux de la Lèze primeur ou nouveau rosé	\N
10370	2293	Ariège Coteaux de la Lèze	\N	IGP -	{"fra": "Ariège Coteaux de la Lèze primeur ou nouveau rouge"}	Ariège Coteaux de la Lèze primeur ou nouveau rouge	\N
10371	2294	Ariège Coteaux du Plantaurel	\N	IGP -	{"fra": "Ariège Coteaux du Plantaurel surmûri blanc"}	Ariège Coteaux du Plantaurel surmûri blanc	\N
10372	2294	Ariège Coteaux du Plantaurel	\N	IGP -	{"fra": "Ariège Coteaux du Plantaurel blanc"}	Ariège Coteaux du Plantaurel blanc	\N
10373	2294	Ariège Coteaux du Plantaurel	\N	IGP -	{"fra": "Ariège Coteaux du Plantaurel rosé"}	Ariège Coteaux du Plantaurel rosé	\N
10374	2294	Ariège Coteaux du Plantaurel	\N	IGP -	{"fra": "Ariège Coteaux du Plantaurel rouge"}	Ariège Coteaux du Plantaurel rouge	\N
10375	2294	Ariège Coteaux du Plantaurel	\N	IGP -	{"fra": "Ariège Coteaux du Plantaurel primeur ou nouveau blanc"}	Ariège Coteaux du Plantaurel primeur ou nouveau blanc	\N
10376	2294	Ariège Coteaux du Plantaurel	\N	IGP -	{"fra": "Ariège Coteaux du Plantaurel primeur ou nouveau rosé"}	Ariège Coteaux du Plantaurel primeur ou nouveau rosé	\N
10377	2294	Ariège Coteaux du Plantaurel	\N	IGP -	{"fra": "Ariège Coteaux du Plantaurel primeur ou nouveau rouge"}	Ariège Coteaux du Plantaurel primeur ou nouveau rouge	\N
13188	1953	Armagnac	AOC -	IG - 	{"fra": "Armagnac"}	Armagnac	\N
13387	1955	Armagnac-Ténarèze	AOC -	IG - 	{"fra": "Armagnac Ténarèze"}	Armagnac Ténarèze	\N
4381	1790	Artichaut du Roussillon	\N	IGP -	{"fra": "Artichaut du Roussillon"}	Artichaut du Roussillon	\N
3513	1635	Asperge des Sables des Landes 	\N	IGP -	{"fra": "Asperge des Sables des Landes "}	Asperge des Sables des Landes 	IG/08/98
4334	1743	Asperges du Blayais	\N	IGP -	{"fra": "Asperges du Blayais"}	Asperges du Blayais	\N
7866	1969	Atlantique	\N	IGP -	{"fra": "Atlantique blanc"}	Atlantique blanc	\N
8845	1969	Atlantique	\N	IGP -	{"fra": "Atlantique rosé"}	Atlantique rosé	\N
8846	1969	Atlantique	\N	IGP -	{"fra": "Atlantique rouge"}	Atlantique rouge	\N
10378	1969	Atlantique	\N	IGP -	{"fra": "Atlantique primeur ou nouveau blanc"}	Atlantique primeur ou nouveau blanc	\N
10379	1969	Atlantique	\N	IGP -	{"fra": "Atlantique primeur ou nouveau rosé"}	Atlantique primeur ou nouveau rosé	\N
10380	1969	Atlantique	\N	IGP -	{"fra": "Atlantique primeur ou nouveau rouge"}	Atlantique primeur ou nouveau rouge	\N
7841	1981	Aude	\N	IGP -	{"fra": "Aude blanc"}	Aude blanc	\N
8360	1981	Aude	\N	IGP -	{"fra": "Aude rosé"}	Aude rosé	\N
8361	1981	Aude	\N	IGP -	{"fra": "Aude rouge"}	Aude rouge	\N
10381	1981	Aude	\N	IGP -	{"fra": "Aude primeur ou nouveau blanc"}	Aude primeur ou nouveau blanc	\N
10382	1981	Aude	\N	IGP -	{"fra": "Aude primeur ou nouveau rosé"}	Aude primeur ou nouveau rosé	\N
10383	1981	Aude	\N	IGP -	{"fra": "Aude primeur ou nouveau rouge"}	Aude primeur ou nouveau rouge	\N
10384	2295	Aude Coteaux de la Cabrerisse	\N	IGP -	{"fra": "Aude Coteaux de la Cabrerisse blanc"}	Aude Coteaux de la Cabrerisse blanc	\N
10385	2295	Aude Coteaux de la Cabrerisse	\N	IGP -	{"fra": "Aude Coteaux de la Cabrerisse rosé"}	Aude Coteaux de la Cabrerisse rosé	\N
10386	2295	Aude Coteaux de la Cabrerisse	\N	IGP -	{"fra": "Aude Coteaux de la Cabrerisse rouge"}	Aude Coteaux de la Cabrerisse rouge	\N
10387	2295	Aude Coteaux de la Cabrerisse	\N	IGP -	{"fra": "Aude Coteaux de la Cabrerisse primeur ou nouveau blanc"}	Aude Coteaux de la Cabrerisse primeur ou nouveau blanc	\N
10388	2295	Aude Coteaux de la Cabrerisse	\N	IGP -	{"fra": "Aude Coteaux de la Cabrerisse primeur ou nouveau rosé"}	Aude Coteaux de la Cabrerisse primeur ou nouveau rosé	\N
10389	2295	Aude Coteaux de la Cabrerisse	\N	IGP -	{"fra": "Aude Coteaux de la Cabrerisse primeur ou nouveau rouge"}	Aude Coteaux de la Cabrerisse primeur ou nouveau rouge	\N
10391	2296	Aude Coteaux de Miramont	\N	IGP -	{"fra": "Aude Coteaux de Miramont blanc"}	Aude Coteaux de Miramont blanc	\N
10392	2296	Aude Coteaux de Miramont	\N	IGP -	{"fra": "Aude Coteaux de Miramont rosé"}	Aude Coteaux de Miramont rosé	\N
10393	2296	Aude Coteaux de Miramont	\N	IGP -	{"fra": "Aude Coteaux de Miramont rouge"}	Aude Coteaux de Miramont rouge	\N
10394	2296	Aude Coteaux de Miramont	\N	IGP -	{"fra": "Aude Coteaux de Miramont primeur ou nouveau blanc"}	Aude Coteaux de Miramont primeur ou nouveau blanc	\N
10395	2296	Aude Coteaux de Miramont	\N	IGP -	{"fra": "Aude Coteaux de Miramont primeur ou nouveau rosé"}	Aude Coteaux de Miramont primeur ou nouveau rosé	\N
10396	2296	Aude Coteaux de Miramont	\N	IGP -	{"fra": "Aude Coteaux de Miramont primeur ou nouveau rouge"}	Aude Coteaux de Miramont primeur ou nouveau rouge	\N
10397	2297	Aude Côtes de Lastours	\N	IGP -	{"fra": "Aude Côtes de Lastours blanc"}	Aude Côtes de Lastours blanc	\N
10398	2297	Aude Côtes de Lastours	\N	IGP -	{"fra": "Aude Côtes de Lastours rosé"}	Aude Côtes de Lastours rosé	\N
10399	2297	Aude Côtes de Lastours	\N	IGP -	{"fra": "Aude Côtes de Lastours rouge"}	Aude Côtes de Lastours rouge	\N
10400	2297	Aude Côtes de Lastours	\N	IGP -	{"fra": "Aude Côtes de Lastours primeur ou nouveau blanc"}	Aude Côtes de Lastours primeur ou nouveau blanc	\N
10401	2297	Aude Côtes de Lastours	\N	IGP -	{"fra": "Aude Côtes de Lastours primeur ou nouveau rosé"}	Aude Côtes de Lastours primeur ou nouveau rosé	\N
10402	2297	Aude Côtes de Lastours	\N	IGP -	{"fra": "Aude Côtes de Lastours primeur ou nouveau rouge"}	Aude Côtes de Lastours primeur ou nouveau rouge	\N
10403	2298	Aude Côtes de Prouilhe	\N	IGP -	{"fra": "Aude Côtes de Prouilhe blanc"}	Aude Côtes de Prouilhe blanc	\N
10404	2298	Aude Côtes de Prouilhe	\N	IGP -	{"fra": "Aude Côtes de Prouilhe rosé"}	Aude Côtes de Prouilhe rosé	\N
10405	2298	Aude Côtes de Prouilhe	\N	IGP -	{"fra": "Aude Côtes de Prouilhe rouge"}	Aude Côtes de Prouilhe rouge	\N
10406	2298	Aude Côtes de Prouilhe	\N	IGP -	{"fra": "Aude Côtes de Prouilhe primeur ou nouveau blanc"}	Aude Côtes de Prouilhe primeur ou nouveau blanc	\N
10407	2298	Aude Côtes de Prouilhe	\N	IGP -	{"fra": "Aude Côtes de Prouilhe primeur ou nouveau rosé"}	Aude Côtes de Prouilhe primeur ou nouveau rosé	\N
10409	2298	Aude Côtes de Prouilhe	\N	IGP -	{"fra": "Aude Côtes de Prouilhe primeur ou nouveau rouge"}	Aude Côtes de Prouilhe primeur ou nouveau rouge	\N
10410	2299	Aude Hauterive	\N	IGP -	{"fra": "Aude Hauterive blanc"}	Aude Hauterive blanc	\N
10411	2299	Aude Hauterive	\N	IGP -	{"fra": "Aude Hauterive rosé"}	Aude Hauterive rosé	\N
10412	2299	Aude Hauterive	\N	IGP -	{"fra": "Aude Hauterive rouge"}	Aude Hauterive rouge	\N
10413	2299	Aude Hauterive	\N	IGP -	{"fra": "Aude Hauterive primeur ou nouveau blanc"}	Aude Hauterive primeur ou nouveau blanc	\N
10414	2299	Aude Hauterive	\N	IGP -	{"fra": "Aude Hauterive primeur ou nouveau rosé"}	Aude Hauterive primeur ou nouveau rosé	\N
10415	2299	Aude Hauterive	\N	IGP -	{"fra": "Aude Hauterive primeur ou nouveau rouge"}	Aude Hauterive primeur ou nouveau rouge	\N
10416	2300	Aude La côte rêvée	\N	IGP -	{"fra": "Aude La côte rêvée blanc"}	Aude La côte rêvée blanc	\N
10417	2300	Aude La côte rêvée	\N	IGP -	{"fra": "Aude La côte rêvée rosé"}	Aude La côte rêvée rosé	\N
10418	2300	Aude La côte rêvée	\N	IGP -	{"fra": "Aude La côte rêvée rouge"}	Aude La côte rêvée rouge	\N
10419	2300	Aude La côte rêvée	\N	IGP -	{"fra": "Aude La côte rêvée primeur ou nouveau blanc"}	Aude La côte rêvée primeur ou nouveau blanc	\N
10420	2300	Aude La côte rêvée	\N	IGP -	{"fra": "Aude La côte rêvée primeur ou nouveau rosé"}	Aude La côte rêvée primeur ou nouveau rosé	\N
10421	2300	Aude La côte rêvée	\N	IGP -	{"fra": "Aude La côte rêvée primeur ou nouveau rouge"}	Aude La côte rêvée primeur ou nouveau rouge	\N
10422	2301	Aude Pays de Cucugnan	\N	IGP -	{"fra": "Aude Pays de Cucugnan blanc"}	Aude Pays de Cucugnan blanc	\N
10424	2301	Aude Pays de Cucugnan	\N	IGP -	{"fra": "Aude Pays de Cucugnan rosé"}	Aude Pays de Cucugnan rosé	\N
10425	2301	Aude Pays de Cucugnan	\N	IGP -	{"fra": "Aude Pays de Cucugnan rouge"}	Aude Pays de Cucugnan rouge	\N
10426	2301	Aude Pays de Cucugnan	\N	IGP -	{"fra": "Aude Pays de Cucugnan primeur ou nouveau blanc"}	Aude Pays de Cucugnan primeur ou nouveau blanc	\N
10427	2301	Aude Pays de Cucugnan	\N	IGP -	{"fra": "Aude Pays de Cucugnan primeur ou nouveau rosé"}	Aude Pays de Cucugnan primeur ou nouveau rosé	\N
10428	2301	Aude Pays de Cucugnan	\N	IGP -	{"fra": "Aude Pays de Cucugnan primeur ou nouveau rouge"}	Aude Pays de Cucugnan primeur ou nouveau rouge	\N
10429	2303	Aude Val de Cesse	\N	IGP -	{"fra": "Aude Val de Cesse blanc"}	Aude Val de Cesse blanc	\N
10430	2303	Aude Val de Cesse	\N	IGP -	{"fra": "Aude Val de Cesse rosé"}	Aude Val de Cesse rosé	\N
10431	2303	Aude Val de Cesse	\N	IGP -	{"fra": "Aude Val de Cesse rouge"}	Aude Val de Cesse rouge	\N
10432	2303	Aude Val de Cesse	\N	IGP -	{"fra": "Aude Val de Cesse primeur ou nouveau blanc"}	Aude Val de Cesse primeur ou nouveau blanc	\N
10433	2303	Aude Val de Cesse	\N	IGP -	{"fra": "Aude Val de Cesse primeur ou nouveau rosé"}	Aude Val de Cesse primeur ou nouveau rosé	\N
10434	2303	Aude Val de Cesse	\N	IGP -	{"fra": "Aude Val de Cesse primeur ou nouveau rouge"}	Aude Val de Cesse primeur ou nouveau rouge	\N
10435	2304	Aude Val de Dagne	\N	IGP -	{"fra": "Aude Val de Dagne blanc"}	Aude Val de Dagne blanc	\N
10436	2304	Aude Val de Dagne	\N	IGP -	{"fra": "Aude Val de Dagne rosé"}	Aude Val de Dagne rosé	\N
10437	2304	Aude Val de Dagne	\N	IGP -	{"fra": "Aude Val de Dagne rouge"}	Aude Val de Dagne rouge	\N
10438	2304	Aude Val de Dagne	\N	IGP -	{"fra": "Aude Val de Dagne primeur ou nouveau blanc"}	Aude Val de Dagne primeur ou nouveau blanc	\N
10439	2304	Aude Val de Dagne	\N	IGP -	{"fra": "Aude Val de Dagne primeur ou nouveau rosé"}	Aude Val de Dagne primeur ou nouveau rosé	\N
10441	2304	Aude Val de Dagne	\N	IGP -	{"fra": "Aude Val de Dagne primeur ou nouveau rouge"}	Aude Val de Dagne primeur ou nouveau rouge	\N
6000	238	Auxey-Duresses	AOC -	AOP -	{"fra": "Auxey-Duresses blanc"}	Auxey-Duresses blanc	\N
9547	238	Auxey-Duresses	AOC -	AOP -	{"fra": "Auxey-Duresses rouge ou Auxey-Duresses Côte de Beaune"}	Auxey-Duresses rouge ou Auxey-Duresses Côte de Beaune	\N
9529	248	Auxey-Duresses premier cru	AOC -	AOP -	{"fra": "Auxey-Duresses premier cru blanc"}	Auxey-Duresses premier cru blanc	\N
9546	248	Auxey-Duresses premier cru	AOC -	AOP -	{"fra": "Auxey-Duresses premier cru rouge"}	Auxey-Duresses premier cru rouge	\N
9527	239	Auxey-Duresses premier cru Bas des Duresses	AOC -	AOP -	{"fra": "Auxey-Duresses premier cru Bas des Duresses blanc"}	Auxey-Duresses premier cru Bas des Duresses blanc	\N
9528	239	Auxey-Duresses premier cru Bas des Duresses	AOC -	AOP -	{"fra": "Auxey-Duresses premier cru Bas des Duresses rouge"}	Auxey-Duresses premier cru Bas des Duresses rouge	\N
9530	240	Auxey-Duresses premier cru Climat du Val	AOC -	AOP -	{"fra": "Auxey-Duresses premier cru Climat du Val blanc"}	Auxey-Duresses premier cru Climat du Val blanc	\N
9531	240	Auxey-Duresses premier cru Climat du Val	AOC -	AOP -	{"fra": "Auxey-Duresses premier cru Climat du Val rouge"}	Auxey-Duresses premier cru Climat du Val rouge	\N
9532	241	Auxey-Duresses premier cru Clos du Val	AOC -	AOP -	{"fra": "Auxey-Duresses premier cru Clos du Val blanc"}	Auxey-Duresses premier cru Clos du Val blanc	\N
9533	241	Auxey-Duresses premier cru Clos du Val	AOC -	AOP -	{"fra": "Auxey-Duresses premier cru Clos du Val rouge"}	Auxey-Duresses premier cru Clos du Val rouge	\N
9534	242	Auxey-Duresses premier cru La Chapelle	AOC -	AOP -	{"fra": "Auxey-Duresses premier cru La Chapelle blanc"}	Auxey-Duresses premier cru La Chapelle blanc	\N
9535	242	Auxey-Duresses premier cru La Chapelle	AOC -	AOP -	{"fra": "Auxey-Duresses premier cru La Chapelle rouge"}	Auxey-Duresses premier cru La Chapelle rouge	\N
9536	243	Auxey-Duresses premier cru Les Bréterins	AOC -	AOP -	{"fra": "Auxey-Duresses premier cru Les Bréterins blanc"}	Auxey-Duresses premier cru Les Bréterins blanc	\N
9537	243	Auxey-Duresses premier cru Les Bréterins	AOC -	AOP -	{"fra": "Auxey-Duresses premier cru Les Bréterins rouge"}	Auxey-Duresses premier cru Les Bréterins rouge	\N
9538	244	Auxey-Duresses premier cru Les Duresses	AOC -	AOP -	{"fra": "Auxey-Duresses premier cru Les Duresses blanc"}	Auxey-Duresses premier cru Les Duresses blanc	\N
9539	244	Auxey-Duresses premier cru Les Duresses	AOC -	AOP -	{"fra": "Auxey-Duresses premier cru Les Duresses rouge"}	Auxey-Duresses premier cru Les Duresses rouge	\N
9540	245	Auxey-Duresses premier cru Les Ecussaux	AOC -	AOP -	{"fra": "Auxey-Duresses premier cru Les Ecussaux blanc"}	Auxey-Duresses premier cru Les Ecussaux blanc	\N
9541	245	Auxey-Duresses premier cru Les Ecussaux	AOC -	AOP -	{"fra": "Auxey-Duresses premier cru Les Ecussaux rouge"}	Auxey-Duresses premier cru Les Ecussaux rouge	\N
9542	246	Auxey-Duresses premier cru Les Grands Champs	AOC -	AOP -	{"fra": "Auxey-Duresses premier cru Les Grands Champs blanc"}	Auxey-Duresses premier cru Les Grands Champs blanc	\N
9543	246	Auxey-Duresses premier cru Les Grands Champs	AOC -	AOP -	{"fra": "Auxey-Duresses premier cru Les Grands Champs rouge"}	Auxey-Duresses premier cru Les Grands Champs rouge	\N
9544	247	Auxey-Duresses premier cru Reugne	AOC -	AOP -	{"fra": "Auxey-Duresses premier cru Reugne blanc"}	Auxey-Duresses premier cru Reugne blanc	\N
9545	247	Auxey-Duresses premier cru Reugne	AOC -	AOP -	{"fra": "Auxey-Duresses premier cru Reugne rouge"}	Auxey-Duresses premier cru Reugne rouge	\N
7842	1989	Aveyron	\N	IGP -	{"fra": "Aveyron blanc"}	Aveyron blanc	\N
8401	1989	Aveyron	\N	IGP -	{"fra": "Aveyron rosé"}	Aveyron rosé	\N
8402	1989	Aveyron	\N	IGP -	{"fra": "Aveyron rouge"}	Aveyron rouge	\N
10443	1989	Aveyron	\N	IGP -	{"fra": "Aveyron primeur ou nouveau blanc"}	Aveyron primeur ou nouveau blanc	\N
10444	1989	Aveyron	\N	IGP -	{"fra": "Aveyron primeur ou nouveau rosé"}	Aveyron primeur ou nouveau rosé	\N
10445	1989	Aveyron	\N	IGP -	{"fra": "Aveyron primeur ou nouveau rouge"}	Aveyron primeur ou nouveau rouge	\N
8014	1317	Bandol	AOC -	AOP -	{"fra": "Bandol blanc"}	Bandol blanc	\N
8015	1317	Bandol	AOC -	AOP -	{"fra": "Bandol rosé"}	Bandol rosé	\N
8016	1317	Bandol	AOC -	AOP -	{"fra": "Bandol rouge"}	Bandol rouge	\N
15965	1518	Banon	AOC -	AOP -	{"fra": "Banon"}	Banon	\N
7807	1332	Banyuls	AOC -	AOP -	{"fra": "Banyuls grand cru"}	Banyuls grand cru	\N
9458	1332	Banyuls	AOC -	AOP -	{"fra": "Banyuls grand cru hors d'âge"}	Banyuls grand cru hors d'âge	\N
9459	1332	Banyuls	AOC -	AOP -	{"fra": "Banyuls grand cru rancio"}	Banyuls grand cru rancio	\N
9460	1332	Banyuls	AOC -	AOP -	{"fra": "Banyuls grand cru rancio hors d'âge"}	Banyuls grand cru rancio hors d'âge	\N
14459	1332	Banyuls	AOC -	AOP -	{"fra": "Banyuls ambré"}	Banyuls ambré	\N
14460	1332	Banyuls	AOC -	AOP -	{"fra": "Banyuls blanc"}	Banyuls blanc	\N
14461	1332	Banyuls	AOC -	AOP -	{"fra": "Banyuls rimage"}	Banyuls rimage	\N
14462	1332	Banyuls	AOC -	AOP -	{"fra": "Banyuls rosé"}	Banyuls rosé	\N
14463	1332	Banyuls	AOC -	AOP -	{"fra": "Banyuls traditionnel"}	Banyuls traditionnel	\N
14464	1332	Banyuls	AOC -	AOP -	{"fra": "Banyuls ambré hors d'âge"}	Banyuls ambré hors d'âge	\N
14465	1332	Banyuls	AOC -	AOP -	{"fra": "Banyuls traditionnel hors âge"}	Banyuls traditionnel hors âge	\N
14466	1332	Banyuls	AOC -	AOP -	{"fra": "Banyuls ambré hors âge rancio"}	Banyuls ambré hors âge rancio	\N
14467	1332	Banyuls	AOC -	AOP -	{"fra": "Banyuls ambré rancio"}	Banyuls ambré rancio	\N
14468	1332	Banyuls	AOC -	AOP -	{"fra": "Banyuls traditionnel rancio"}	Banyuls traditionnel rancio	\N
14469	1332	Banyuls	AOC -	AOP -	{"fra": "Banyuls traditionnel rancio hors d'âge"}	Banyuls traditionnel rancio hors d'âge	\N
4266	1577	Barèges-Gavarnie	AOC -	AOP -	{"fra": "Barèges-Gavarnie"}	Barèges-Gavarnie	\N
8022	58	Barsac	AOC -	AOP -	{"fra": "Barsac"}	Barsac	\N
13388	1956	Bas Armagnac	AOC -	IG - 	{"fra": "Bas Armagnac"}	Bas Armagnac	\N
7679	249	Bâtard-Montrachet	AOC -	AOP -	{"fra": "Bâtard-Montrachet"}	Bâtard-Montrachet	\N
7099	1639	Béa du Roussillon	AOC -	AOP -	{"fra": "Béa du Roussillon"}	Béa du Roussillon	\N
14576	59	Béarn	AOC -	AOP -	{"fra": "Béarn blanc"}	Béarn blanc	\N
14577	59	Béarn	AOC -	AOP -	{"fra": "Béarn rosé"}	Béarn rosé	\N
14578	59	Béarn	AOC -	AOP -	{"fra": "Béarn rouge"}	Béarn rouge	\N
4489	1455	Beaufort	AOC -	AOP -	{"fra": "Beaufort"}	Beaufort	\N
12144	250	Beaujolais	AOC -	AOP -	{"fra": "Beaujolais rouge"}	Beaujolais rouge	\N
12388	250	Beaujolais	AOC -	AOP -	{"fra": "Beaujolais blanc"}	Beaujolais blanc	\N
12492	250	Beaujolais	AOC -	AOP -	{"fra": "Beaujolais rosé"}	Beaujolais rosé	\N
12493	250	Beaujolais	AOC -	AOP -	{"fra": "Beaujolais rosé  nouveau ou primeur"}	Beaujolais rosé  nouveau ou primeur	\N
12494	250	Beaujolais	AOC -	AOP -	{"fra": "Beaujolais rouge nouveau ou primeur"}	Beaujolais rouge nouveau ou primeur	\N
12529	250	Beaujolais	AOC -	AOP -	{"fra": "Beaujolais supérieur"}	Beaujolais supérieur	\N
12370	252	Beaujolais Beaujeu	AOC -	AOP -	{"fra": "Beaujolais Beaujeu blanc"}	Beaujolais Beaujeu blanc	\N
12372	252	Beaujolais Beaujeu	AOC -	AOP -	{"fra": "Beaujolais Beaujeu rosé"}	Beaujolais Beaujeu rosé	\N
12373	252	Beaujolais Beaujeu	AOC -	AOP -	{"fra": "Beaujolais Beaujeu rosé nouveau ou primeur"}	Beaujolais Beaujeu rosé nouveau ou primeur	\N
12374	252	Beaujolais Beaujeu	AOC -	AOP -	{"fra": "Beaujolais Beaujeu rouge"}	Beaujolais Beaujeu rouge	\N
12375	252	Beaujolais Beaujeu	AOC -	AOP -	{"fra": "Beaujolais Beaujeu rouge nouveau ou primeur"}	Beaujolais Beaujeu rouge nouveau ou primeur	\N
12383	253	Beaujolais Blacé	AOC -	AOP -	{"fra": "Beaujolais Blacé blanc"}	Beaujolais Blacé blanc	\N
12384	253	Beaujolais Blacé	AOC -	AOP -	{"fra": "Beaujolais Blacé rosé"}	Beaujolais Blacé rosé	\N
12385	253	Beaujolais Blacé	AOC -	AOP -	{"fra": "Beaujolais Blacé rosé nouveau ou primeur"}	Beaujolais Blacé rosé nouveau ou primeur	\N
12386	253	Beaujolais Blacé	AOC -	AOP -	{"fra": "Beaujolais Blacé rouge"}	Beaujolais Blacé rouge	\N
12387	253	Beaujolais Blacé	AOC -	AOP -	{"fra": "Beaujolais Blacé rouge nouveau ou primeur"}	Beaujolais Blacé rouge nouveau ou primeur	\N
12389	254	Beaujolais Cercié	AOC -	AOP -	{"fra": "Beaujolais Cercié blanc"}	Beaujolais Cercié blanc	\N
12390	254	Beaujolais Cercié	AOC -	AOP -	{"fra": "Beaujolais Cercié rosé"}	Beaujolais Cercié rosé	\N
12391	254	Beaujolais Cercié	AOC -	AOP -	{"fra": "Beaujolais Cercié rosé nouveau ou primeur"}	Beaujolais Cercié rosé nouveau ou primeur	\N
12392	254	Beaujolais Cercié	AOC -	AOP -	{"fra": "Beaujolais Cercié rouge"}	Beaujolais Cercié rouge	\N
12393	254	Beaujolais Cercié	AOC -	AOP -	{"fra": "Beaujolais Cercié rouge nouveau ou primeur"}	Beaujolais Cercié rouge nouveau ou primeur	\N
12394	255	Beaujolais Chânes	AOC -	AOP -	{"fra": "Beaujolais Chânes blanc"}	Beaujolais Chânes blanc	\N
12396	255	Beaujolais Chânes	AOC -	AOP -	{"fra": "Beaujolais Chânes rosé nouveau ou primeur"}	Beaujolais Chânes rosé nouveau ou primeur	\N
12397	255	Beaujolais Chânes	AOC -	AOP -	{"fra": "Beaujolais Chânes rouge"}	Beaujolais Chânes rouge	\N
12398	255	Beaujolais Chânes	AOC -	AOP -	{"fra": "Beaujolais Chânes rouge nouveau ou primeur"}	Beaujolais Chânes rouge nouveau ou primeur	\N
12399	256	Beaujolais Charentay	AOC -	AOP -	{"fra": "Beaujolais Charentay blanc"}	Beaujolais Charentay blanc	\N
12400	256	Beaujolais Charentay	AOC -	AOP -	{"fra": "Beaujolais Charentay rosé"}	Beaujolais Charentay rosé	\N
12401	256	Beaujolais Charentay	AOC -	AOP -	{"fra": "Beaujolais Charentay rosé nouveau ou primeur"}	Beaujolais Charentay rosé nouveau ou primeur	\N
12402	256	Beaujolais Charentay	AOC -	AOP -	{"fra": "Beaujolais Charentay rouge"}	Beaujolais Charentay rouge	\N
12403	256	Beaujolais Charentay	AOC -	AOP -	{"fra": "Beaujolais Charentay rouge nouveau ou primeur"}	Beaujolais Charentay rouge nouveau ou primeur	\N
12404	257	Beaujolais Denicé	AOC -	AOP -	{"fra": "Beaujolais Denicé blanc"}	Beaujolais Denicé blanc	\N
12405	257	Beaujolais Denicé	AOC -	AOP -	{"fra": "Beaujolais Denicé rosé"}	Beaujolais Denicé rosé	\N
12406	257	Beaujolais Denicé	AOC -	AOP -	{"fra": "Beaujolais Denicé rosé nouveau ou primeur"}	Beaujolais Denicé rosé nouveau ou primeur	\N
12407	257	Beaujolais Denicé	AOC -	AOP -	{"fra": "Beaujolais Denicé rouge"}	Beaujolais Denicé rouge	\N
12408	257	Beaujolais Denicé	AOC -	AOP -	{"fra": "Beaujolais Denicé rouge nouveau ou primeur"}	Beaujolais Denicé rouge nouveau ou primeur	\N
12409	258	Beaujolais Emeringes	AOC -	AOP -	{"fra": "Beaujolais Emeringes blanc"}	Beaujolais Emeringes blanc	\N
12410	258	Beaujolais Emeringes	AOC -	AOP -	{"fra": "Beaujolais Emeringes rosé"}	Beaujolais Emeringes rosé	\N
12411	258	Beaujolais Emeringes	AOC -	AOP -	{"fra": "Beaujolais Emeringes rosé nouveau ou primeur"}	Beaujolais Emeringes rosé nouveau ou primeur	\N
12412	258	Beaujolais Emeringes	AOC -	AOP -	{"fra": "Beaujolais Emeringes rouge"}	Beaujolais Emeringes rouge	\N
12413	258	Beaujolais Emeringes	AOC -	AOP -	{"fra": "Beaujolais Emeringes rouge nouveau ou primeur"}	Beaujolais Emeringes rouge nouveau ou primeur	\N
12414	259	Beaujolais Jullié	AOC -	AOP -	{"fra": "Beaujolais Jullié blanc"}	Beaujolais Jullié blanc	\N
12415	259	Beaujolais Jullié	AOC -	AOP -	{"fra": "Beaujolais Jullié rosé"}	Beaujolais Jullié rosé	\N
12416	259	Beaujolais Jullié	AOC -	AOP -	{"fra": "Beaujolais Jullié rosé nouveau ou primeur"}	Beaujolais Jullié rosé nouveau ou primeur	\N
12417	259	Beaujolais Jullié	AOC -	AOP -	{"fra": "Beaujolais Jullié rouge"}	Beaujolais Jullié rouge	\N
12418	259	Beaujolais Jullié	AOC -	AOP -	{"fra": "Beaujolais Jullié rouge nouveau ou primeur"}	Beaujolais Jullié rouge nouveau ou primeur	\N
12419	260	Beaujolais La Chapelle-de-Guinchay	AOC -	AOP -	{"fra": "Beaujolais La Chapelle-de-Guinchay blanc"}	Beaujolais La Chapelle-de-Guinchay blanc	\N
12420	260	Beaujolais La Chapelle-de-Guinchay	AOC -	AOP -	{"fra": "Beaujolais La Chapelle-de-Guinchay rosé"}	Beaujolais La Chapelle-de-Guinchay rosé	\N
12421	260	Beaujolais La Chapelle-de-Guinchay	AOC -	AOP -	{"fra": "Beaujolais La Chapelle-de-Guinchay rosé nouveau ou primeur"}	Beaujolais La Chapelle-de-Guinchay rosé nouveau ou primeur	\N
12422	260	Beaujolais La Chapelle-de-Guinchay	AOC -	AOP -	{"fra": "Beaujolais La Chapelle-de-Guinchay rouge"}	Beaujolais La Chapelle-de-Guinchay rouge	\N
12423	260	Beaujolais La Chapelle-de-Guinchay	AOC -	AOP -	{"fra": "Beaujolais La Chapelle-de-Guinchay rouge nouveau ou primeur"}	Beaujolais La Chapelle-de-Guinchay rouge nouveau ou primeur	\N
12424	261	Beaujolais Lancié	AOC -	AOP -	{"fra": "Beaujolais Lancié blanc"}	Beaujolais Lancié blanc	\N
12425	261	Beaujolais Lancié	AOC -	AOP -	{"fra": "Beaujolais Lancié rosé"}	Beaujolais Lancié rosé	\N
12426	261	Beaujolais Lancié	AOC -	AOP -	{"fra": "Beaujolais Lancié rosé nouveau ou primeur"}	Beaujolais Lancié rosé nouveau ou primeur	\N
12427	261	Beaujolais Lancié	AOC -	AOP -	{"fra": "Beaujolais Lancié rouge"}	Beaujolais Lancié rouge	\N
12428	261	Beaujolais Lancié	AOC -	AOP -	{"fra": "Beaujolais Lancié rouge nouveau ou primeur"}	Beaujolais Lancié rouge nouveau ou primeur	\N
12429	262	Beaujolais Lantignié	AOC -	AOP -	{"fra": "Beaujolais Lantignié blanc"}	Beaujolais Lantignié blanc	\N
12430	262	Beaujolais Lantignié	AOC -	AOP -	{"fra": "Beaujolais Lantignié rosé"}	Beaujolais Lantignié rosé	\N
12431	262	Beaujolais Lantignié	AOC -	AOP -	{"fra": "Beaujolais Lantignié rosé nouveau ou primeur"}	Beaujolais Lantignié rosé nouveau ou primeur	\N
12432	262	Beaujolais Lantignié	AOC -	AOP -	{"fra": "Beaujolais Lantignié rouge"}	Beaujolais Lantignié rouge	\N
12433	262	Beaujolais Lantignié	AOC -	AOP -	{"fra": "Beaujolais Lantignié rouge nouveau ou primeur"}	Beaujolais Lantignié rouge nouveau ou primeur	\N
12434	263	Beaujolais Le Perréon	AOC -	AOP -	{"fra": "Beaujolais Le Perréon blanc"}	Beaujolais Le Perréon blanc	\N
12435	263	Beaujolais Le Perréon	AOC -	AOP -	{"fra": "Beaujolais Le Perréon rosé"}	Beaujolais Le Perréon rosé	\N
12436	263	Beaujolais Le Perréon	AOC -	AOP -	{"fra": "Beaujolais Le Perréon rosé nouveau ou primeur"}	Beaujolais Le Perréon rosé nouveau ou primeur	\N
12437	263	Beaujolais Le Perréon	AOC -	AOP -	{"fra": "Beaujolais Le Perréon rouge"}	Beaujolais Le Perréon rouge	\N
12438	263	Beaujolais Le Perréon	AOC -	AOP -	{"fra": "Beaujolais Le Perréon rouge nouveau ou primeur"}	Beaujolais Le Perréon rouge nouveau ou primeur	\N
12447	264	Beaujolais Les Ardillats	AOC -	AOP -	{"fra": "Beaujolais Les Ardillats blanc"}	Beaujolais Les Ardillats blanc	\N
12448	264	Beaujolais Les Ardillats	AOC -	AOP -	{"fra": "Beaujolais Les Ardillats rosé"}	Beaujolais Les Ardillats rosé	\N
12449	264	Beaujolais Les Ardillats	AOC -	AOP -	{"fra": "Beaujolais Les Ardillats rosé nouveau ou primeur"}	Beaujolais Les Ardillats rosé nouveau ou primeur	\N
12450	264	Beaujolais Les Ardillats	AOC -	AOP -	{"fra": "Beaujolais Les Ardillats rouge"}	Beaujolais Les Ardillats rouge	\N
12451	264	Beaujolais Les Ardillats	AOC -	AOP -	{"fra": "Beaujolais Les Ardillats rouge nouveau ou primeur"}	Beaujolais Les Ardillats rouge nouveau ou primeur	\N
12452	265	Beaujolais Leynes	AOC -	AOP -	{"fra": "Beaujolais Leynes blanc"}	Beaujolais Leynes blanc	\N
12453	265	Beaujolais Leynes	AOC -	AOP -	{"fra": "Beaujolais Leynes rosé"}	Beaujolais Leynes rosé	\N
12464	265	Beaujolais Leynes	AOC -	AOP -	{"fra": "Beaujolais Leynes rosé nouveau ou primeur"}	Beaujolais Leynes rosé nouveau ou primeur	\N
12466	265	Beaujolais Leynes	AOC -	AOP -	{"fra": "Beaujolais Leynes rouge nouveau ou primeur"}	Beaujolais Leynes rouge nouveau ou primeur	\N
12467	266	Beaujolais Marchampt	AOC -	AOP -	{"fra": "Beaujolais Marchampt blanc"}	Beaujolais Marchampt blanc	\N
12468	266	Beaujolais Marchampt	AOC -	AOP -	{"fra": "Beaujolais Marchampt rosé"}	Beaujolais Marchampt rosé	\N
12469	266	Beaujolais Marchampt	AOC -	AOP -	{"fra": "Beaujolais Marchampt rosé nouveau ou primeur"}	Beaujolais Marchampt rosé nouveau ou primeur	\N
12470	266	Beaujolais Marchampt	AOC -	AOP -	{"fra": "Beaujolais Marchampt rouge"}	Beaujolais Marchampt rouge	\N
12472	266	Beaujolais Marchampt	AOC -	AOP -	{"fra": "Beaujolais Marchampt rouge nouveau ou primeur"}	Beaujolais Marchampt rouge nouveau ou primeur	\N
12471	267	Beaujolais Montmelas-Saint-Sorlin	AOC -	AOP -	{"fra": "Beaujolais Montmelas-Saint-Sorlin rouge"}	Beaujolais Montmelas-Saint-Sorlin rouge	\N
12473	267	Beaujolais Montmelas-Saint-Sorlin	AOC -	AOP -	{"fra": "Beaujolais Montmelas-Saint-Sorlin blanc"}	Beaujolais Montmelas-Saint-Sorlin blanc	\N
12474	267	Beaujolais Montmelas-Saint-Sorlin	AOC -	AOP -	{"fra": "Beaujolais Montmelas-Saint-Sorlin rosé"}	Beaujolais Montmelas-Saint-Sorlin rosé	\N
12475	267	Beaujolais Montmelas-Saint-Sorlin	AOC -	AOP -	{"fra": "Beaujolais Montmelas-Saint-Sorlin rosé nouveau ou primeur"}	Beaujolais Montmelas-Saint-Sorlin rosé nouveau ou primeur	\N
12476	267	Beaujolais Montmelas-Saint-Sorlin	AOC -	AOP -	{"fra": "Beaujolais Montmelas-Saint-Sorlin rouge nouveau ou primeur"}	Beaujolais Montmelas-Saint-Sorlin rouge nouveau ou primeur	\N
12477	268	Beaujolais Odenas	AOC -	AOP -	{"fra": "Beaujolais Odenas blanc"}	Beaujolais Odenas blanc	\N
12478	268	Beaujolais Odenas	AOC -	AOP -	{"fra": "Beaujolais Odenas rosé"}	Beaujolais Odenas rosé	\N
12479	268	Beaujolais Odenas	AOC -	AOP -	{"fra": "Beaujolais Odenas rosé nouveau ou primeur"}	Beaujolais Odenas rosé nouveau ou primeur	\N
12480	268	Beaujolais Odenas	AOC -	AOP -	{"fra": "Beaujolais Odenas rouge"}	Beaujolais Odenas rouge	\N
12481	268	Beaujolais Odenas	AOC -	AOP -	{"fra": "Beaujolais Odenas rouge nouveau ou primeur"}	Beaujolais Odenas rouge nouveau ou primeur	\N
12463	269	Beaujolais Pruzilly	AOC -	AOP -	{"fra": "Beaujolais Pruzilly rouge nouveau ou primeur"}	Beaujolais Pruzilly rouge nouveau ou primeur	\N
12482	269	Beaujolais Pruzilly	AOC -	AOP -	{"fra": "Beaujolais Pruzilly blanc"}	Beaujolais Pruzilly blanc	\N
12483	269	Beaujolais Pruzilly	AOC -	AOP -	{"fra": "Beaujolais Pruzilly rosé"}	Beaujolais Pruzilly rosé	\N
12484	269	Beaujolais Pruzilly	AOC -	AOP -	{"fra": "Beaujolais Pruzilly rosé nouveau ou primeur"}	Beaujolais Pruzilly rosé nouveau ou primeur	\N
12485	269	Beaujolais Pruzilly	AOC -	AOP -	{"fra": "Beaujolais Pruzilly rouge"}	Beaujolais Pruzilly rouge	\N
12458	270	Beaujolais Quincié-en-Beaujolais	AOC -	AOP -	{"fra": "Beaujolais Quincié-en-Beaujolais rouge nouveau ou primeur"}	Beaujolais Quincié-en-Beaujolais rouge nouveau ou primeur	\N
12459	270	Beaujolais Quincié-en-Beaujolais	AOC -	AOP -	{"fra": "Beaujolais Quincié-en-Beaujolais rouge"}	Beaujolais Quincié-en-Beaujolais rouge	\N
12460	270	Beaujolais Quincié-en-Beaujolais	AOC -	AOP -	{"fra": "Beaujolais Quincié-en-Beaujolais rosé nouveau ou primeur"}	Beaujolais Quincié-en-Beaujolais rosé nouveau ou primeur	\N
12461	270	Beaujolais Quincié-en-Beaujolais	AOC -	AOP -	{"fra": "Beaujolais Quincié-en-Beaujolais rosé"}	Beaujolais Quincié-en-Beaujolais rosé	\N
12462	270	Beaujolais Quincié-en-Beaujolais	AOC -	AOP -	{"fra": "Beaujolais Quincié-en-Beaujolais blanc"}	Beaujolais Quincié-en-Beaujolais blanc	\N
12454	271	Beaujolais Rivolet	AOC -	AOP -	{"fra": "Beaujolais Rivolet rouge"}	Beaujolais Rivolet rouge	\N
12455	271	Beaujolais Rivolet	AOC -	AOP -	{"fra": "Beaujolais Rivolet rosé nouveau ou primeur"}	Beaujolais Rivolet rosé nouveau ou primeur	\N
12456	271	Beaujolais Rivolet	AOC -	AOP -	{"fra": "Beaujolais Rivolet rosé"}	Beaujolais Rivolet rosé	\N
12457	271	Beaujolais Rivolet	AOC -	AOP -	{"fra": "Beaujolais Rivolet blanc"}	Beaujolais Rivolet blanc	\N
12486	271	Beaujolais Rivolet	AOC -	AOP -	{"fra": "Beaujolais Rivolet rouge nouveau ou primeur"}	Beaujolais Rivolet rouge nouveau ou primeur	\N
12487	272	Beaujolais Romanèche-Thorins	AOC -	AOP -	{"fra": "Beaujolais Romanèche-Thorins blanc"}	Beaujolais Romanèche-Thorins blanc	\N
12488	272	Beaujolais Romanèche-Thorins	AOC -	AOP -	{"fra": "Beaujolais Romanèche-Thorins rosé"}	Beaujolais Romanèche-Thorins rosé	\N
12489	272	Beaujolais Romanèche-Thorins	AOC -	AOP -	{"fra": "Beaujolais Romanèche-Thorins rosé nouveau ou primeur"}	Beaujolais Romanèche-Thorins rosé nouveau ou primeur	\N
12490	272	Beaujolais Romanèche-Thorins	AOC -	AOP -	{"fra": "Beaujolais Romanèche-Thorins rouge"}	Beaujolais Romanèche-Thorins rouge	\N
12491	272	Beaujolais Romanèche-Thorins	AOC -	AOP -	{"fra": "Beaujolais Romanèche-Thorins rouge nouveau ou primeur"}	Beaujolais Romanèche-Thorins rouge nouveau ou primeur	\N
12495	273	Beaujolais Saint-Didier-sur-Beaujeu	AOC -	AOP -	{"fra": "Beaujolais Saint-Didier-sur-Beaujeu blanc"}	Beaujolais Saint-Didier-sur-Beaujeu blanc	\N
12496	273	Beaujolais Saint-Didier-sur-Beaujeu	AOC -	AOP -	{"fra": "Beaujolais Saint-Didier-sur-Beaujeu rosé"}	Beaujolais Saint-Didier-sur-Beaujeu rosé	\N
12497	273	Beaujolais Saint-Didier-sur-Beaujeu	AOC -	AOP -	{"fra": "Beaujolais Saint-Didier-sur-Beaujeu rosé nouveau ou primeur"}	Beaujolais Saint-Didier-sur-Beaujeu rosé nouveau ou primeur	\N
12501	273	Beaujolais Saint-Didier-sur-Beaujeu	AOC -	AOP -	{"fra": "Beaujolais Saint-Didier-sur-Beaujeu rouge nouveau ou primeur"}	Beaujolais Saint-Didier-sur-Beaujeu rouge nouveau ou primeur	\N
12502	273	Beaujolais Saint-Didier-sur-Beaujeu	AOC -	AOP -	{"fra": "Beaujolais Saint-Didier-sur-Beaujeu rouge"}	Beaujolais Saint-Didier-sur-Beaujeu rouge	\N
12498	274	Beaujolais Saint-Etienne-des-Oullières	AOC -	AOP -	{"fra": "Beaujolais Saint-Etienne-des-Oullières blanc"}	Beaujolais Saint-Etienne-des-Oullières blanc	\N
12499	274	Beaujolais Saint-Etienne-des-Oullières	AOC -	AOP -	{"fra": "Beaujolais Saint-Etienne-des-Oullières rosé"}	Beaujolais Saint-Etienne-des-Oullières rosé	\N
12500	274	Beaujolais Saint-Etienne-des-Oullières	AOC -	AOP -	{"fra": "Beaujolais Saint-Etienne-des-Oullières rosé nouveau ou primeur"}	Beaujolais Saint-Etienne-des-Oullières rosé nouveau ou primeur	\N
12503	274	Beaujolais Saint-Etienne-des-Oullières	AOC -	AOP -	{"fra": "Beaujolais Saint-Etienne-des-Oullières rouge"}	Beaujolais Saint-Etienne-des-Oullières rouge	\N
9594	283	Beaune premier cru A l'Ecu	AOC -	AOP -	{"fra": "Beaune premier cru A l'Ecu blanc"}	Beaune premier cru A l'Ecu blanc	\N
12504	274	Beaujolais Saint-Etienne-des-Oullières	AOC -	AOP -	{"fra": "Beaujolais Saint-Etienne-des-Oullières rouge nouveau ou primeur"}	Beaujolais Saint-Etienne-des-Oullières rouge nouveau ou primeur	\N
12505	275	Beaujolais Saint-Etienne-la-Varenne	AOC -	AOP -	{"fra": "Beaujolais Saint-Etienne-la-Varenne blanc"}	Beaujolais Saint-Etienne-la-Varenne blanc	\N
12506	275	Beaujolais Saint-Etienne-la-Varenne	AOC -	AOP -	{"fra": "Beaujolais Saint-Etienne-la-Varenne rosé"}	Beaujolais Saint-Etienne-la-Varenne rosé	\N
12507	275	Beaujolais Saint-Etienne-la-Varenne	AOC -	AOP -	{"fra": "Beaujolais Saint-Etienne-la-Varenne rosé nouveau ou primeur"}	Beaujolais Saint-Etienne-la-Varenne rosé nouveau ou primeur	\N
12508	275	Beaujolais Saint-Etienne-la-Varenne	AOC -	AOP -	{"fra": "Beaujolais Saint-Etienne-la-Varenne rouge"}	Beaujolais Saint-Etienne-la-Varenne rouge	\N
12509	275	Beaujolais Saint-Etienne-la-Varenne	AOC -	AOP -	{"fra": "Beaujolais Saint-Etienne-la-Varenne rouge nouveau ou primeur"}	Beaujolais Saint-Etienne-la-Varenne rouge nouveau ou primeur	\N
12510	276	Beaujolais Saint-Julien	AOC -	AOP -	{"fra": "Beaujolais Saint-Julien blanc"}	Beaujolais Saint-Julien blanc	\N
12511	276	Beaujolais Saint-Julien	AOC -	AOP -	{"fra": "Beaujolais Saint-Julien rosé"}	Beaujolais Saint-Julien rosé	\N
12512	276	Beaujolais Saint-Julien	AOC -	AOP -	{"fra": "Beaujolais Saint-Julien rosé nouveau ou primeur"}	Beaujolais Saint-Julien rosé nouveau ou primeur	\N
12513	276	Beaujolais Saint-Julien	AOC -	AOP -	{"fra": "Beaujolais Saint-Julien rouge nouveau ou primeur"}	Beaujolais Saint-Julien rouge nouveau ou primeur	\N
12515	276	Beaujolais Saint-Julien	AOC -	AOP -	{"fra": "Beaujolais Saint-Julien rouge"}	Beaujolais Saint-Julien rouge	\N
12514	277	Beaujolais Saint-Lager	AOC -	AOP -	{"fra": "Beaujolais Saint-Lager blanc"}	Beaujolais Saint-Lager blanc	\N
12516	277	Beaujolais Saint-Lager	AOC -	AOP -	{"fra": "Beaujolais Saint-Lager rosé"}	Beaujolais Saint-Lager rosé	\N
12517	277	Beaujolais Saint-Lager	AOC -	AOP -	{"fra": "Beaujolais Saint-Lager rosé nouveau ou primeur"}	Beaujolais Saint-Lager rosé nouveau ou primeur	\N
12518	277	Beaujolais Saint-Lager	AOC -	AOP -	{"fra": "Beaujolais Saint-Lager rouge"}	Beaujolais Saint-Lager rouge	\N
12519	277	Beaujolais Saint-Lager	AOC -	AOP -	{"fra": "Beaujolais Saint-Lager rouge nouveau ou primeur"}	Beaujolais Saint-Lager rouge nouveau ou primeur	\N
12520	278	Beaujolais Saint-Symphorien-d'Ancelles	AOC -	AOP -	{"fra": "Beaujolais Saint-Symphorien-d'Ancelles blanc"}	Beaujolais Saint-Symphorien-d'Ancelles blanc	\N
12521	278	Beaujolais Saint-Symphorien-d'Ancelles	AOC -	AOP -	{"fra": "Beaujolais Saint-Symphorien-d'Ancelles rosé"}	Beaujolais Saint-Symphorien-d'Ancelles rosé	\N
12522	278	Beaujolais Saint-Symphorien-d'Ancelles	AOC -	AOP -	{"fra": "Beaujolais Saint-Symphorien-d'Ancelles rosé nouveau ou primeur"}	Beaujolais Saint-Symphorien-d'Ancelles rosé nouveau ou primeur	\N
12523	278	Beaujolais Saint-Symphorien-d'Ancelles	AOC -	AOP -	{"fra": "Beaujolais Saint-Symphorien-d'Ancelles rouge"}	Beaujolais Saint-Symphorien-d'Ancelles rouge	\N
12545	278	Beaujolais Saint-Symphorien-d'Ancelles	AOC -	AOP -	{"fra": "Beaujolais Saint-Symphorien-d'Ancelles rouge nouveau ou primeur"}	Beaujolais Saint-Symphorien-d'Ancelles rouge nouveau ou primeur	\N
12524	279	Beaujolais Salles-Arbuissonnas-en-Beaujolais	AOC -	AOP -	{"fra": "Beaujolais Salles-Arbuissonnas-en-Beaujolais blanc"}	Beaujolais Salles-Arbuissonnas-en-Beaujolais blanc	\N
12525	279	Beaujolais Salles-Arbuissonnas-en-Beaujolais	AOC -	AOP -	{"fra": "Beaujolais Salles-Arbuissonnas-en-Beaujolais rosé"}	Beaujolais Salles-Arbuissonnas-en-Beaujolais rosé	\N
12526	279	Beaujolais Salles-Arbuissonnas-en-Beaujolais	AOC -	AOP -	{"fra": "Beaujolais Salles-Arbuissonnas-en-Beaujolais rosé nouveau ou primeur"}	Beaujolais Salles-Arbuissonnas-en-Beaujolais rosé nouveau ou primeur	\N
12527	279	Beaujolais Salles-Arbuissonnas-en-Beaujolais	AOC -	AOP -	{"fra": "Beaujolais Salles-Arbuissonnas-en-Beaujolais rouge"}	Beaujolais Salles-Arbuissonnas-en-Beaujolais rouge	\N
12528	279	Beaujolais Salles-Arbuissonnas-en-Beaujolais	AOC -	AOP -	{"fra": "Beaujolais Salles-Arbuissonnas-en-Beaujolais rouge nouveau ou primeur"}	Beaujolais Salles-Arbuissonnas-en-Beaujolais rouge nouveau ou primeur	\N
12530	280	Beaujolais Vaux-en-Beaujolais	AOC -	AOP -	{"fra": "Beaujolais Vaux-en-Beaujolais blanc"}	Beaujolais Vaux-en-Beaujolais blanc	\N
12531	280	Beaujolais Vaux-en-Beaujolais	AOC -	AOP -	{"fra": "Beaujolais Vaux-en-Beaujolais rosé"}	Beaujolais Vaux-en-Beaujolais rosé	\N
12532	280	Beaujolais Vaux-en-Beaujolais	AOC -	AOP -	{"fra": "Beaujolais Vaux-en-Beaujolais rosé nouveau ou primeur"}	Beaujolais Vaux-en-Beaujolais rosé nouveau ou primeur	\N
12533	280	Beaujolais Vaux-en-Beaujolais	AOC -	AOP -	{"fra": "Beaujolais Vaux-en-Beaujolais rouge"}	Beaujolais Vaux-en-Beaujolais rouge	\N
12534	280	Beaujolais Vaux-en-Beaujolais	AOC -	AOP -	{"fra": "Beaujolais Vaux-en-Beaujolais rouge nouveau ou primeur"}	Beaujolais Vaux-en-Beaujolais rouge nouveau ou primeur	\N
12535	281	Beaujolais Vauxrenard	AOC -	AOP -	{"fra": "Beaujolais Vauxrenard blanc"}	Beaujolais Vauxrenard blanc	\N
12536	281	Beaujolais Vauxrenard	AOC -	AOP -	{"fra": "Beaujolais Vauxrenard rosé"}	Beaujolais Vauxrenard rosé	\N
12537	281	Beaujolais Vauxrenard	AOC -	AOP -	{"fra": "Beaujolais Vauxrenard rosé nouveau ou primeur"}	Beaujolais Vauxrenard rosé nouveau ou primeur	\N
12538	281	Beaujolais Vauxrenard	AOC -	AOP -	{"fra": "Beaujolais Vauxrenard rouge"}	Beaujolais Vauxrenard rouge	\N
12539	281	Beaujolais Vauxrenard	AOC -	AOP -	{"fra": "Beaujolais Vauxrenard rouge nouveau ou primeur"}	Beaujolais Vauxrenard rouge nouveau ou primeur	\N
12540	251	Beaujolais Villages	AOC -	AOP -	{"fra": "Beaujolais Villages blanc"}	Beaujolais Villages blanc	\N
12541	251	Beaujolais Villages	AOC -	AOP -	{"fra": "Beaujolais Villages rosé"}	Beaujolais Villages rosé	\N
12542	251	Beaujolais Villages	AOC -	AOP -	{"fra": "Beaujolais Villages rosé nouveau ou primeur"}	Beaujolais Villages rosé nouveau ou primeur	\N
12543	251	Beaujolais Villages	AOC -	AOP -	{"fra": "Beaujolais Villages rouge"}	Beaujolais Villages rouge	\N
12544	251	Beaujolais Villages	AOC -	AOP -	{"fra": "Beaujolais Villages rouge primeur ou nouveau"}	Beaujolais Villages rouge primeur ou nouveau	\N
13050	1288	Beaumes de Venise	AOC -	AOP -	{"fra": "Beaumes de Venise"}	Beaumes de Venise	\N
7696	282	Beaune	AOC -	AOP -	{"fra": "Beaune"}	Beaune	\N
9680	282	Beaune	AOC -	AOP -	{"fra": "Beaune rouge"}	Beaune rouge	\N
9602	325	Beaune premier cru	AOC -	AOP -	{"fra": "Beaune premier cru blanc"}	Beaune premier cru blanc	\N
9595	283	Beaune premier cru A l'Ecu	AOC -	AOP -	{"fra": "Beaune premier cru A l'Ecu rouge"}	Beaune premier cru A l'Ecu rouge	\N
9596	284	Beaune premier cru Aux Coucherias	AOC -	AOP -	{"fra": "Beaune premier cru Aux Coucherias blanc"}	Beaune premier cru Aux Coucherias blanc	\N
9597	284	Beaune premier cru Aux Coucherias	AOC -	AOP -	{"fra": "Beaune premier cru Aux Coucherias rouge"}	Beaune premier cru Aux Coucherias rouge	\N
9598	285	Beaune premier cru Aux Cras	AOC -	AOP -	{"fra": "Beaune premier cru Aux Cras blanc"}	Beaune premier cru Aux Cras blanc	\N
9599	285	Beaune premier cru Aux Cras	AOC -	AOP -	{"fra": "Beaune premier cru Aux Cras rouge"}	Beaune premier cru Aux Cras rouge	\N
9600	286	Beaune premier cru Belissand	AOC -	AOP -	{"fra": "Beaune premier cru Belissand blanc"}	Beaune premier cru Belissand blanc	\N
9601	286	Beaune premier cru Belissand	AOC -	AOP -	{"fra": "Beaune premier cru Belissand rouge"}	Beaune premier cru Belissand rouge	\N
9603	287	Beaune premier cru Blanches Fleurs	AOC -	AOP -	{"fra": "Beaune premier cru Blanches Fleurs blanc"}	Beaune premier cru Blanches Fleurs blanc	\N
9604	287	Beaune premier cru Blanches Fleurs	AOC -	AOP -	{"fra": "Beaune premier cru Blanches Fleurs rouge"}	Beaune premier cru Blanches Fleurs rouge	\N
9605	288	Beaune premier cru Champs Pimont	AOC -	AOP -	{"fra": "Beaune premier cru Champs Pimont blanc"}	Beaune premier cru Champs Pimont blanc	\N
9606	288	Beaune premier cru Champs Pimont	AOC -	AOP -	{"fra": "Beaune premier cru Champs Pimont rouge"}	Beaune premier cru Champs Pimont rouge	\N
9607	290	Beaune premier cru Clos de l'Ecu	AOC -	AOP -	{"fra": "Beaune premier cru Clos de l'Ecu blanc"}	Beaune premier cru Clos de l'Ecu blanc	\N
9608	290	Beaune premier cru Clos de l'Ecu	AOC -	AOP -	{"fra": "Beaune premier cru Clos de l'Ecu rouge"}	Beaune premier cru Clos de l'Ecu rouge	\N
9609	291	Beaune premier cru Clos de la Feguine	AOC -	AOP -	{"fra": "Beaune premier cru Clos de la Feguine blanc"}	Beaune premier cru Clos de la Feguine blanc	\N
9610	291	Beaune premier cru Clos de la Feguine	AOC -	AOP -	{"fra": "Beaune premier cru Clos de la Feguine rouge"}	Beaune premier cru Clos de la Feguine rouge	\N
9611	292	Beaune premier cru Clos de la Mousse	AOC -	AOP -	{"fra": "Beaune premier cru Clos de la Mousse blanc"}	Beaune premier cru Clos de la Mousse blanc	\N
9612	292	Beaune premier cru Clos de la Mousse	AOC -	AOP -	{"fra": "Beaune premier cru Clos de la Mousse rouge"}	Beaune premier cru Clos de la Mousse rouge	\N
9613	293	Beaune premier cru Clos des Avaux	AOC -	AOP -	{"fra": "Beaune premier cru Clos des Avaux blanc"}	Beaune premier cru Clos des Avaux blanc	\N
9614	293	Beaune premier cru Clos des Avaux	AOC -	AOP -	{"fra": "Beaune premier cru Clos des Avaux rouge"}	Beaune premier cru Clos des Avaux rouge	\N
9615	294	Beaune premier cru Clos des Ursules	AOC -	AOP -	{"fra": "Beaune premier cru Clos des Ursules blanc"}	Beaune premier cru Clos des Ursules blanc	\N
9616	294	Beaune premier cru Clos des Ursules	AOC -	AOP -	{"fra": "Beaune premier cru Clos des Ursules rouge"}	Beaune premier cru Clos des Ursules rouge	\N
9617	295	Beaune premier cru Clos du Roi	AOC -	AOP -	{"fra": "Beaune premier cru Clos du Roi blanc"}	Beaune premier cru Clos du Roi blanc	\N
9618	295	Beaune premier cru Clos du Roi	AOC -	AOP -	{"fra": "Beaune premier cru Clos du Roi rouge"}	Beaune premier cru Clos du Roi rouge	\N
9619	289	Beaune premier cru Clos Saint-Landry	AOC -	AOP -	{"fra": "Beaune premier cru Clos Saint-Landry blanc"}	Beaune premier cru Clos Saint-Landry blanc	\N
9620	289	Beaune premier cru Clos Saint-Landry	AOC -	AOP -	{"fra": "Beaune premier cru Clos Saint-Landry rouge"}	Beaune premier cru Clos Saint-Landry rouge	\N
9621	296	Beaune premier cru En Genêt	AOC -	AOP -	{"fra": "Beaune premier cru En Genêt blanc"}	Beaune premier cru En Genêt blanc	\N
9622	296	Beaune premier cru En Genêt	AOC -	AOP -	{"fra": "Beaune premier cru En Genêt rouge"}	Beaune premier cru En Genêt rouge	\N
9623	297	Beaune premier cru En l'Orme	AOC -	AOP -	{"fra": "Beaune premier cru En l'Orme blanc"}	Beaune premier cru En l'Orme blanc	\N
9624	297	Beaune premier cru En l'Orme	AOC -	AOP -	{"fra": "Beaune premier cru En l'Orme rouge"}	Beaune premier cru En l'Orme rouge	\N
9625	298	Beaune premier cru La Mignotte	AOC -	AOP -	{"fra": "Beaune premier cru La Mignotte blanc"}	Beaune premier cru La Mignotte blanc	\N
9626	298	Beaune premier cru La Mignotte	AOC -	AOP -	{"fra": "Beaune premier cru La Mignotte rouge"}	Beaune premier cru La Mignotte rouge	\N
9627	299	Beaune premier cru Le Bas des Teurons	AOC -	AOP -	{"fra": "Beaune premier cru Le Bas des Teurons blanc"}	Beaune premier cru Le Bas des Teurons blanc	\N
9628	299	Beaune premier cru Le Bas des Teurons	AOC -	AOP -	{"fra": "Beaune premier cru Le Bas des Teurons rouge"}	Beaune premier cru Le Bas des Teurons rouge	\N
9629	300	Beaune premier cru Le Clos des Mouches	AOC -	AOP -	{"fra": "Beaune premier cru Le Clos des Mouches blanc"}	Beaune premier cru Le Clos des Mouches blanc	\N
9630	300	Beaune premier cru Le Clos des Mouches	AOC -	AOP -	{"fra": "Beaune premier cru Le Clos des Mouches rouge"}	Beaune premier cru Le Clos des Mouches rouge	\N
9631	301	Beaune premier cru Les Aigrots	AOC -	AOP -	{"fra": "Beaune premier cru Les Aigrots blanc"}	Beaune premier cru Les Aigrots blanc	\N
9632	301	Beaune premier cru Les Aigrots	AOC -	AOP -	{"fra": "Beaune premier cru Les Aigrots rouge"}	Beaune premier cru Les Aigrots rouge	\N
9633	302	Beaune premier cru Les Avaux	AOC -	AOP -	{"fra": "Beaune premier cru Les Avaux blanc"}	Beaune premier cru Les Avaux blanc	\N
9634	302	Beaune premier cru Les Avaux	AOC -	AOP -	{"fra": "Beaune premier cru Les Avaux rouge"}	Beaune premier cru Les Avaux rouge	\N
9635	303	Beaune premier cru Les Boucherottes	AOC -	AOP -	{"fra": "Beaune premier cru Les Boucherottes blanc"}	Beaune premier cru Les Boucherottes blanc	\N
9636	303	Beaune premier cru Les Boucherottes	AOC -	AOP -	{"fra": "Beaune premier cru Les Boucherottes rouge"}	Beaune premier cru Les Boucherottes rouge	\N
9637	304	Beaune premier cru Les Bressandes	AOC -	AOP -	{"fra": "Beaune premier cru Les Bressandes blanc"}	Beaune premier cru Les Bressandes blanc	\N
9638	304	Beaune premier cru Les Bressandes	AOC -	AOP -	{"fra": "Beaune premier cru Les Bressandes rouge"}	Beaune premier cru Les Bressandes rouge	\N
9639	305	Beaune premier cru Les Cents Vignes	AOC -	AOP -	{"fra": "Beaune premier cru Les Cents Vignes blanc"}	Beaune premier cru Les Cents Vignes blanc	\N
9640	305	Beaune premier cru Les Cents Vignes	AOC -	AOP -	{"fra": "Beaune premier cru Les Cents Vignes rouge"}	Beaune premier cru Les Cents Vignes rouge	\N
9641	306	Beaune premier cru Les Chouacheux	AOC -	AOP -	{"fra": "Beaune premier cru Les Chouacheux blanc"}	Beaune premier cru Les Chouacheux blanc	\N
9642	306	Beaune premier cru Les Chouacheux	AOC -	AOP -	{"fra": "Beaune premier cru Les Chouacheux rouge"}	Beaune premier cru Les Chouacheux rouge	\N
9643	307	Beaune premier cru Les Epenotes	AOC -	AOP -	{"fra": "Beaune premier cru Les Epenotes blanc"}	Beaune premier cru Les Epenotes blanc	\N
9644	307	Beaune premier cru Les Epenotes	AOC -	AOP -	{"fra": "Beaune premier cru Les Epenotes rouge"}	Beaune premier cru Les Epenotes rouge	\N
9645	308	Beaune premier cru Les Fèves	AOC -	AOP -	{"fra": "Beaune premier cru Les Fèves blanc"}	Beaune premier cru Les Fèves blanc	\N
9646	308	Beaune premier cru Les Fèves	AOC -	AOP -	{"fra": "Beaune premier cru Les Fèves rouge"}	Beaune premier cru Les Fèves rouge	\N
9647	309	Beaune premier cru Les Grèves	AOC -	AOP -	{"fra": "Beaune premier cru Les Grèves blanc"}	Beaune premier cru Les Grèves blanc	\N
9648	309	Beaune premier cru Les Grèves	AOC -	AOP -	{"fra": "Beaune premier cru Les Grèves rouge"}	Beaune premier cru Les Grèves rouge	\N
9649	310	Beaune premier cru Les Marconnets	AOC -	AOP -	{"fra": "Beaune premier cru Les Marconnets blanc"}	Beaune premier cru Les Marconnets blanc	\N
9650	310	Beaune premier cru Les Marconnets	AOC -	AOP -	{"fra": "Beaune premier cru Les Marconnets rouge"}	Beaune premier cru Les Marconnets rouge	\N
9651	311	Beaune premier cru Les Montrevenots	AOC -	AOP -	{"fra": "Beaune premier cru Les Montrevenots blanc"}	Beaune premier cru Les Montrevenots blanc	\N
9652	311	Beaune premier cru Les Montrevenots	AOC -	AOP -	{"fra": "Beaune premier cru Les Montrevenots rouge"}	Beaune premier cru Les Montrevenots rouge	\N
9653	312	Beaune premier cru Les Perrières	AOC -	AOP -	{"fra": "Beaune premier cru Les Perrières blanc"}	Beaune premier cru Les Perrières blanc	\N
9654	312	Beaune premier cru Les Perrières	AOC -	AOP -	{"fra": "Beaune premier cru Les Perrières rouge"}	Beaune premier cru Les Perrières rouge	\N
9655	313	Beaune premier cru Les Reversés	AOC -	AOP -	{"fra": "Beaune premier cru Les Reversés blanc"}	Beaune premier cru Les Reversés blanc	\N
9656	313	Beaune premier cru Les Reversés	AOC -	AOP -	{"fra": "Beaune premier cru Les Reversés rouge"}	Beaune premier cru Les Reversés rouge	\N
9657	314	Beaune premier cru Les Sceaux	AOC -	AOP -	{"fra": "Beaune premier cru Les Sceaux blanc"}	Beaune premier cru Les Sceaux blanc	\N
9658	314	Beaune premier cru Les Sceaux	AOC -	AOP -	{"fra": "Beaune premier cru Les Sceaux rouge"}	Beaune premier cru Les Sceaux rouge	\N
9659	315	Beaune premier cru Les Seurey	AOC -	AOP -	{"fra": "Beaune premier cru Les Seurey blanc"}	Beaune premier cru Les Seurey blanc	\N
9660	315	Beaune premier cru Les Seurey	AOC -	AOP -	{"fra": "Beaune premier cru Les Seurey rouge"}	Beaune premier cru Les Seurey rouge	\N
9661	316	Beaune premier cru Les Sizies	AOC -	AOP -	{"fra": "Beaune premier cru Les Sizies blanc"}	Beaune premier cru Les Sizies blanc	\N
9662	316	Beaune premier cru Les Sizies	AOC -	AOP -	{"fra": "Beaune premier cru Les Sizies rouge"}	Beaune premier cru Les Sizies rouge	\N
9663	317	Beaune premier cru Les Teurons	AOC -	AOP -	{"fra": "Beaune premier cru Les Teurons blanc"}	Beaune premier cru Les Teurons blanc	\N
9664	317	Beaune premier cru Les Teurons	AOC -	AOP -	{"fra": "Beaune premier cru Les Teurons rouge"}	Beaune premier cru Les Teurons rouge	\N
9665	318	Beaune premier cru Les Toussaints	AOC -	AOP -	{"fra": "Beaune premier cru Les Toussaints blanc"}	Beaune premier cru Les Toussaints blanc	\N
9666	318	Beaune premier cru Les Toussaints	AOC -	AOP -	{"fra": "Beaune premier cru Les Toussaints rouge"}	Beaune premier cru Les Toussaints rouge	\N
9667	319	Beaune premier cru Les Tuvilains	AOC -	AOP -	{"fra": "Beaune premier cru Les Tuvilains blanc"}	Beaune premier cru Les Tuvilains blanc	\N
9668	319	Beaune premier cru Les Tuvilains	AOC -	AOP -	{"fra": "Beaune premier cru Les Tuvilains rouge"}	Beaune premier cru Les Tuvilains rouge	\N
9669	320	Beaune premier cru Les Vignes Franches	AOC -	AOP -	{"fra": "Beaune premier cru Les Vignes Franches blanc"}	Beaune premier cru Les Vignes Franches blanc	\N
9670	320	Beaune premier cru Les Vignes Franches	AOC -	AOP -	{"fra": "Beaune premier cru Les Vignes Franches rouge"}	Beaune premier cru Les Vignes Franches rouge	\N
9671	321	Beaune premier cru Montée Rouge	AOC -	AOP -	{"fra": "Beaune premier cru Montée Rouge blanc"}	Beaune premier cru Montée Rouge blanc	\N
9672	321	Beaune premier cru Montée Rouge	AOC -	AOP -	{"fra": "Beaune premier cru Montée Rouge rouge"}	Beaune premier cru Montée Rouge rouge	\N
9673	322	Beaune premier cru Pertuisots	AOC -	AOP -	{"fra": "Beaune premier cru Pertuisots blanc"}	Beaune premier cru Pertuisots blanc	\N
9674	322	Beaune premier cru Pertuisots	AOC -	AOP -	{"fra": "Beaune premier cru Pertuisots rouge"}	Beaune premier cru Pertuisots rouge	\N
9678	323	Beaune premier cru Sur les Grèves	AOC -	AOP -	{"fra": "Beaune premier cru Sur les Grèves blanc"}	Beaune premier cru Sur les Grèves blanc	\N
9679	323	Beaune premier cru Sur les Grèves	AOC -	AOP -	{"fra": "Beaune premier cru Sur les Grèves rouge"}	Beaune premier cru Sur les Grèves rouge	\N
9676	324	Beaune premier cru Sur les Grèves - Clos Saint-Anne	AOC -	AOP -	{"fra": "Beaune premier cru Sur les Grèves - Clos Saint-Anne blanc"}	Beaune premier cru Sur les Grèves - Clos Saint-Anne blanc	\N
9677	324	Beaune premier cru Sur les Grèves - Clos Saint-Anne	AOC -	AOP -	{"fra": "Beaune premier cru Sur les Grèves - Clos Saint-Anne rouge"}	Beaune premier cru Sur les Grèves - Clos Saint-Anne rouge	\N
9203	1318	Bellet	AOC -	AOP -	{"fra": "Bellet ou Vin de Bellet blanc"}	Bellet ou Vin de Bellet blanc	\N
9204	1318	Bellet	AOC -	AOP -	{"fra": "Bellet ou Vin de Bellet rosé"}	Bellet ou Vin de Bellet rosé	\N
9205	1318	Bellet	AOC -	AOP -	{"fra": "Bellet ou Vin de Bellet rouge"}	Bellet ou Vin de Bellet rouge	\N
16115	1523	Bergamotes de Nancy	\N	IGP -	{"fra": "Bergamotes de Nancy"}	Bergamotes de Nancy	IG/47/94
12978	61	Bergerac	AOC -	AOP -	{"fra": "Bergerac blanc"}	Bergerac blanc	\N
13176	61	Bergerac	AOC -	AOP -	{"fra": "Bergerac rosé"}	Bergerac rosé	\N
13177	61	Bergerac	AOC -	AOP -	{"fra": "Bergerac rouge"}	Bergerac rouge	\N
3296	1488	Beurre Charentes-Poitou	AOC -	AOP -	{"fra": "Beurre Charentes-Poitou"}	Beurre Charentes-Poitou	\N
3297	1488	Beurre Charentes-Poitou	AOC -	AOP -	{"fra": "BEURRE DES CHARENTES"}	BEURRE DES CHARENTES	\N
3298	1488	Beurre Charentes-Poitou	AOC -	AOP -	{"fra": "BEURRE DES DEUX SEVRES"}	BEURRE DES DEUX SEVRES	\N
13174	2225	Beurre de Bresse	AOC -	AOP -	{"fra": "Beurre de Bresse"}	Beurre de Bresse	\N
12035	1489	Beurre et crème d'Isigny	AOC -	AOP -	{"fra": "Beurre d'Isigny"}	Beurre d'Isigny	\N
15966	1489	Beurre et crème d'Isigny	AOC -	AOP -	{"fra": "Crème d'Isigny"}	Crème d'Isigny	\N
7680	326	Bienvenues-Bâtard-Montrachet	AOC -	AOP -	{"fra": "Bienvenues-Bâtard-Montrachet"}	Bienvenues-Bâtard-Montrachet	\N
7713	327	Blagny	AOC -	AOP -	{"fra": "Blagny ou Blagny Côte de Beaune"}	Blagny ou Blagny Côte de Beaune	\N
9116	335	Blagny premier cru	AOC -	AOP -	{"fra": "Blagny premier cru"}	Blagny premier cru	\N
9117	328	Blagny premier cru Hameau de Blagny	AOC -	AOP -	{"fra": "Blagny premier cru Hameau de Blagny"}	Blagny premier cru Hameau de Blagny	\N
9118	329	Blagny premier cru La Garenne ou sur la Garenne	AOC -	AOP -	{"fra": "Blagny premier cru La Garenne ou sur la Garenne"}	Blagny premier cru La Garenne ou sur la Garenne	\N
9119	330	Blagny premier cru La Jeunellotte	AOC -	AOP -	{"fra": "Blagny premier cru La Jeunellotte"}	Blagny premier cru La Jeunellotte	\N
9120	331	Blagny premier cru La Pièce sous le Bois	AOC -	AOP -	{"fra": "Blagny premier cru La Pièce sous le Bois"}	Blagny premier cru La Pièce sous le Bois	\N
9121	332	Blagny premier cru Sous Blagny	AOC -	AOP -	{"fra": "Blagny premier cru Sous Blagny"}	Blagny premier cru Sous Blagny	\N
15464	2349	Brulhois	AOC -	AOP -	{"fra": "Brulhois rosé"}	Brulhois rosé	\N
9122	333	Blagny premier cru Sous le Dos d'Ane	AOC -	AOP -	{"fra": "Blagny premier cru Sous le Dos d'Ane"}	Blagny premier cru Sous le Dos d'Ane	\N
9123	334	Blagny premier cru Sous le Puits	AOC -	AOP -	{"fra": "Blagny premier cru Sous le Puits"}	Blagny premier cru Sous le Puits	\N
13389	1952	Blanche Armagnac	AOC -	IG - 	{"fra": "Armagnac Blanche Armagnac"}	Armagnac Blanche Armagnac	\N
14982	62	Blaye	AOC -	AOP -	{"fra": "Blaye"}	Blaye	\N
4562	1456	Bleu d'Auvergne	AOC -	AOP -	{"fra": "Bleu d'Auvergne"}	Bleu d'Auvergne	\N
13171	2222	Bleu de Gex haut Jura ou Bleu de Septmoncel	AOC -	AOP -	{"fra": "Bleu de Gex haut Jura ou Bleu de Septmoncel"}	Bleu de Gex haut Jura ou Bleu de Septmoncel	\N
14230	1457	Bleu des Causses	AOC -	AOP -	{"fra": "Bleu des Causses"}	Bleu des Causses	\N
16082	1490	Bleu du Vercors-Sassenage	AOC -	AOP -	{"fra": "Bleu du Vercors-Sassenage"}	Bleu du Vercors-Sassenage	\N
4115	2451	Bois de Chartreuse	AOC -	\N	{"fra": "Bois de Chartreuse"}	Bois de Chartreuse	\N
4330	1739	Bois du Jura	AOC -	\N	{"fra": "Bois du Jura"}	Bois du Jura	\N
7706	336	Bonnes-Mares	AOC -	AOP -	{"fra": "Bonnes-Mares"}	Bonnes-Mares	\N
15168	162	Bonnezeaux	AOC -	AOP -	{"fra": "Bonnezeaux"}	Bonnezeaux	\N
15244	63	Bordeaux	AOC -	AOP -	{"fra": "Bordeaux blanc"}	Bordeaux blanc	\N
15246	63	Bordeaux	AOC -	AOP -	{"fra": "Bordeaux rosé"}	Bordeaux rosé	\N
15247	63	Bordeaux	AOC -	AOP -	{"fra": "Bordeaux rouge ou claret"}	Bordeaux rouge ou claret	\N
15248	63	Bordeaux	AOC -	AOP -	{"fra": "Bordeaux clairet"}	Bordeaux clairet	\N
15249	63	Bordeaux	AOC -	AOP -	{"fra": "Bordeaux claret"}	Bordeaux claret	\N
15428	63	Bordeaux	AOC -	AOP -	{"fra": "Bordeaux blanc avec sucres"}	Bordeaux blanc avec sucres	\N
15250	65	Bordeaux Haut-Benauge	AOC -	AOP -	{"fra": "Bordeaux Haut-Benauge"}	Bordeaux Haut-Benauge	\N
15251	65	Bordeaux Haut-Benauge	AOC -	AOP -	{"fra": "Bordeaux Haut-Benauge avec sucres"}	Bordeaux Haut-Benauge avec sucres	\N
15253	1807	Bordeaux supérieur	AOC -	AOP -	{"fra": "Bordeaux supérieur blanc"}	Bordeaux supérieur blanc	\N
15254	1807	Bordeaux supérieur	AOC -	AOP -	{"fra": "Bordeaux supérieur rouge"}	Bordeaux supérieur rouge	\N
4480	1526	Boudin blanc de Rethel	\N	IGP -	{"fra": "Boudin blanc de Rethel"}	Boudin blanc de Rethel	IG/19/95
10197	2184	Bourgogne	AOC -	AOP -	{"fra": "Bourgogne blanc"}	Bourgogne blanc	\N
12326	2184	Bourgogne	AOC -	AOP -	{"fra": "Bourgogne clairet ou rosé"}	Bourgogne clairet ou rosé	\N
12362	2184	Bourgogne	AOC -	AOP -	{"fra": "Bourgogne rouge"}	Bourgogne rouge	\N
12364	2184	Bourgogne	AOC -	AOP -	{"fra": "Bourgogne nouveau ou primeur"}	Bourgogne nouveau ou primeur	\N
12365	2184	Bourgogne	AOC -	AOP -	{"fra": "Bourgogne gamay rouge"}	Bourgogne gamay rouge	\N
5356	2183	Bourgogne aligoté	AOC -	AOP -	{"fra": "Bourgogne aligoté"}	Bourgogne aligoté	\N
9418	2183	Bourgogne aligoté	AOC -	AOP -	{"fra": "Bourgogne aligoté nouveau ou primeur"}	Bourgogne aligoté nouveau ou primeur	\N
12316	342	Bourgogne Chitry	AOC -	AOP -	{"fra": "Bourgogne Chitry blanc"}	Bourgogne Chitry blanc	\N
12324	342	Bourgogne Chitry	AOC -	AOP -	{"fra": "Bourgogne Chitry clairet ou rosé"}	Bourgogne Chitry clairet ou rosé	\N
12325	342	Bourgogne Chitry	AOC -	AOP -	{"fra": "Bourgogne Chitry rouge"}	Bourgogne Chitry rouge	\N
12327	340	Bourgogne Côte Chalonnaise	AOC -	AOP -	{"fra": "Bourgogne Côte Chalonnaise blanc"}	Bourgogne Côte Chalonnaise blanc	\N
12328	340	Bourgogne Côte Chalonnaise	AOC -	AOP -	{"fra": "Bourgogne Côte Chalonnaise clairet ou rosé"}	Bourgogne Côte Chalonnaise clairet ou rosé	\N
12329	340	Bourgogne Côte Chalonnaise	AOC -	AOP -	{"fra": "Bourgogne Côte Chalonnaise rouge"}	Bourgogne Côte Chalonnaise rouge	\N
14636	2442	Bourgogne Côte d'Or	AOC -	AOP -	{"fra": "Bourgogne Côte d'Or blanc"}	Bourgogne Côte d'Or blanc	\N
14637	2442	Bourgogne Côte d'Or	AOC -	AOP -	{"fra": "Bourgogne Côte d'Or rouge"}	Bourgogne Côte d'Or rouge	\N
12333	349	Bourgogne Côte Saint-Jacques	AOC -	AOP -	{"fra": "Bourgogne Côte Saint-Jacques blanc"}	Bourgogne Côte Saint-Jacques blanc	\N
12334	349	Bourgogne Côte Saint-Jacques	AOC -	AOP -	{"fra": "Bourgogne Côte Saint-Jacques clairet ou rosé"}	Bourgogne Côte Saint-Jacques clairet ou rosé	\N
12335	349	Bourgogne Côte Saint-Jacques	AOC -	AOP -	{"fra": "Bourgogne Côte Saint-Jacques rouge"}	Bourgogne Côte Saint-Jacques rouge	\N
12336	341	Bourgogne Côtes d'Auxerre	AOC -	AOP -	{"fra": "Bourgogne Côtes d'Auxerre blanc"}	Bourgogne Côtes d'Auxerre blanc	\N
12337	341	Bourgogne Côtes d'Auxerre	AOC -	AOP -	{"fra": "Bourgogne Côtes d'Auxerre clairet ou rosé"}	Bourgogne Côtes d'Auxerre clairet ou rosé	\N
12338	341	Bourgogne Côtes d'Auxerre	AOC -	AOP -	{"fra": "Bourgogne Côtes d'Auxerre rouge"}	Bourgogne Côtes d'Auxerre rouge	\N
12339	351	Bourgogne Côtes du Couchois	AOC -	AOP -	{"fra": "Bourgogne Côtes du Couchois"}	Bourgogne Côtes du Couchois	\N
13201	1958	Bœuf de Charolles	AOC -	AOP -	{"fra": "Bœuf de Charolles"}	Bœuf de Charolles	\N
12340	343	Bourgogne Coulanges-la-Vineuse	AOC -	AOP -	{"fra": "Bourgogne Coulanges-la-Vineuse blanc"}	Bourgogne Coulanges-la-Vineuse blanc	\N
12341	343	Bourgogne Coulanges-la-Vineuse	AOC -	AOP -	{"fra": "Bourgogne Coulanges-la-Vineuse clairet ou rosé"}	Bourgogne Coulanges-la-Vineuse clairet ou rosé	\N
12342	343	Bourgogne Coulanges-la-Vineuse	AOC -	AOP -	{"fra": "Bourgogne Coulanges-la-Vineuse rouge"}	Bourgogne Coulanges-la-Vineuse rouge	\N
12343	344	Bourgogne Epineuil	AOC -	AOP -	{"fra": "Bourgogne Epineuil clairet ou rosé"}	Bourgogne Epineuil clairet ou rosé	\N
12344	344	Bourgogne Epineuil	AOC -	AOP -	{"fra": "Bourgogne Epineuil rouge"}	Bourgogne Epineuil rouge	\N
12345	338	Bourgogne Hautes Côtes de Beaune	AOC -	AOP -	{"fra": "Bourgogne Hautes Côtes de Beaune blanc"}	Bourgogne Hautes Côtes de Beaune blanc	\N
12346	338	Bourgogne Hautes Côtes de Beaune	AOC -	AOP -	{"fra": "Bourgogne Hautes Côtes de Beaune clairet ou rosé"}	Bourgogne Hautes Côtes de Beaune clairet ou rosé	\N
12348	338	Bourgogne Hautes Côtes de Beaune	AOC -	AOP -	{"fra": "Bourgogne Hautes Côtes de Beaune rouge"}	Bourgogne Hautes Côtes de Beaune rouge	\N
12349	339	Bourgogne Hautes Côtes de Nuits	AOC -	AOP -	{"fra": "Bourgogne Hautes Côtes de Nuits blanc"}	Bourgogne Hautes Côtes de Nuits blanc	\N
12350	339	Bourgogne Hautes Côtes de Nuits	AOC -	AOP -	{"fra": "Bourgogne Hautes Côtes de Nuits clairet ou rosé"}	Bourgogne Hautes Côtes de Nuits clairet ou rosé	\N
12351	339	Bourgogne Hautes Côtes de Nuits	AOC -	AOP -	{"fra": "Bourgogne Hautes Côtes de Nuits rouge"}	Bourgogne Hautes Côtes de Nuits rouge	\N
12352	346	Bourgogne La Chapelle Notre-Dame	AOC -	AOP -	{"fra": "Bourgogne La Chapelle Notre-Dame blanc"}	Bourgogne La Chapelle Notre-Dame blanc	\N
12353	346	Bourgogne La Chapelle Notre-Dame	AOC -	AOP -	{"fra": "Bourgogne La Chapelle Notre-Dame clairet ou rosé"}	Bourgogne La Chapelle Notre-Dame clairet ou rosé	\N
12354	346	Bourgogne La Chapelle Notre-Dame	AOC -	AOP -	{"fra": "Bourgogne La Chapelle Notre-Dame rouge"}	Bourgogne La Chapelle Notre-Dame rouge	\N
12355	347	Bourgogne Le Chapitre	AOC -	AOP -	{"fra": "Bourgogne Le Chapitre blanc"}	Bourgogne Le Chapitre blanc	\N
12356	347	Bourgogne Le Chapitre	AOC -	AOP -	{"fra": "Bourgogne Le Chapitre clairet ou rosé"}	Bourgogne Le Chapitre clairet ou rosé	\N
12357	347	Bourgogne Le Chapitre	AOC -	AOP -	{"fra": "Bourgogne Le Chapitre rouge"}	Bourgogne Le Chapitre rouge	\N
12358	348	Bourgogne Montrecul	AOC -	AOP -	{"fra": "Bourgogne Montrecul ou Montre-Cul ou En Montre-Cul blanc"}	Bourgogne Montrecul ou Montre-Cul ou En Montre-Cul blanc	\N
12359	348	Bourgogne Montrecul	AOC -	AOP -	{"fra": "Bourgogne Montrecul ou Montre-Cul ou En Montre-Cul clairet ou rosé"}	Bourgogne Montrecul ou Montre-Cul ou En Montre-Cul clairet ou rosé	\N
12360	348	Bourgogne Montrecul	AOC -	AOP -	{"fra": "Bourgogne Montrecul ou Montre-Cul ou En Montre-Cul rouge"}	Bourgogne Montrecul ou Montre-Cul ou En Montre-Cul rouge	\N
7751	1879	Bourgogne mousseux	AOC -	AOP -	{"fra": "Bourgogne mousseux"}	Bourgogne mousseux	\N
10237	1876	Bourgogne Passe-tout-grains	AOC -	AOP -	{"fra": "Bourgogne Passe-tout-grains rouge"}	Bourgogne Passe-tout-grains rouge	\N
12312	1876	Bourgogne Passe-tout-grains	AOC -	AOP -	{"fra": "Bourgogne Passe-tout-grains rosé"}	Bourgogne Passe-tout-grains rosé	\N
12363	1641	Bourgogne Tonnerre	AOC -	AOP -	{"fra": "Bourgogne Tonnerre"}	Bourgogne Tonnerre	\N
15219	163	Bourgueil	AOC -	AOP -	{"fra": "Bourgueil rosé"}	Bourgueil rosé	\N
15220	163	Bourgueil	AOC -	AOP -	{"fra": "Bourgueil rouge"}	Bourgueil rouge	\N
7747	1231	Bouzeron	AOC -	AOP -	{"fra": "Bouzeron"}	Bouzeron	\N
16167	1459	Brie de Meaux	AOC -	AOP -	{"fra": "Brie de Meaux"}	Brie de Meaux	\N
12196	1460	Brie de Melun	AOC -	AOP -	{"fra": "Brie de Melun"}	Brie de Melun	\N
4365	1774	Brillat-Savarin	\N	IGP -	{"fra": "Brillat-Savarin"}	Brillat-Savarin	\N
14146	1608	Brioche vendéenne	\N	IGP -	{"fra": "Brioche vendéenne"}	Brioche vendéenne	IG/02/98
3269	1461	Brocciu	AOC -	AOP -	{"fra": "Brocciu"}	Brocciu	\N
10241	354	Brouilly	AOC -	AOP -	{"fra": "Brouilly ou Brouilly cru du Beaujolais"}	Brouilly ou Brouilly cru du Beaujolais	\N
4311	1720	Brousse du Rove	AOC -	AOP -	{"fra": "Brousse du Rove"}	Brousse du Rove	\N
15465	2349	Brulhois	AOC -	AOP -	{"fra": "Brulhois rouge"}	Brulhois rouge	\N
7634	1597	Bugey	AOC -	AOP -	{"fra": "Bugey blanc"}	Bugey blanc	\N
12219	1597	Bugey	AOC -	AOP -	{"fra": "Bugey mousseux blanc"}	Bugey mousseux blanc	\N
12220	1597	Bugey	AOC -	AOP -	{"fra": "Bugey mousseux rosé"}	Bugey mousseux rosé	\N
12221	1597	Bugey	AOC -	AOP -	{"fra": "Bugey pétillant blanc"}	Bugey pétillant blanc	\N
12222	1597	Bugey	AOC -	AOP -	{"fra": "Bugey pétillant rosé"}	Bugey pétillant rosé	\N
12223	1597	Bugey	AOC -	AOP -	{"fra": "Bugey rosé"}	Bugey rosé	\N
12224	1597	Bugey	AOC -	AOP -	{"fra": "Bugey rouge"}	Bugey rouge	\N
12225	1597	Bugey	AOC -	AOP -	{"fra": "Bugey rouge Gamay"}	Bugey rouge Gamay	\N
12226	1597	Bugey	AOC -	AOP -	{"fra": "Bugey rouge Mondeuse"}	Bugey rouge Mondeuse	\N
12227	1597	Bugey	AOC -	AOP -	{"fra": "Bugey rouge Pinot noir"}	Bugey rouge Pinot noir	\N
12213	1598	Bugey Cerdon	AOC -	AOP -	{"fra": "Bugey Cerdon méthode ancestrale"}	Bugey Cerdon méthode ancestrale	\N
12214	1599	Bugey Manicle	AOC -	AOP -	{"fra": "Bugey Manicle blanc"}	Bugey Manicle blanc	\N
12215	1599	Bugey Manicle	AOC -	AOP -	{"fra": "Bugey Manicle rouge"}	Bugey Manicle rouge	\N
12216	1600	Bugey Montagnieu	AOC -	AOP -	{"fra": "Bugey Montagnieu"}	Bugey Montagnieu	\N
12217	1600	Bugey Montagnieu	AOC -	AOP -	{"fra": "Bugey Montagnieu mousseux"}	Bugey Montagnieu mousseux	\N
12218	1600	Bugey Montagnieu	AOC -	AOP -	{"fra": "Bugey Montagnieu pétillant"}	Bugey Montagnieu pétillant	\N
14202	2431	Bulot de la Baie de Granville	\N	IGP -	{"fra": "Bulot de la Baie de Granville"}	Bulot de la Baie de Granville	\N
15934	67	Buzet	AOC -	AOP -	{"fra": "Buzet blanc"}	Buzet blanc	\N
15936	67	Buzet	AOC -	AOP -	{"fra": "Buzet rosé"}	Buzet rosé	\N
15937	67	Buzet	AOC -	AOP -	{"fra": "Buzet rouge"}	Buzet rouge	\N
3461	1590	Bœuf Charolais du Bourbonnais	\N	IGP -	{"fra": "Bœuf Charolais du Bourbonnais"}	Bœuf Charolais du Bourbonnais	IG/36/94
4148	1668	Bœuf de Bazas	\N	IGP -	{"fra": "Bœuf de Bazas"}	Bœuf de Bazas	\N
3396	1524	Bœuf de Chalosse	\N	IGP -	{"fra": "Bœuf de Chalosse"}	Bœuf de Chalosse	IG/35/94
4143	1660	Bœuf de Vendée	\N	IGP -	{"fra": "Bœuf de Vendée"}	Bœuf de Vendée	IG/24/01
3397	1525	Bœuf du Maine	\N	IGP -	{"fra": "Bœuf du Maine"}	Bœuf du Maine	IG/37/94
9548	1276	Cabardès	AOC -	AOP -	{"fra": "Cabardès rosé"}	Cabardès rosé	\N
9549	1276	Cabardès	AOC -	AOP -	{"fra": "Cabardès rouge"}	Cabardès rouge	\N
14906	68	Cadillac	AOC -	AOP -	{"fra": "Cadillac"}	Cadillac	\N
8230	2145	Cahors	AOC -	AOP -	{"fra": "Cahors"}	Cahors	\N
14866	1822	Cairanne	AOC -	AOP -	{"fra": "Cairanne blanc"}	Cairanne blanc	\N
14867	1822	Cairanne	AOC -	AOP -	{"fra": "Cairanne rouge"}	Cairanne rouge	\N
13415	1993	Calvados	\N	IGP -	{"fra": "Calvados blanc"}	Calvados blanc	\N
13416	1993	Calvados	\N	IGP -	{"fra": "Calvados blanc primeur ou nouveau blanc"}	Calvados blanc primeur ou nouveau blanc	\N
13417	1993	Calvados	\N	IGP -	{"fra": "Calvados rosé"}	Calvados rosé	\N
13418	1993	Calvados	\N	IGP -	{"fra": "Calvados rosé primeur ou nouveau rosé"}	Calvados rosé primeur ou nouveau rosé	\N
13419	1993	Calvados	\N	IGP -	{"fra": "Calvados rouge"}	Calvados rouge	\N
13420	1993	Calvados	\N	IGP -	{"fra": "Calvados rouge primeur ou nouveau rouge"}	Calvados rouge primeur ou nouveau rouge	\N
13106	2375	Calvados	AOC -	IG - 	{"fra": "Calvados"}	Calvados	\N
13114	1362	Calvados Domfrontais	AOC -	IG - 	{"fra": "Calvados Domfrontais"}	Calvados Domfrontais	\N
10465	2307	Calvados Grisy	\N	IGP -	{"fra": "Calvados Grisy blanc"}	Calvados Grisy blanc	\N
10466	2307	Calvados Grisy	\N	IGP -	{"fra": "Calvados Grisy rosé"}	Calvados Grisy rosé	\N
10467	2307	Calvados Grisy	\N	IGP -	{"fra": "Calvados Grisy rouge"}	Calvados Grisy rouge	\N
10468	2307	Calvados Grisy	\N	IGP -	{"fra": "Calvados Grisy primeur ou nouveau blanc"}	Calvados Grisy primeur ou nouveau blanc	\N
10470	2307	Calvados Grisy	\N	IGP -	{"fra": "Calvados Grisy primeur ou nouveau rosé"}	Calvados Grisy primeur ou nouveau rosé	\N
10471	2307	Calvados Grisy	\N	IGP -	{"fra": "Calvados Grisy primeur ou nouveau rouge"}	Calvados Grisy primeur ou nouveau rouge	\N
13105	2374	Calvados Pays d'Auge	AOC -	IG - 	{"fra": "Calvados Pays d'Auge"}	Calvados Pays d'Auge	\N
4204	1462	Camembert de Normandie	AOC -	AOP -	{"fra": "Camembert de Normandie"}	Camembert de Normandie	\N
12949	1527	Canard à foie gras du Sud-Ouest	\N	IGP -	{"fra": "Canard à foie gras du Sud-Ouest (Chalosse, Gascogne, Gers, Landes, Périgord, Quercy"}	Canard à foie gras du Sud-Ouest (Chalosse, Gascogne, Gers, Landes, Périgord, Quercy	IG/06/95
8353	70	Canon Fronsac	AOC -	AOP -	{"fra": "Canon Fronsac"}	Canon Fronsac	\N
15010	1463	Cantal	AOC -	AOP -	{"fra": "Cantal ou Fourme de Cantal"}	Cantal ou Fourme de Cantal	\N
8664	1319	Cassis	AOC -	AOP -	{"fra": "Cassis blanc"}	Cassis blanc	\N
8665	1319	Cassis	AOC -	AOP -	{"fra": "Cassis rosé"}	Cassis rosé	\N
8666	1319	Cassis	AOC -	AOP -	{"fra": "Cassis rouge"}	Cassis rouge	\N
4433	1809	Cassis de Bourgogne	\N	IG - 	{"fra": "Cassis de Bourgogne"}	Cassis de Bourgogne	\N
12823	2348	Cassis de Dijon	\N	IG - 	{"fra": "Cassis de Dijon"}	Cassis de Dijon	\N
13108	2376	Cassis de Saintonge	\N	IG - 	{"fra": "Cassis de Saintonge"}	Cassis de Saintonge	\N
7875	2114	Cathare	\N	IGP -	{"fra": "Le Pays Cathare blanc"}	Le Pays Cathare blanc	\N
8430	2114	Cathare	\N	IGP -	{"fra": "Le Pays Cathare rosé"}	Le Pays Cathare rosé	\N
8431	2114	Cathare	\N	IGP -	{"fra": "Le Pays Cathare rouge"}	Le Pays Cathare rouge	\N
10472	2114	Cathare	\N	IGP -	{"fra": "Le Pays Cathare primeur ou nouveau blanc"}	Le Pays Cathare primeur ou nouveau blanc	\N
10473	2114	Cathare	\N	IGP -	{"fra": "Le Pays Cathare primeur ou nouveau rosé"}	Le Pays Cathare primeur ou nouveau rosé	\N
10474	2114	Cathare	\N	IGP -	{"fra": "Le Pays Cathare primeur ou nouveau rouge"}	Le Pays Cathare primeur ou nouveau rouge	\N
9198	71	Cérons	AOC -	AOP -	{"fra": "Cérons"}	Cérons	\N
15391	2217	Cévennes	\N	IGP -	{"fra": "Cévennes blanc"}	Cévennes blanc	\N
15392	2217	Cévennes	\N	IGP -	{"fra": "Cévennes mousseux de qualité blanc"}	Cévennes mousseux de qualité blanc	\N
15393	2217	Cévennes	\N	IGP -	{"fra": "Cévennes mousseux de qualité rosé"}	Cévennes mousseux de qualité rosé	\N
15394	2217	Cévennes	\N	IGP -	{"fra": "Cévennes mousseux de qualité rouge"}	Cévennes mousseux de qualité rouge	\N
15395	2217	Cévennes	\N	IGP -	{"fra": "Cévennes primeur ou nouveau blanc"}	Cévennes primeur ou nouveau blanc	\N
15396	2217	Cévennes	\N	IGP -	{"fra": "Cévennes primeur ou nouveau rosé"}	Cévennes primeur ou nouveau rosé	\N
15397	2217	Cévennes	\N	IGP -	{"fra": "Cévennes primeur ou nouveau rouge"}	Cévennes primeur ou nouveau rouge	\N
15398	2217	Cévennes	\N	IGP -	{"fra": "Cévennes rosé"}	Cévennes rosé	\N
15399	2217	Cévennes	\N	IGP -	{"fra": "Cévennes rouge"}	Cévennes rouge	\N
15400	2217	Cévennes	\N	IGP -	{"fra": "Cévennes surmûri blanc"}	Cévennes surmûri blanc	\N
15401	2217	Cévennes	\N	IGP -	{"fra": "Cévennes surmûri rosé"}	Cévennes surmûri rosé	\N
15402	2217	Cévennes	\N	IGP -	{"fra": "Cévennes surmûri rouge"}	Cévennes surmûri rouge	\N
16081	1464	Chabichou du Poitou	AOC -	AOP -	{"fra": "Chabichou du Poitou"}	Chabichou du Poitou	\N
6351	356	Chablis	AOC -	AOP -	{"fra": "Chablis"}	Chablis	\N
6352	398	Chablis Grand Cru	AOC -	AOP -	{"fra": "Chablis Grand Cru"}	Chablis Grand Cru	\N
8945	399	Chablis Grand Cru Blanchot	AOC -	AOP -	{"fra": "Chablis Grand Cru Blanchot"}	Chablis Grand Cru Blanchot	\N
8947	400	Chablis Grand Cru Bougros	AOC -	AOP -	{"fra": "Chablis Grand Cru Bougros"}	Chablis Grand Cru Bougros	\N
8948	401	Chablis Grand Cru Grenouilles	AOC -	AOP -	{"fra": "Chablis Grand Cru Grenouilles"}	Chablis Grand Cru Grenouilles	\N
8949	402	Chablis Grand Cru Les Clos	AOC -	AOP -	{"fra": "Chablis Grand Cru Les Clos"}	Chablis Grand Cru Les Clos	\N
8950	403	Chablis Grand Cru Preuses	AOC -	AOP -	{"fra": "Chablis Grand Cru Preuses"}	Chablis Grand Cru Preuses	\N
8951	404	Chablis Grand Cru Valmur	AOC -	AOP -	{"fra": "Chablis Grand Cru Valmur"}	Chablis Grand Cru Valmur	\N
8952	405	Chablis Grand Cru Vaudésir	AOC -	AOP -	{"fra": "Chablis Grand Cru Vaudésir"}	Chablis Grand Cru Vaudésir	\N
9682	397	Chablis premier cru	AOC -	AOP -	{"fra": "Chablis premier cru"}	Chablis premier cru	\N
9683	357	Chablis premier cru Beauroy	AOC -	AOP -	{"fra": "Chablis premier cru Beauroy"}	Chablis premier cru Beauroy	\N
9684	358	Chablis premier cru Berdiot	AOC -	AOP -	{"fra": "Chablis premier cru Berdiot"}	Chablis premier cru Berdiot	\N
9685	359	Chablis premier cru Beugnons	AOC -	AOP -	{"fra": "Chablis premier cru Beugnons"}	Chablis premier cru Beugnons	\N
9686	360	Chablis premier cru Butteaux	AOC -	AOP -	{"fra": "Chablis premier cru Butteaux"}	Chablis premier cru Butteaux	\N
9687	361	Chablis premier cru Chapelot	AOC -	AOP -	{"fra": "Chablis premier cru Chapelot"}	Chablis premier cru Chapelot	\N
9688	362	Chablis premier cru Chatains	AOC -	AOP -	{"fra": "Chablis premier cru Chatains"}	Chablis premier cru Chatains	\N
9689	363	Chablis premier cru Chaume de Talvat	AOC -	AOP -	{"fra": "Chablis premier cru Chaume de Talvat"}	Chablis premier cru Chaume de Talvat	\N
9690	364	Chablis premier cru Côte de Bréchain	AOC -	AOP -	{"fra": "Chablis premier cru Côte de Bréchain"}	Chablis premier cru Côte de Bréchain	\N
9691	365	Chablis premier cru Côte de Cuisy	AOC -	AOP -	{"fra": "Chablis premier cru Côte de Cuisy"}	Chablis premier cru Côte de Cuisy	\N
9692	366	Chablis premier cru Côte de Fontenay	AOC -	AOP -	{"fra": "Chablis premier cru Côte de Fontenay"}	Chablis premier cru Côte de Fontenay	\N
9693	367	Chablis premier cru Côte de Jouan	AOC -	AOP -	{"fra": "Chablis premier cru Côte de Jouan"}	Chablis premier cru Côte de Jouan	\N
9694	368	Chablis premier cru Côte de Léchet	AOC -	AOP -	{"fra": "Chablis premier cru Côte de Léchet"}	Chablis premier cru Côte de Léchet	\N
9695	369	Chablis premier cru Côte de Savant	AOC -	AOP -	{"fra": "Chablis premier cru Côte de Savant"}	Chablis premier cru Côte de Savant	\N
9696	370	Chablis premier cru Côte de Vaubarousse	AOC -	AOP -	{"fra": "Chablis premier cru Côte de Vaubarousse"}	Chablis premier cru Côte de Vaubarousse	\N
9697	371	Chablis premier cru Côte des Prés-Girots	AOC -	AOP -	{"fra": "Chablis premier cru Côte des Prés-Girots"}	Chablis premier cru Côte des Prés-Girots	\N
9698	372	Chablis premier cru Forêts	AOC -	AOP -	{"fra": "Chablis premier cru Forêts"}	Chablis premier cru Forêts	\N
9699	373	Chablis premier cru Fourchaume	AOC -	AOP -	{"fra": "Chablis premier cru Fourchaume"}	Chablis premier cru Fourchaume	\N
9704	374	Chablis premier cru L'Homme Mort	AOC -	AOP -	{"fra": "Chablis premier cru L'Homme Mort"}	Chablis premier cru L'Homme Mort	\N
9700	375	Chablis premier cru Les Beauregards	AOC -	AOP -	{"fra": "Chablis premier cru Les Beauregards"}	Chablis premier cru Les Beauregards	\N
9701	376	Chablis premier cru Les Epinottes	AOC -	AOP -	{"fra": "Chablis premier cru Les Epinottes"}	Chablis premier cru Les Epinottes	\N
9702	377	Chablis premier cru Les Fourneaux	AOC -	AOP -	{"fra": "Chablis premier cru Les Fourneaux"}	Chablis premier cru Les Fourneaux	\N
9703	378	Chablis premier cru Les Lys	AOC -	AOP -	{"fra": "Chablis premier cru Les Lys"}	Chablis premier cru Les Lys	\N
9705	383	Chablis premier cru Mélinots	AOC -	AOP -	{"fra": "Chablis premier cru Mélinots"}	Chablis premier cru Mélinots	\N
9706	379	Chablis premier cru Mont de Milieu	AOC -	AOP -	{"fra": "Chablis premier cru Mont de Milieu"}	Chablis premier cru Mont de Milieu	\N
9707	381	Chablis premier cru Montée de Tonnerre	AOC -	AOP -	{"fra": "Chablis premier cru Montée de Tonnerre"}	Chablis premier cru Montée de Tonnerre	\N
9708	380	Chablis premier cru Montmains	AOC -	AOP -	{"fra": "Chablis premier cru Montmains"}	Chablis premier cru Montmains	\N
9709	382	Chablis premier cru Morein	AOC -	AOP -	{"fra": "Chablis premier cru Morein"}	Chablis premier cru Morein	\N
9710	384	Chablis premier cru Pied d'Aloup	AOC -	AOP -	{"fra": "Chablis premier cru Pied d'Aloup"}	Chablis premier cru Pied d'Aloup	\N
9711	385	Chablis premier cru Roncières	AOC -	AOP -	{"fra": "Chablis premier cru Roncières"}	Chablis premier cru Roncières	\N
9712	386	Chablis premier cru Sécher	AOC -	AOP -	{"fra": "Chablis premier cru Sécher"}	Chablis premier cru Sécher	\N
9713	387	Chablis premier cru Troesmes	AOC -	AOP -	{"fra": "Chablis premier cru Troesmes"}	Chablis premier cru Troesmes	\N
9714	388	Chablis premier cru Vaillons	AOC -	AOP -	{"fra": "Chablis premier cru Vaillons"}	Chablis premier cru Vaillons	\N
9715	390	Chablis premier cru Vau de Vey	AOC -	AOP -	{"fra": "Chablis premier cru Vau de Vey"}	Chablis premier cru Vau de Vey	\N
9716	389	Chablis premier cru Vau Ligneau	AOC -	AOP -	{"fra": "Chablis premier cru Vau Ligneau"}	Chablis premier cru Vau Ligneau	\N
9717	391	Chablis premier cru Vaucoupin	AOC -	AOP -	{"fra": "Chablis premier cru Vaucoupin"}	Chablis premier cru Vaucoupin	\N
9718	392	Chablis premier cru Vaugiraut	AOC -	AOP -	{"fra": "Chablis premier cru Vaugiraut"}	Chablis premier cru Vaugiraut	\N
9719	393	Chablis premier cru Vaulorent	AOC -	AOP -	{"fra": "Chablis premier cru Vaulorent"}	Chablis premier cru Vaulorent	\N
9720	394	Chablis premier cru Vaupulent	AOC -	AOP -	{"fra": "Chablis premier cru Vaupulent"}	Chablis premier cru Vaupulent	\N
9721	395	Chablis premier cru Vaux Ragons	AOC -	AOP -	{"fra": "Chablis premier cru Vaux Ragons"}	Chablis premier cru Vaux Ragons	\N
9722	396	Chablis premier cru Vosgros	AOC -	AOP -	{"fra": "Chablis premier cru Vosgros"}	Chablis premier cru Vosgros	\N
7717	406	Chambertin	AOC -	AOP -	{"fra": "Chambertin"}	Chambertin	\N
7718	407	Chambertin-Clos de Bèze	AOC -	AOP -	{"fra": "Chambertin-Clos de Bèze"}	Chambertin-Clos de Bèze	\N
7683	408	Chambolle-Musigny	AOC -	AOP -	{"fra": "Chambolle-Musigny"}	Chambolle-Musigny	\N
8793	433	Chambolle-Musigny premier cru	AOC -	AOP -	{"fra": "Chambolle-Musigny premier cru"}	Chambolle-Musigny premier cru	\N
8794	409	Chambolle-Musigny premier cru Aux Beaux Bruns	AOC -	AOP -	{"fra": "Chambolle-Musigny premier cru Aux Beaux Bruns"}	Chambolle-Musigny premier cru Aux Beaux Bruns	\N
8795	410	Chambolle-Musigny premier cru Aux Combottes	AOC -	AOP -	{"fra": "Chambolle-Musigny premier cru Aux Combottes"}	Chambolle-Musigny premier cru Aux Combottes	\N
8796	411	Chambolle-Musigny premier cru Aux Echanges	AOC -	AOP -	{"fra": "Chambolle-Musigny premier cru Aux Echanges"}	Chambolle-Musigny premier cru Aux Echanges	\N
8797	412	Chambolle-Musigny premier cru Derrière la Grange	AOC -	AOP -	{"fra": "Chambolle-Musigny premier cru Derrière la Grange"}	Chambolle-Musigny premier cru Derrière la Grange	\N
8798	413	Chambolle-Musigny premier cru La Combe d'Orveau	AOC -	AOP -	{"fra": "Chambolle-Musigny premier cru La Combe d'Orveau"}	Chambolle-Musigny premier cru La Combe d'Orveau	\N
8799	414	Chambolle-Musigny premier cru Les Amoureuses	AOC -	AOP -	{"fra": "Chambolle-Musigny premier cru Les Amoureuses"}	Chambolle-Musigny premier cru Les Amoureuses	\N
8800	415	Chambolle-Musigny premier cru Les Baudes	AOC -	AOP -	{"fra": "Chambolle-Musigny premier cru Les Baudes"}	Chambolle-Musigny premier cru Les Baudes	\N
8801	416	Chambolle-Musigny premier cru Les Borniques	AOC -	AOP -	{"fra": "Chambolle-Musigny premier cru Les Borniques"}	Chambolle-Musigny premier cru Les Borniques	\N
8802	417	Chambolle-Musigny premier cru Les Carrières	AOC -	AOP -	{"fra": "Chambolle-Musigny premier cru Les Carrières"}	Chambolle-Musigny premier cru Les Carrières	\N
8803	418	Chambolle-Musigny premier cru Les Chabiots	AOC -	AOP -	{"fra": "Chambolle-Musigny premier cru Les Chabiots"}	Chambolle-Musigny premier cru Les Chabiots	\N
8804	419	Chambolle-Musigny premier cru Les Charmes	AOC -	AOP -	{"fra": "Chambolle-Musigny premier cru Les Charmes"}	Chambolle-Musigny premier cru Les Charmes	\N
8805	420	Chambolle-Musigny premier cru Les Chatelots	AOC -	AOP -	{"fra": "Chambolle-Musigny premier cru Les Chatelots"}	Chambolle-Musigny premier cru Les Chatelots	\N
8806	421	Chambolle-Musigny premier cru Les Combottes	AOC -	AOP -	{"fra": "Chambolle-Musigny premier cru Les Combottes"}	Chambolle-Musigny premier cru Les Combottes	\N
8807	422	Chambolle-Musigny premier cru Les Cras	AOC -	AOP -	{"fra": "Chambolle-Musigny premier cru Les Cras"}	Chambolle-Musigny premier cru Les Cras	\N
8808	423	Chambolle-Musigny premier cru Les Feusselottes ou Les Feusselotes	AOC -	AOP -	{"fra": "Chambolle-Musigny premier cru Les Feusselottes ou Les Feusselotes"}	Chambolle-Musigny premier cru Les Feusselottes ou Les Feusselotes	\N
8809	424	Chambolle-Musigny premier cru Les Fuées	AOC -	AOP -	{"fra": "Chambolle-Musigny premier cru Les Fuées"}	Chambolle-Musigny premier cru Les Fuées	\N
8810	425	Chambolle-Musigny premier cru Les Groseilles	AOC -	AOP -	{"fra": "Chambolle-Musigny premier cru Les Groseilles"}	Chambolle-Musigny premier cru Les Groseilles	\N
8811	426	Chambolle-Musigny premier cru Les Gruenchers	AOC -	AOP -	{"fra": "Chambolle-Musigny premier cru Les Gruenchers"}	Chambolle-Musigny premier cru Les Gruenchers	\N
8812	427	Chambolle-Musigny premier cru Les Hauts Doix	AOC -	AOP -	{"fra": "Chambolle-Musigny premier cru Les Hauts Doix"}	Chambolle-Musigny premier cru Les Hauts Doix	\N
8813	428	Chambolle-Musigny premier cru Les Lavrottes	AOC -	AOP -	{"fra": "Chambolle-Musigny premier cru Les Lavrottes"}	Chambolle-Musigny premier cru Les Lavrottes	\N
8814	429	Chambolle-Musigny premier cru Les Noirots	AOC -	AOP -	{"fra": "Chambolle-Musigny premier cru Les Noirots"}	Chambolle-Musigny premier cru Les Noirots	\N
8815	430	Chambolle-Musigny premier cru Les Plantes	AOC -	AOP -	{"fra": "Chambolle-Musigny premier cru Les Plantes"}	Chambolle-Musigny premier cru Les Plantes	\N
8816	431	Chambolle-Musigny premier cru Les Sentiers	AOC -	AOP -	{"fra": "Chambolle-Musigny premier cru Les Sentiers"}	Chambolle-Musigny premier cru Les Sentiers	\N
7686	502	Chorey-lès-Beaune	AOC -	AOP -	{"fra": "Chorey-lès-Beaune"}	Chorey-lès-Beaune	\N
8817	432	Chambolle-Musigny premier cru Les Véroilles	AOC -	AOP -	{"fra": "Chambolle-Musigny premier cru Les Véroilles"}	Chambolle-Musigny premier cru Les Véroilles	\N
13951	54	Champagne	AOC -	AOP -	{"fra": "Champagne"}	Champagne	\N
13952	54	Champagne	AOC -	AOP -	{"fra": "Champagne rosé"}	Champagne rosé	\N
14108	54	Champagne	AOC -	AOP -	{"fra": "Champagne grand cru"}	Champagne grand cru	\N
14109	54	Champagne	AOC -	AOP -	{"fra": "Champagne premier cru"}	Champagne premier cru	\N
4232	1466	Chaource	AOC -	AOP -	{"fra": "Chaource"}	Chaource	\N
7719	434	Chapelle-Chambertin	AOC -	AOP -	{"fra": "Chapelle-Chambertin"}	Chapelle-Chambertin	\N
13459	2396	Chapon du Périgord	\N	IGP -	{"fra": "Chapon du Périgord"}	Chapon du Périgord	\N
8459	1994	Charentais	\N	IGP -	{"fra": "Charentais blanc"}	Charentais blanc	\N
8466	1994	Charentais	\N	IGP -	{"fra": "Charentais rosé"}	Charentais rosé	\N
8467	1994	Charentais	\N	IGP -	{"fra": "Charentais rouge"}	Charentais rouge	\N
8471	1994	Charentais	\N	IGP -	{"fra": "Charentais blanc primeur ou nouveau"}	Charentais blanc primeur ou nouveau	\N
8478	1994	Charentais	\N	IGP -	{"fra": "Charentais rosé primeur ou nouveau"}	Charentais rosé primeur ou nouveau	\N
8479	1994	Charentais	\N	IGP -	{"fra": "Charentais rouge primeur ou nouveau"}	Charentais rouge primeur ou nouveau	\N
10484	2308	Charentais Charente	\N	IGP -	{"fra": "Charentais Charente blanc"}	Charentais Charente blanc	\N
10485	2308	Charentais Charente	\N	IGP -	{"fra": "Charentais Charente rosé"}	Charentais Charente rosé	\N
10486	2308	Charentais Charente	\N	IGP -	{"fra": "Charentais Charente rouge"}	Charentais Charente rouge	\N
10487	2308	Charentais Charente	\N	IGP -	{"fra": "Charentais Charente primeur ou nouveau blanc"}	Charentais Charente primeur ou nouveau blanc	\N
10488	2308	Charentais Charente	\N	IGP -	{"fra": "Charentais Charente primeur ou nouveau rosé"}	Charentais Charente primeur ou nouveau rosé	\N
10489	2308	Charentais Charente	\N	IGP -	{"fra": "Charentais Charente primeur ou nouveau rouge"}	Charentais Charente primeur ou nouveau rouge	\N
10490	2310	Charentais Charente-Maritime	\N	IGP -	{"fra": "Charentais Charente-Maritime blanc"}	Charentais Charente-Maritime blanc	\N
10491	2310	Charentais Charente-Maritime	\N	IGP -	{"fra": "Charentais Charente-Maritime rosé"}	Charentais Charente-Maritime rosé	\N
10492	2310	Charentais Charente-Maritime	\N	IGP -	{"fra": "Charentais Charente-Maritime rouge"}	Charentais Charente-Maritime rouge	\N
10493	2310	Charentais Charente-Maritime	\N	IGP -	{"fra": "Charentais Charente-Maritime primeur ou nouveau blanc"}	Charentais Charente-Maritime primeur ou nouveau blanc	\N
10494	2310	Charentais Charente-Maritime	\N	IGP -	{"fra": "Charentais Charente-Maritime primeur ou nouveau rosé"}	Charentais Charente-Maritime primeur ou nouveau rosé	\N
10495	2310	Charentais Charente-Maritime	\N	IGP -	{"fra": "Charentais Charente-Maritime primeur ou nouveau rouge"}	Charentais Charente-Maritime primeur ou nouveau rouge	\N
8460	2119	Charentais Ile de Ré	\N	IGP -	{"fra": "Charentais Ile de Ré blanc"}	Charentais Ile de Ré blanc	\N
8461	2119	Charentais Ile de Ré	\N	IGP -	{"fra": "Charentais Ile de Ré rosé"}	Charentais Ile de Ré rosé	\N
8462	2119	Charentais Ile de Ré	\N	IGP -	{"fra": "Charentais Ile de Ré rouge"}	Charentais Ile de Ré rouge	\N
8472	2119	Charentais Ile de Ré	\N	IGP -	{"fra": "Charentais Ile de Ré blanc primeur ou nouveau"}	Charentais Ile de Ré blanc primeur ou nouveau	\N
8473	2119	Charentais Ile de Ré	\N	IGP -	{"fra": "Charentais Ile de Ré rosé primeur ou nouveau"}	Charentais Ile de Ré rosé primeur ou nouveau	\N
15032	1351	Cognac Fine Champagne	AOC -	IG - 	{"fra": "Cognac Fine Champagne"}	Cognac Fine Champagne	\N
8474	2119	Charentais Ile de Ré	\N	IGP -	{"fra": "Charentais Ile de Ré rouge primeur ou nouveau"}	Charentais Ile de Ré rouge primeur ou nouveau	\N
8463	2121	Charentais Ile d’Oléron	\N	IGP -	{"fra": "Charentais Ile d'Oléron blanc"}	Charentais Ile d'Oléron blanc	\N
8464	2121	Charentais Ile d’Oléron	\N	IGP -	{"fra": "Charentais Ile d'Oléron rosé"}	Charentais Ile d'Oléron rosé	\N
8465	2121	Charentais Ile d’Oléron	\N	IGP -	{"fra": "Charentais Ile d'Oléron rouge"}	Charentais Ile d'Oléron rouge	\N
8475	2121	Charentais Ile d’Oléron	\N	IGP -	{"fra": "Charentais Ile d'Oléron blanc primeur ou nouveau"}	Charentais Ile d'Oléron blanc primeur ou nouveau	\N
8476	2121	Charentais Ile d’Oléron	\N	IGP -	{"fra": "Charentais Ile d'Oléron rosé primeur ou nouveau"}	Charentais Ile d'Oléron rosé primeur ou nouveau	\N
8477	2121	Charentais Ile d’Oléron	\N	IGP -	{"fra": "Charentais Ile d'Oléron rouge primeur ou nouveau"}	Charentais Ile d'Oléron rouge primeur ou nouveau	\N
8468	2120	Charentais Saint-Sornin	\N	IGP -	{"fra": "Charentais Saint-Sornin blanc"}	Charentais Saint-Sornin blanc	\N
8469	2120	Charentais Saint-Sornin	\N	IGP -	{"fra": "Charentais Saint-Sornin rosé"}	Charentais Saint-Sornin rosé	\N
8470	2120	Charentais Saint-Sornin	\N	IGP -	{"fra": "Charentais Saint-Sornin rouge"}	Charentais Saint-Sornin rouge	\N
8480	2120	Charentais Saint-Sornin	\N	IGP -	{"fra": "Charentais Saint-Sornin blanc primeur ou nouveau"}	Charentais Saint-Sornin blanc primeur ou nouveau	\N
8481	2120	Charentais Saint-Sornin	\N	IGP -	{"fra": "Charentais Saint-Sornin rosé primeur ou nouveau"}	Charentais Saint-Sornin rosé primeur ou nouveau	\N
8482	2120	Charentais Saint-Sornin	\N	IGP -	{"fra": "Charentais Saint-Sornin rouge primeur ou nouveau"}	Charentais Saint-Sornin rouge primeur ou nouveau	\N
7716	2185	Charlemagne	AOC -	AOP -	{"fra": "Charlemagne"}	Charlemagne	\N
7720	436	Charmes-Chambertin	AOC -	AOP -	{"fra": "Charmes-Chambertin"}	Charmes-Chambertin	\N
13191	1948	Charolais	AOC -	AOP -	{"fra": "Charolais"}	Charolais	\N
4313	1722	Charolais de Bourgogne	\N	IGP -	{"fra": "Charolais de Bourgogne"}	Charolais de Bourgogne	\N
7685	437	Chassagne-Montrachet	AOC -	AOP -	{"fra": "Chassagne-Montrachet"}	Chassagne-Montrachet	\N
9835	437	Chassagne-Montrachet	AOC -	AOP -	{"fra": "Chassagne-Montrachet rouge ou Chassagne-Montrachet Côte de Beaune"}	Chassagne-Montrachet rouge ou Chassagne-Montrachet Côte de Beaune	\N
9725	493	Chassagne-Montrachet premier cru	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru blanc"}	Chassagne-Montrachet premier cru blanc	\N
9824	493	Chassagne-Montrachet premier cru	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru rouge"}	Chassagne-Montrachet premier cru rouge	\N
9723	438	Chassagne-Montrachet premier cru Abbaye de Morgeot	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Abbaye de Morgeot blanc"}	Chassagne-Montrachet premier cru Abbaye de Morgeot blanc	\N
9724	438	Chassagne-Montrachet premier cru Abbaye de Morgeot	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Abbaye de Morgeot rouge"}	Chassagne-Montrachet premier cru Abbaye de Morgeot rouge	\N
9726	439	Chassagne-Montrachet premier cru Blanchot dessus	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Blanchot dessus blanc"}	Chassagne-Montrachet premier cru Blanchot dessus blanc	\N
9727	439	Chassagne-Montrachet premier cru Blanchot dessus	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Blanchot dessus rouge"}	Chassagne-Montrachet premier cru Blanchot dessus rouge	\N
9728	440	Chassagne-Montrachet premier cru Bois de Chassagne	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Bois de Chassagne blanc"}	Chassagne-Montrachet premier cru Bois de Chassagne blanc	\N
9729	440	Chassagne-Montrachet premier cru Bois de Chassagne	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Bois de Chassagne rouge"}	Chassagne-Montrachet premier cru Bois de Chassagne rouge	\N
9730	441	Chassagne-Montrachet premier cru Cailleret	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Cailleret blanc"}	Chassagne-Montrachet premier cru Cailleret blanc	\N
9731	441	Chassagne-Montrachet premier cru Cailleret	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Cailleret rouge"}	Chassagne-Montrachet premier cru Cailleret rouge	\N
9732	442	Chassagne-Montrachet premier cru Champs Jendreau	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Champs Jendreau blanc"}	Chassagne-Montrachet premier cru Champs Jendreau blanc	\N
9733	442	Chassagne-Montrachet premier cru Champs Jendreau	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Champs Jendreau rouge"}	Chassagne-Montrachet premier cru Champs Jendreau rouge	\N
9734	443	Chassagne-Montrachet premier cru Chassagne	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Chassagne blanc"}	Chassagne-Montrachet premier cru Chassagne blanc	\N
9739	443	Chassagne-Montrachet premier cru Chassagne	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Chassagne rouge"}	Chassagne-Montrachet premier cru Chassagne rouge	\N
9737	444	Chassagne-Montrachet premier cru Chassagne du Clos Saint-Jean	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Chassagne du Clos Saint-Jean blanc"}	Chassagne-Montrachet premier cru Chassagne du Clos Saint-Jean blanc	\N
9738	444	Chassagne-Montrachet premier cru Chassagne du Clos Saint-Jean	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Chassagne du Clos Saint-Jean rouge"}	Chassagne-Montrachet premier cru Chassagne du Clos Saint-Jean rouge	\N
9735	445	Chassagne-Montrachet premier cru Clos Chareau	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Clos Chareau blanc"}	Chassagne-Montrachet premier cru Clos Chareau blanc	\N
9736	445	Chassagne-Montrachet premier cru Clos Chareau	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Clos Chareau rouge"}	Chassagne-Montrachet premier cru Clos Chareau rouge	\N
9740	446	Chassagne-Montrachet premier cru Clos Pitois	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Clos Pitois blanc"}	Chassagne-Montrachet premier cru Clos Pitois blanc	\N
9741	446	Chassagne-Montrachet premier cru Clos Pitois	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Clos Pitois rouge"}	Chassagne-Montrachet premier cru Clos Pitois rouge	\N
9742	447	Chassagne-Montrachet premier cru Clos Saint-Jean	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Clos Saint-Jean blanc"}	Chassagne-Montrachet premier cru Clos Saint-Jean blanc	\N
9743	447	Chassagne-Montrachet premier cru Clos Saint-Jean	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Clos Saint-Jean rouge"}	Chassagne-Montrachet premier cru Clos Saint-Jean rouge	\N
9744	448	Chassagne-Montrachet premier cru Dent de Chien	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Dent de Chien blanc"}	Chassagne-Montrachet premier cru Dent de Chien blanc	\N
9745	448	Chassagne-Montrachet premier cru Dent de Chien	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Dent de Chien rouge"}	Chassagne-Montrachet premier cru Dent de Chien rouge	\N
9746	449	Chassagne-Montrachet premier cru En Cailleret	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru En Cailleret blanc"}	Chassagne-Montrachet premier cru En Cailleret blanc	\N
9747	449	Chassagne-Montrachet premier cru En Cailleret	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru En Cailleret rouge"}	Chassagne-Montrachet premier cru En Cailleret rouge	\N
9748	450	Chassagne-Montrachet premier cru En Remilly	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru En Remilly blanc"}	Chassagne-Montrachet premier cru En Remilly blanc	\N
9749	450	Chassagne-Montrachet premier cru En Remilly	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru En Remilly rouge"}	Chassagne-Montrachet premier cru En Remilly rouge	\N
9750	451	Chassagne-Montrachet premier cru En Virondot	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru En Virondot blanc"}	Chassagne-Montrachet premier cru En Virondot blanc	\N
9751	451	Chassagne-Montrachet premier cru En Virondot	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru En Virondot rouge"}	Chassagne-Montrachet premier cru En Virondot rouge	\N
9752	452	Chassagne-Montrachet premier cru Ez Crets	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Ez Crets blanc"}	Chassagne-Montrachet premier cru Ez Crets blanc	\N
9753	452	Chassagne-Montrachet premier cru Ez Crets	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Ez Crets rouge"}	Chassagne-Montrachet premier cru Ez Crets rouge	\N
9754	453	Chassagne-Montrachet premier cru Ez Crottes	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Ez Crottes blanc"}	Chassagne-Montrachet premier cru Ez Crottes blanc	\N
9755	453	Chassagne-Montrachet premier cru Ez Crottes	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Ez Crottes rouge"}	Chassagne-Montrachet premier cru Ez Crottes rouge	\N
9756	454	Chassagne-Montrachet premier cru Francemont	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Francemont blanc"}	Chassagne-Montrachet premier cru Francemont blanc	\N
9757	454	Chassagne-Montrachet premier cru Francemont	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Francemont rouge"}	Chassagne-Montrachet premier cru Francemont rouge	\N
9758	455	Chassagne-Montrachet premier cru Guerchère	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Guerchère blanc"}	Chassagne-Montrachet premier cru Guerchère blanc	\N
9759	455	Chassagne-Montrachet premier cru Guerchère	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Guerchère rouge"}	Chassagne-Montrachet premier cru Guerchère rouge	\N
9760	456	Chassagne-Montrachet premier cru La Boudriotte	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru La Boudriotte blanc"}	Chassagne-Montrachet premier cru La Boudriotte blanc	\N
9761	456	Chassagne-Montrachet premier cru La Boudriotte	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru La Boudriotte rouge"}	Chassagne-Montrachet premier cru La Boudriotte rouge	\N
9762	457	Chassagne-Montrachet premier cru La Cardeuse	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru La Cardeuse blanc"}	Chassagne-Montrachet premier cru La Cardeuse blanc	\N
9763	457	Chassagne-Montrachet premier cru La Cardeuse	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru La Cardeuse rouge"}	Chassagne-Montrachet premier cru La Cardeuse rouge	\N
9764	458	Chassagne-Montrachet premier cru La Chapelle	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru La Chapelle blanc"}	Chassagne-Montrachet premier cru La Chapelle blanc	\N
9765	458	Chassagne-Montrachet premier cru La Chapelle	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru La Chapelle rouge"}	Chassagne-Montrachet premier cru La Chapelle rouge	\N
9766	459	Chassagne-Montrachet premier cru La Grande Borne	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru La Grande Borne blanc"}	Chassagne-Montrachet premier cru La Grande Borne blanc	\N
9767	459	Chassagne-Montrachet premier cru La Grande Borne	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru La Grande Borne rouge"}	Chassagne-Montrachet premier cru La Grande Borne rouge	\N
9768	460	Chassagne-Montrachet premier cru La Grande Montagne	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru La Grande Montagne blanc"}	Chassagne-Montrachet premier cru La Grande Montagne blanc	\N
9769	460	Chassagne-Montrachet premier cru La Grande Montagne	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru La Grande Montagne rouge"}	Chassagne-Montrachet premier cru La Grande Montagne rouge	\N
9770	461	Chassagne-Montrachet premier cru La Maltroie	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru La Maltroie blanc"}	Chassagne-Montrachet premier cru La Maltroie blanc	\N
9771	461	Chassagne-Montrachet premier cru La Maltroie	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru La Maltroie rouge"}	Chassagne-Montrachet premier cru La Maltroie rouge	\N
9772	462	Chassagne-Montrachet premier cru La Romanée	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru La Romanée blanc"}	Chassagne-Montrachet premier cru La Romanée blanc	\N
9773	462	Chassagne-Montrachet premier cru La Romanée	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru La Romanée rouge"}	Chassagne-Montrachet premier cru La Romanée rouge	\N
9774	463	Chassagne-Montrachet premier cru La Roquemaure	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru La Roquemaure blanc"}	Chassagne-Montrachet premier cru La Roquemaure blanc	\N
9775	463	Chassagne-Montrachet premier cru La Roquemaure	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru La Roquemaure rouge"}	Chassagne-Montrachet premier cru La Roquemaure rouge	\N
9776	464	Chassagne-Montrachet premier cru Les Baudines	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Baudines blanc"}	Chassagne-Montrachet premier cru Les Baudines blanc	\N
9777	464	Chassagne-Montrachet premier cru Les Baudines	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Baudines rouge"}	Chassagne-Montrachet premier cru Les Baudines rouge	\N
9778	465	Chassagne-Montrachet premier cru Les Boirettes	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Boirettes blanc"}	Chassagne-Montrachet premier cru Les Boirettes blanc	\N
9779	465	Chassagne-Montrachet premier cru Les Boirettes	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Boirettes rouge"}	Chassagne-Montrachet premier cru Les Boirettes rouge	\N
9780	466	Chassagne-Montrachet premier cru Les Bondues	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Bondues blanc"}	Chassagne-Montrachet premier cru Les Bondues blanc	\N
9781	466	Chassagne-Montrachet premier cru Les Bondues	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Bondues rouge"}	Chassagne-Montrachet premier cru Les Bondues rouge	\N
8226	1236	Clairette de Bellegarde	AOC -	AOP -	{"fra": "Clairette de Bellegarde"}	Clairette de Bellegarde	\N
9782	467	Chassagne-Montrachet premier cru Les Brussonnes	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Brussonnes blanc"}	Chassagne-Montrachet premier cru Les Brussonnes blanc	\N
9783	467	Chassagne-Montrachet premier cru Les Brussonnes	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Brussonnes rouge"}	Chassagne-Montrachet premier cru Les Brussonnes rouge	\N
9784	468	Chassagne-Montrachet premier cru Les Champs gain	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Champs gain blanc"}	Chassagne-Montrachet premier cru Les Champs gain blanc	\N
9785	468	Chassagne-Montrachet premier cru Les Champs gain	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Champs gain rouge"}	Chassagne-Montrachet premier cru Les Champs gain rouge	\N
9786	470	Chassagne-Montrachet premier cru Les Chaumées	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Chaumées blanc"}	Chassagne-Montrachet premier cru Les Chaumées blanc	\N
9787	470	Chassagne-Montrachet premier cru Les Chaumées	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Chaumées rouge"}	Chassagne-Montrachet premier cru Les Chaumées rouge	\N
9788	469	Chassagne-Montrachet premier cru Les Chaumes	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Chaumes blanc"}	Chassagne-Montrachet premier cru Les Chaumes blanc	\N
9789	469	Chassagne-Montrachet premier cru Les Chaumes	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Chaumes rouge"}	Chassagne-Montrachet premier cru Les Chaumes rouge	\N
9790	471	Chassagne-Montrachet premier cru Les Chenevottes	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Chenevottes blanc"}	Chassagne-Montrachet premier cru Les Chenevottes blanc	\N
9791	471	Chassagne-Montrachet premier cru Les Chenevottes	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Chenevottes rouge"}	Chassagne-Montrachet premier cru Les Chenevottes rouge	\N
9792	472	Chassagne-Montrachet premier cru Les Combards	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Combards blanc"}	Chassagne-Montrachet premier cru Les Combards blanc	\N
9793	472	Chassagne-Montrachet premier cru Les Combards	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Combards rouge"}	Chassagne-Montrachet premier cru Les Combards rouge	\N
9794	473	Chassagne-Montrachet premier cru Les Commes	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Commes blanc"}	Chassagne-Montrachet premier cru Les Commes blanc	\N
9795	473	Chassagne-Montrachet premier cru Les Commes	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Commes rouge"}	Chassagne-Montrachet premier cru Les Commes rouge	\N
9796	474	Chassagne-Montrachet premier cru Les Embazées	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Embazées blanc"}	Chassagne-Montrachet premier cru Les Embazées blanc	\N
9797	474	Chassagne-Montrachet premier cru Les Embazées	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Embazées rouge"}	Chassagne-Montrachet premier cru Les Embazées rouge	\N
9798	475	Chassagne-Montrachet premier cru Les Fairendes	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Fairendes blanc"}	Chassagne-Montrachet premier cru Les Fairendes blanc	\N
9799	475	Chassagne-Montrachet premier cru Les Fairendes	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Fairendes rouge"}	Chassagne-Montrachet premier cru Les Fairendes rouge	\N
9802	476	Chassagne-Montrachet premier cru Les Grandes Ruchottes	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Grandes Ruchottes blanc"}	Chassagne-Montrachet premier cru Les Grandes Ruchottes blanc	\N
9803	476	Chassagne-Montrachet premier cru Les Grandes Ruchottes	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Grandes Ruchottes rouge"}	Chassagne-Montrachet premier cru Les Grandes Ruchottes rouge	\N
9800	477	Chassagne-Montrachet premier cru Les Grands Clos	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Grands Clos blanc"}	Chassagne-Montrachet premier cru Les Grands Clos blanc	\N
9801	477	Chassagne-Montrachet premier cru Les Grands Clos	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Grands Clos rouge"}	Chassagne-Montrachet premier cru Les Grands Clos rouge	\N
9804	478	Chassagne-Montrachet premier cru Les Macherelles	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Macherelles blanc"}	Chassagne-Montrachet premier cru Les Macherelles blanc	\N
9805	478	Chassagne-Montrachet premier cru Les Macherelles	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Macherelles rouge"}	Chassagne-Montrachet premier cru Les Macherelles rouge	\N
9806	479	Chassagne-Montrachet premier cru Les Murées	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Murées blanc"}	Chassagne-Montrachet premier cru Les Murées blanc	\N
9807	479	Chassagne-Montrachet premier cru Les Murées	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Murées rouge"}	Chassagne-Montrachet premier cru Les Murées rouge	\N
9808	480	Chassagne-Montrachet premier cru Les Pasquelles	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Pasquelles blanc"}	Chassagne-Montrachet premier cru Les Pasquelles blanc	\N
9809	480	Chassagne-Montrachet premier cru Les Pasquelles	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Pasquelles rouge"}	Chassagne-Montrachet premier cru Les Pasquelles rouge	\N
9810	481	Chassagne-Montrachet premier cru Les Petites Fairendes	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Petites Fairendes blanc"}	Chassagne-Montrachet premier cru Les Petites Fairendes blanc	\N
9811	481	Chassagne-Montrachet premier cru Les Petites Fairendes	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Petites Fairendes rouge"}	Chassagne-Montrachet premier cru Les Petites Fairendes rouge	\N
9812	482	Chassagne-Montrachet premier cru Les Petits Clos	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Petits Clos blanc"}	Chassagne-Montrachet premier cru Les Petits Clos blanc	\N
9813	482	Chassagne-Montrachet premier cru Les Petits Clos	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Petits Clos rouge"}	Chassagne-Montrachet premier cru Les Petits Clos rouge	\N
9814	483	Chassagne-Montrachet premier cru Les Places	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Places blanc"}	Chassagne-Montrachet premier cru Les Places blanc	\N
9815	483	Chassagne-Montrachet premier cru Les Places	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Places rouge"}	Chassagne-Montrachet premier cru Les Places rouge	\N
9816	484	Chassagne-Montrachet premier cru Les Rebichets	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Rebichets blanc"}	Chassagne-Montrachet premier cru Les Rebichets blanc	\N
9817	484	Chassagne-Montrachet premier cru Les Rebichets	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Rebichets rouge"}	Chassagne-Montrachet premier cru Les Rebichets rouge	\N
13436	1281	Clairette de Die	AOC -	AOP -	{"fra": "Clairette de Die"}	Clairette de Die	\N
9818	485	Chassagne-Montrachet premier cru Les Vergers	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Vergers blanc"}	Chassagne-Montrachet premier cru Les Vergers blanc	\N
9819	485	Chassagne-Montrachet premier cru Les Vergers	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Les Vergers rouge"}	Chassagne-Montrachet premier cru Les Vergers rouge	\N
9820	486	Chassagne-Montrachet premier cru Morgeot	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Morgeot blanc"}	Chassagne-Montrachet premier cru Morgeot blanc	\N
9821	486	Chassagne-Montrachet premier cru Morgeot	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Morgeot rouge"}	Chassagne-Montrachet premier cru Morgeot rouge	\N
9822	487	Chassagne-Montrachet premier cru Petingeret	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Petingeret blanc"}	Chassagne-Montrachet premier cru Petingeret blanc	\N
9823	487	Chassagne-Montrachet premier cru Petingeret	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Petingeret rouge"}	Chassagne-Montrachet premier cru Petingeret rouge	\N
9825	489	Chassagne-Montrachet premier cru Tête du Clos	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Tête du Clos blanc"}	Chassagne-Montrachet premier cru Tête du Clos blanc	\N
9826	489	Chassagne-Montrachet premier cru Tête du Clos	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Tête du Clos rouge"}	Chassagne-Montrachet premier cru Tête du Clos rouge	\N
9827	488	Chassagne-Montrachet premier cru Tonton Marcel	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Tonton Marcel blanc"}	Chassagne-Montrachet premier cru Tonton Marcel blanc	\N
9828	488	Chassagne-Montrachet premier cru Tonton Marcel	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Tonton Marcel rouge"}	Chassagne-Montrachet premier cru Tonton Marcel rouge	\N
9829	490	Chassagne-Montrachet premier cru Vide Bourse	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Vide Bourse blanc"}	Chassagne-Montrachet premier cru Vide Bourse blanc	\N
9830	490	Chassagne-Montrachet premier cru Vide Bourse	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Vide Bourse rouge"}	Chassagne-Montrachet premier cru Vide Bourse rouge	\N
9831	491	Chassagne-Montrachet premier cru Vigne Blanche	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Vigne Blanche blanc"}	Chassagne-Montrachet premier cru Vigne Blanche blanc	\N
9832	491	Chassagne-Montrachet premier cru Vigne Blanche	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Vigne Blanche rouge"}	Chassagne-Montrachet premier cru Vigne Blanche rouge	\N
9833	492	Chassagne-Montrachet premier cru Vigne Derrière	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Vigne Derrière blanc"}	Chassagne-Montrachet premier cru Vigne Derrière blanc	\N
9834	492	Chassagne-Montrachet premier cru Vigne Derrière	AOC -	AOP -	{"fra": "Chassagne-Montrachet premier cru Vigne Derrière rouge"}	Chassagne-Montrachet premier cru Vigne Derrière rouge	\N
12601	1497	Chasselas de Moissac	AOC -	AOP -	{"fra": "Chasselas de Moissac"}	Chasselas de Moissac	\N
13173	1638	Châtaigne d'Ardèche	AOC -	AOP -	{"fra": "Châtaigne d'Ardèche"}	Châtaigne d'Ardèche	\N
16084	2464	Chataîgne des Cévennes	AOC -	AOP -	{"fra": "Chataîgne des Cévennes"}	Chataîgne des Cévennes	\N
12233	494	Château-Chalon	AOC -	AOP -	{"fra": "Château-Chalon"}	Château-Chalon	\N
9124	1278	Château-Grillet	AOC -	AOP -	{"fra": "Château-Grillet"}	Château-Grillet	\N
7665	2130	Châteaumeillant	AOC -	AOP -	{"fra": "Châteaumeillant gris"}	Châteaumeillant gris	\N
7666	2130	Châteaumeillant	AOC -	AOP -	{"fra": "Châteaumeillant rouge"}	Châteaumeillant rouge	\N
8936	1279	Châteauneuf-du-Pape	AOC -	AOP -	{"fra": "Châteauneuf-du-Pape blanc"}	Châteauneuf-du-Pape blanc	\N
8937	1279	Châteauneuf-du-Pape	AOC -	AOP -	{"fra": "Châteauneuf-du-Pape rouge"}	Châteauneuf-du-Pape rouge	\N
13433	1280	Châtillon-en-Diois	AOC -	AOP -	{"fra": "Châtillon-en-Diois blanc"}	Châtillon-en-Diois blanc	\N
14150	1280	Châtillon-en-Diois	AOC -	AOP -	{"fra": "Châtillon-en-Diois rosé"}	Châtillon-en-Diois rosé	\N
14151	1280	Châtillon-en-Diois	AOC -	AOP -	{"fra": "Châtillon-en-Diois rouge"}	Châtillon-en-Diois rouge	\N
4573	1467	Chavignol	AOC -	AOP -	{"fra": "Chavignol"}	Chavignol	\N
10242	495	Chénas	AOC -	AOP -	{"fra": "Chénas ou Chénas cru du Beaujolais"}	Chénas ou Chénas cru du Beaujolais	\N
7678	498	Chevalier-Montrachet	AOC -	AOP -	{"fra": "Chevalier-Montrachet"}	Chevalier-Montrachet	\N
15322	164	Cheverny	AOC -	AOP -	{"fra": "Cheverny blanc"}	Cheverny blanc	\N
15323	164	Cheverny	AOC -	AOP -	{"fra": "Cheverny rosé"}	Cheverny rosé	\N
15324	164	Cheverny	AOC -	AOP -	{"fra": "Cheverny rouge"}	Cheverny rouge	\N
13476	1495	Chevrotin	AOC -	AOP -	{"fra": "Chevrotin"}	Chevrotin	\N
13970	165	Chinon	AOC -	AOP -	{"fra": "Chinon blanc"}	Chinon blanc	\N
13971	165	Chinon	AOC -	AOP -	{"fra": "Chinon rosé"}	Chinon rosé	\N
13972	165	Chinon	AOC -	AOP -	{"fra": "Chinon rouge"}	Chinon rouge	\N
10243	499	Chiroubles	AOC -	AOP -	{"fra": "Chiroubles ou Chiroubles cru du Beaujolais"}	Chiroubles ou Chiroubles cru du Beaujolais	\N
9417	502	Chorey-lès-Beaune	AOC -	AOP -	{"fra": "Chorey-lès-Beaune rouge ou Chorey-lès-Beaune Côte de Beaune"}	Chorey-lès-Beaune rouge ou Chorey-lès-Beaune Côte de Beaune	\N
4169	1671	Choucroute d'Alsace	\N	IGP -	{"fra": "Choucroute d'Alsace"}	Choucroute d'Alsace	\N
15037	1854	Cidre Cotentin ou Cotentin	AOC -	AOP -	{"fra": "Cidre Cotentin ou Cotentin"}	Cidre Cotentin ou Cotentin	\N
15228	1582	Cidre de Bretagne	\N	IGP -	{"fra": "Cidre de Bretagne ou Cidre breton"}	Cidre de Bretagne ou Cidre breton	IG/04/96
14000	1528	Cidre de Normandie	\N	IGP -	{"fra": "Cidre de Normandie ou Cidre normand"}	Cidre de Normandie ou Cidre normand	IG/05/96
7844	1982	Cité de Carcassonne	\N	IGP -	{"fra": "Cité de Carcassonne blanc"}	Cité de Carcassonne blanc	\N
8407	1982	Cité de Carcassonne	\N	IGP -	{"fra": "Cité de Carcassonne rosé"}	Cité de Carcassonne rosé	\N
8408	1982	Cité de Carcassonne	\N	IGP -	{"fra": "Cité de Carcassonne rouge"}	Cité de Carcassonne rouge	\N
10496	1982	Cité de Carcassonne	\N	IGP -	{"fra": "Cité de Carcassonne primeur ou nouveau blanc"}	Cité de Carcassonne primeur ou nouveau blanc	\N
10497	1982	Cité de Carcassonne	\N	IGP -	{"fra": "Cité de Carcassonne primeur ou nouveau rosé"}	Cité de Carcassonne primeur ou nouveau rosé	\N
10498	1982	Cité de Carcassonne	\N	IGP -	{"fra": "Cité de Carcassonne primeur ou nouveau rouge"}	Cité de Carcassonne primeur ou nouveau rouge	\N
4371	1780	Citron de Menton	\N	IGP -	{"fra": "Citron de Menton"}	Citron de Menton	\N
13437	1281	Clairette de Die	AOC -	AOP -	{"fra": "Clairette de Die méthode ancestrale"}	Clairette de Die méthode ancestrale	\N
14175	1281	Clairette de Die	AOC -	AOP -	{"fra": "Clairette de Die méthode ancestrale rosé"}	Clairette de Die méthode ancestrale rosé	\N
8266	1237	Clairette du Languedoc	AOC -	AOP -	{"fra": "Clairette du Languedoc"}	Clairette du Languedoc	\N
8297	1237	Clairette du Languedoc	AOC -	AOP -	{"fra": "Clairette du Languedoc rancio"}	Clairette du Languedoc rancio	\N
8301	1237	Clairette du Languedoc	AOC -	AOP -	{"fra": "Clairette du Languedoc vin de liqueur"}	Clairette du Languedoc vin de liqueur	\N
8267	1238	Clairette du Languedoc Adissan	AOC -	AOP -	{"fra": "Clairette du Languedoc Adissan"}	Clairette du Languedoc Adissan	\N
8268	1238	Clairette du Languedoc Adissan	AOC -	AOP -	{"fra": "Clairette du Languedoc Adissan rancio"}	Clairette du Languedoc Adissan rancio	\N
8269	1238	Clairette du Languedoc Adissan	AOC -	AOP -	{"fra": "Clairette du Languedoc Adissan vin de liqueur"}	Clairette du Languedoc Adissan vin de liqueur	\N
8270	1239	Clairette du Languedoc Aspiran	AOC -	AOP -	{"fra": "Clairette du Languedoc Aspiran"}	Clairette du Languedoc Aspiran	\N
8271	1239	Clairette du Languedoc Aspiran	AOC -	AOP -	{"fra": "Clairette du Languedoc Aspiran rancio"}	Clairette du Languedoc Aspiran rancio	\N
8272	1239	Clairette du Languedoc Aspiran	AOC -	AOP -	{"fra": "Clairette du Languedoc Aspiran vin de liqueur"}	Clairette du Languedoc Aspiran vin de liqueur	\N
8273	1240	Clairette du Languedoc Cabrières	AOC -	AOP -	{"fra": "Clairette du Languedoc Cabrières"}	Clairette du Languedoc Cabrières	\N
8274	1240	Clairette du Languedoc Cabrières	AOC -	AOP -	{"fra": "Clairette du Languedoc Cabrières rancio"}	Clairette du Languedoc Cabrières rancio	\N
8275	1240	Clairette du Languedoc Cabrières	AOC -	AOP -	{"fra": "Clairette du Languedoc Cabrières vin de liqueur"}	Clairette du Languedoc Cabrières vin de liqueur	\N
8276	1241	Clairette du Languedoc Ceyras	AOC -	AOP -	{"fra": "Clairette du Languedoc Ceyras"}	Clairette du Languedoc Ceyras	\N
8277	1241	Clairette du Languedoc Ceyras	AOC -	AOP -	{"fra": "Clairette du Languedoc Ceyras rancio"}	Clairette du Languedoc Ceyras rancio	\N
8278	1241	Clairette du Languedoc Ceyras	AOC -	AOP -	{"fra": "Clairette du Languedoc Ceyras vin de liqueur"}	Clairette du Languedoc Ceyras vin de liqueur	\N
8279	1242	Clairette du Languedoc Fontès	AOC -	AOP -	{"fra": "Clairette du Languedoc Fontès"}	Clairette du Languedoc Fontès	\N
8280	1242	Clairette du Languedoc Fontès	AOC -	AOP -	{"fra": "Clairette du Languedoc Fontès rancio"}	Clairette du Languedoc Fontès rancio	\N
8281	1242	Clairette du Languedoc Fontès	AOC -	AOP -	{"fra": "Clairette du Languedoc Fontès vin de liqueur"}	Clairette du Languedoc Fontès vin de liqueur	\N
8282	1243	Clairette du Languedoc Le Bosc	AOC -	AOP -	{"fra": "Clairette du Languedoc Le Bosc"}	Clairette du Languedoc Le Bosc	\N
8283	1243	Clairette du Languedoc Le Bosc	AOC -	AOP -	{"fra": "Clairette du Languedoc Le Bosc rancio"}	Clairette du Languedoc Le Bosc rancio	\N
8284	1243	Clairette du Languedoc Le Bosc	AOC -	AOP -	{"fra": "Clairette du Languedoc Le Bosc vin de liqueur"}	Clairette du Languedoc Le Bosc vin de liqueur	\N
8285	1244	Clairette du Languedoc Lieuran-Cabrières	AOC -	AOP -	{"fra": "Clairette du Languedoc Lieuran-Cabrières"}	Clairette du Languedoc Lieuran-Cabrières	\N
8286	1244	Clairette du Languedoc Lieuran-Cabrières	AOC -	AOP -	{"fra": "Clairette du Languedoc Lieuran-Cabrières rancio"}	Clairette du Languedoc Lieuran-Cabrières rancio	\N
8287	1244	Clairette du Languedoc Lieuran-Cabrières	AOC -	AOP -	{"fra": "Clairette du Languedoc Lieuran-Cabrières vin de liqueur"}	Clairette du Languedoc Lieuran-Cabrières vin de liqueur	\N
8288	1245	Clairette du Languedoc Nizas	AOC -	AOP -	{"fra": "Clairette du Languedoc Nizas"}	Clairette du Languedoc Nizas	\N
8289	1245	Clairette du Languedoc Nizas	AOC -	AOP -	{"fra": "Clairette du Languedoc Nizas rancio"}	Clairette du Languedoc Nizas rancio	\N
8290	1245	Clairette du Languedoc Nizas	AOC -	AOP -	{"fra": "Clairette du Languedoc Nizas vin de liqueur"}	Clairette du Languedoc Nizas vin de liqueur	\N
8291	1246	Clairette du Languedoc Paulhan	AOC -	AOP -	{"fra": "Clairette du Languedoc Paulhan"}	Clairette du Languedoc Paulhan	\N
8292	1246	Clairette du Languedoc Paulhan	AOC -	AOP -	{"fra": "Clairette du Languedoc Paulhan rancio"}	Clairette du Languedoc Paulhan rancio	\N
8293	1246	Clairette du Languedoc Paulhan	AOC -	AOP -	{"fra": "Clairette du Languedoc Paulhan vin de liqueur"}	Clairette du Languedoc Paulhan vin de liqueur	\N
8294	1247	Clairette du Languedoc Péret	AOC -	AOP -	{"fra": "Clairette du Languedoc Péret"}	Clairette du Languedoc Péret	\N
8295	1247	Clairette du Languedoc Péret	AOC -	AOP -	{"fra": "Clairette du Languedoc Péret rancio"}	Clairette du Languedoc Péret rancio	\N
8296	1247	Clairette du Languedoc Péret	AOC -	AOP -	{"fra": "Clairette du Languedoc Péret vin de liqueur"}	Clairette du Languedoc Péret vin de liqueur	\N
8298	1248	Clairette du Languedoc Saint-André-de-Sangonis	AOC -	AOP -	{"fra": "Clairette du Languedoc Saint-André-de-Sangonis"}	Clairette du Languedoc Saint-André-de-Sangonis	\N
8299	1248	Clairette du Languedoc Saint-André-de-Sangonis	AOC -	AOP -	{"fra": "Clairette du Languedoc Saint-André-de-Sangonis rancio"}	Clairette du Languedoc Saint-André-de-Sangonis rancio	\N
8300	1248	Clairette du Languedoc Saint-André-de-Sangonis	AOC -	AOP -	{"fra": "Clairette du Languedoc Saint-André-de-Sangonis vin de liqueur"}	Clairette du Languedoc Saint-André-de-Sangonis vin de liqueur	\N
12981	2355	Clémentine	LR - 	\N	{"fra": "Clémentine"}	Clémentine	LA/03/14
3531	1649	Clémentine de Corse	\N	IGP -	{"fra": "Clémentine de Corse"}	Clémentine de Corse	IG/19/01
7704	503	Clos de la Roche	AOC -	AOP -	{"fra": "Clos de la Roche"}	Clos de la Roche	\N
7708	504	Clos de Tart	AOC -	AOP -	{"fra": "Clos de Tart"}	Clos de Tart	\N
7687	505	Clos de Vougeot	AOC -	AOP -	{"fra": "Clos de Vougeot ou Clos Vougeot"}	Clos de Vougeot ou Clos Vougeot	\N
7707	506	Clos des Lambrays	AOC -	AOP -	{"fra": "Clos des Lambrays"}	Clos des Lambrays	\N
7705	507	Clos Saint-Denis	AOC -	AOP -	{"fra": "Clos Saint-Denis"}	Clos Saint-Denis	\N
13962	1511	Coco de Paimpol	AOC -	AOP -	{"fra": "Coco de Paimpol"}	Coco de Paimpol	\N
15029	1354	Cognac Bois ordinaires ou Bois à terroirs	AOC -	IG - 	{"fra": "Cognac Bois ordinaires ou Bois à terroirs"}	Cognac Bois ordinaires ou Bois à terroirs	\N
15030	2133	Cognac Bons Bois	AOC -	IG - 	{"fra": "Cognac Bons Bois"}	Cognac Bons Bois	\N
15031	1352	Cognac Borderies	AOC -	IG - 	{"fra": "Cognac Borderies"}	Cognac Borderies	\N
15033	1353	Cognac Fins Bois	AOC -	IG - 	{"fra": "Cognac Fins Bois"}	Cognac Fins Bois	\N
15034	1349	Cognac Grande Champagne ou Grande Fine Champagne	AOC -	IG - 	{"fra": "Cognac Grande Champagne ou Grande Fine Champagne"}	Cognac Grande Champagne ou Grande Fine Champagne	\N
15035	1348	Cognac ou Eau-de-vie de Cognac ou Eau-de-vie des Charentes	AOC -	IG - 	{"fra": "Cognac ou Eau-de-vie de Cognac ou Eau-de-vie des Charentes"}	Cognac ou Eau-de-vie de Cognac ou Eau-de-vie des Charentes	\N
15036	1350	Cognac Petite Champagne ou Petite Fine Champagne	AOC -	IG - 	{"fra": "Cognac Petite Champagne ou Petite Fine Champagne"}	Cognac Petite Champagne ou Petite Fine Champagne	\N
7845	1979	Collines Rhodaniennes	\N	IGP -	{"fra": "Collines Rhodaniennes blanc"}	Collines Rhodaniennes blanc	\N
8581	1979	Collines Rhodaniennes	\N	IGP -	{"fra": "Collines Rhodaniennes rosé"}	Collines Rhodaniennes rosé	\N
8582	1979	Collines Rhodaniennes	\N	IGP -	{"fra": "Collines Rhodaniennes rouge"}	Collines Rhodaniennes rouge	\N
10500	1979	Collines Rhodaniennes	\N	IGP -	{"fra": "Collines Rhodaniennes Mousseux de qualité blanc"}	Collines Rhodaniennes Mousseux de qualité blanc	\N
10501	1979	Collines Rhodaniennes	\N	IGP -	{"fra": "Collines Rhodaniennes Mousseux de qualité rosé"}	Collines Rhodaniennes Mousseux de qualité rosé	\N
10502	1979	Collines Rhodaniennes	\N	IGP -	{"fra": "Collines Rhodaniennes Mousseux de qualité rouge"}	Collines Rhodaniennes Mousseux de qualité rouge	\N
10503	1979	Collines Rhodaniennes	\N	IGP -	{"fra": "Collines Rhodaniennes primeur ou nouveau blanc"}	Collines Rhodaniennes primeur ou nouveau blanc	\N
10504	1979	Collines Rhodaniennes	\N	IGP -	{"fra": "Collines Rhodaniennes primeur ou nouveau rosé"}	Collines Rhodaniennes primeur ou nouveau rosé	\N
10505	1979	Collines Rhodaniennes	\N	IGP -	{"fra": "Collines Rhodaniennes primeur ou nouveau rouge"}	Collines Rhodaniennes primeur ou nouveau rouge	\N
7797	1249	Collioure	AOC -	AOP -	{"fra": "Collioure blanc"}	Collioure blanc	\N
9423	1249	Collioure	AOC -	AOP -	{"fra": "Collioure rosé"}	Collioure rosé	\N
9424	1249	Collioure	AOC -	AOP -	{"fra": "Collioure rouge"}	Collioure rouge	\N
14400	1465	Comté	AOC -	AOP -	{"fra": "Comté"}	Comté	\N
14292	1966	Comté Tolosan	\N	IGP -	{"fra": "Comté Tolosan blanc"}	Comté Tolosan blanc	\N
14333	1966	Comté Tolosan	\N	IGP -	{"fra": "Comté Tolosan mousseux de qualité blanc"}	Comté Tolosan mousseux de qualité blanc	\N
14334	1966	Comté Tolosan	\N	IGP -	{"fra": "Comté Tolosan mousseux de qualité rosé"}	Comté Tolosan mousseux de qualité rosé	\N
14335	1966	Comté Tolosan	\N	IGP -	{"fra": "Comté Tolosan primeur ou nouveau blanc"}	Comté Tolosan primeur ou nouveau blanc	\N
14336	1966	Comté Tolosan	\N	IGP -	{"fra": "Comté Tolosan primeur ou nouveau rosé"}	Comté Tolosan primeur ou nouveau rosé	\N
14337	1966	Comté Tolosan	\N	IGP -	{"fra": "Comté Tolosan primeur ou nouveau rouge"}	Comté Tolosan primeur ou nouveau rouge	\N
14346	1966	Comté Tolosan	\N	IGP -	{"fra": "Comté Tolosan rosé"}	Comté Tolosan rosé	\N
14347	1966	Comté Tolosan	\N	IGP -	{"fra": "Comté Tolosan rouge"}	Comté Tolosan rouge	\N
14348	1966	Comté Tolosan	\N	IGP -	{"fra": "Comté Tolosan surmûri blanc"}	Comté Tolosan surmûri blanc	\N
14285	2315	Comté tolosan Bigorre	\N	IGP -	{"fra": "Comté Tolosan Bigorre mousseux de qualité rosé"}	Comté Tolosan Bigorre mousseux de qualité rosé	\N
14286	2315	Comté tolosan Bigorre	\N	IGP -	{"fra": "Comté Tolosan Bigorre rosé"}	Comté Tolosan Bigorre rosé	\N
14287	2315	Comté tolosan Bigorre	\N	IGP -	{"fra": "Comté Tolosan Bigorre surmûri blanc"}	Comté Tolosan Bigorre surmûri blanc	\N
14300	2315	Comté tolosan Bigorre	\N	IGP -	{"fra": "Comté Tolosan Bigorre blanc"}	Comté Tolosan Bigorre blanc	\N
14301	2315	Comté tolosan Bigorre	\N	IGP -	{"fra": "Comté Tolosan Bigorre mousseux de qualité blanc"}	Comté Tolosan Bigorre mousseux de qualité blanc	\N
14302	2315	Comté tolosan Bigorre	\N	IGP -	{"fra": "Comté Tolosan Bigorre primeur ou nouveau blanc"}	Comté Tolosan Bigorre primeur ou nouveau blanc	\N
14303	2315	Comté tolosan Bigorre	\N	IGP -	{"fra": "Comté Tolosan Bigorre primeur ou nouveau rosé"}	Comté Tolosan Bigorre primeur ou nouveau rosé	\N
14304	2315	Comté tolosan Bigorre	\N	IGP -	{"fra": "Comté Tolosan Bigorre primeur ou nouveau rouge"}	Comté Tolosan Bigorre primeur ou nouveau rouge	\N
14305	2315	Comté tolosan Bigorre	\N	IGP -	{"fra": "Comté Tolosan Bigorre rouge"}	Comté Tolosan Bigorre rouge	\N
14306	2316	Comté tolosan Cantal	\N	IGP -	{"fra": "Comté Tolosan Cantal blanc"}	Comté Tolosan Cantal blanc	\N
14307	2316	Comté tolosan Cantal	\N	IGP -	{"fra": "Comté Tolosan Cantal mousseux de qualité blanc"}	Comté Tolosan Cantal mousseux de qualité blanc	\N
14308	2316	Comté tolosan Cantal	\N	IGP -	{"fra": "Comté Tolosan Cantal mousseux de qualité rosé"}	Comté Tolosan Cantal mousseux de qualité rosé	\N
14309	2316	Comté tolosan Cantal	\N	IGP -	{"fra": "Comté Tolosan Cantal primeur ou nouveau blanc"}	Comté Tolosan Cantal primeur ou nouveau blanc	\N
14310	2316	Comté tolosan Cantal	\N	IGP -	{"fra": "Comté Tolosan Cantal primeur ou nouveau rosé"}	Comté Tolosan Cantal primeur ou nouveau rosé	\N
14311	2316	Comté tolosan Cantal	\N	IGP -	{"fra": "Comté Tolosan Cantal primeur ou nouveau rouge"}	Comté Tolosan Cantal primeur ou nouveau rouge	\N
14312	2316	Comté tolosan Cantal	\N	IGP -	{"fra": "Comté Tolosan Cantal rosé"}	Comté Tolosan Cantal rosé	\N
14313	2316	Comté tolosan Cantal	\N	IGP -	{"fra": "Comté Tolosan Cantal rouge"}	Comté Tolosan Cantal rouge	\N
14314	2316	Comté tolosan Cantal	\N	IGP -	{"fra": "Comté Tolosan Cantal surmûri blanc"}	Comté Tolosan Cantal surmûri blanc	\N
14315	2317	Comté tolosan Coteaux et Terrasses de Montauban	\N	IGP -	{"fra": "Comté Tolosan Coteaux et Terrasses de Montauban blanc"}	Comté Tolosan Coteaux et Terrasses de Montauban blanc	\N
14316	2317	Comté tolosan Coteaux et Terrasses de Montauban	\N	IGP -	{"fra": "Comté Tolosan Coteaux et Terrasses de Montauban mousseux de qualité blanc"}	Comté Tolosan Coteaux et Terrasses de Montauban mousseux de qualité blanc	\N
14317	2317	Comté tolosan Coteaux et Terrasses de Montauban	\N	IGP -	{"fra": "Comté Tolosan Coteaux et Terrasses de Montauban mousseux de qualité rosé"}	Comté Tolosan Coteaux et Terrasses de Montauban mousseux de qualité rosé	\N
14318	2317	Comté tolosan Coteaux et Terrasses de Montauban	\N	IGP -	{"fra": "Comté Tolosan Coteaux et Terrasses de Montauban primeur ou nouveau blanc"}	Comté Tolosan Coteaux et Terrasses de Montauban primeur ou nouveau blanc	\N
14319	2317	Comté tolosan Coteaux et Terrasses de Montauban	\N	IGP -	{"fra": "Comté Tolosan Coteaux et Terrasses de Montauban primeur ou nouveau rosé"}	Comté Tolosan Coteaux et Terrasses de Montauban primeur ou nouveau rosé	\N
14320	2317	Comté tolosan Coteaux et Terrasses de Montauban	\N	IGP -	{"fra": "Comté Tolosan Coteaux et Terrasses de Montauban primeur ou nouveau rouge"}	Comté Tolosan Coteaux et Terrasses de Montauban primeur ou nouveau rouge	\N
14321	2317	Comté tolosan Coteaux et Terrasses de Montauban	\N	IGP -	{"fra": "Comté Tolosan Coteaux et Terrasses de Montauban rosé"}	Comté Tolosan Coteaux et Terrasses de Montauban rosé	\N
14322	2317	Comté tolosan Coteaux et Terrasses de Montauban	\N	IGP -	{"fra": "Comté Tolosan Coteaux et Terrasses de Montauban rouge"}	Comté Tolosan Coteaux et Terrasses de Montauban rouge	\N
14323	2317	Comté tolosan Coteaux et Terrasses de Montauban	\N	IGP -	{"fra": "Comté Tolosan Coteaux et Terrasses de Montauban surmûri blanc"}	Comté Tolosan Coteaux et Terrasses de Montauban surmûri blanc	\N
14324	2318	Comté tolosan Haute-Garonne	\N	IGP -	{"fra": "Comté Tolosan Haute-Garonne blanc"}	Comté Tolosan Haute-Garonne blanc	\N
14325	2318	Comté tolosan Haute-Garonne	\N	IGP -	{"fra": "Comté Tolosan Haute-Garonne mousseux de qualité blanc"}	Comté Tolosan Haute-Garonne mousseux de qualité blanc	\N
14326	2318	Comté tolosan Haute-Garonne	\N	IGP -	{"fra": "Comté Tolosan Haute-Garonne mousseux de qualité rosé"}	Comté Tolosan Haute-Garonne mousseux de qualité rosé	\N
14327	2318	Comté tolosan Haute-Garonne	\N	IGP -	{"fra": "Comté Tolosan Haute-Garonne primeur ou nouveau blanc"}	Comté Tolosan Haute-Garonne primeur ou nouveau blanc	\N
14328	2318	Comté tolosan Haute-Garonne	\N	IGP -	{"fra": "Comté Tolosan Haute-Garonne primeur ou nouveau rosé"}	Comté Tolosan Haute-Garonne primeur ou nouveau rosé	\N
14329	2318	Comté tolosan Haute-Garonne	\N	IGP -	{"fra": "Comté Tolosan Haute-Garonne primeur ou nouveau rouge"}	Comté Tolosan Haute-Garonne primeur ou nouveau rouge	\N
14330	2318	Comté tolosan Haute-Garonne	\N	IGP -	{"fra": "Comté Tolosan Haute-Garonne rosé"}	Comté Tolosan Haute-Garonne rosé	\N
14331	2318	Comté tolosan Haute-Garonne	\N	IGP -	{"fra": "Comté Tolosan Haute-Garonne rouge"}	Comté Tolosan Haute-Garonne rouge	\N
14332	2318	Comté tolosan Haute-Garonne	\N	IGP -	{"fra": "Comté Tolosan Haute-Garonne surmûri blanc"}	Comté Tolosan Haute-Garonne surmûri blanc	\N
14278	2319	Comté tolosan Pyrénées Atlantiques	\N	IGP -	{"fra": "Comté Tolosan Pyrénées Atlantiques primeur ou nouveau blanc"}	Comté Tolosan Pyrénées Atlantiques primeur ou nouveau blanc	\N
14338	2319	Comté tolosan Pyrénées Atlantiques	\N	IGP -	{"fra": "Comté Tolosan Pyrénées Atlantiques blanc"}	Comté Tolosan Pyrénées Atlantiques blanc	\N
14339	2319	Comté tolosan Pyrénées Atlantiques	\N	IGP -	{"fra": "Comté Tolosan Pyrénées Atlantiques mousseux de qualité blanc"}	Comté Tolosan Pyrénées Atlantiques mousseux de qualité blanc	\N
14340	2319	Comté tolosan Pyrénées Atlantiques	\N	IGP -	{"fra": "Comté Tolosan Pyrénées Atlantiques mousseux de qualité rosé"}	Comté Tolosan Pyrénées Atlantiques mousseux de qualité rosé	\N
14341	2319	Comté tolosan Pyrénées Atlantiques	\N	IGP -	{"fra": "Comté Tolosan Pyrénées Atlantiques primeur ou nouveau rosé"}	Comté Tolosan Pyrénées Atlantiques primeur ou nouveau rosé	\N
14342	2319	Comté tolosan Pyrénées Atlantiques	\N	IGP -	{"fra": "Comté Tolosan Pyrénées Atlantiques primeur ou nouveau rouge"}	Comté Tolosan Pyrénées Atlantiques primeur ou nouveau rouge	\N
14343	2319	Comté tolosan Pyrénées Atlantiques	\N	IGP -	{"fra": "Comté Tolosan Pyrénées Atlantiques rosé"}	Comté Tolosan Pyrénées Atlantiques rosé	\N
14344	2319	Comté tolosan Pyrénées Atlantiques	\N	IGP -	{"fra": "Comté Tolosan Pyrénées Atlantiques rouge"}	Comté Tolosan Pyrénées Atlantiques rouge	\N
14345	2319	Comté tolosan Pyrénées Atlantiques	\N	IGP -	{"fra": "Comté Tolosan Pyrénées Atlantiques surmûri blanc"}	Comté Tolosan Pyrénées Atlantiques surmûri blanc	\N
14349	2320	Comté tolosan Tarn et Garonne	\N	IGP -	{"fra": "Comté Tolosan Tarn et Garonne blanc"}	Comté Tolosan Tarn et Garonne blanc	\N
14350	2320	Comté tolosan Tarn et Garonne	\N	IGP -	{"fra": "Comté Tolosan Tarn et Garonne mousseux de qualité rosé"}	Comté Tolosan Tarn et Garonne mousseux de qualité rosé	\N
14351	2320	Comté tolosan Tarn et Garonne	\N	IGP -	{"fra": "Comté Tolosan Tarn et Garonne mousseux de qualité blanc"}	Comté Tolosan Tarn et Garonne mousseux de qualité blanc	\N
14352	2320	Comté tolosan Tarn et Garonne	\N	IGP -	{"fra": "Comté Tolosan Tarn et Garonne surmûri blanc"}	Comté Tolosan Tarn et Garonne surmûri blanc	\N
14353	2320	Comté tolosan Tarn et Garonne	\N	IGP -	{"fra": "Comté Tolosan Tarn et Garonne rouge"}	Comté Tolosan Tarn et Garonne rouge	\N
14354	2320	Comté tolosan Tarn et Garonne	\N	IGP -	{"fra": "Comté Tolosan Tarn et Garonne rosé"}	Comté Tolosan Tarn et Garonne rosé	\N
14355	2320	Comté tolosan Tarn et Garonne	\N	IGP -	{"fra": "Comté Tolosan Tarn et Garonne primeur ou nouveau rouge"}	Comté Tolosan Tarn et Garonne primeur ou nouveau rouge	\N
14356	2320	Comté tolosan Tarn et Garonne	\N	IGP -	{"fra": "Comté Tolosan Tarn et Garonne primeur ou nouveau blanc"}	Comté Tolosan Tarn et Garonne primeur ou nouveau blanc	\N
14357	2320	Comté tolosan Tarn et Garonne	\N	IGP -	{"fra": "Comté Tolosan Tarn et Garonne primeur ou nouveau rosé"}	Comté Tolosan Tarn et Garonne primeur ou nouveau rosé	\N
13539	1967	Comtés Rhodaniens	\N	IGP -	{"fra": "Comtés Rhodaniens blanc"}	Comtés Rhodaniens blanc	\N
13540	1967	Comtés Rhodaniens	\N	IGP -	{"fra": "Comtés Rhodaniens rosé"}	Comtés Rhodaniens rosé	\N
13541	1967	Comtés Rhodaniens	\N	IGP -	{"fra": "Comtés Rhodaniens rouge"}	Comtés Rhodaniens rouge	\N
9550	1282	Condrieu	AOC -	AOP -	{"fra": "Condrieu"}	Condrieu	\N
4270	1680	Coppa de Corse ou Coppa de Corse - Coppa di Corsica	AOC -	AOP -	{"fra": "Coppa de Corse ou Coppa de Corse - Coppa di Corsica"}	Coppa de Corse ou Coppa de Corse - Coppa di Corsica	\N
3401	1529	Coquille Saint-Jacques des Côtes-d’Armor	\N	IGP -	{"fra": "Coquille Saint-Jacques des Côtes-d’Armor"}	Coquille Saint-Jacques des Côtes-d’Armor	IG/15/95
15793	1250	Corbières	AOC -	AOP -	{"fra": "Corbières blanc"}	Corbières blanc	\N
15794	1250	Corbières	AOC -	AOP -	{"fra": "Corbières rosé"}	Corbières rosé	\N
15795	1250	Corbières	AOC -	AOP -	{"fra": "Corbières rouge"}	Corbières rouge	\N
9836	1620	Corbières-Boutenac	AOC -	\N	{"fra": "Corbières-Boutenac"}	Corbières-Boutenac	\N
15439	1283	Cornas	AOC -	AOP -	{"fra": "Cornas"}	Cornas	\N
6163	1360	Cornouaille	AOC -	AOP -	{"fra": "Cornouaille"}	Cornouaille	\N
14649	2419	Corrèze	AOC -	\N	{"fra": "Corrèze rouge"}	Corrèze rouge	\N
14096	2420	Corrèze Coteaux de la Vézère	AOC -	\N	{"fra": "Corrèze Coteaux de la Vézère rouge"}	Corrèze Coteaux de la Vézère rouge	\N
14097	2420	Corrèze Coteaux de la Vézère	AOC -	\N	{"fra": "Corrèze Coteaux de la Vézère blanc"}	Corrèze Coteaux de la Vézère blanc	\N
14095	2444	Corrèze vin de paille	AOC -	\N	{"fra": "Corrèze vins de raisins passerillés vin de paille"}	Corrèze vins de raisins passerillés vin de paille	\N
7714	508	Corton	AOC -	AOP -	{"fra": "Corton blanc"}	Corton blanc	\N
8302	508	Corton	AOC -	AOP -	{"fra": "Corton rouge"}	Corton rouge	\N
10253	2193	Corton Basses Mourottes	AOC -	AOP -	{"fra": "Corton Basses Mourottes rouge"}	Corton Basses Mourottes rouge	\N
10254	2194	Corton Clos des Meix	AOC -	AOP -	{"fra": "Corton Clos des Meix rouge"}	Corton Clos des Meix rouge	\N
10255	2195	Corton Hautes Mourottes	AOC -	AOP -	{"fra": "Corton Hautes Mourottes rouge"}	Corton Hautes Mourottes rouge	\N
10256	2196	Corton La Toppe au Vert	AOC -	AOP -	{"fra": "Corton La Toppe au Vert rouge"}	Corton La Toppe au Vert rouge	\N
10257	2197	Corton La Vigne au Saint	AOC -	AOP -	{"fra": "Corton La Vigne au Saint rouge"}	Corton La Vigne au Saint rouge	\N
10258	2198	Corton Le Clos du Roi	AOC -	AOP -	{"fra": "Corton Le Clos du Roi rouge"}	Corton Le Clos du Roi rouge	\N
10259	2338	Corton Le Corton	AOC -	AOP -	{"fra": "Corton Le Corton rouge"}	Corton Le Corton rouge	\N
10260	2199	Corton Le Meix Lallemand	AOC -	AOP -	{"fra": "Corton Le Meix Lallemand rouge"}	Corton Le Meix Lallemand rouge	\N
10261	2200	Corton Le Rognet et Corton	AOC -	AOP -	{"fra": "Corton Le Rognet et Corton rouge"}	Corton Le Rognet et Corton rouge	\N
10262	2201	Corton Les Bressandes	AOC -	AOP -	{"fra": "Corton Les Bressandes rouge"}	Corton Les Bressandes rouge	\N
10263	2202	Corton Les Carrières	AOC -	AOP -	{"fra": "Corton Les Carrières rouge"}	Corton Les Carrières rouge	\N
10264	2203	Corton Les Chaumes	AOC -	AOP -	{"fra": "Corton Les Chaumes rouge"}	Corton Les Chaumes rouge	\N
10265	2204	Corton Les Combes	AOC -	AOP -	{"fra": "Corton Les Combes rouge"}	Corton Les Combes rouge	\N
10266	2205	Corton Les Fiètres	AOC -	AOP -	{"fra": "Corton Les Fiètres rouge"}	Corton Les Fiètres rouge	\N
10267	2206	Corton Les Grandes Lolières	AOC -	AOP -	{"fra": "Corton Les Grandes Lolières rouge"}	Corton Les Grandes Lolières rouge	\N
10268	2207	Corton Les Grèves	AOC -	AOP -	{"fra": "Corton Les Grèves rouge"}	Corton Les Grèves rouge	\N
10269	2208	Corton Les Languettes	AOC -	AOP -	{"fra": "Corton Les Languettes rouge"}	Corton Les Languettes rouge	\N
10270	2209	Corton Les Maréchaudes	AOC -	AOP -	{"fra": "Corton Les Maréchaudes rouge"}	Corton Les Maréchaudes rouge	\N
10271	2210	Corton Les Moutottes	AOC -	AOP -	{"fra": "Corton Les Moutottes rouge"}	Corton Les Moutottes rouge	\N
10272	2211	Corton Les Paulands	AOC -	AOP -	{"fra": "Corton Les Paulands rouge"}	Corton Les Paulands rouge	\N
10273	2212	Corton Les Perrières	AOC -	AOP -	{"fra": "Corton Les Perrières rouge"}	Corton Les Perrières rouge	\N
10274	2213	Corton Les Pougets	AOC -	AOP -	{"fra": "Corton Les Pougets rouge"}	Corton Les Pougets rouge	\N
10275	2214	Corton Les Renardes	AOC -	AOP -	{"fra": "Corton Les Renardes rouge"}	Corton Les Renardes rouge	\N
10276	2215	Corton Les Vergennes	AOC -	AOP -	{"fra": "Corton Les Vergennes rouge"}	Corton Les Vergennes rouge	\N
7715	509	Corton-Charlemagne	AOC -	AOP -	{"fra": "Corton-Charlemagne"}	Corton-Charlemagne	\N
7754	1251	Costières de Nîmes	AOC -	AOP -	{"fra": "Costières de Nîmes blanc"}	Costières de Nîmes blanc	\N
7755	1251	Costières de Nîmes	AOC -	AOP -	{"fra": "Costières de Nîmes rosé"}	Costières de Nîmes rosé	\N
7756	1251	Costières de Nîmes	AOC -	AOP -	{"fra": "Costières de Nîmes rouge"}	Costières de Nîmes rouge	\N
7697	510	Côte de Beaune	AOC -	AOP -	{"fra": "Côte de Beaune blanc"}	Côte de Beaune blanc	\N
9075	510	Côte de Beaune	AOC -	AOP -	{"fra": "Côte de Beaune rouge"}	Côte de Beaune rouge	\N
7688	511	Côte de Beaune-Villages	AOC -	AOP -	{"fra": "Côte de Beaune-Villages"}	Côte de Beaune-Villages	\N
10244	512	Côte de Brouilly	AOC -	AOP -	{"fra": "Côte de Brouilly ou Côte de Brouilly cru du Beaujolais"}	Côte de Brouilly ou Côte de Brouilly cru du Beaujolais	\N
7689	516	Côte de Nuits-Villages	AOC -	AOP -	{"fra": "Côte de Nuits-Villages blanc ou Vins fins de la Côte de Nuits blanc"}	Côte de Nuits-Villages blanc ou Vins fins de la Côte de Nuits blanc	\N
8156	516	Côte de Nuits-Villages	AOC -	AOP -	{"fra": "Côte de Nuits-Villages rouge ou Vins fins de la Côte de Nuits rouge"}	Côte de Nuits-Villages rouge ou Vins fins de la Côte de Nuits rouge	\N
7914	515	Côte roannaise	AOC -	AOP -	{"fra": "Côte roannaise rosé"}	Côte roannaise rosé	\N
7915	515	Côte roannaise	AOC -	AOP -	{"fra": "Côte roannaise rouge"}	Côte roannaise rouge	\N
8225	1284	Côte Rôtie	AOC -	AOP -	{"fra": "Côte Rôtie"}	Côte Rôtie	\N
7829	2062	Côte Vermeille	\N	IGP -	{"fra": "Côte Vermeille blanc"}	Côte Vermeille blanc	\N
8587	2062	Côte Vermeille	\N	IGP -	{"fra": "Côte Vermeille rosé"}	Côte Vermeille rosé	\N
8588	2062	Côte Vermeille	\N	IGP -	{"fra": "Côte Vermeille rouge"}	Côte Vermeille rouge	\N
10586	2062	Côte Vermeille	\N	IGP -	{"fra": "Côte Vermeille surmûri blanc"}	Côte Vermeille surmûri blanc	\N
10587	2062	Côte Vermeille	\N	IGP -	{"fra": "Côte Vermeille surmûri rosé"}	Côte Vermeille surmûri rosé	\N
10588	2062	Côte Vermeille	\N	IGP -	{"fra": "Côte Vermeille surmûri rouge"}	Côte Vermeille surmûri rouge	\N
10589	2062	Côte Vermeille	\N	IGP -	{"fra": "Côte Vermeille rancio blanc"}	Côte Vermeille rancio blanc	\N
10590	2062	Côte Vermeille	\N	IGP -	{"fra": "Côte Vermeille rancio rosé"}	Côte Vermeille rancio rosé	\N
10591	2062	Côte Vermeille	\N	IGP -	{"fra": "Côte Vermeille rancio rouge"}	Côte Vermeille rancio rouge	\N
10238	2186	Coteaux Bourguignons	AOC -	AOP -	{"fra": "Coteaux Bourguignons ou Bourgogne grand ordinaire ou Bourgogne ordinaire blanc"}	Coteaux Bourguignons ou Bourgogne grand ordinaire ou Bourgogne ordinaire blanc	\N
12313	2186	Coteaux Bourguignons	AOC -	AOP -	{"fra": "Coteaux Bourguignons ou Bourgogne grand ordinaire ou Bourgogne ordinaire blanc nouveau ou primeur"}	Coteaux Bourguignons ou Bourgogne grand ordinaire ou Bourgogne ordinaire blanc nouveau ou primeur	\N
12314	2186	Coteaux Bourguignons	AOC -	AOP -	{"fra": "Coteaux Bourguignons ou Bourgogne grand ordinaire ou Bourgogne ordinaire clairet ou rosé"}	Coteaux Bourguignons ou Bourgogne grand ordinaire ou Bourgogne ordinaire clairet ou rosé	\N
12315	2186	Coteaux Bourguignons	AOC -	AOP -	{"fra": "Coteaux Bourguignons ou Bourgogne grand ordinaire ou Bourgogne ordinaire rouge"}	Coteaux Bourguignons ou Bourgogne grand ordinaire ou Bourgogne ordinaire rouge	\N
13084	1963	Coteaux champenois	AOC -	AOP -	{"fra": "Coteaux champenois blanc"}	Coteaux champenois blanc	\N
13318	1963	Coteaux champenois	AOC -	AOP -	{"fra": "Coteaux champenois rosé"}	Coteaux champenois rosé	\N
13319	1963	Coteaux champenois	AOC -	AOP -	{"fra": "Coteaux champenois rouge"}	Coteaux champenois rouge	\N
15440	1320	Coteaux d'Aix-en-Provence	AOC -	AOP -	{"fra": "Coteaux d'Aix-en-Provence blanc"}	Coteaux d'Aix-en-Provence blanc	\N
15441	1320	Coteaux d'Aix-en-Provence	AOC -	AOP -	{"fra": "Coteaux d'Aix-en-Provence rosé"}	Coteaux d'Aix-en-Provence rosé	\N
15442	1320	Coteaux d'Aix-en-Provence	AOC -	AOP -	{"fra": "Coteaux d'Aix-en-Provence rouge"}	Coteaux d'Aix-en-Provence rouge	\N
14371	2175	Coteaux d'Ancenis	AOC -	AOP -	{"fra": "Coteaux d'Ancenis blanc"}	Coteaux d'Ancenis blanc	\N
15241	2175	Coteaux d'Ancenis	AOC -	AOP -	{"fra": "Coteaux d'Ancenis Malvoisie"}	Coteaux d'Ancenis Malvoisie	\N
15242	2175	Coteaux d'Ancenis	AOC -	AOP -	{"fra": "Coteaux d'Ancenis rosé"}	Coteaux d'Ancenis rosé	\N
15243	2175	Coteaux d'Ancenis	AOC -	AOP -	{"fra": "Coteaux d'Ancenis rouge"}	Coteaux d'Ancenis rouge	\N
7817	2098	Coteaux d'Ensérune	\N	IGP -	{"fra": "Coteaux d'Ensérune blanc"}	Coteaux d'Ensérune blanc	\N
8420	2098	Coteaux d'Ensérune	\N	IGP -	{"fra": "Coteaux d'Ensérune rosé"}	Coteaux d'Ensérune rosé	\N
8421	2098	Coteaux d'Ensérune	\N	IGP -	{"fra": "Coteaux d'Ensérune rouge"}	Coteaux d'Ensérune rouge	\N
10629	2098	Coteaux d'Ensérune	\N	IGP -	{"fra": "Coteaux d'Ensérune primeur ou nouveau blanc"}	Coteaux d'Ensérune primeur ou nouveau blanc	\N
10630	2098	Coteaux d'Ensérune	\N	IGP -	{"fra": "Coteaux d'Ensérune primeur ou nouveau rosé"}	Coteaux d'Ensérune primeur ou nouveau rosé	\N
10631	2098	Coteaux d'Ensérune	\N	IGP -	{"fra": "Coteaux d'Ensérune primeur ou nouveau rouge"}	Coteaux d'Ensérune primeur ou nouveau rouge	\N
13764	2101	Coteaux de Béziers	\N	IGP -	{"fra": "Coteaux de Béziers rosé"}	Coteaux de Béziers rosé	\N
13765	2101	Coteaux de Béziers	\N	IGP -	{"fra": "Coteaux de Béziers rouge"}	Coteaux de Béziers rouge	\N
13766	2101	Coteaux de Béziers	\N	IGP -	{"fra": "Coteaux de Béziers primeur ou nouveau blanc"}	Coteaux de Béziers primeur ou nouveau blanc	\N
13767	2101	Coteaux de Béziers	\N	IGP -	{"fra": "Coteaux de Béziers primeur ou nouveau rosé"}	Coteaux de Béziers primeur ou nouveau rosé	\N
13768	2101	Coteaux de Béziers	\N	IGP -	{"fra": "Coteaux de Béziers primeur ou nouveau rouge"}	Coteaux de Béziers primeur ou nouveau rouge	\N
16012	2360	Coteaux de Béziers	\N	IGP -	{"fra": "Coteaux de Béziers blanc"}	Coteaux de Béziers blanc	\N
7816	2050	Coteaux de Coiffy	\N	IGP -	{"fra": "Coteaux de Coiffy blanc"}	Coteaux de Coiffy blanc	\N
8871	2050	Coteaux de Coiffy	\N	IGP -	{"fra": "Coteaux de Coiffy rosé"}	Coteaux de Coiffy rosé	\N
8872	2050	Coteaux de Coiffy	\N	IGP -	{"fra": "Coteaux de Coiffy rouge"}	Coteaux de Coiffy rouge	\N
10593	2050	Coteaux de Coiffy	\N	IGP -	{"fra": "Coteaux de Coiffy mousseux de qualité rosé"}	Coteaux de Coiffy mousseux de qualité rosé	\N
10594	2050	Coteaux de Coiffy	\N	IGP -	{"fra": "Coteaux de Coiffy mousseux de qualité rouge"}	Coteaux de Coiffy mousseux de qualité rouge	\N
10596	2050	Coteaux de Coiffy	\N	IGP -	{"fra": "Coteaux de Coiffy primeur ou nouveau rosé"}	Coteaux de Coiffy primeur ou nouveau rosé	\N
10597	2050	Coteaux de Coiffy	\N	IGP -	{"fra": "Coteaux de Coiffy primeur ou nouveau rouge"}	Coteaux de Coiffy primeur ou nouveau rouge	\N
10598	2050	Coteaux de Coiffy	\N	IGP -	{"fra": "Coteaux de Coiffy primeur ou nouveau blanc"}	Coteaux de Coiffy primeur ou nouveau blanc	\N
13434	1869	Coteaux de Die	AOC -	AOP -	{"fra": "Coteaux de Die"}	Coteaux de Die	\N
7849	2044	Coteaux de Glanes	\N	IGP -	{"fra": "Coteaux de Glanes blanc"}	Coteaux de Glanes blanc	\N
8835	2044	Coteaux de Glanes	\N	IGP -	{"fra": "Coteaux de Glanes rosé"}	Coteaux de Glanes rosé	\N
8836	2044	Coteaux de Glanes	\N	IGP -	{"fra": "Coteaux de Glanes rouge"}	Coteaux de Glanes rouge	\N
10599	2044	Coteaux de Glanes	\N	IGP -	{"fra": "Coteaux de Glanes primeur ou nouveau blanc"}	Coteaux de Glanes primeur ou nouveau blanc	\N
10600	2044	Coteaux de Glanes	\N	IGP -	{"fra": "Coteaux de Glanes primeur ou nouveau rosé"}	Coteaux de Glanes primeur ou nouveau rosé	\N
10601	2044	Coteaux de Glanes	\N	IGP -	{"fra": "Coteaux de Glanes primeur ou nouveau rouge"}	Coteaux de Glanes primeur ou nouveau rouge	\N
14281	2156	Coteaux de l'Ain	\N	IGP -	{"fra": "Coteaux de l'Ain blanc"}	Coteaux de l'Ain blanc	\N
14282	2156	Coteaux de l'Ain	\N	IGP -	{"fra": "Coteaux de l'Ain mousseux de qualité blanc"}	Coteaux de l'Ain mousseux de qualité blanc	\N
14358	2156	Coteaux de l'Ain	\N	IGP -	{"fra": "Coteaux de l'Ain mousseux de qualité rosé"}	Coteaux de l'Ain mousseux de qualité rosé	\N
14359	2156	Coteaux de l'Ain	\N	IGP -	{"fra": "Coteaux de l'Ain mousseux de qualité rouge"}	Coteaux de l'Ain mousseux de qualité rouge	\N
14368	2156	Coteaux de l'Ain	\N	IGP -	{"fra": "Coteaux de l'Ain primeur ou nouveau blanc"}	Coteaux de l'Ain primeur ou nouveau blanc	\N
14369	2156	Coteaux de l'Ain	\N	IGP -	{"fra": "Coteaux de l'Ain primeur ou nouveau rosé"}	Coteaux de l'Ain primeur ou nouveau rosé	\N
14370	2156	Coteaux de l'Ain	\N	IGP -	{"fra": "Coteaux de l'Ain primeur ou nouveau rouge"}	Coteaux de l'Ain primeur ou nouveau rouge	\N
14379	2156	Coteaux de l'Ain	\N	IGP -	{"fra": "Coteaux de l'Ain rosé"}	Coteaux de l'Ain rosé	\N
14380	2156	Coteaux de l'Ain	\N	IGP -	{"fra": "Coteaux de l'Ain rouge"}	Coteaux de l'Ain rouge	\N
14360	2226	Coteaux de l'Ain Pays de Gex	\N	IGP -	{"fra": "Coteaux de l'Ain Pays de Gex blanc"}	Coteaux de l'Ain Pays de Gex blanc	\N
14361	2226	Coteaux de l'Ain Pays de Gex	\N	IGP -	{"fra": "Coteaux de l'Ain Pays de Gex mousseux de qualité blanc"}	Coteaux de l'Ain Pays de Gex mousseux de qualité blanc	\N
14362	2226	Coteaux de l'Ain Pays de Gex	\N	IGP -	{"fra": "Coteaux de l'Ain Pays de Gex mousseux de qualité rosé"}	Coteaux de l'Ain Pays de Gex mousseux de qualité rosé	\N
14363	2226	Coteaux de l'Ain Pays de Gex	\N	IGP -	{"fra": "Coteaux de l'Ain Pays de Gex mousseux de qualité rouge"}	Coteaux de l'Ain Pays de Gex mousseux de qualité rouge	\N
14364	2226	Coteaux de l'Ain Pays de Gex	\N	IGP -	{"fra": "Coteaux de l'Ain Pays de Gex primeur ou nouveau blanc"}	Coteaux de l'Ain Pays de Gex primeur ou nouveau blanc	\N
14365	2226	Coteaux de l'Ain Pays de Gex	\N	IGP -	{"fra": "Coteaux de l'Ain Pays de Gex rosé"}	Coteaux de l'Ain Pays de Gex rosé	\N
14366	2226	Coteaux de l'Ain Pays de Gex	\N	IGP -	{"fra": "Coteaux de l'Ain Pays de Gex rouge"}	Coteaux de l'Ain Pays de Gex rouge	\N
14367	2226	Coteaux de l'Ain Pays de Gex	\N	IGP -	{"fra": "Coteaux de l'Ain Pays de Gex Rouge Primeur ou Nouveau"}	Coteaux de l'Ain Pays de Gex Rouge Primeur ou Nouveau	\N
15165	166	Coteaux de l'Aubance	AOC -	AOP -	{"fra": "Coteaux de l'Aubance"}	Coteaux de l'Aubance	\N
15166	166	Coteaux de l'Aubance	AOC -	AOP -	{"fra": "Coteaux de l'Aubance Sélection de grains nobles"}	Coteaux de l'Aubance Sélection de grains nobles	\N
15588	2001	Coteaux de l'Auxois	\N	IGP -	{"fra": "Coteaux de l'Auxois blanc"}	Coteaux de l'Auxois blanc	\N
15589	2001	Coteaux de l'Auxois	\N	IGP -	{"fra": "Coteaux de l'Auxois mousseux de qualité blanc"}	Coteaux de l'Auxois mousseux de qualité blanc	\N
15590	2001	Coteaux de l'Auxois	\N	IGP -	{"fra": "Coteaux de l'Auxois mousseux de qualité rosé"}	Coteaux de l'Auxois mousseux de qualité rosé	\N
15591	2001	Coteaux de l'Auxois	\N	IGP -	{"fra": "Coteaux de l'Auxois mousseux de qualité rouge"}	Coteaux de l'Auxois mousseux de qualité rouge	\N
15592	2001	Coteaux de l'Auxois	\N	IGP -	{"fra": "Coteaux de l'Auxois primeur ou nouveau blanc"}	Coteaux de l'Auxois primeur ou nouveau blanc	\N
15593	2001	Coteaux de l'Auxois	\N	IGP -	{"fra": "Coteaux de l'Auxois primeur ou nouveau rosé"}	Coteaux de l'Auxois primeur ou nouveau rosé	\N
15594	2001	Coteaux de l'Auxois	\N	IGP -	{"fra": "Coteaux de l'Auxois primeur ou nouveau rouge"}	Coteaux de l'Auxois primeur ou nouveau rouge	\N
15595	2001	Coteaux de l'Auxois	\N	IGP -	{"fra": "Coteaux de l'Auxois rosé"}	Coteaux de l'Auxois rosé	\N
15596	2001	Coteaux de l'Auxois	\N	IGP -	{"fra": "Coteaux de l'Auxois rouge"}	Coteaux de l'Auxois rouge	\N
15597	2001	Coteaux de l'Auxois	\N	IGP -	{"fra": "Coteaux de l'Auxois surmûri blanc"}	Coteaux de l'Auxois surmûri blanc	\N
15598	2001	Coteaux de l'Auxois	\N	IGP -	{"fra": "Coteaux de l'Auxois surmûri rosé"}	Coteaux de l'Auxois surmûri rosé	\N
15599	2001	Coteaux de l'Auxois	\N	IGP -	{"fra": "Coteaux de l'Auxois surmûri rouge"}	Coteaux de l'Auxois surmûri rouge	\N
14372	2289	Coteaux de l’Ain Revermont	\N	IGP -	{"fra": "Coteaux de l'Ain Revermont mousseux de qualité rosé"}	Coteaux de l'Ain Revermont mousseux de qualité rosé	\N
14373	2289	Coteaux de l’Ain Revermont	\N	IGP -	{"fra": "Coteaux de l'Ain Revermont mousseux de qualité rouge"}	Coteaux de l'Ain Revermont mousseux de qualité rouge	\N
14374	2289	Coteaux de l’Ain Revermont	\N	IGP -	{"fra": "Coteaux de l'Ain Revermont primeur ou nouveau blanc"}	Coteaux de l'Ain Revermont primeur ou nouveau blanc	\N
14375	2289	Coteaux de l’Ain Revermont	\N	IGP -	{"fra": "Coteaux de l'Ain Revermont primeur ou nouveau rosé"}	Coteaux de l'Ain Revermont primeur ou nouveau rosé	\N
14376	2289	Coteaux de l’Ain Revermont	\N	IGP -	{"fra": "Coteaux de l'Ain Revermont primeur ou nouveau rouge"}	Coteaux de l'Ain Revermont primeur ou nouveau rouge	\N
14377	2289	Coteaux de l’Ain Revermont	\N	IGP -	{"fra": "Coteaux de l'Ain Revermont rosé"}	Coteaux de l'Ain Revermont rosé	\N
14378	2289	Coteaux de l’Ain Revermont	\N	IGP -	{"fra": "Coteaux de l'Ain Revermont rouge"}	Coteaux de l'Ain Revermont rouge	\N
14689	2289	Coteaux de l’Ain Revermont	\N	IGP -	{"fra": "Coteaux de l'Ain Revermont blanc"}	Coteaux de l'Ain Revermont blanc	\N
14690	2289	Coteaux de l’Ain Revermont	\N	IGP -	{"fra": "Coteaux de l'Ain Revermont mousseux de qualité blanc"}	Coteaux de l'Ain Revermont mousseux de qualité blanc	\N
14390	2290	Coteaux de l’Ain Val de Saône	\N	IGP -	{"fra": "Coteaux de l'Ain Val de Saône blanc"}	Coteaux de l'Ain Val de Saône blanc	\N
14392	2290	Coteaux de l’Ain Val de Saône	\N	IGP -	{"fra": "Coteaux de l'Ain Val de Saône rouge"}	Coteaux de l'Ain Val de Saône rouge	\N
14393	2290	Coteaux de l’Ain Val de Saône	\N	IGP -	{"fra": "Coteaux de l'Ain Val de Saône mousseux de qualité blanc"}	Coteaux de l'Ain Val de Saône mousseux de qualité blanc	\N
14394	2290	Coteaux de l’Ain Val de Saône	\N	IGP -	{"fra": "Coteaux de l'Ain Val de Saône rosé"}	Coteaux de l'Ain Val de Saône rosé	\N
14395	2290	Coteaux de l’Ain Val de Saône	\N	IGP -	{"fra": "Coteaux de l'Ain Val de Saône mousseux de qualité rosé"}	Coteaux de l'Ain Val de Saône mousseux de qualité rosé	\N
14396	2290	Coteaux de l’Ain Val de Saône	\N	IGP -	{"fra": "Coteaux de l'Ain Val de Saône mousseux de qualité rouge"}	Coteaux de l'Ain Val de Saône mousseux de qualité rouge	\N
14397	2290	Coteaux de l’Ain Val de Saône	\N	IGP -	{"fra": "Coteaux de l'Ain Val de Saône primeur ou nouveau blanc"}	Coteaux de l'Ain Val de Saône primeur ou nouveau blanc	\N
14398	2290	Coteaux de l’Ain Val de Saône	\N	IGP -	{"fra": "Coteaux de l'Ain Val de Saône primeur ou nouveau rouge"}	Coteaux de l'Ain Val de Saône primeur ou nouveau rouge	\N
14399	2290	Coteaux de l’Ain Val de Saône	\N	IGP -	{"fra": "Coteaux de l'Ain Val de Saône primeur ou nouveau rosé"}	Coteaux de l'Ain Val de Saône primeur ou nouveau rosé	\N
14381	2291	Coteaux de l’Ain Valromey	\N	IGP -	{"fra": "Coteaux de l'Ain Valromey rouge"}	Coteaux de l'Ain Valromey rouge	\N
14382	2291	Coteaux de l’Ain Valromey	\N	IGP -	{"fra": "Coteaux de l'Ain Valromey rosé"}	Coteaux de l'Ain Valromey rosé	\N
14383	2291	Coteaux de l’Ain Valromey	\N	IGP -	{"fra": "Coteaux de l'Ain Valromey primeur ou nouveau rouge"}	Coteaux de l'Ain Valromey primeur ou nouveau rouge	\N
14384	2291	Coteaux de l’Ain Valromey	\N	IGP -	{"fra": "Coteaux de l'Ain Valromey primeur ou nouveau rosé"}	Coteaux de l'Ain Valromey primeur ou nouveau rosé	\N
14385	2291	Coteaux de l’Ain Valromey	\N	IGP -	{"fra": "Coteaux de l'Ain Valromey primeur ou nouveau rosé"}	Coteaux de l'Ain Valromey primeur ou nouveau rosé	\N
14386	2291	Coteaux de l’Ain Valromey	\N	IGP -	{"fra": "Coteaux de l'Ain Valromey primeur ou nouveau blanc"}	Coteaux de l'Ain Valromey primeur ou nouveau blanc	\N
14387	2291	Coteaux de l’Ain Valromey	\N	IGP -	{"fra": "Coteaux de l'Ain Valromey mousseux de qualité rouge"}	Coteaux de l'Ain Valromey mousseux de qualité rouge	\N
14388	2291	Coteaux de l’Ain Valromey	\N	IGP -	{"fra": "Coteaux de l'Ain Valromey mousseux de qualité rosé"}	Coteaux de l'Ain Valromey mousseux de qualité rosé	\N
14389	2291	Coteaux de l’Ain Valromey	\N	IGP -	{"fra": "Coteaux de l'Ain Valromey mousseux de qualité blanc"}	Coteaux de l'Ain Valromey mousseux de qualité blanc	\N
14391	2291	Coteaux de l’Ain Valromey	\N	IGP -	{"fra": "Coteaux de l'Ain Valromey blanc"}	Coteaux de l'Ain Valromey blanc	\N
7850	1986	Coteaux de Narbonne	\N	IGP -	{"fra": "Coteaux de Narbonne blanc"}	Coteaux de Narbonne blanc	\N
8436	1986	Coteaux de Narbonne	\N	IGP -	{"fra": "Coteaux de Narbonne rosé"}	Coteaux de Narbonne rosé	\N
8437	1986	Coteaux de Narbonne	\N	IGP -	{"fra": "Coteaux de Narbonne rouge"}	Coteaux de Narbonne rouge	\N
10611	1986	Coteaux de Narbonne	\N	IGP -	{"fra": "Coteaux de Narbonne primeur ou nouveau blanc"}	Coteaux de Narbonne primeur ou nouveau blanc	\N
10612	1986	Coteaux de Narbonne	\N	IGP -	{"fra": "Coteaux de Narbonne primeur ou nouveau rosé"}	Coteaux de Narbonne primeur ou nouveau rosé	\N
10613	1986	Coteaux de Narbonne	\N	IGP -	{"fra": "Coteaux de Narbonne primeur ou nouveau rouge"}	Coteaux de Narbonne primeur ou nouveau rouge	\N
7851	1987	Coteaux de Peyriac	\N	IGP -	{"fra": "Coteaux de Peyriac blanc"}	Coteaux de Peyriac blanc	\N
8593	1987	Coteaux de Peyriac	\N	IGP -	{"fra": "Coteaux de Peyriac rosé"}	Coteaux de Peyriac rosé	\N
8594	1987	Coteaux de Peyriac	\N	IGP -	{"fra": "Coteaux de Peyriac rouge"}	Coteaux de Peyriac rouge	\N
10614	1987	Coteaux de Peyriac	\N	IGP -	{"fra": "Coteaux de Peyriac primeur ou nouveau blanc"}	Coteaux de Peyriac primeur ou nouveau blanc	\N
10615	1987	Coteaux de Peyriac	\N	IGP -	{"fra": "Coteaux de Peyriac primeur ou nouveau rosé"}	Coteaux de Peyriac primeur ou nouveau rosé	\N
10616	1987	Coteaux de Peyriac	\N	IGP -	{"fra": "Coteaux de Peyriac primeur ou nouveau rouge"}	Coteaux de Peyriac primeur ou nouveau rouge	\N
10617	2321	Coteaux de Peyriac Haut de Badens	\N	IGP -	{"fra": "Coteaux de Peyriac Haut de Badens blanc"}	Coteaux de Peyriac Haut de Badens blanc	\N
10618	2321	Coteaux de Peyriac Haut de Badens	\N	IGP -	{"fra": "Coteaux de Peyriac Haut de Badens rosé"}	Coteaux de Peyriac Haut de Badens rosé	\N
10619	2321	Coteaux de Peyriac Haut de Badens	\N	IGP -	{"fra": "Coteaux de Peyriac Haut de Badens rouge"}	Coteaux de Peyriac Haut de Badens rouge	\N
10620	2321	Coteaux de Peyriac Haut de Badens	\N	IGP -	{"fra": "Coteaux de Peyriac Haut de Badens primeur ou nouveau blanc"}	Coteaux de Peyriac Haut de Badens primeur ou nouveau blanc	\N
10621	2321	Coteaux de Peyriac Haut de Badens	\N	IGP -	{"fra": "Coteaux de Peyriac Haut de Badens primeur ou nouveau rosé"}	Coteaux de Peyriac Haut de Badens primeur ou nouveau rosé	\N
10622	2321	Coteaux de Peyriac Haut de Badens	\N	IGP -	{"fra": "Coteaux de Peyriac Haut de Badens primeur ou nouveau rouge"}	Coteaux de Peyriac Haut de Badens primeur ou nouveau rouge	\N
16085	167	Coteaux de Saumur	AOC -	AOP -	{"fra": "Coteaux de Saumur"}	Coteaux de Saumur	\N
13496	2055	Coteaux de Tannay	\N	IGP -	{"fra": "Coteaux de Tannay blanc"}	Coteaux de Tannay blanc	\N
13497	2055	Coteaux de Tannay	\N	IGP -	{"fra": "Coteaux de Tannay rosé"}	Coteaux de Tannay rosé	\N
13498	2055	Coteaux de Tannay	\N	IGP -	{"fra": "Coteaux de Tannay rouge"}	Coteaux de Tannay rouge	\N
13861	2055	Coteaux de Tannay	\N	IGP -	{"fra": "Coteaux de Tannay mousseux de qualité blanc"}	Coteaux de Tannay mousseux de qualité blanc	\N
13862	2055	Coteaux de Tannay	\N	IGP -	{"fra": "Coteaux de Tannay mousseux de qualité rosé"}	Coteaux de Tannay mousseux de qualité rosé	\N
13863	2055	Coteaux de Tannay	\N	IGP -	{"fra": "Coteaux de Tannay mousseux de qualité rouge"}	Coteaux de Tannay mousseux de qualité rouge	\N
13864	2055	Coteaux de Tannay	\N	IGP -	{"fra": "Coteaux de Tannay primeur ou nouveau blanc"}	Coteaux de Tannay primeur ou nouveau blanc	\N
13865	2055	Coteaux de Tannay	\N	IGP -	{"fra": "Coteaux de Tannay primeur ou nouveau rosé"}	Coteaux de Tannay primeur ou nouveau rosé	\N
13866	2055	Coteaux de Tannay	\N	IGP -	{"fra": "Coteaux de Tannay primeur ou nouveau rouge"}	Coteaux de Tannay primeur ou nouveau rouge	\N
7833	2008	Coteaux des Baronnies	\N	IGP -	{"fra": "Coteaux des Baronnies blanc"}	Coteaux des Baronnies blanc	\N
8841	2008	Coteaux des Baronnies	\N	IGP -	{"fra": "Coteaux des Baronnies rosé"}	Coteaux des Baronnies rosé	\N
8842	2008	Coteaux des Baronnies	\N	IGP -	{"fra": "Coteaux des Baronnies rouge"}	Coteaux des Baronnies rouge	\N
10632	2008	Coteaux des Baronnies	\N	IGP -	{"fra": "Coteaux des Baronnies mousseux de qualité blanc"}	Coteaux des Baronnies mousseux de qualité blanc	\N
10633	2008	Coteaux des Baronnies	\N	IGP -	{"fra": "Coteaux des Baronnies mousseux de qualité rosé"}	Coteaux des Baronnies mousseux de qualité rosé	\N
10634	2008	Coteaux des Baronnies	\N	IGP -	{"fra": "Coteaux des Baronnies mousseux de qualité rouge"}	Coteaux des Baronnies mousseux de qualité rouge	\N
10635	2008	Coteaux des Baronnies	\N	IGP -	{"fra": "Coteaux des Baronnies primeur ou nouveau blanc"}	Coteaux des Baronnies primeur ou nouveau blanc	\N
10636	2008	Coteaux des Baronnies	\N	IGP -	{"fra": "Coteaux des Baronnies primeur ou nouveau rosé"}	Coteaux des Baronnies primeur ou nouveau rosé	\N
10637	2008	Coteaux des Baronnies	\N	IGP -	{"fra": "Coteaux des Baronnies primeur ou nouveau rouge"}	Coteaux des Baronnies primeur ou nouveau rouge	\N
13993	1998	Coteaux du Cher et de l'Arnon	\N	IGP -	{"fra": "Coteaux du Cher et de l'Arnon blanc"}	Coteaux du Cher et de l'Arnon blanc	\N
14079	1998	Coteaux du Cher et de l'Arnon	\N	IGP -	{"fra": "Coteaux du Cher et de l'Arnon rosé"}	Coteaux du Cher et de l'Arnon rosé	\N
14080	1998	Coteaux du Cher et de l'Arnon	\N	IGP -	{"fra": "Coteaux du Cher et de l'Arnon rouge"}	Coteaux du Cher et de l'Arnon rouge	\N
16108	219	Coteaux du Giennois	AOC -	AOP -	{"fra": "Coteaux du Giennois blanc"}	Coteaux du Giennois blanc	\N
16109	219	Coteaux du Giennois	AOC -	AOP -	{"fra": "Coteaux du Giennois rosé"}	Coteaux du Giennois rosé	\N
16110	219	Coteaux du Giennois	AOC -	AOP -	{"fra": "Coteaux du Giennois rouge"}	Coteaux du Giennois rouge	\N
15146	168	Coteaux du Layon	AOC -	AOP -	{"fra": "Coteaux du Layon"}	Coteaux du Layon	\N
15160	168	Coteaux du Layon	AOC -	AOP -	{"fra": "Coteaux du Layon Sélection de grains nobles"}	Coteaux du Layon Sélection de grains nobles	\N
15147	169	Coteaux du Layon Beaulieu-sur-Layon	AOC -	AOP -	{"fra": "Coteaux du Layon Beaulieu-sur-Layon ou Beaulieu"}	Coteaux du Layon Beaulieu-sur-Layon ou Beaulieu	\N
15148	169	Coteaux du Layon Beaulieu-sur-Layon	AOC -	AOP -	{"fra": "Coteaux du Layon Beaulieu-sur-Layon ou Beaulieu Sélection de grains nobles"}	Coteaux du Layon Beaulieu-sur-Layon ou Beaulieu Sélection de grains nobles	\N
15149	171	Coteaux du Layon Faye-d'Anjou	AOC -	AOP -	{"fra": "Coteaux du Layon Faye-d'Anjou ou Faye"}	Coteaux du Layon Faye-d'Anjou ou Faye	\N
15150	171	Coteaux du Layon Faye-d'Anjou	AOC -	AOP -	{"fra": "Coteaux du Layon Faye-d'Anjou ou Faye Sélection de grains nobles"}	Coteaux du Layon Faye-d'Anjou ou Faye Sélection de grains nobles	\N
15151	2172	Coteaux du Layon premier cru Chaume	AOC -	AOP -	{"fra": "Coteaux du Layon premier cru Chaume"}	Coteaux du Layon premier cru Chaume	\N
15152	172	Coteaux du Layon Rablay-sur-Layon	AOC -	AOP -	{"fra": "Coteaux du Layon Rablay-sur-Layon ou Rablay"}	Coteaux du Layon Rablay-sur-Layon ou Rablay	\N
15153	172	Coteaux du Layon Rablay-sur-Layon	AOC -	AOP -	{"fra": "Coteaux du Layon Rablay-sur-Layon ou Rablay Sélection de grains nobles"}	Coteaux du Layon Rablay-sur-Layon ou Rablay Sélection de grains nobles	\N
15154	173	Coteaux du Layon Rochefort-sur-Loire	AOC -	AOP -	{"fra": "Coteaux du Layon Rochefort-sur-Loire ou Rochefort"}	Coteaux du Layon Rochefort-sur-Loire ou Rochefort	\N
15155	173	Coteaux du Layon Rochefort-sur-Loire	AOC -	AOP -	{"fra": "Coteaux du Layon Rochefort-sur-Loire ou Rochefort Sélection de grains nobles"}	Coteaux du Layon Rochefort-sur-Loire ou Rochefort Sélection de grains nobles	\N
15156	174	Coteaux du Layon Saint-Aubin-de-Luigné	AOC -	AOP -	{"fra": "Coteaux du Layon Saint-Aubin-de-Luigné ou Saint-Aubin"}	Coteaux du Layon Saint-Aubin-de-Luigné ou Saint-Aubin	\N
15157	174	Coteaux du Layon Saint-Aubin-de-Luigné	AOC -	AOP -	{"fra": "Coteaux du Layon Saint-Aubin-de-Luigné ou Saint-Aubin Sélection de grains nobles"}	Coteaux du Layon Saint-Aubin-de-Luigné ou Saint-Aubin Sélection de grains nobles	\N
15158	175	Coteaux du Layon Saint-Lambert-du-Lattay	AOC -	AOP -	{"fra": "Coteaux du Layon Saint-Lambert-du-Lattay ou Saint-Lambert"}	Coteaux du Layon Saint-Lambert-du-Lattay ou Saint-Lambert	\N
15159	175	Coteaux du Layon Saint-Lambert-du-Lattay	AOC -	AOP -	{"fra": "Coteaux du Layon Saint-Lambert-du-Lattay ou Saint-Lambert Sélection de grains nobles"}	Coteaux du Layon Saint-Lambert-du-Lattay ou Saint-Lambert Sélection de grains nobles	\N
7967	176	Coteaux du Loir	AOC -	AOP -	{"fra": "Coteaux du Loir blanc"}	Coteaux du Loir blanc	\N
7968	176	Coteaux du Loir	AOC -	AOP -	{"fra": "Coteaux du Loir rosé"}	Coteaux du Loir rosé	\N
7969	176	Coteaux du Loir	AOC -	AOP -	{"fra": "Coteaux du Loir rouge"}	Coteaux du Loir rouge	\N
6340	517	Coteaux du Lyonnais	AOC -	AOP -	{"fra": "Coteaux du Lyonnais blanc"}	Coteaux du Lyonnais blanc	\N
6341	517	Coteaux du Lyonnais	AOC -	AOP -	{"fra": "Coteaux du Lyonnais rouge"}	Coteaux du Lyonnais rouge	\N
6342	517	Coteaux du Lyonnais	AOC -	AOP -	{"fra": "Coteaux du Lyonnais rosé"}	Coteaux du Lyonnais rosé	\N
6343	517	Coteaux du Lyonnais	AOC -	AOP -	{"fra": "Coteaux du Lyonnais rouge nouveau ou primeur"}	Coteaux du Lyonnais rouge nouveau ou primeur	\N
6344	517	Coteaux du Lyonnais	AOC -	AOP -	{"fra": "Coteaux du Lyonnais rosé nouveau ou primeur"}	Coteaux du Lyonnais rosé nouveau ou primeur	\N
6345	517	Coteaux du Lyonnais	AOC -	AOP -	{"fra": "Coteaux du Lyonnais blanc nouveau ou primeur"}	Coteaux du Lyonnais blanc nouveau ou primeur	\N
16028	2014	Coteaux du Pont du Gard	\N	IGP -	{"fra": "Coteaux du Pont du Gard blanc"}	Coteaux du Pont du Gard blanc	\N
16029	2014	Coteaux du Pont du Gard	\N	IGP -	{"fra": "Coteaux du Pont du Gard primeur ou nouveau blanc"}	Coteaux du Pont du Gard primeur ou nouveau blanc	\N
16030	2014	Coteaux du Pont du Gard	\N	IGP -	{"fra": "Coteaux du Pont du Gard primeur ou nouveau rosé"}	Coteaux du Pont du Gard primeur ou nouveau rosé	\N
16031	2014	Coteaux du Pont du Gard	\N	IGP -	{"fra": "Coteaux du Pont du Gard primeur ou nouveau rouge"}	Coteaux du Pont du Gard primeur ou nouveau rouge	\N
16032	2014	Coteaux du Pont du Gard	\N	IGP -	{"fra": "Coteaux du Pont du Gard rosé"}	Coteaux du Pont du Gard rosé	\N
16033	2014	Coteaux du Pont du Gard	\N	IGP -	{"fra": "Coteaux du Pont du Gard rouge"}	Coteaux du Pont du Gard rouge	\N
16034	2014	Coteaux du Pont du Gard	\N	IGP -	{"fra": "Coteaux du Pont du Gard surmûri blanc"}	Coteaux du Pont du Gard surmûri blanc	\N
16035	2014	Coteaux du Pont du Gard	\N	IGP -	{"fra": "Coteaux du Pont du Gard surmûri rosé"}	Coteaux du Pont du Gard surmûri rosé	\N
16036	2014	Coteaux du Pont du Gard	\N	IGP -	{"fra": "Coteaux du Pont du Gard surmûri rouge"}	Coteaux du Pont du Gard surmûri rouge	\N
4275	2336	Coteaux du Quercy	AOC -	AOP -	{"fra": "Coteaux du Quercy rouge"}	Coteaux du Quercy rouge	\N
12202	2336	Coteaux du Quercy	AOC -	AOP -	{"fra": "Coteaux du Quercy rosé"}	Coteaux du Quercy rosé	\N
8202	217	Coteaux du Vendômois	AOC -	AOP -	{"fra": "Coteaux du Vendômois blanc"}	Coteaux du Vendômois blanc	\N
8203	217	Coteaux du Vendômois	AOC -	AOP -	{"fra": "Coteaux du Vendômois gris"}	Coteaux du Vendômois gris	\N
8204	217	Coteaux du Vendômois	AOC -	AOP -	{"fra": "Coteaux du Vendômois rouge"}	Coteaux du Vendômois rouge	\N
14454	1321	Coteaux varois en Provence	AOC -	AOP -	{"fra": "Coteaux varois en Provence blanc"}	Coteaux varois en Provence blanc	\N
14455	1321	Coteaux varois en Provence	AOC -	AOP -	{"fra": "Coteaux varois en Provence rosé"}	Coteaux varois en Provence rosé	\N
14456	1321	Coteaux varois en Provence	AOC -	AOP -	{"fra": "Coteaux varois en Provence rouge"}	Coteaux varois en Provence rouge	\N
7830	2061	Côtes Catalanes	\N	IGP -	{"fra": "Côtes Catalanes blanc"}	Côtes Catalanes blanc	\N
8585	2061	Côtes Catalanes	\N	IGP -	{"fra": "Côtes Catalanes rosé"}	Côtes Catalanes rosé	\N
8586	2061	Côtes Catalanes	\N	IGP -	{"fra": "Côtes Catalanes rouge"}	Côtes Catalanes rouge	\N
10658	2061	Côtes Catalanes	\N	IGP -	{"fra": "Côtes Catalanes primeur ou nouveau blanc"}	Côtes Catalanes primeur ou nouveau blanc	\N
10659	2061	Côtes Catalanes	\N	IGP -	{"fra": "Côtes Catalanes primeur ou nouveau rosé"}	Côtes Catalanes primeur ou nouveau rosé	\N
10660	2061	Côtes Catalanes	\N	IGP -	{"fra": "Côtes Catalanes primeur ou nouveau rouge"}	Côtes Catalanes primeur ou nouveau rouge	\N
10661	2061	Côtes Catalanes	\N	IGP -	{"fra": "Côtes Catalanes rancio blanc"}	Côtes Catalanes rancio blanc	\N
10662	2061	Côtes Catalanes	\N	IGP -	{"fra": "Côtes Catalanes rancio rosé"}	Côtes Catalanes rancio rosé	\N
10663	2061	Côtes Catalanes	\N	IGP -	{"fra": "Côtes Catalanes rancio rouge"}	Côtes Catalanes rancio rouge	\N
10664	2323	Côtes catalanes Pyrénées Orientales	\N	IGP -	{"fra": "Côtes Catalanes Pyrénées Orientales blanc"}	Côtes Catalanes Pyrénées Orientales blanc	\N
10665	2323	Côtes catalanes Pyrénées Orientales	\N	IGP -	{"fra": "Côtes Catalanes Pyrénées Orientales rosé"}	Côtes Catalanes Pyrénées Orientales rosé	\N
10666	2323	Côtes catalanes Pyrénées Orientales	\N	IGP -	{"fra": "Côtes Catalanes Pyrénées Orientales rouge"}	Côtes Catalanes Pyrénées Orientales rouge	\N
10667	2323	Côtes catalanes Pyrénées Orientales	\N	IGP -	{"fra": "Côtes Catalanes Pyrénées Orientales primeur ou nouveau blanc"}	Côtes Catalanes Pyrénées Orientales primeur ou nouveau blanc	\N
10668	2323	Côtes catalanes Pyrénées Orientales	\N	IGP -	{"fra": "Côtes Catalanes Pyrénées Orientales primeur ou nouveau rosé"}	Côtes Catalanes Pyrénées Orientales primeur ou nouveau rosé	\N
10669	2323	Côtes catalanes Pyrénées Orientales	\N	IGP -	{"fra": "Côtes Catalanes Pyrénées Orientales primeur ou nouveau rouge"}	Côtes Catalanes Pyrénées Orientales primeur ou nouveau rouge	\N
10670	2323	Côtes catalanes Pyrénées Orientales	\N	IGP -	{"fra": "Côtes Catalanes Pyrénées Orientales rancio blanc"}	Côtes Catalanes Pyrénées Orientales rancio blanc	\N
10671	2323	Côtes catalanes Pyrénées Orientales	\N	IGP -	{"fra": "Côtes Catalanes Pyrénées Orientales rancio rosé"}	Côtes Catalanes Pyrénées Orientales rancio rosé	\N
10672	2323	Côtes catalanes Pyrénées Orientales	\N	IGP -	{"fra": "Côtes Catalanes Pyrénées Orientales rancio rouge"}	Côtes Catalanes Pyrénées Orientales rancio rouge	\N
14878	2146	Côtes d'Auvergne	AOC -	AOP -	{"fra": "Côtes d'Auvergne blanc"}	Côtes d'Auvergne blanc	\N
14879	2146	Côtes d'Auvergne	AOC -	AOP -	{"fra": "Côtes d'Auvergne rosé"}	Côtes d'Auvergne rosé	\N
14880	2146	Côtes d'Auvergne	AOC -	AOP -	{"fra": "Côtes d'Auvergne rouge"}	Côtes d'Auvergne rouge	\N
14881	2147	Côtes d'Auvergne Boudes	AOC -	AOP -	{"fra": "Côtes d'Auvergne Boudes rouge"}	Côtes d'Auvergne Boudes rouge	\N
14882	2148	Côtes d'Auvergne Chanturgue	AOC -	AOP -	{"fra": "Côtes d'Auvergne Chanturgue rouge"}	Côtes d'Auvergne Chanturgue rouge	\N
14883	2149	Côtes d'Auvergne Châteaugay	AOC -	AOP -	{"fra": "Côtes d'Auvergne Châteaugay rouge"}	Côtes d'Auvergne Châteaugay rouge	\N
14885	2150	Côtes d'Auvergne Corent	AOC -	AOP -	{"fra": "Côtes d'Auvergne Corent rosé"}	Côtes d'Auvergne Corent rosé	\N
14884	2151	Côtes d'Auvergne Madargues	AOC -	AOP -	{"fra": "Côtes d'Auvergne Madargues rouge"}	Côtes d'Auvergne Madargues rouge	\N
14452	1875	Côtes de Bergerac	AOC -	AOP -	{"fra": "Côtes de Bergerac blanc"}	Côtes de Bergerac blanc	\N
14453	1875	Côtes de Bergerac	AOC -	AOP -	{"fra": "Côtes de Bergerac rouge"}	Côtes de Bergerac rouge	\N
14980	72	Côtes de Blaye	AOC -	AOP -	{"fra": "Côtes de Blaye"}	Côtes de Blaye	\N
14051	1681	Côtes de Bordeaux	AOC -	AOP -	{"fra": "Côtes de Bordeaux"}	Côtes de Bordeaux	\N
14052	1892	Côtes de Bordeaux Blaye	AOC -	AOP -	{"fra": "Côtes de Bordeaux Blaye blanc"}	Côtes de Bordeaux Blaye blanc	\N
14053	1892	Côtes de Bordeaux Blaye	AOC -	AOP -	{"fra": "Côtes de Bordeaux Blaye rouge"}	Côtes de Bordeaux Blaye rouge	\N
14054	1890	Côtes de Bordeaux Cadillac	AOC -	AOP -	{"fra": "Côtes de Bordeaux Cadillac"}	Côtes de Bordeaux Cadillac	\N
14055	1891	Côtes de Bordeaux Castillon	AOC -	AOP -	{"fra": "Côtes de Bordeaux Castillon"}	Côtes de Bordeaux Castillon	\N
9395	1893	Côtes de Bordeaux Francs	AOC -	AOP -	{"fra": "Côtes de Bordeaux Francs rouge"}	Côtes de Bordeaux Francs rouge	\N
14056	1893	Côtes de Bordeaux Francs	AOC -	AOP -	{"fra": "Côtes de Bordeaux Francs blanc sec"}	Côtes de Bordeaux Francs blanc sec	\N
14057	1893	Côtes de Bordeaux Francs	AOC -	AOP -	{"fra": "Côtes de Bordeaux Francs liquoreux"}	Côtes de Bordeaux Francs liquoreux	\N
14154	2422	Côtes de Bordeaux Sainte-Foy	AOC -	AOP -	{"fra": "Côtes de Bordeaux-Sainte-Foy moelleux"}	Côtes de Bordeaux-Sainte-Foy moelleux	\N
14155	2422	Côtes de Bordeaux Sainte-Foy	AOC -	AOP -	{"fra": "Côtes de Bordeaux Sainte-Foy liquoreux"}	Côtes de Bordeaux Sainte-Foy liquoreux	\N
14156	2422	Côtes de Bordeaux Sainte-Foy	AOC -	AOP -	{"fra": "Côtes de Bordeaux Sainte-Foy blanc sec"}	Côtes de Bordeaux Sainte-Foy blanc sec	\N
14157	2422	Côtes de Bordeaux Sainte-Foy	AOC -	AOP -	{"fra": "Côtes de Bordeaux Sainte-Foy rouge"}	Côtes de Bordeaux Sainte-Foy rouge	\N
14917	73	Côtes de Bordeaux-Saint-Macaire	AOC -	AOP -	{"fra": "Côtes de Bordeaux-Saint-Macaire"}	Côtes de Bordeaux-Saint-Macaire	\N
14918	73	Côtes de Bordeaux-Saint-Macaire	AOC -	AOP -	{"fra": "Côtes de Bordeaux-Saint-Macaire liquoreux"}	Côtes de Bordeaux-Saint-Macaire liquoreux	\N
14919	73	Côtes de Bordeaux-Saint-Macaire	AOC -	AOP -	{"fra": "Côtes de Bordeaux-Saint-Macaire moelleux"}	Côtes de Bordeaux-Saint-Macaire moelleux	\N
12198	66	Côtes de Bourg, Bourg et Bourgeais	AOC -	AOP -	{"fra": "Côtes de Bourg, Bourg et Bourgeais blanc"}	Côtes de Bourg, Bourg et Bourgeais blanc	\N
12311	66	Côtes de Bourg, Bourg et Bourgeais	AOC -	AOP -	{"fra": "Côtes de Bourg, Bourg et Bourgeais rouge"}	Côtes de Bourg, Bourg et Bourgeais rouge	\N
8303	75	Côtes de Duras	AOC -	AOP -	{"fra": "Côtes de Duras blanc"}	Côtes de Duras blanc	\N
8304	75	Côtes de Duras	AOC -	AOP -	{"fra": "Côtes de Duras blanc sec"}	Côtes de Duras blanc sec	\N
8305	75	Côtes de Duras	AOC -	AOP -	{"fra": "Côtes de Duras rosé"}	Côtes de Duras rosé	\N
8306	75	Côtes de Duras	AOC -	AOP -	{"fra": "Côtes de Duras rouge"}	Côtes de Duras rouge	\N
7853	2022	Côtes de Gascogne	\N	IGP -	{"fra": "Côtes de Gascogne blanc"}	Côtes de Gascogne blanc	\N
8424	2022	Côtes de Gascogne	\N	IGP -	{"fra": "Côtes de Gascogne rosé"}	Côtes de Gascogne rosé	\N
8425	2022	Côtes de Gascogne	\N	IGP -	{"fra": "Côtes de Gascogne rouge"}	Côtes de Gascogne rouge	\N
10673	2022	Côtes de Gascogne	\N	IGP -	{"fra": "Côtes de Gascogne surmûri blanc"}	Côtes de Gascogne surmûri blanc	\N
10674	2022	Côtes de Gascogne	\N	IGP -	{"fra": "Côtes de Gascogne primeur ou nouveau blanc"}	Côtes de Gascogne primeur ou nouveau blanc	\N
10675	2022	Côtes de Gascogne	\N	IGP -	{"fra": "Côtes de Gascogne primeur ou nouveau rosé"}	Côtes de Gascogne primeur ou nouveau rosé	\N
10676	2022	Côtes de Gascogne	\N	IGP -	{"fra": "Côtes de Gascogne  primeur ou nouveau rouge"}	Côtes de Gascogne  primeur ou nouveau rouge	\N
10677	2324	Côtes de Gascogne Condomois	\N	IGP -	{"fra": "Côtes de Gascogne Condomois blanc"}	Côtes de Gascogne Condomois blanc	\N
10678	2324	Côtes de Gascogne Condomois	\N	IGP -	{"fra": "Côtes de Gascogne Condomois rosé"}	Côtes de Gascogne Condomois rosé	\N
10679	2324	Côtes de Gascogne Condomois	\N	IGP -	{"fra": "Côtes de Gascogne Condomois rouge"}	Côtes de Gascogne Condomois rouge	\N
10680	2324	Côtes de Gascogne Condomois	\N	IGP -	{"fra": "Côtes de Gascogne Condomois surmûri blanc"}	Côtes de Gascogne Condomois surmûri blanc	\N
10681	2324	Côtes de Gascogne Condomois	\N	IGP -	{"fra": "Côtes de Gascogne Condomois primeur ou nouveau blanc"}	Côtes de Gascogne Condomois primeur ou nouveau blanc	\N
10682	2324	Côtes de Gascogne Condomois	\N	IGP -	{"fra": "Côtes de Gascogne Condomois primeur ou nouveau rosé"}	Côtes de Gascogne Condomois primeur ou nouveau rosé	\N
10683	2324	Côtes de Gascogne Condomois	\N	IGP -	{"fra": "Côtes de Gascogne Condomois primeur ou nouveau rouge"}	Côtes de Gascogne Condomois primeur ou nouveau rouge	\N
14486	2054	Côtes de la Charité	\N	IGP -	{"fra": "Côtes de la Charité  mousseux de qualité rosé"}	Côtes de la Charité  mousseux de qualité rosé	\N
14487	2054	Côtes de la Charité	\N	IGP -	{"fra": "Côtes de la Charité blanc"}	Côtes de la Charité blanc	\N
14488	2054	Côtes de la Charité	\N	IGP -	{"fra": "Côtes de la Charité mousseux de qualité blanc"}	Côtes de la Charité mousseux de qualité blanc	\N
14489	2054	Côtes de la Charité	\N	IGP -	{"fra": "Côtes de la Charité rosé"}	Côtes de la Charité rosé	\N
14490	2054	Côtes de la Charité	\N	IGP -	{"fra": "Côtes de la Charité rouge"}	Côtes de la Charité rouge	\N
8787	2052	Côtes de Meuse	\N	IGP -	{"fra": "Côtes de Meuse blanc"}	Côtes de Meuse blanc	\N
8788	2052	Côtes de Meuse	\N	IGP -	{"fra": "Côtes de Meuse rosé"}	Côtes de Meuse rosé	\N
8789	2052	Côtes de Meuse	\N	IGP -	{"fra": "Côtes de Meuse rouge"}	Côtes de Meuse rouge	\N
10691	2052	Côtes de Meuse	\N	IGP -	{"fra": "Côtes de Meuse primeur ou nouveau blanc"}	Côtes de Meuse primeur ou nouveau blanc	\N
10692	2052	Côtes de Meuse	\N	IGP -	{"fra": "Côtes de Meuse primeur ou nouveau rosé"}	Côtes de Meuse primeur ou nouveau rosé	\N
10693	2052	Côtes de Meuse	\N	IGP -	{"fra": "Côtes de Meuse primeur ou nouveau rouge"}	Côtes de Meuse primeur ou nouveau rouge	\N
9072	1723	Côtes de Millau	AOC -	AOP -	{"fra": "Côtes de Millau blanc"}	Côtes de Millau blanc	\N
9073	1723	Côtes de Millau	AOC -	AOP -	{"fra": "Côtes de Millau rosé"}	Côtes de Millau rosé	\N
9074	1723	Côtes de Millau	AOC -	AOP -	{"fra": "Côtes de Millau rouge"}	Côtes de Millau rouge	\N
12976	1665	Côtes de Montravel	AOC -	AOP -	{"fra": "Côtes de Montravel"}	Côtes de Montravel	\N
15332	1322	Côtes de Provence	AOC -	AOP -	{"fra": "Côtes de Provence blanc"}	Côtes de Provence blanc	\N
15333	1322	Côtes de Provence	AOC -	AOP -	{"fra": "Côtes de Provence rosé"}	Côtes de Provence rosé	\N
15334	1322	Côtes de Provence	AOC -	AOP -	{"fra": "Côtes de Provence rouge"}	Côtes de Provence rouge	\N
15337	1633	Côtes de Provence Fréjus	AOC -	AOP -	{"fra": "Côtes de Provence Fréjus rosé"}	Côtes de Provence Fréjus rosé	\N
15338	1633	Côtes de Provence Fréjus	AOC -	AOP -	{"fra": "Côtes de Provence Fréjus rouge"}	Côtes de Provence Fréjus rouge	\N
15339	1677	Côtes de Provence la Londe	AOC -	AOP -	{"fra": "Côtes de Provence la Londe blanc"}	Côtes de Provence la Londe blanc	\N
15340	1677	Côtes de Provence la Londe	AOC -	AOP -	{"fra": "Côtes de Provence la Londe rosé"}	Côtes de Provence la Londe rosé	\N
15341	1677	Côtes de Provence la Londe	AOC -	AOP -	{"fra": "Côtes de Provence la Londe rouge"}	Côtes de Provence la Londe rouge	\N
15335	2462	Côtes de Provence Notre-Dame des Anges	AOC -	AOP -	{"fra": "Côtes de Provence Notre-Dame des Anges rosé"}	Côtes de Provence Notre-Dame des Anges rosé	\N
15336	2462	Côtes de Provence Notre-Dame des Anges	AOC -	AOP -	{"fra": "Côtes de Provence Notre-Dame des Anges rouge"}	Côtes de Provence Notre-Dame des Anges rouge	\N
15342	2347	Côtes de Provence Pierrefeu	AOC -	AOP -	{"fra": "Côtes de Provence Pierrefeu rosé"}	Côtes de Provence Pierrefeu rosé	\N
15343	2347	Côtes de Provence Pierrefeu	AOC -	AOP -	{"fra": "Côtes de Provence Pierrefeu rouge"}	Côtes de Provence Pierrefeu rouge	\N
15344	1616	Côtes de Provence Sainte-Victoire	AOC -	AOP -	{"fra": "Côtes de Provence Sainte-Victoire rosé"}	Côtes de Provence Sainte-Victoire rosé	\N
15345	1616	Côtes de Provence Sainte-Victoire	AOC -	AOP -	{"fra": "Côtes de Provence Sainte-Victoire rouge"}	Côtes de Provence Sainte-Victoire rouge	\N
7826	2106	Côtes de Thau	\N	IGP -	{"fra": "Côtes de Thau blanc"}	Côtes de Thau blanc	\N
8426	2106	Côtes de Thau	\N	IGP -	{"fra": "Côtes de Thau rosé"}	Côtes de Thau rosé	\N
8427	2106	Côtes de Thau	\N	IGP -	{"fra": "Côtes de Thau rouge"}	Côtes de Thau rouge	\N
10694	2106	Côtes de Thau	\N	IGP -	{"fra": "Côtes de Thau mousseux de qualité blanc"}	Côtes de Thau mousseux de qualité blanc	\N
10695	2106	Côtes de Thau	\N	IGP -	{"fra": "Côtes de Thau mousseux de qualité rosé"}	Côtes de Thau mousseux de qualité rosé	\N
10696	2106	Côtes de Thau	\N	IGP -	{"fra": "Côtes de Thau mousseux de qualité rouge"}	Côtes de Thau mousseux de qualité rouge	\N
10697	2106	Côtes de Thau	\N	IGP -	{"fra": "Côtes de Thau primeur ou nouveau blanc"}	Côtes de Thau primeur ou nouveau blanc	\N
10698	2106	Côtes de Thau	\N	IGP -	{"fra": "Côtes de Thau primeur ou nouveau rosé"}	Côtes de Thau primeur ou nouveau rosé	\N
10699	2106	Côtes de Thau	\N	IGP -	{"fra": "Côtes de Thau primeur ou nouveau rouge"}	Côtes de Thau primeur ou nouveau rouge	\N
10700	2325	Côtes de Thau Cap d'Agde	\N	IGP -	{"fra": "Côtes de Thau Cap d'Agde blanc"}	Côtes de Thau Cap d'Agde blanc	\N
10701	2325	Côtes de Thau Cap d'Agde	\N	IGP -	{"fra": "Côtes de Thau Cap d'Agde rosé"}	Côtes de Thau Cap d'Agde rosé	\N
10702	2325	Côtes de Thau Cap d'Agde	\N	IGP -	{"fra": "Côtes de Thau Cap d'Agde rouge"}	Côtes de Thau Cap d'Agde rouge	\N
10703	2325	Côtes de Thau Cap d'Agde	\N	IGP -	{"fra": "Côtes de Thau Cap d'Agde mousseux de qualité blanc"}	Côtes de Thau Cap d'Agde mousseux de qualité blanc	\N
10704	2325	Côtes de Thau Cap d'Agde	\N	IGP -	{"fra": "Côtes de Thau Cap d'Agde mousseux de qualité rosé"}	Côtes de Thau Cap d'Agde mousseux de qualité rosé	\N
10705	2325	Côtes de Thau Cap d'Agde	\N	IGP -	{"fra": "Côtes de Thau Cap d'Agde mousseux de qualité rouge"}	Côtes de Thau Cap d'Agde mousseux de qualité rouge	\N
10706	2325	Côtes de Thau Cap d'Agde	\N	IGP -	{"fra": "Côtes de Thau Cap d'Agde primeur ou nouveau blanc"}	Côtes de Thau Cap d'Agde primeur ou nouveau blanc	\N
10707	2325	Côtes de Thau Cap d'Agde	\N	IGP -	{"fra": "Côtes de Thau Cap d'Agde primeur ou nouveau rosé"}	Côtes de Thau Cap d'Agde primeur ou nouveau rosé	\N
10708	2325	Côtes de Thau Cap d'Agde	\N	IGP -	{"fra": "Côtes de Thau Cap d'Agde primeur ou nouveau rouge"}	Côtes de Thau Cap d'Agde primeur ou nouveau rouge	\N
12562	2107	Côtes de Thongue	\N	IGP -	{"fra": "Côtes de Thongue rouge"}	Côtes de Thongue rouge	\N
12824	2107	Côtes de Thongue	\N	IGP -	{"fra": "Côtes de Thongue blanc"}	Côtes de Thongue blanc	\N
12825	2107	Côtes de Thongue	\N	IGP -	{"fra": "Côtes de Thongue rosé"}	Côtes de Thongue rosé	\N
12826	2107	Côtes de Thongue	\N	IGP -	{"fra": "Côtes de Thongue mousseux de qualité blanc"}	Côtes de Thongue mousseux de qualité blanc	\N
12827	2107	Côtes de Thongue	\N	IGP -	{"fra": "Côtes de Thongue mousseux de qualité rosé"}	Côtes de Thongue mousseux de qualité rosé	\N
12828	2107	Côtes de Thongue	\N	IGP -	{"fra": "Côtes de Thongue mousseux de qualité rouge"}	Côtes de Thongue mousseux de qualité rouge	\N
12829	2107	Côtes de Thongue	\N	IGP -	{"fra": "Côtes de Thongue primeur ou nouveau blanc"}	Côtes de Thongue primeur ou nouveau blanc	\N
12830	2107	Côtes de Thongue	\N	IGP -	{"fra": "Côtes de Thongue primeur ou nouveau rosé"}	Côtes de Thongue primeur ou nouveau rosé	\N
12831	2107	Côtes de Thongue	\N	IGP -	{"fra": "Côtes de Thongue primeur ou nouveau rouge"}	Côtes de Thongue primeur ou nouveau rouge	\N
12832	2107	Côtes de Thongue	\N	IGP -	{"fra": "Côtes de Thongue surmûri blanc"}	Côtes de Thongue surmûri blanc	\N
12833	2107	Côtes de Thongue	\N	IGP -	{"fra": "Côtes de Thongue surmûri rosé"}	Côtes de Thongue surmûri rosé	\N
12834	2107	Côtes de Thongue	\N	IGP -	{"fra": "Côtes de Thongue surmûri rouge"}	Côtes de Thongue surmûri rouge	\N
7996	53	Côtes de Toul	AOC -	AOP -	{"fra": "Côtes de Toul blanc"}	Côtes de Toul blanc	\N
7997	53	Côtes de Toul	AOC -	AOP -	{"fra": "Côtes de Toul gris"}	Côtes de Toul gris	\N
7998	53	Côtes de Toul	AOC -	AOP -	{"fra": "Côtes de Toul rouge"}	Côtes de Toul rouge	\N
7629	1229	Côtes du Forez	AOC -	AOP -	{"fra": "Côtes du Forez rosé"}	Côtes du Forez rosé	\N
7630	1229	Côtes du Forez	AOC -	AOP -	{"fra": "Côtes du Forez rouge"}	Côtes du Forez rouge	\N
12234	518	Côtes du Jura	AOC -	AOP -	{"fra": "Côtes du Jura blanc"}	Côtes du Jura blanc	\N
12235	518	Côtes du Jura	AOC -	AOP -	{"fra": "Côtes du Jura rosé"}	Côtes du Jura rosé	\N
12236	518	Côtes du Jura	AOC -	AOP -	{"fra": "Côtes du Jura rouge"}	Côtes du Jura rouge	\N
12237	518	Côtes du Jura	AOC -	AOP -	{"fra": "Côtes du Jura vin de paille"}	Côtes du Jura vin de paille	\N
12238	518	Côtes du Jura	AOC -	AOP -	{"fra": "Côtes du Jura vin jaune"}	Côtes du Jura vin jaune	\N
10951	2245	Côtes du Lot Rocamadour	\N	IGP -	{"fra": "Côtes du Lot Rocamadour blanc"}	Côtes du Lot Rocamadour blanc	\N
10952	2245	Côtes du Lot Rocamadour	\N	IGP -	{"fra": "Côtes du Lot Rocamadour rosé"}	Côtes du Lot Rocamadour rosé	\N
10953	2245	Côtes du Lot Rocamadour	\N	IGP -	{"fra": "Côtes du Lot Rocamadour rouge"}	Côtes du Lot Rocamadour rouge	\N
10954	2245	Côtes du Lot Rocamadour	\N	IGP -	{"fra": "Côtes du Lot Rocamadour mousseux de qualité blanc"}	Côtes du Lot Rocamadour mousseux de qualité blanc	\N
10955	2245	Côtes du Lot Rocamadour	\N	IGP -	{"fra": "Côtes du Lot Rocamadour mousseux de qualité rosé"}	Côtes du Lot Rocamadour mousseux de qualité rosé	\N
10956	2245	Côtes du Lot Rocamadour	\N	IGP -	{"fra": "Côtes du Lot Rocamadour primeur ou nouveau blanc"}	Côtes du Lot Rocamadour primeur ou nouveau blanc	\N
10957	2245	Côtes du Lot Rocamadour	\N	IGP -	{"fra": "Côtes du Lot Rocamadour primeur ou nouveau rosé"}	Côtes du Lot Rocamadour primeur ou nouveau rosé	\N
10959	2245	Côtes du Lot Rocamadour	\N	IGP -	{"fra": "Côtes du Lot Rocamadour primeur ou nouveau rouge"}	Côtes du Lot Rocamadour primeur ou nouveau rouge	\N
9554	80	Côtes du Marmandais	AOC -	AOP -	{"fra": "Côtes du Marmandais blanc"}	Côtes du Marmandais blanc	\N
9555	80	Côtes du Marmandais	AOC -	AOP -	{"fra": "Côtes du Marmandais rosé"}	Côtes du Marmandais rosé	\N
9556	80	Côtes du Marmandais	AOC -	AOP -	{"fra": "Côtes du Marmandais rouge"}	Côtes du Marmandais rouge	\N
15044	1286	Côtes du Rhône	AOC -	AOP -	{"fra": "Côtes du Rhône blanc"}	Côtes du Rhône blanc	\N
15045	1286	Côtes du Rhône	AOC -	AOP -	{"fra": "Côtes du Rhône primeur ou nouveau rosé"}	Côtes du Rhône primeur ou nouveau rosé	\N
15046	1286	Côtes du Rhône	AOC -	AOP -	{"fra": "Côtes du Rhône primeur ou nouveau rouge"}	Côtes du Rhône primeur ou nouveau rouge	\N
15047	1286	Côtes du Rhône	AOC -	AOP -	{"fra": "Côtes du Rhône rosé"}	Côtes du Rhône rosé	\N
15048	1286	Côtes du Rhône	AOC -	AOP -	{"fra": "Côtes du Rhône rouge"}	Côtes du Rhône rouge	\N
16118	1287	Côtes du Rhône Villages	AOC -	AOP -	{"fra": "Côtes du Rhône Villages blanc"}	Côtes du Rhône Villages blanc	\N
16119	1287	Côtes du Rhône Villages	AOC -	AOP -	{"fra": "Côtes du Rhône Villages rosé"}	Côtes du Rhône Villages rosé	\N
16120	1287	Côtes du Rhône Villages	AOC -	AOP -	{"fra": "Côtes du Rhône Villages rouge"}	Côtes du Rhône Villages rouge	\N
16155	1290	Côtes du Rhône Villages Chusclan	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Chusclan rosé"}	Côtes du Rhône Villages Chusclan rosé	\N
16156	1290	Côtes du Rhône Villages Chusclan	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Chusclan rouge"}	Côtes du Rhône Villages Chusclan rouge	\N
16157	2340	Côtes du Rhône villages Gadagne	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Gadagne rouge"}	Côtes du Rhône Villages Gadagne rouge	\N
16121	1291	Côtes du Rhône Villages Laudun	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Laudun blanc"}	Côtes du Rhône Villages Laudun blanc	\N
16122	1291	Côtes du Rhône Villages Laudun	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Laudun rosé"}	Côtes du Rhône Villages Laudun rosé	\N
16123	1291	Côtes du Rhône Villages Laudun	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Laudun rouge"}	Côtes du Rhône Villages Laudun rouge	\N
16158	1623	Côtes du Rhône Villages Massif d'Uchaux	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Massif d'Uchaux rouge"}	Côtes du Rhône Villages Massif d'Uchaux rouge	\N
16165	2466	Côtes du Rhône Villages Nyons	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Nyons rouge"}	Côtes du Rhône Villages Nyons rouge	\N
16159	1624	Côtes du Rhône Villages Plan de Dieu	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Plan de Dieu rouge"}	Côtes du Rhône Villages Plan de Dieu rouge	\N
16160	1625	Côtes du Rhône Villages Puyméras	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Puyméras rouge"}	Côtes du Rhône Villages Puyméras rouge	\N
16124	1293	Côtes du Rhône Villages Roaix	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Roaix blanc"}	Côtes du Rhône Villages Roaix blanc	\N
16125	1293	Côtes du Rhône Villages Roaix	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Roaix rosé"}	Côtes du Rhône Villages Roaix rosé	\N
16126	1293	Côtes du Rhône Villages Roaix	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Roaix rouge"}	Côtes du Rhône Villages Roaix rouge	\N
16127	1294	Côtes du Rhône Villages Rochegude	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Rochegude blanc"}	Côtes du Rhône Villages Rochegude blanc	\N
16128	1294	Côtes du Rhône Villages Rochegude	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Rochegude rosé"}	Côtes du Rhône Villages Rochegude rosé	\N
16129	1294	Côtes du Rhône Villages Rochegude	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Rochegude rouge"}	Côtes du Rhône Villages Rochegude rouge	\N
16130	1295	Côtes du Rhône Villages Rousset-les-Vignes	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Rousset-les-Vignes blanc"}	Côtes du Rhône Villages Rousset-les-Vignes blanc	\N
16131	1295	Côtes du Rhône Villages Rousset-les-Vignes	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Rousset-les-Vignes rosé"}	Côtes du Rhône Villages Rousset-les-Vignes rosé	\N
16132	1295	Côtes du Rhône Villages Rousset-les-Vignes	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Rousset-les-Vignes rouge"}	Côtes du Rhône Villages Rousset-les-Vignes rouge	\N
16133	1296	Côtes du Rhône Villages Sablet	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Sablet blanc"}	Côtes du Rhône Villages Sablet blanc	\N
16134	1296	Côtes du Rhône Villages Sablet	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Sablet rosé"}	Côtes du Rhône Villages Sablet rosé	\N
16135	1296	Côtes du Rhône Villages Sablet	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Sablet rouge"}	Côtes du Rhône Villages Sablet rouge	\N
16161	2443	Côtes du Rhône Villages Saint-Andéol	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Saint-Andéol rouge"}	Côtes du Rhône Villages Saint-Andéol rouge	\N
16136	1297	Côtes du Rhône Villages Saint-Gervais	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Saint-Gervais blanc"}	Côtes du Rhône Villages Saint-Gervais blanc	\N
16137	1297	Côtes du Rhône Villages Saint-Gervais	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Saint-Gervais rosé"}	Côtes du Rhône Villages Saint-Gervais rosé	\N
16138	1297	Côtes du Rhône Villages Saint-Gervais	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Saint-Gervais rouge"}	Côtes du Rhône Villages Saint-Gervais rouge	\N
16139	1298	Côtes du Rhône Villages Saint-Maurice	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Saint-Maurice blanc"}	Côtes du Rhône Villages Saint-Maurice blanc	\N
16140	1298	Côtes du Rhône Villages Saint-Maurice	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Saint-Maurice rosé"}	Côtes du Rhône Villages Saint-Maurice rosé	\N
16141	1298	Côtes du Rhône Villages Saint-Maurice	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Saint-Maurice rouge"}	Côtes du Rhône Villages Saint-Maurice rouge	\N
15066	178	Crémant de Loire	AOC -	AOP -	{"fra": "Crémant de Loire blanc"}	Crémant de Loire blanc	\N
16142	1299	Côtes du Rhône Villages Saint-Pantaléon-les-Vignes	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Saint-Pantaléon-les-Vignes blanc"}	Côtes du Rhône Villages Saint-Pantaléon-les-Vignes blanc	\N
16143	1299	Côtes du Rhône Villages Saint-Pantaléon-les-Vignes	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Saint-Pantaléon-les-Vignes rosé"}	Côtes du Rhône Villages Saint-Pantaléon-les-Vignes rosé	\N
16144	1299	Côtes du Rhône Villages Saint-Pantaléon-les-Vignes	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Saint-Pantaléon-les-Vignes rouge"}	Côtes du Rhône Villages Saint-Pantaléon-les-Vignes rouge	\N
16162	2423	Côtes du Rhône Villages Sainte-Cécile	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Sainte-Cécile rouge"}	Côtes du Rhône Villages Sainte-Cécile rouge	\N
16145	1300	Côtes du Rhône Villages Séguret	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Séguret blanc"}	Côtes du Rhône Villages Séguret blanc	\N
16146	1300	Côtes du Rhône Villages Séguret	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Séguret rosé"}	Côtes du Rhône Villages Séguret rosé	\N
16148	1300	Côtes du Rhône Villages Séguret	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Séguret rouge"}	Côtes du Rhône Villages Séguret rouge	\N
16147	1626	Côtes du Rhône Villages Signargues	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Signargues rouge"}	Côtes du Rhône Villages Signargues rouge	\N
16163	2424	Côtes du Rhône Villages Suze-la-Rousse	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Suze-la-Rousse rouge"}	Côtes du Rhône Villages Suze-la-Rousse rouge	\N
16164	2425	Côtes du Rhône Villages Vaison-la-Romaine	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Vaison-la-Romaine rouge"}	Côtes du Rhône Villages Vaison-la-Romaine rouge	\N
16149	1301	Côtes du Rhône Villages Valréas	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Valréas blanc"}	Côtes du Rhône Villages Valréas blanc	\N
16150	1301	Côtes du Rhône Villages Valréas	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Valréas rosé"}	Côtes du Rhône Villages Valréas rosé	\N
16151	1301	Côtes du Rhône Villages Valréas	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Valréas rouge"}	Côtes du Rhône Villages Valréas rouge	\N
16152	1303	Côtes du Rhône Villages Visan	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Visan blanc"}	Côtes du Rhône Villages Visan blanc	\N
16153	1303	Côtes du Rhône Villages Visan	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Visan rosé"}	Côtes du Rhône Villages Visan rosé	\N
16154	1303	Côtes du Rhône Villages Visan	AOC -	AOP -	{"fra": "Côtes du Rhône Villages Visan rouge"}	Côtes du Rhône Villages Visan rouge	\N
14712	1266	Côtes du Roussillon	AOC -	AOP -	{"fra": "Côtes du Roussillon blanc"}	Côtes du Roussillon blanc	\N
14713	1266	Côtes du Roussillon	AOC -	AOP -	{"fra": "Côtes du Roussillon nouveau ou primeur blanc"}	Côtes du Roussillon nouveau ou primeur blanc	\N
14714	1266	Côtes du Roussillon	AOC -	AOP -	{"fra": "Côtes du Roussillon nouveau ou primeur rosé"}	Côtes du Roussillon nouveau ou primeur rosé	\N
14715	1266	Côtes du Roussillon	AOC -	AOP -	{"fra": "Côtes du Roussillon nouveau ou primeur rouge"}	Côtes du Roussillon nouveau ou primeur rouge	\N
14716	1266	Côtes du Roussillon	AOC -	AOP -	{"fra": "Côtes du Roussillon rosé"}	Côtes du Roussillon rosé	\N
14717	1266	Côtes du Roussillon	AOC -	AOP -	{"fra": "Côtes du Roussillon rouge"}	Côtes du Roussillon rouge	\N
14718	1267	Côtes du Roussillon Villages	AOC -	AOP -	{"fra": "Côtes du Roussillon Villages"}	Côtes du Roussillon Villages	\N
14719	1268	Côtes du Roussillon Villages Caramany	AOC -	AOP -	{"fra": "Côtes du Roussillon Villages Caramany"}	Côtes du Roussillon Villages Caramany	\N
14720	1269	Côtes du Roussillon Villages Latour-de-France	AOC -	AOP -	{"fra": "Côtes du Roussillon Villages Latour-de-France"}	Côtes du Roussillon Villages Latour-de-France	\N
14723	2447	Côtes du Roussillon Villages Les Aspres	AOC -	AOP -	{"fra": "Côtes du Roussillon Villages Les Aspres"}	Côtes du Roussillon Villages Les Aspres	\N
14721	1270	Côtes du Roussillon Villages Lesquerde	AOC -	AOP -	{"fra": "Côtes du Roussillon Villages Lesquerde"}	Côtes du Roussillon Villages Lesquerde	\N
14722	1271	Côtes du Roussillon Villages Tautavel	AOC -	AOP -	{"fra": "Côtes du Roussillon Villages Tautavel"}	Côtes du Roussillon Villages Tautavel	\N
7854	2071	Côtes du Tarn	\N	IGP -	{"fra": "Côtes du Tarn blanc"}	Côtes du Tarn blanc	\N
8441	2071	Côtes du Tarn	\N	IGP -	{"fra": "Côtes du Tarn rosé"}	Côtes du Tarn rosé	\N
8442	2071	Côtes du Tarn	\N	IGP -	{"fra": "Côtes du Tarn rouge"}	Côtes du Tarn rouge	\N
10201	2071	Côtes du Tarn	\N	IGP -	{"fra": "Côtes du Tarn Blanc Surmûri"}	Côtes du Tarn Blanc Surmûri	\N
10718	2071	Côtes du Tarn	\N	IGP -	{"fra": "Côtes du Tarn primeur ou nouveau blanc"}	Côtes du Tarn primeur ou nouveau blanc	\N
10719	2071	Côtes du Tarn	\N	IGP -	{"fra": "Côtes du Tarn primeur ou nouveau rosé"}	Côtes du Tarn primeur ou nouveau rosé	\N
10720	2071	Côtes du Tarn	\N	IGP -	{"fra": "Côtes du Tarn primeur ou nouveau rouge"}	Côtes du Tarn primeur ou nouveau rouge	\N
10721	2326	Côtes du Tarn Cabanes	\N	IGP -	{"fra": "Côtes du Tarn Cabanes blanc"}	Côtes du Tarn Cabanes blanc	\N
10722	2326	Côtes du Tarn Cabanes	\N	IGP -	{"fra": "Côtes du Tarn Cabanes rosé"}	Côtes du Tarn Cabanes rosé	\N
10723	2326	Côtes du Tarn Cabanes	\N	IGP -	{"fra": "Côtes du Tarn Cabanes rouge"}	Côtes du Tarn Cabanes rouge	\N
10724	2326	Côtes du Tarn Cabanes	\N	IGP -	{"fra": "Côtes du Tarn Cabanes surmûri blanc"}	Côtes du Tarn Cabanes surmûri blanc	\N
10725	2326	Côtes du Tarn Cabanes	\N	IGP -	{"fra": "Côtes du Tarn Cabanes primeur ou nouveau blanc"}	Côtes du Tarn Cabanes primeur ou nouveau blanc	\N
10726	2326	Côtes du Tarn Cabanes	\N	IGP -	{"fra": "Côtes du Tarn Cabanes primeur ou nouveau rosé"}	Côtes du Tarn Cabanes primeur ou nouveau rosé	\N
10727	2326	Côtes du Tarn Cabanes	\N	IGP -	{"fra": "Côtes du Tarn Cabanes primeur ou nouveau rouge"}	Côtes du Tarn Cabanes primeur ou nouveau rouge	\N
10728	2327	Côtes du Tarn Cunac	\N	IGP -	{"fra": "Côtes du Tarn Cunac blanc"}	Côtes du Tarn Cunac blanc	\N
10729	2327	Côtes du Tarn Cunac	\N	IGP -	{"fra": "Côtes du Tarn Cunac rosé"}	Côtes du Tarn Cunac rosé	\N
10730	2327	Côtes du Tarn Cunac	\N	IGP -	{"fra": "Côtes du Tarn Cunac rouge"}	Côtes du Tarn Cunac rouge	\N
10731	2327	Côtes du Tarn Cunac	\N	IGP -	{"fra": "Côtes du Tarn Cunac surmûri blanc"}	Côtes du Tarn Cunac surmûri blanc	\N
10732	2327	Côtes du Tarn Cunac	\N	IGP -	{"fra": "Côtes du Tarn Cunac primeur ou nouveau blanc"}	Côtes du Tarn Cunac primeur ou nouveau blanc	\N
10733	2327	Côtes du Tarn Cunac	\N	IGP -	{"fra": "Côtes du Tarn Cunac primeur ou nouveau rosé"}	Côtes du Tarn Cunac primeur ou nouveau rosé	\N
10734	2327	Côtes du Tarn Cunac	\N	IGP -	{"fra": "Côtes du Tarn Cunac primeur ou nouveau rouge"}	Côtes du Tarn Cunac primeur ou nouveau rouge	\N
7993	1314	Côtes du Vivarais	AOC -	AOP -	{"fra": "Côtes du Vivarais blanc"}	Côtes du Vivarais blanc	\N
7994	1314	Côtes du Vivarais	AOC -	AOP -	{"fra": "Côtes du Vivarais rosé"}	Côtes du Vivarais rosé	\N
7995	1314	Côtes du Vivarais	AOC -	AOP -	{"fra": "Côtes du Vivarais rouge"}	Côtes du Vivarais rouge	\N
13353	2407	Coulée de Serrant	AOC -	AOP -	{"fra": "Coulée de Serrant"}	Coulée de Serrant	\N
13354	2407	Coulée de Serrant	AOC -	AOP -	{"fra": "Coulée de Serrant moelleux ou doux"}	Coulée de Serrant moelleux ou doux	\N
15325	177	Cour-Cheverny	AOC -	AOP -	{"fra": "Cour-Cheverny"}	Cour-Cheverny	\N
15326	177	Cour-Cheverny	AOC -	AOP -	{"fra": "Cour-Cheverny moelleux et doux"}	Cour-Cheverny moelleux et doux	\N
10059	2181	Crémant d'Alsace	AOC -	AOP -	{"fra": "Crémant d'Alsace blanc"}	Crémant d'Alsace blanc	\N
10060	2181	Crémant d'Alsace	AOC -	AOP -	{"fra": "Crémant d'Alsace blanc Auxerrois"}	Crémant d'Alsace blanc Auxerrois	\N
10061	2181	Crémant d'Alsace	AOC -	AOP -	{"fra": "Crémant d'Alsace blanc Chardonnay"}	Crémant d'Alsace blanc Chardonnay	\N
10062	2181	Crémant d'Alsace	AOC -	AOP -	{"fra": "Crémant d'Alsace blanc Pinot blanc"}	Crémant d'Alsace blanc Pinot blanc	\N
10063	2181	Crémant d'Alsace	AOC -	AOP -	{"fra": "Crémant d'Alsace blanc Pinot gris"}	Crémant d'Alsace blanc Pinot gris	\N
10064	2181	Crémant d'Alsace	AOC -	AOP -	{"fra": "Crémant d'Alsace blanc Pinot noir"}	Crémant d'Alsace blanc Pinot noir	\N
10065	2181	Crémant d'Alsace	AOC -	AOP -	{"fra": "Crémant d'Alsace blanc Riesling"}	Crémant d'Alsace blanc Riesling	\N
10066	2181	Crémant d'Alsace	AOC -	AOP -	{"fra": "Crémant d'Alsace rosé"}	Crémant d'Alsace rosé	\N
15429	1886	Crémant de Bordeaux	AOC -	AOP -	{"fra": "Crémant de Bordeaux blanc"}	Crémant de Bordeaux blanc	\N
15430	1886	Crémant de Bordeaux	AOC -	AOP -	{"fra": "Crémant de Bordeaux rosé"}	Crémant de Bordeaux rosé	\N
15022	2399	Crémant de Bourgogne	AOC -	AOP -	{"fra": "Crémant de Bourgogne blanc"}	Crémant de Bourgogne blanc	\N
15023	2399	Crémant de Bourgogne	AOC -	AOP -	{"fra": "Crémant de Bourgogne rosé"}	Crémant de Bourgogne rosé	\N
13435	1871	Crémant de Die	AOC -	AOP -	{"fra": "Crémant de Die"}	Crémant de Die	\N
14543	1870	Crémant de Limoux	AOC -	AOP -	{"fra": "Crémant de Limoux blanc"}	Crémant de Limoux blanc	\N
14544	1870	Crémant de Limoux	AOC -	AOP -	{"fra": "Crémant de Limoux rosé"}	Crémant de Limoux rosé	\N
15954	2010	Gard	\N	IGP -	{"fra": "Gard rosé"}	Gard rosé	\N
15067	178	Crémant de Loire	AOC -	AOP -	{"fra": "Crémant de Loire rosé"}	Crémant de Loire rosé	\N
15330	2398	Crémant du Jura	AOC -	AOP -	{"fra": "Crémant du Jura blanc"}	Crémant du Jura blanc	\N
15331	2398	Crémant du Jura	AOC -	AOP -	{"fra": "Crémant du Jura rosé"}	Crémant du Jura rosé	\N
13175	2339	Crème de Bresse	AOC -	AOP -	{"fra": "Crème de Bresse"}	Crème de Bresse	\N
3449	1530	Crème fraîche fluide d'Alsace	\N	IGP -	{"fra": "Crème fraîche fluide d'Alsace"}	Crème fraîche fluide d'Alsace	IG/51/94
7681	520	Criots-Bâtard-Montrachet	AOC -	AOP -	{"fra": "Criots-Bâtard-Montrachet"}	Criots-Bâtard-Montrachet	\N
8662	1306	Crozes-Hermitage	AOC -	AOP -	{"fra": "Crozes-Hermitage ou Crozes-Ermitage blanc"}	Crozes-Hermitage ou Crozes-Ermitage blanc	\N
8663	1306	Crozes-Hermitage	AOC -	AOP -	{"fra": "Crozes-Hermitage ou Crozes-Ermitage rouge"}	Crozes-Hermitage ou Crozes-Ermitage rouge	\N
13165	1498	Dinde de Bresse	AOC -	AOP -	{"fra": "Dinde de Bresse"}	Dinde de Bresse	\N
13062	1363	Domfront	AOC -	AOP -	{"fra": "Domfront"}	Domfront	\N
7835	2006	Drôme	\N	IGP -	{"fra": "Drôme blanc"}	Drôme blanc	\N
8781	2006	Drôme	\N	IGP -	{"fra": "Drôme rosé"}	Drôme rosé	\N
8782	2006	Drôme	\N	IGP -	{"fra": "Drôme rouge"}	Drôme rouge	\N
10736	2006	Drôme	\N	IGP -	{"fra": "Drôme mousseux de qualité blanc"}	Drôme mousseux de qualité blanc	\N
10737	2006	Drôme	\N	IGP -	{"fra": "Drôme mousseux de qualité rosé"}	Drôme mousseux de qualité rosé	\N
10738	2006	Drôme	\N	IGP -	{"fra": "Drôme mousseux de qualité rouge"}	Drôme mousseux de qualité rouge	\N
10739	2006	Drôme	\N	IGP -	{"fra": "Drôme primeur ou nouveau blanc"}	Drôme primeur ou nouveau blanc	\N
10740	2006	Drôme	\N	IGP -	{"fra": "Drôme primeur ou nouveau rosé"}	Drôme primeur ou nouveau rosé	\N
10741	2006	Drôme	\N	IGP -	{"fra": "Drôme primeur ou nouveau rouge"}	Drôme primeur ou nouveau rouge	\N
10742	2227	Drôme Comté de Grignan	\N	IGP -	{"fra": "Drôme Comté de Grignan blanc"}	Drôme Comté de Grignan blanc	\N
10743	2227	Drôme Comté de Grignan	\N	IGP -	{"fra": "Drôme Comté de Grignan rosé"}	Drôme Comté de Grignan rosé	\N
10744	2227	Drôme Comté de Grignan	\N	IGP -	{"fra": "Drôme Comté de Grignan rouge"}	Drôme Comté de Grignan rouge	\N
10745	2227	Drôme Comté de Grignan	\N	IGP -	{"fra": "Drôme Comté de Grignan mousseux de qualité blanc"}	Drôme Comté de Grignan mousseux de qualité blanc	\N
10746	2227	Drôme Comté de Grignan	\N	IGP -	{"fra": "Drôme Comté de Grignan mousseux de qualité rosé"}	Drôme Comté de Grignan mousseux de qualité rosé	\N
10747	2227	Drôme Comté de Grignan	\N	IGP -	{"fra": "Drôme Comté de Grignan mousseux de qualité rouge"}	Drôme Comté de Grignan mousseux de qualité rouge	\N
10748	2227	Drôme Comté de Grignan	\N	IGP -	{"fra": "Drôme Comté de Grignan primeur ou nouveau blanc"}	Drôme Comté de Grignan primeur ou nouveau blanc	\N
10749	2227	Drôme Comté de Grignan	\N	IGP -	{"fra": "Drôme Comté de Grignan primeur ou nouveau rosé"}	Drôme Comté de Grignan primeur ou nouveau rosé	\N
10750	2227	Drôme Comté de Grignan	\N	IGP -	{"fra": "Drôme Comté de Grignan primeur ou nouveau rouge"}	Drôme Comté de Grignan primeur ou nouveau rouge	\N
10751	2228	Drôme Coteaux de Montélimar	\N	IGP -	{"fra": "Drôme Coteaux de Montélimar blanc"}	Drôme Coteaux de Montélimar blanc	\N
10752	2228	Drôme Coteaux de Montélimar	\N	IGP -	{"fra": "Drôme Coteaux de Montélimar rosé"}	Drôme Coteaux de Montélimar rosé	\N
10753	2228	Drôme Coteaux de Montélimar	\N	IGP -	{"fra": "Drôme Coteaux de Montélimar rouge"}	Drôme Coteaux de Montélimar rouge	\N
10754	2228	Drôme Coteaux de Montélimar	\N	IGP -	{"fra": "Drôme Coteaux de Montélimar mousseux de qualité blanc"}	Drôme Coteaux de Montélimar mousseux de qualité blanc	\N
10755	2228	Drôme Coteaux de Montélimar	\N	IGP -	{"fra": "Drôme Coteaux de Montélimar mousseux de qualité rosé"}	Drôme Coteaux de Montélimar mousseux de qualité rosé	\N
10756	2228	Drôme Coteaux de Montélimar	\N	IGP -	{"fra": "Drôme Coteaux de Montélimar mousseux de qualité rouge"}	Drôme Coteaux de Montélimar mousseux de qualité rouge	\N
10757	2228	Drôme Coteaux de Montélimar	\N	IGP -	{"fra": "Drôme Coteaux de Montélimar primeur ou nouveau blanc"}	Drôme Coteaux de Montélimar primeur ou nouveau blanc	\N
10758	2228	Drôme Coteaux de Montélimar	\N	IGP -	{"fra": "Drôme Coteaux de Montélimar primeur ou nouveau rosé"}	Drôme Coteaux de Montélimar primeur ou nouveau rosé	\N
10759	2228	Drôme Coteaux de Montélimar	\N	IGP -	{"fra": "Drôme Coteaux de Montélimar primeur ou nouveau rouge"}	Drôme Coteaux de Montélimar primeur ou nouveau rouge	\N
4523	1836	Duché d'Uzès	AOC -	\N	{"fra": "Duché d'Uzès blanc"}	Duché d'Uzès blanc	\N
12935	1836	Duché d'Uzès	AOC -	\N	{"fra": "Duché d'Uzès rosé"}	Duché d'Uzès rosé	\N
12936	1836	Duché d'Uzès	AOC -	\N	{"fra": "Duché d'Uzès rouge"}	Duché d'Uzès rouge	\N
13086	1449	Eau-de-vie de cidre de Bretagne	AOC -	IG - 	{"fra": "Eau-de-vie de cidre de Bretagne"}	Eau-de-vie de cidre de Bretagne	\N
13122	2388	Eau-de-vie de cidre de Normandie	\N	IG - 	{"fra": "Eau-de-vie de cidre de Normandie "}	Eau-de-vie de cidre de Normandie 	\N
13427	1450	Eau-de-vie de cidre du Maine	AOC -	IG - 	{"fra": "Eau-de-vie de cidre du Maine"}	Eau-de-vie de cidre du Maine	\N
13112	1446	Eau-de-vie de vin de la Marne ou Fine champenoise	\N	IG - 	{"fra": "Eau-de-vie de vin de la Marne ou Fine champenoise"}	Eau-de-vie de vin de la Marne ou Fine champenoise	\N
13156	2391	Eau-de-vie de vin des côtes-du-rhône ou Fine des côtes-du-rhône	\N	IG - 	{"fra": "Eau-de-vie de vin des côtes-du-rhône ou Fine des côtes-du-rhône"}	Eau-de-vie de vin des côtes-du-rhône ou Fine des côtes-du-rhône	\N
13215	2395	Eau-de-vie de vin originaire du Bugey ou Fine du Bugey	\N	IG - 	{"fra": "Eau-de-vie de vin originaire du Bugey ou Fine du Bugey"}	Eau-de-vie de vin originaire du Bugey ou Fine du Bugey	\N
13120	2384	Eau-de-vie de vin originaire du Languedoc ou Fine du Languedoc ou	\N	IG - 	{"fra": "Eau-de-vie de vin originaire du Languedoc ou Fine du Languedoc ou Eau-de-vie de vin du Languedoc"}	Eau-de-vie de vin originaire du Languedoc ou Fine du Languedoc ou Eau-de-vie de vin du Languedoc	\N
13096	1451	Eaux-de-vie de poiré de Normandie	\N	IG - 	{"fra": "Eaux-de-vie de poiré de Normandie"}	Eaux-de-vie de poiré de Normandie	\N
15309	1686	Echalote d'Anjou	\N	IGP -	{"fra": "Echalote d'Anjou"}	Echalote d'Anjou	\N
7736	2187	Echezeaux	AOC -	AOP -	{"fra": "Echezeaux"}	Echezeaux	\N
4498	1531	Emmental de Savoie	\N	IGP -	{"fra": "Emmental de Savoie"}	Emmental de Savoie	IG/53/94
4465	2219	Emmental français Est-Central	\N	IGP -	{"fra": "Emmental français Est-Central"}	Emmental français Est-Central	IG/54/94
14232	2356	Endives de pleine terre	LR - 	\N	{"fra": "Endives de pleine terre"}	Endives de pleine terre	LA/04/14
7974	2141	Entraygues - Le Fel	AOC -	AOP -	{"fra": "Entraygues - Le Fel blanc"}	Entraygues - Le Fel blanc	\N
8369	2141	Entraygues - Le Fel	AOC -	AOP -	{"fra": "Entraygues - Le Fel rosé"}	Entraygues - Le Fel rosé	\N
8370	2141	Entraygues - Le Fel	AOC -	AOP -	{"fra": "Entraygues - Le Fel rouge"}	Entraygues - Le Fel rouge	\N
15426	81	Entre-deux-Mers	AOC -	AOP -	{"fra": "Entre-deux-Mers"}	Entre-deux-Mers	\N
8375	82	Entre-deux-Mers Haut-Benauge	AOC -	AOP -	{"fra": "Entre-deux-Mers Haut-Benauge"}	Entre-deux-Mers Haut-Benauge	\N
7148	1468	Epoisses	AOC -	AOP -	{"fra": "Epoisses"}	Epoisses	\N
7975	2142	Estaing	AOC -	AOP -	{"fra": "Estaing blanc"}	Estaing blanc	\N
8371	2142	Estaing	AOC -	AOP -	{"fra": "Estaing rosé"}	Estaing rosé	\N
8372	2142	Estaing	AOC -	AOP -	{"fra": "Estaing rouge"}	Estaing rouge	\N
4154	1949	Farine de blé noir de Bretagne - Gwinizh du Breizh	\N	IGP -	{"fra": "Farine de blé noir de Bretagne - Gwinizh du Breizh"}	Farine de blé noir de Bretagne - Gwinizh du Breizh	IG/02/00
7109	1618	Farine de châtaigne corse – Farina castagnina corsa	AOC -	AOP -	{"fra": "Farine de châtaigne corse - Farina castagnina corsa"}	Farine de châtaigne corse - Farina castagnina corsa	\N
14169	2357	Farine de meule	LR - 	\N	{"fra": " Farine de meule"}	 Farine de meule	LA/05/14
4156	2136	Farine de petit épeautre de haute Provence	\N	IGP -	{"fra": "Farine de petit épeautre de haute Provence"}	Farine de petit épeautre de haute Provence	IG/03/04
7763	1272	Faugères	AOC -	AOP -	{"fra": "Faugères blanc"}	Faugères blanc	\N
9241	1272	Faugères	AOC -	AOP -	{"fra": "Faugères rosé"}	Faugères rosé	\N
9242	1272	Faugères	AOC -	AOP -	{"fra": "Faugères rouge"}	Faugères rouge	\N
14891	2176	Fiefs Vendéens Brem	AOC -	AOP -	{"fra": "Fiefs Vendéens Brem blanc"}	Fiefs Vendéens Brem blanc	\N
14892	2176	Fiefs Vendéens Brem	AOC -	AOP -	{"fra": "Fiefs Vendéens Brem rosé"}	Fiefs Vendéens Brem rosé	\N
14893	2176	Fiefs Vendéens Brem	AOC -	AOP -	{"fra": "Fiefs Vendéens Brem rouge"}	Fiefs Vendéens Brem rouge	\N
14894	2177	Fiefs Vendéens Mareuil	AOC -	AOP -	{"fra": "Fiefs Vendéens Mareuil blanc"}	Fiefs Vendéens Mareuil blanc	\N
14895	2177	Fiefs Vendéens Mareuil	AOC -	AOP -	{"fra": "Fiefs Vendéens Mareuil rosé"}	Fiefs Vendéens Mareuil rosé	\N
14896	2177	Fiefs Vendéens Mareuil	AOC -	AOP -	{"fra": "Fiefs Vendéens Mareuil rouge"}	Fiefs Vendéens Mareuil rouge	\N
14897	2178	Fiefs Vendéens Pissotte	AOC -	AOP -	{"fra": "Fiefs Vendéens Pissotte blanc"}	Fiefs Vendéens Pissotte blanc	\N
14898	2178	Fiefs Vendéens Pissotte	AOC -	AOP -	{"fra": "Fiefs Vendéens Pissotte rosé"}	Fiefs Vendéens Pissotte rosé	\N
14899	2178	Fiefs Vendéens Pissotte	AOC -	AOP -	{"fra": "Fiefs Vendéens Pissotte rouge"}	Fiefs Vendéens Pissotte rouge	\N
14900	2179	Fiefs Vendéens Vix	AOC -	AOP -	{"fra": "Fiefs Vendéens Vix blanc"}	Fiefs Vendéens Vix blanc	\N
14901	2179	Fiefs Vendéens Vix	AOC -	AOP -	{"fra": "Fiefs Vendéens Vix rosé"}	Fiefs Vendéens Vix rosé	\N
14902	2179	Fiefs Vendéens Vix	AOC -	AOP -	{"fra": "Fiefs Vendéens Vix rouge"}	Fiefs Vendéens Vix rouge	\N
14903	2180	Fiefs Vendéens Chantonnay	AOC -	AOP -	{"fra": "Fiefs Vendéens Chantonnay blanc"}	Fiefs Vendéens Chantonnay blanc	\N
14904	2180	Fiefs Vendéens Chantonnay	AOC -	AOP -	{"fra": "Fiefs Vendéens Chantonnay rosé"}	Fiefs Vendéens Chantonnay rosé	\N
14905	2180	Fiefs Vendéens Chantonnay	AOC -	AOP -	{"fra": "Fiefs Vendéens Chantonnay rouge"}	Fiefs Vendéens Chantonnay rouge	\N
14888	1637	Figue de Solliès	AOC -	AOP -	{"fra": "Figue de Solliès"}	Figue de Solliès	\N
7926	1595	Fin Gras du Mézenc	AOC -	AOP -	{"fra": "Fin Gras du Mézenc"}	Fin Gras du Mézenc	\N
13107	1422	Fine Bordeaux	\N	IG - 	{"fra": "Fine Bordeaux"}	Fine Bordeaux	\N
13044	1947	Fine de Bourgogne	AOC -	IG - 	{"fra": "Fine de Bourgogne"}	Fine de Bourgogne	\N
13124	2387	Fine Faugères ou Eau-de-vie de Faugères	\N	IG - 	{"fra": "Fine Faugères ou Eau-de-vie de Faugères"}	Fine Faugères ou Eau-de-vie de Faugères	\N
8359	1273	Fitou	AOC -	AOP -	{"fra": "Fitou"}	Fitou	\N
7674	522	Fixin	AOC -	AOP -	{"fra": "Fixin blanc"}	Fixin blanc	\N
9581	522	Fixin	AOC -	AOP -	{"fra": "Fixin rouge"}	Fixin rouge	\N
9561	528	Fixin premier cru	AOC -	AOP -	{"fra": "Fixin premier cru blanc"}	Fixin premier cru blanc	\N
9580	528	Fixin premier cru	AOC -	AOP -	{"fra": "Fixin premier cru rouge"}	Fixin premier cru rouge	\N
9574	523	Fixin premier cru Arvelets	AOC -	AOP -	{"fra": "Fixin premier cru Arvelets blanc"}	Fixin premier cru Arvelets blanc	\N
9575	523	Fixin premier cru Arvelets	AOC -	AOP -	{"fra": "Fixin premier cru Arvelets rouge"}	Fixin premier cru Arvelets rouge	\N
9562	525	Fixin premier cru Clos de la Perrière	AOC -	AOP -	{"fra": "Fixin premier cru Clos de la Perrière blanc"}	Fixin premier cru Clos de la Perrière blanc	\N
9563	525	Fixin premier cru Clos de la Perrière	AOC -	AOP -	{"fra": "Fixin premier cru Clos de la Perrière rouge"}	Fixin premier cru Clos de la Perrière rouge	\N
9570	526	Fixin premier cru Clos du Chapitre	AOC -	AOP -	{"fra": "Fixin premier cru Clos du Chapitre blanc"}	Fixin premier cru Clos du Chapitre blanc	\N
9571	526	Fixin premier cru Clos du Chapitre	AOC -	AOP -	{"fra": "Fixin premier cru Clos du Chapitre rouge"}	Fixin premier cru Clos du Chapitre rouge	\N
9564	524	Fixin premier cru Clos Napoléon	AOC -	AOP -	{"fra": "Fixin premier cru Clos Napoléon blanc"}	Fixin premier cru Clos Napoléon blanc	\N
9565	524	Fixin premier cru Clos Napoléon	AOC -	AOP -	{"fra": "Fixin premier cru Clos Napoléon rouge"}	Fixin premier cru Clos Napoléon rouge	\N
9576	527	Fixin premier cru Hervelets	AOC -	AOP -	{"fra": "Fixin premier cru Hervelets blanc"}	Fixin premier cru Hervelets blanc	\N
9577	527	Fixin premier cru Hervelets	AOC -	AOP -	{"fra": "Fixin premier cru Hervelets rouge"}	Fixin premier cru Hervelets rouge	\N
10278	2220	Fixin premier cru Les Meix Bas	AOC -	AOP -	{"fra": "Fixin premier cru Les Meix Bas blanc"}	Fixin premier cru Les Meix Bas blanc	\N
10279	2220	Fixin premier cru Les Meix Bas	AOC -	AOP -	{"fra": "Fixin premier cru Les Meix Bas rouge"}	Fixin premier cru Les Meix Bas rouge	\N
10245	529	Fleurie	AOC -	AOP -	{"fra": "Fleurie ou Fleurie cru du Beaujolais"}	Fleurie ou Fleurie cru du Beaujolais	\N
9020	1347	Floc de Gascogne	AOC -	AOP -	{"fra": "Floc de Gascogne blanc"}	Floc de Gascogne blanc	\N
9021	1347	Floc de Gascogne	AOC -	AOP -	{"fra": "Floc de Gascogne rosé"}	Floc de Gascogne rosé	\N
12765	1505	Foin de Crau	AOC -	AOP -	{"fra": "Foin de Crau"}	Foin de Crau	\N
13163	1469	Fourme d'Ambert	AOC -	AOP -	{"fra": "Fourme d'Ambert"}	Fourme d'Ambert	\N
13161	1494	Fourme de Montbrison	AOC -	AOP -	{"fra": "Fourme de Montbrison"}	Fourme de Montbrison	\N
3463	1592	Fraise du Périgord	\N	IGP -	{"fra": "Fraise du Périgord"}	Fraise du Périgord	IG/16/97
4525	1837	Fraises de Nîmes	\N	IGP -	{"fra": "Fraises de Nîmes"}	Fraises de Nîmes	\N
13088	2362	Framboise d’Alsace	\N	IG - 	{"fra": "Framboise d’Alsace"}	Framboise d’Alsace	\N
7868	2218	Franche-Comté	\N	IGP -	{"fra": "Franche-Comté blanc"}	Franche-Comté blanc	\N
8849	2218	Franche-Comté	\N	IGP -	{"fra": "Franche-Comté rosé"}	Franche-Comté rosé	\N
8850	2218	Franche-Comté	\N	IGP -	{"fra": "Franche-Comté rouge"}	Franche-Comté rouge	\N
10764	2218	Franche-Comté	\N	IGP -	{"fra": "Franche-Comté mousseux de qualité blanc"}	Franche-Comté mousseux de qualité blanc	\N
10765	2218	Franche-Comté	\N	IGP -	{"fra": "Franche-Comté mousseux de qualité rosé"}	Franche-Comté mousseux de qualité rosé	\N
10766	2218	Franche-Comté	\N	IGP -	{"fra": "Franche-Comté mousseux de qualité rouge"}	Franche-Comté mousseux de qualité rouge	\N
10767	2218	Franche-Comté	\N	IGP -	{"fra": "Franche-Comté primeur ou nouveau blanc"}	Franche-Comté primeur ou nouveau blanc	\N
10768	2218	Franche-Comté	\N	IGP -	{"fra": "Franche-Comté primeur ou nouveau rosé"}	Franche-Comté primeur ou nouveau rosé	\N
10769	2218	Franche-Comté	\N	IGP -	{"fra": "Franche-Comté primeur ou nouveau rouge"}	Franche-Comté primeur ou nouveau rouge	\N
10770	2229	Franche-Comté Buffard	\N	IGP -	{"fra": "Franche-Comté Buffard blanc"}	Franche-Comté Buffard blanc	\N
10771	2229	Franche-Comté Buffard	\N	IGP -	{"fra": "Franche-Comté Buffard rosé"}	Franche-Comté Buffard rosé	\N
10772	2229	Franche-Comté Buffard	\N	IGP -	{"fra": "Franche-Comté Buffard rouge"}	Franche-Comté Buffard rouge	\N
10773	2229	Franche-Comté Buffard	\N	IGP -	{"fra": "Franche-Comté Buffard mousseux de qualité blanc"}	Franche-Comté Buffard mousseux de qualité blanc	\N
10774	2229	Franche-Comté Buffard	\N	IGP -	{"fra": "Franche-Comté Buffard mousseux de qualité rosé"}	Franche-Comté Buffard mousseux de qualité rosé	\N
10775	2229	Franche-Comté Buffard	\N	IGP -	{"fra": "Franche-Comté Buffard mousseux de qualité rouge"}	Franche-Comté Buffard mousseux de qualité rouge	\N
10777	2229	Franche-Comté Buffard	\N	IGP -	{"fra": "Franche-Comté Buffard primeur ou nouveau blanc"}	Franche-Comté Buffard primeur ou nouveau blanc	\N
10778	2229	Franche-Comté Buffard	\N	IGP -	{"fra": "Franche-Comté Buffard primeur ou nouveau rosé"}	Franche-Comté Buffard primeur ou nouveau rosé	\N
10779	2229	Franche-Comté Buffard	\N	IGP -	{"fra": "Franche-Comté Buffard primeur ou nouveau rouge"}	Franche-Comté Buffard primeur ou nouveau rouge	\N
10780	2230	Franche-Comté Coteaux de Champlitte	\N	IGP -	{"fra": "Franche-Comté Coteaux de Champlitte blanc"}	Franche-Comté Coteaux de Champlitte blanc	\N
10781	2230	Franche-Comté Coteaux de Champlitte	\N	IGP -	{"fra": "Franche-Comté Coteaux de Champlitte rosé"}	Franche-Comté Coteaux de Champlitte rosé	\N
10782	2230	Franche-Comté Coteaux de Champlitte	\N	IGP -	{"fra": "Franche-Comté Coteaux de Champlitte rouge"}	Franche-Comté Coteaux de Champlitte rouge	\N
10783	2230	Franche-Comté Coteaux de Champlitte	\N	IGP -	{"fra": "Franche-Comté Coteaux de Champlitte mousseux de qualité blanc"}	Franche-Comté Coteaux de Champlitte mousseux de qualité blanc	\N
10784	2230	Franche-Comté Coteaux de Champlitte	\N	IGP -	{"fra": "Franche-Comté Coteaux de Champlitte mousseux de qualité rosé"}	Franche-Comté Coteaux de Champlitte mousseux de qualité rosé	\N
10785	2230	Franche-Comté Coteaux de Champlitte	\N	IGP -	{"fra": "Franche-Comté Coteaux de Champlitte mousseux de qualité rouge"}	Franche-Comté Coteaux de Champlitte mousseux de qualité rouge	\N
10786	2230	Franche-Comté Coteaux de Champlitte	\N	IGP -	{"fra": "Franche-Comté Coteaux de Champlitte primeur ou nouveau blanc"}	Franche-Comté Coteaux de Champlitte primeur ou nouveau blanc	\N
10787	2230	Franche-Comté Coteaux de Champlitte	\N	IGP -	{"fra": "Franche-Comté Coteaux de Champlitte primeur ou nouveau rosé"}	Franche-Comté Coteaux de Champlitte primeur ou nouveau rosé	\N
10788	2230	Franche-Comté Coteaux de Champlitte	\N	IGP -	{"fra": "Franche-Comté Coteaux de Champlitte primeur ou nouveau rouge"}	Franche-Comté Coteaux de Champlitte primeur ou nouveau rouge	\N
10789	2231	Franche-Comté Doubs	\N	IGP -	{"fra": "Franche-Comté Doubs blanc"}	Franche-Comté Doubs blanc	\N
10791	2231	Franche-Comté Doubs	\N	IGP -	{"fra": "Franche-Comté Doubs rosé"}	Franche-Comté Doubs rosé	\N
10792	2231	Franche-Comté Doubs	\N	IGP -	{"fra": "Franche-Comté Doubs rouge"}	Franche-Comté Doubs rouge	\N
10793	2231	Franche-Comté Doubs	\N	IGP -	{"fra": "Franche-Comté Doubs mousseux de qualité blanc"}	Franche-Comté Doubs mousseux de qualité blanc	\N
10794	2231	Franche-Comté Doubs	\N	IGP -	{"fra": "Franche-Comté Doubs mousseux de qualité rosé"}	Franche-Comté Doubs mousseux de qualité rosé	\N
10795	2231	Franche-Comté Doubs	\N	IGP -	{"fra": "Franche-Comté Doubs mousseux de qualité rouge"}	Franche-Comté Doubs mousseux de qualité rouge	\N
10796	2231	Franche-Comté Doubs	\N	IGP -	{"fra": "Franche-Comté Doubs primeur ou nouveau blanc"}	Franche-Comté Doubs primeur ou nouveau blanc	\N
10797	2231	Franche-Comté Doubs	\N	IGP -	{"fra": "Franche-Comté Doubs primeur ou nouveau rosé"}	Franche-Comté Doubs primeur ou nouveau rosé	\N
10798	2231	Franche-Comté Doubs	\N	IGP -	{"fra": "Franche-Comté Doubs primeur ou nouveau rouge"}	Franche-Comté Doubs primeur ou nouveau rouge	\N
10790	2232	Franche-Comté Gy	\N	IGP -	{"fra": "Franche-Comté Gy blanc"}	Franche-Comté Gy blanc	\N
10799	2232	Franche-Comté Gy	\N	IGP -	{"fra": "Franche-Comté Gy rosé"}	Franche-Comté Gy rosé	\N
10800	2232	Franche-Comté Gy	\N	IGP -	{"fra": "Franche-Comté Gy rouge"}	Franche-Comté Gy rouge	\N
10801	2232	Franche-Comté Gy	\N	IGP -	{"fra": "Franche-Comté Gy  mousseux de qualité blanc"}	Franche-Comté Gy  mousseux de qualité blanc	\N
10802	2232	Franche-Comté Gy	\N	IGP -	{"fra": "Franche-Comté Gy mousseux de qualité rosé"}	Franche-Comté Gy mousseux de qualité rosé	\N
10803	2232	Franche-Comté Gy	\N	IGP -	{"fra": "Franche-Comté Gy mousseux de qualité rouge"}	Franche-Comté Gy mousseux de qualité rouge	\N
10804	2232	Franche-Comté Gy	\N	IGP -	{"fra": "Franche-Comté Gy primeur ou nouveau blanc"}	Franche-Comté Gy primeur ou nouveau blanc	\N
10805	2232	Franche-Comté Gy	\N	IGP -	{"fra": "Franche-Comté Gy primeur ou nouveau rosé"}	Franche-Comté Gy primeur ou nouveau rosé	\N
10806	2232	Franche-Comté Gy	\N	IGP -	{"fra": "Franche-Comté Gy primeur ou nouveau rouge"}	Franche-Comté Gy primeur ou nouveau rouge	\N
10807	2233	Franche-Comté Haute-Saône	\N	IGP -	{"fra": "Franche-Comté Haute-Saône blanc"}	Franche-Comté Haute-Saône blanc	\N
10808	2233	Franche-Comté Haute-Saône	\N	IGP -	{"fra": "Franche-Comté Haute-Saône rosé"}	Franche-Comté Haute-Saône rosé	\N
10809	2233	Franche-Comté Haute-Saône	\N	IGP -	{"fra": "Franche-Comté Haute-Saône rouge"}	Franche-Comté Haute-Saône rouge	\N
10813	2233	Franche-Comté Haute-Saône	\N	IGP -	{"fra": "Franche-Comté Haute-Saône mousseux de qualité blanc"}	Franche-Comté Haute-Saône mousseux de qualité blanc	\N
10814	2233	Franche-Comté Haute-Saône	\N	IGP -	{"fra": "Franche-Comté Haute-Saône mousseux de qualité rosé"}	Franche-Comté Haute-Saône mousseux de qualité rosé	\N
10815	2233	Franche-Comté Haute-Saône	\N	IGP -	{"fra": "Franche-Comté Haute-Saône mousseux de qualité rouge"}	Franche-Comté Haute-Saône mousseux de qualité rouge	\N
10816	2233	Franche-Comté Haute-Saône	\N	IGP -	{"fra": "Franche-Comté Haute-Saône primeur ou nouveau blanc"}	Franche-Comté Haute-Saône primeur ou nouveau blanc	\N
10817	2233	Franche-Comté Haute-Saône	\N	IGP -	{"fra": "Franche-Comté Haute-Saône primeur ou nouveau rosé"}	Franche-Comté Haute-Saône primeur ou nouveau rosé	\N
10818	2233	Franche-Comté Haute-Saône	\N	IGP -	{"fra": "Franche-Comté Haute-Saône primeur ou nouveau rouge"}	Franche-Comté Haute-Saône primeur ou nouveau rouge	\N
10810	2234	Franche-Comté Hugier	\N	IGP -	{"fra": "Franche-Comté Hugier blanc"}	Franche-Comté Hugier blanc	\N
10811	2234	Franche-Comté Hugier	\N	IGP -	{"fra": "Franche-Comté Hugier rosé"}	Franche-Comté Hugier rosé	\N
10812	2234	Franche-Comté Hugier	\N	IGP -	{"fra": "Franche-Comté Hugier rouge"}	Franche-Comté Hugier rouge	\N
10819	2234	Franche-Comté Hugier	\N	IGP -	{"fra": "Franche-Comté Hugier mousseux de qualité blanc"}	Franche-Comté Hugier mousseux de qualité blanc	\N
10820	2234	Franche-Comté Hugier	\N	IGP -	{"fra": "Franche-Comté Hugier  mousseux de qualité rosé"}	Franche-Comté Hugier  mousseux de qualité rosé	\N
10821	2234	Franche-Comté Hugier	\N	IGP -	{"fra": "Franche-Comté Hugier mousseux de qualité rouge"}	Franche-Comté Hugier mousseux de qualité rouge	\N
10822	2234	Franche-Comté Hugier	\N	IGP -	{"fra": "Franche-Comté Hugier primeur ou nouveau blanc"}	Franche-Comté Hugier primeur ou nouveau blanc	\N
10823	2234	Franche-Comté Hugier	\N	IGP -	{"fra": "Franche-Comté Hugier primeur ou nouveau rosé"}	Franche-Comté Hugier primeur ou nouveau rosé	\N
10824	2234	Franche-Comté Hugier	\N	IGP -	{"fra": "Franche-Comté Hugier primeur ou nouveau rouge"}	Franche-Comté Hugier primeur ou nouveau rouge	\N
10825	2235	Franche-Comté Motey-Besuche	\N	IGP -	{"fra": "Franche-Comté Motey-Besuche blanc"}	Franche-Comté Motey-Besuche blanc	\N
10829	2235	Franche-Comté Motey-Besuche	\N	IGP -	{"fra": "Franche-Comté Motey-Besuche rosé"}	Franche-Comté Motey-Besuche rosé	\N
10830	2235	Franche-Comté Motey-Besuche	\N	IGP -	{"fra": "Franche-Comté Motey-Besuche rouge"}	Franche-Comté Motey-Besuche rouge	\N
10831	2235	Franche-Comté Motey-Besuche	\N	IGP -	{"fra": "Franche-Comté Motey-Besuche mousseux de qualité blanc"}	Franche-Comté Motey-Besuche mousseux de qualité blanc	\N
10832	2235	Franche-Comté Motey-Besuche	\N	IGP -	{"fra": "Franche-Comté Motey-Besuche mousseux de qualité rosé"}	Franche-Comté Motey-Besuche mousseux de qualité rosé	\N
10833	2235	Franche-Comté Motey-Besuche	\N	IGP -	{"fra": "Franche-Comté Motey-Besuche mousseux de qualité rouge"}	Franche-Comté Motey-Besuche mousseux de qualité rouge	\N
10834	2235	Franche-Comté Motey-Besuche	\N	IGP -	{"fra": "Franche-Comté Motey-Besuche primeur ou nouveau blanc"}	Franche-Comté Motey-Besuche primeur ou nouveau blanc	\N
10835	2235	Franche-Comté Motey-Besuche	\N	IGP -	{"fra": "Franche-Comté Motey-Besuche primeur ou nouveau rosé"}	Franche-Comté Motey-Besuche primeur ou nouveau rosé	\N
10836	2235	Franche-Comté Motey-Besuche	\N	IGP -	{"fra": "Franche-Comté Motey-Besuche primeur ou nouveau rouge"}	Franche-Comté Motey-Besuche primeur ou nouveau rouge	\N
10826	2236	Franche-Comté Offlanges	\N	IGP -	{"fra": "Franche-Comté Offlanges blanc"}	Franche-Comté Offlanges blanc	\N
10837	2236	Franche-Comté Offlanges	\N	IGP -	{"fra": "Franche-Comté Offlanges rosé"}	Franche-Comté Offlanges rosé	\N
10838	2236	Franche-Comté Offlanges	\N	IGP -	{"fra": "Franche-Comté Offlanges rouge"}	Franche-Comté Offlanges rouge	\N
10840	2236	Franche-Comté Offlanges	\N	IGP -	{"fra": "Franche-Comté Offlanges mousseux de qualité blanc"}	Franche-Comté Offlanges mousseux de qualité blanc	\N
10841	2236	Franche-Comté Offlanges	\N	IGP -	{"fra": "Franche-Comté Offlanges mousseux de qualité rosé"}	Franche-Comté Offlanges mousseux de qualité rosé	\N
10842	2236	Franche-Comté Offlanges	\N	IGP -	{"fra": "Franche-Comté Offlanges mousseux de qualité rouge"}	Franche-Comté Offlanges mousseux de qualité rouge	\N
10843	2236	Franche-Comté Offlanges	\N	IGP -	{"fra": "Franche-Comté Offlanges primeur ou nouveau blanc"}	Franche-Comté Offlanges primeur ou nouveau blanc	\N
10844	2236	Franche-Comté Offlanges	\N	IGP -	{"fra": "Franche-Comté Offlanges primeur ou nouveau rosé"}	Franche-Comté Offlanges primeur ou nouveau rosé	\N
10845	2236	Franche-Comté Offlanges	\N	IGP -	{"fra": "Franche-Comté Offlanges primeur ou nouveau rouge"}	Franche-Comté Offlanges primeur ou nouveau rouge	\N
10827	2237	Franche-Comté Vuillafans blanc	\N	IGP -	{"fra": "Franche-Comté Vuillafans blanc"}	Franche-Comté Vuillafans blanc	\N
10846	2237	Franche-Comté Vuillafans blanc	\N	IGP -	{"fra": "Franche-Comté Vuillafans rosé"}	Franche-Comté Vuillafans rosé	\N
10847	2237	Franche-Comté Vuillafans blanc	\N	IGP -	{"fra": "Franche-Comté Vuillafans rouge"}	Franche-Comté Vuillafans rouge	\N
10848	2237	Franche-Comté Vuillafans blanc	\N	IGP -	{"fra": "Franche-Comté Vuillafans mousseux de qualité blanc"}	Franche-Comté Vuillafans mousseux de qualité blanc	\N
10849	2237	Franche-Comté Vuillafans blanc	\N	IGP -	{"fra": "Franche-Comté Vuillafans mousseux de qualité rosé"}	Franche-Comté Vuillafans mousseux de qualité rosé	\N
10850	2237	Franche-Comté Vuillafans blanc	\N	IGP -	{"fra": "Franche-Comté Vuillafans mousseux de qualité rouge"}	Franche-Comté Vuillafans mousseux de qualité rouge	\N
10851	2237	Franche-Comté Vuillafans blanc	\N	IGP -	{"fra": "Franche-Comté Vuillafans primeur ou nouveau blanc"}	Franche-Comté Vuillafans primeur ou nouveau blanc	\N
10852	2237	Franche-Comté Vuillafans blanc	\N	IGP -	{"fra": "Franche-Comté Vuillafans primeur ou nouveau rosé"}	Franche-Comté Vuillafans primeur ou nouveau rosé	\N
10853	2237	Franche-Comté Vuillafans blanc	\N	IGP -	{"fra": "Franche-Comté Vuillafans primeur ou nouveau rouge"}	Franche-Comté Vuillafans primeur ou nouveau rouge	\N
9837	83	Fronsac	AOC -	AOP -	{"fra": "Fronsac"}	Fronsac	\N
9195	77	Fronton	AOC -	AOP -	{"fra": "Fronton rosé"}	Fronton rosé	\N
9196	77	Fronton	AOC -	AOP -	{"fra": "Fronton rouge"}	Fronton rouge	\N
4591	1846	Gâche vendéenne	\N	IGP -	{"fra": "Gâche vendéenne"}	Gâche vendéenne	\N
14220	84	Gaillac blanc	AOC -	AOP -	{"fra": "Gaillac méthode ancestrale doux"}	Gaillac méthode ancestrale doux	\N
16003	84	Gaillac blanc	AOC -	AOP -	{"fra": "Gaillac blanc"}	Gaillac blanc	\N
16006	84	Gaillac blanc	AOC -	AOP -	{"fra": "Gaillac mousseux"}	Gaillac mousseux	\N
16007	84	Gaillac blanc	AOC -	AOP -	{"fra": "Gaillac blanc primeur"}	Gaillac blanc primeur	\N
16009	84	Gaillac blanc	AOC -	AOP -	{"fra": "Gaillac méthode ancestrale"}	Gaillac méthode ancestrale	\N
16010	84	Gaillac blanc	AOC -	AOP -	{"fra": "Gaillac doux"}	Gaillac doux	\N
16011	84	Gaillac blanc	AOC -	AOP -	{"fra": "Gaillac vendanges tardives"}	Gaillac vendanges tardives	\N
13407	85	Gaillac premières côtes	AOC -	AOP -	{"fra": "Gaillac premières côtes"}	Gaillac premières côtes	\N
16004	1627	Gaillac rouge et rosé	AOC -	AOP -	{"fra": "Gaillac rouge"}	Gaillac rouge	\N
16005	1627	Gaillac rouge et rosé	AOC -	AOP -	{"fra": "Gaillac rosé"}	Gaillac rosé	\N
16008	1627	Gaillac rouge et rosé	AOC -	AOP -	{"fra": "Gaillac rouge primeur"}	Gaillac rouge primeur	\N
13461	2010	Gard	\N	IGP -	{"fra": "Gard blanc"}	Gard blanc	\N
15951	2010	Gard	\N	IGP -	{"fra": "Gard primeur ou nouveau blanc"}	Gard primeur ou nouveau blanc	\N
15952	2010	Gard	\N	IGP -	{"fra": "Gard primeur ou nouveau rosé"}	Gard primeur ou nouveau rosé	\N
15953	2010	Gard	\N	IGP -	{"fra": "Gard primeur ou nouveau rouge"}	Gard primeur ou nouveau rouge	\N
13187	2392	Génépi des Alpes	\N	IG - 	{"fra": "Génépi des Alpes"}	Génépi des Alpes	\N
13203	2394	Genièvre de grains ou Graanjenever ou Graangenever	\N	IG - 	{"fra": "Genièvre ou Jenever ou Genever"}	Genièvre ou Jenever ou Genever	\N
10442	2224	Genièvre Flandre-Artois	\N	IG - 	{"fra": "Genièvre Flandre-Artois"}	Genièvre Flandre-Artois	\N
4147	1667	Génisse Fleur d'Aubrac	\N	IGP -	{"fra": "Génisse Fleur d'Aubrac"}	Génisse Fleur d'Aubrac	\N
7855	2020	Gers	\N	IGP -	{"fra": "Gers blanc"}	Gers blanc	\N
8833	2020	Gers	\N	IGP -	{"fra": "Gers rosé"}	Gers rosé	\N
8834	2020	Gers	\N	IGP -	{"fra": "Gers rouge"}	Gers rouge	\N
10857	2020	Gers	\N	IGP -	{"fra": "Gers primeur ou nouveau blanc"}	Gers primeur ou nouveau blanc	\N
10858	2020	Gers	\N	IGP -	{"fra": "Gers primeur ou nouveau rosé"}	Gers primeur ou nouveau rosé	\N
10859	2020	Gers	\N	IGP -	{"fra": "Gers primeur ou nouveau rouge"}	Gers primeur ou nouveau rouge	\N
10860	2020	Gers	\N	IGP -	{"fra": "Gers mousseux de qualité blanc"}	Gers mousseux de qualité blanc	\N
10861	2020	Gers	\N	IGP -	{"fra": "Gers mousseux de qualité rosé"}	Gers mousseux de qualité rosé	\N
10862	2020	Gers	\N	IGP -	{"fra": "Gers mousseux de qualité rouge"}	Gers mousseux de qualité rouge	\N
10863	2020	Gers	\N	IGP -	{"fra": "Gers surmûri blanc"}	Gers surmûri blanc	\N
10864	2020	Gers	\N	IGP -	{"fra": "Gers surmûri rosé"}	Gers surmûri rosé	\N
10865	2020	Gers	\N	IGP -	{"fra": "Gers surmûri rouge"}	Gers surmûri rouge	\N
7700	543	Gevrey-Chambertin	AOC -	AOP -	{"fra": "Gevrey-Chambertin"}	Gevrey-Chambertin	\N
8313	570	Gevrey-Chambertin premier cru	AOC -	AOP -	{"fra": "Gevrey-Chambertin premier cru"}	Gevrey-Chambertin premier cru	\N
8314	544	Gevrey-Chambertin premier cru Au Closeau	AOC -	AOP -	{"fra": "Gevrey-Chambertin premier cru Au Closeau"}	Gevrey-Chambertin premier cru Au Closeau	\N
8315	545	Gevrey-Chambertin premier cru Aux Combottes	AOC -	AOP -	{"fra": "Gevrey-Chambertin premier cru Aux Combottes"}	Gevrey-Chambertin premier cru Aux Combottes	\N
8316	546	Gevrey-Chambertin premier cru Bel Air	AOC -	AOP -	{"fra": "Gevrey-Chambertin premier cru Bel Air"}	Gevrey-Chambertin premier cru Bel Air	\N
8317	547	Gevrey-Chambertin premier cru Champeaux	AOC -	AOP -	{"fra": "Gevrey-Chambertin premier cru Champeaux"}	Gevrey-Chambertin premier cru Champeaux	\N
8318	548	Gevrey-Chambertin premier cru Champonnet	AOC -	AOP -	{"fra": "Gevrey-Chambertin premier cru Champonnet"}	Gevrey-Chambertin premier cru Champonnet	\N
8319	549	Gevrey-Chambertin premier cru Cherbaudes	AOC -	AOP -	{"fra": "Gevrey-Chambertin premier cru Cherbaudes"}	Gevrey-Chambertin premier cru Cherbaudes	\N
8320	552	Gevrey-Chambertin premier cru Clos des Varoilles	AOC -	AOP -	{"fra": "Gevrey-Chambertin premier cru Clos des Varoilles"}	Gevrey-Chambertin premier cru Clos des Varoilles	\N
8321	553	Gevrey-Chambertin premier cru Clos du Chapitre	AOC -	AOP -	{"fra": "Gevrey-Chambertin premier cru Clos du Chapitre"}	Gevrey-Chambertin premier cru Clos du Chapitre	\N
8322	550	Gevrey-Chambertin premier cru Clos Prieur	AOC -	AOP -	{"fra": "Gevrey-Chambertin premier cru Clos Prieur"}	Gevrey-Chambertin premier cru Clos Prieur	\N
8323	551	Gevrey-Chambertin premier cru Clos Saint-Jacques	AOC -	AOP -	{"fra": "Gevrey-Chambertin premier cru Clos Saint-Jacques"}	Gevrey-Chambertin premier cru Clos Saint-Jacques	\N
8324	554	Gevrey-Chambertin premier cru Combe au Moine	AOC -	AOP -	{"fra": "Gevrey-Chambertin premier cru Combe au Moine"}	Gevrey-Chambertin premier cru Combe au Moine	\N
8325	555	Gevrey-Chambertin premier cru Craipillot	AOC -	AOP -	{"fra": "Gevrey-Chambertin premier cru Craipillot"}	Gevrey-Chambertin premier cru Craipillot	\N
8326	556	Gevrey-Chambertin premier cru En Ergot	AOC -	AOP -	{"fra": "Gevrey-Chambertin premier cru En Ergot"}	Gevrey-Chambertin premier cru En Ergot	\N
8327	557	Gevrey-Chambertin premier cru Estournelles-Saint-Jacques	AOC -	AOP -	{"fra": "Gevrey-Chambertin premier cru Estournelles-Saint-Jacques"}	Gevrey-Chambertin premier cru Estournelles-Saint-Jacques	\N
8328	558	Gevrey-Chambertin premier cru Fonteny	AOC -	AOP -	{"fra": "Gevrey-Chambertin premier cru Fonteny"}	Gevrey-Chambertin premier cru Fonteny	\N
8329	559	Gevrey-Chambertin premier cru Issarts	AOC -	AOP -	{"fra": "Gevrey-Chambertin premier cru Issarts"}	Gevrey-Chambertin premier cru Issarts	\N
8330	560	Gevrey-Chambertin premier cru La Bossière	AOC -	AOP -	{"fra": "Gevrey-Chambertin premier cru La Bossière"}	Gevrey-Chambertin premier cru La Bossière	\N
8331	561	Gevrey-Chambertin premier cru La Perrière	AOC -	AOP -	{"fra": "Gevrey-Chambertin premier cru La Perrière"}	Gevrey-Chambertin premier cru La Perrière	\N
8332	562	Gevrey-Chambertin premier cru La Romanée	AOC -	AOP -	{"fra": "Gevrey-Chambertin premier cru La Romanée"}	Gevrey-Chambertin premier cru La Romanée	\N
8333	563	Gevrey-Chambertin premier cru Lavaut Saint-Jacques	AOC -	AOP -	{"fra": "Gevrey-Chambertin premier cru Lavaut Saint-Jacques"}	Gevrey-Chambertin premier cru Lavaut Saint-Jacques	\N
8334	564	Gevrey-Chambertin premier cru Les Cazetiers	AOC -	AOP -	{"fra": "Gevrey-Chambertin premier cru Les Cazetiers"}	Gevrey-Chambertin premier cru Les Cazetiers	\N
8335	565	Gevrey-Chambertin premier cru Les Corbeaux	AOC -	AOP -	{"fra": "Gevrey-Chambertin premier cru Les Corbeaux"}	Gevrey-Chambertin premier cru Les Corbeaux	\N
8336	566	Gevrey-Chambertin premier cru Les Goulots	AOC -	AOP -	{"fra": "Gevrey-Chambertin premier cru Les Goulots"}	Gevrey-Chambertin premier cru Les Goulots	\N
8337	567	Gevrey-Chambertin premier cru Petite Chapelle	AOC -	AOP -	{"fra": "Gevrey-Chambertin premier cru Petite Chapelle"}	Gevrey-Chambertin premier cru Petite Chapelle	\N
8338	568	Gevrey-Chambertin premier cru Petits Cazetiers	AOC -	AOP -	{"fra": "Gevrey-Chambertin premier cru Petits Cazetiers"}	Gevrey-Chambertin premier cru Petits Cazetiers	\N
8339	569	Gevrey-Chambertin premier cru Poissenot	AOC -	AOP -	{"fra": "Gevrey-Chambertin premier cru Poissenot"}	Gevrey-Chambertin premier cru Poissenot	\N
13974	1307	Gigondas	AOC -	AOP -	{"fra": "Gigondas rosé"}	Gigondas rosé	\N
13975	1307	Gigondas	AOC -	AOP -	{"fra": "Gigondas rouge"}	Gigondas rouge	\N
5826	571	Givry	AOC -	AOP -	{"fra": "Givry blanc"}	Givry blanc	\N
8569	571	Givry	AOC -	AOP -	{"fra": "Givry rouge"}	Givry rouge	\N
8517	598	Givry premier cru	AOC -	AOP -	{"fra": "Givry premier cru blanc"}	Givry premier cru blanc	\N
8566	598	Givry premier cru	AOC -	AOP -	{"fra": "Givry premier cru rouge"}	Givry premier cru rouge	\N
8515	592	Givry premier cru A Vigne Rouge	AOC -	AOP -	{"fra": "Givry premier cru A Vigne Rouge blanc"}	Givry premier cru A Vigne Rouge blanc	\N
8516	592	Givry premier cru A Vigne Rouge	AOC -	AOP -	{"fra": "Givry premier cru A Vigne Rouge rouge"}	Givry premier cru A Vigne Rouge rouge	\N
8671	2157	Givry premier cru Champ Nalot	AOC -	AOP -	{"fra": "Givry premier cru Champ Nalot blanc"}	Givry premier cru Champ Nalot blanc	\N
8672	2157	Givry premier cru Champ Nalot	AOC -	AOP -	{"fra": "Givry premier cru Champ Nalot rouge"}	Givry premier cru Champ Nalot rouge	\N
8520	573	Givry premier cru Clos Charlé	AOC -	AOP -	{"fra": "Givry premier cru Clos Charlé blanc"}	Givry premier cru Clos Charlé blanc	\N
8521	573	Givry premier cru Clos Charlé	AOC -	AOP -	{"fra": "Givry premier cru Clos Charlé rouge"}	Givry premier cru Clos Charlé rouge	\N
8522	580	Givry premier cru Clos de la Baraude	AOC -	AOP -	{"fra": "Givry premier cru Clos de la Baraude blanc"}	Givry premier cru Clos de la Baraude blanc	\N
8523	580	Givry premier cru Clos de la Baraude	AOC -	AOP -	{"fra": "Givry premier cru Clos de la Baraude rouge"}	Givry premier cru Clos de la Baraude rouge	\N
8518	572	Givry premier cru Clos du Cellier aux Moines	AOC -	AOP -	{"fra": "Givry premier cru Clos du Cellier aux Moines blanc"}	Givry premier cru Clos du Cellier aux Moines blanc	\N
8519	572	Givry premier cru Clos du Cellier aux Moines	AOC -	AOP -	{"fra": "Givry premier cru Clos du Cellier aux Moines rouge"}	Givry premier cru Clos du Cellier aux Moines rouge	\N
8524	581	Givry premier cru Clos du Cras long	AOC -	AOP -	{"fra": "Givry premier cru Clos du Cras long blanc"}	Givry premier cru Clos du Cras long blanc	\N
8525	581	Givry premier cru Clos du Cras long	AOC -	AOP -	{"fra": "Givry premier cru Clos du Cras long rouge"}	Givry premier cru Clos du Cras long rouge	\N
8526	582	Givry premier cru Clos du Vernoy	AOC -	AOP -	{"fra": "Givry premier cru Clos du Vernoy blanc"}	Givry premier cru Clos du Vernoy blanc	\N
8527	582	Givry premier cru Clos du Vernoy	AOC -	AOP -	{"fra": "Givry premier cru Clos du Vernoy rouge"}	Givry premier cru Clos du Vernoy rouge	\N
8528	574	Givry premier cru Clos Jus	AOC -	AOP -	{"fra": "Givry premier cru Clos Jus blanc"}	Givry premier cru Clos Jus blanc	\N
8529	574	Givry premier cru Clos Jus	AOC -	AOP -	{"fra": "Givry premier cru Clos Jus rouge"}	Givry premier cru Clos Jus rouge	\N
8530	575	Givry premier cru Clos Marceaux	AOC -	AOP -	{"fra": "Givry premier cru Clos Marceaux blanc"}	Givry premier cru Clos Marceaux blanc	\N
8531	575	Givry premier cru Clos Marceaux	AOC -	AOP -	{"fra": "Givry premier cru Clos Marceaux rouge"}	Givry premier cru Clos Marceaux rouge	\N
8532	576	Givry premier cru Clos Marole	AOC -	AOP -	{"fra": "Givry premier cru Clos Marole blanc"}	Givry premier cru Clos Marole blanc	\N
8533	576	Givry premier cru Clos Marole	AOC -	AOP -	{"fra": "Givry premier cru Clos Marole rouge"}	Givry premier cru Clos Marole rouge	\N
8534	579	Givry premier cru Clos Salomon	AOC -	AOP -	{"fra": "Givry premier cru Clos Salomon blanc"}	Givry premier cru Clos Salomon blanc	\N
8535	579	Givry premier cru Clos Salomon	AOC -	AOP -	{"fra": "Givry premier cru Clos Salomon rouge"}	Givry premier cru Clos Salomon rouge	\N
8536	577	Givry premier cru Clos-Saint-Paul	AOC -	AOP -	{"fra": "Givry premier cru Clos-Saint-Paul blanc"}	Givry premier cru Clos-Saint-Paul blanc	\N
8537	577	Givry premier cru Clos-Saint-Paul	AOC -	AOP -	{"fra": "Givry premier cru Clos-Saint-Paul rouge"}	Givry premier cru Clos-Saint-Paul rouge	\N
8538	578	Givry premier cru Clos-Saint-Pierre	AOC -	AOP -	{"fra": "Givry premier cru Clos-Saint-Pierre blanc"}	Givry premier cru Clos-Saint-Pierre blanc	\N
8539	578	Givry premier cru Clos-Saint-Pierre	AOC -	AOP -	{"fra": "Givry premier cru Clos-Saint-Pierre rouge"}	Givry premier cru Clos-Saint-Pierre rouge	\N
8540	594	Givry premier cru Crausot	AOC -	AOP -	{"fra": "Givry premier cru Crausot blanc"}	Givry premier cru Crausot blanc	\N
8541	594	Givry premier cru Crausot	AOC -	AOP -	{"fra": "Givry premier cru Crausot rouge"}	Givry premier cru Crausot rouge	\N
8542	595	Givry premier cru Crémillons	AOC -	AOP -	{"fra": "Givry premier cru Crémillons blanc"}	Givry premier cru Crémillons blanc	\N
8543	595	Givry premier cru Crémillons	AOC -	AOP -	{"fra": "Givry premier cru Crémillons rouge"}	Givry premier cru Crémillons rouge	\N
8544	597	Givry premier cru En Choué	AOC -	AOP -	{"fra": "Givry premier cru En Choué blanc"}	Givry premier cru En Choué blanc	\N
8545	597	Givry premier cru En Choué	AOC -	AOP -	{"fra": "Givry premier cru En Choué rouge"}	Givry premier cru En Choué rouge	\N
8673	2158	Givry premier cru En Veau	AOC -	AOP -	{"fra": "Givry premier cru En Veau blanc"}	Givry premier cru En Veau blanc	\N
8674	2158	Givry premier cru En Veau	AOC -	AOP -	{"fra": "Givry premier cru En Veau rouge"}	Givry premier cru En Veau rouge	\N
8675	2159	Givry premier cru La Brûlée	AOC -	AOP -	{"fra": "Givry premier cru La Brûlée blanc"}	Givry premier cru La Brûlée blanc	\N
8676	2159	Givry premier cru La Brûlée	AOC -	AOP -	{"fra": "Givry premier cru La Brûlée rouge"}	Givry premier cru La Brûlée rouge	\N
8546	596	Givry premier cru La Grande Berge	AOC -	AOP -	{"fra": "Givry premier cru La Grande Berge blanc"}	Givry premier cru La Grande Berge blanc	\N
8547	596	Givry premier cru La Grande Berge	AOC -	AOP -	{"fra": "Givry premier cru La Grande Berge rouge"}	Givry premier cru La Grande Berge rouge	\N
8677	2160	Givry premier cru La Matrosse	AOC -	AOP -	{"fra": "Givry premier cru La Matrosse blanc"}	Givry premier cru La Matrosse blanc	\N
8678	2160	Givry premier cru La Matrosse	AOC -	AOP -	{"fra": "Givry premier cru La Matrosse rouge"}	Givry premier cru La Matrosse rouge	\N
8679	2161	Givry premier cru La Petite Berge	AOC -	AOP -	{"fra": "Givry premier cru La Petite Berge blanc"}	Givry premier cru La Petite Berge blanc	\N
8680	2161	Givry premier cru La Petite Berge	AOC -	AOP -	{"fra": "Givry premier cru La Petite Berge rouge"}	Givry premier cru La Petite Berge rouge	\N
8548	593	Givry premier cru La Plante	AOC -	AOP -	{"fra": "Givry premier cru La Plante blanc"}	Givry premier cru La Plante blanc	\N
8549	593	Givry premier cru La Plante	AOC -	AOP -	{"fra": "Givry premier cru La Plante rouge"}	Givry premier cru La Plante rouge	\N
8681	2162	Givry premier cru Le Champ Lalot	AOC -	AOP -	{"fra": "Givry premier cru Le Champ Lalot blanc"}	Givry premier cru Le Champ Lalot blanc	\N
8682	2162	Givry premier cru Le Champ Lalot	AOC -	AOP -	{"fra": "Givry premier cru Le Champ Lalot rouge"}	Givry premier cru Le Champ Lalot rouge	\N
8683	2163	Givry premier cru Le Médenchot	AOC -	AOP -	{"fra": "Givry premier cru Le Médenchot blanc"}	Givry premier cru Le Médenchot blanc	\N
8684	2163	Givry premier cru Le Médenchot	AOC -	AOP -	{"fra": "Givry premier cru Le Médenchot rouge"}	Givry premier cru Le Médenchot rouge	\N
8550	589	Givry premier cru Le Paradis	AOC -	AOP -	{"fra": "Givry premier cru Le Paradis blanc"}	Givry premier cru Le Paradis blanc	\N
8551	589	Givry premier cru Le Paradis	AOC -	AOP -	{"fra": "Givry premier cru Le Paradis rouge"}	Givry premier cru Le Paradis rouge	\N
8552	588	Givry premier cru Le Petit Prétan	AOC -	AOP -	{"fra": "Givry premier cru Le Petit Prétan blanc"}	Givry premier cru Le Petit Prétan blanc	\N
8553	588	Givry premier cru Le Petit Prétan	AOC -	AOP -	{"fra": "Givry premier cru Le Petit Prétan rouge"}	Givry premier cru Le Petit Prétan rouge	\N
8685	2164	Givry premier cru Le Pied de Chaume	AOC -	AOP -	{"fra": "Givry premier cru Le Pied de Chaume blanc"}	Givry premier cru Le Pied de Chaume blanc	\N
8686	2164	Givry premier cru Le Pied de Chaume	AOC -	AOP -	{"fra": "Givry premier cru Le Pied de Chaume rouge"}	Givry premier cru Le Pied de Chaume rouge	\N
8687	2165	Givry premier cru Le Pied du Clou	AOC -	AOP -	{"fra": "Givry premier cru Le Pied du Clou blanc"}	Givry premier cru Le Pied du Clou blanc	\N
8688	2165	Givry premier cru Le Pied du Clou	AOC -	AOP -	{"fra": "Givry premier cru Le Pied du Clou rouge"}	Givry premier cru Le Pied du Clou rouge	\N
8689	2166	Givry premier cru Le Vernoy	AOC -	AOP -	{"fra": "Givry premier cru Le Vernoy blanc"}	Givry premier cru Le Vernoy blanc	\N
8690	2166	Givry premier cru Le Vernoy	AOC -	AOP -	{"fra": "Givry premier cru Le Vernoy rouge"}	Givry premier cru Le Vernoy rouge	\N
8554	590	Givry premier cru Le Vigron	AOC -	AOP -	{"fra": "Givry premier cru Le Vigron blanc"}	Givry premier cru Le Vigron blanc	\N
8555	590	Givry premier cru Le Vigron	AOC -	AOP -	{"fra": "Givry premier cru Le Vigron rouge"}	Givry premier cru Le Vigron rouge	\N
8556	583	Givry premier cru Les Bois Chevaux	AOC -	AOP -	{"fra": "Givry premier cru Les Bois Chevaux blanc"}	Givry premier cru Les Bois Chevaux blanc	\N
8557	583	Givry premier cru Les Bois Chevaux	AOC -	AOP -	{"fra": "Givry premier cru Les Bois Chevaux rouge"}	Givry premier cru Les Bois Chevaux rouge	\N
8558	591	Givry premier cru Les Bois Gautiers	AOC -	AOP -	{"fra": "Givry premier cru Les Bois Gautiers blanc"}	Givry premier cru Les Bois Gautiers blanc	\N
8559	591	Givry premier cru Les Bois Gautiers	AOC -	AOP -	{"fra": "Givry premier cru Les Bois Gautiers rouge"}	Givry premier cru Les Bois Gautiers rouge	\N
8691	2167	Givry premier cru Les Combes	AOC -	AOP -	{"fra": "Givry premier cru Les Combes blanc"}	Givry premier cru Les Combes blanc	\N
8692	2167	Givry premier cru Les Combes	AOC -	AOP -	{"fra": "Givry premier cru Les Combes rouge"}	Givry premier cru Les Combes rouge	\N
8693	2168	Givry premier cru Les Galaffres	AOC -	AOP -	{"fra": "Givry premier cru Les Galaffres blanc"}	Givry premier cru Les Galaffres blanc	\N
8694	2168	Givry premier cru Les Galaffres	AOC -	AOP -	{"fra": "Givry premier cru Les Galaffres rouge"}	Givry premier cru Les Galaffres rouge	\N
8560	584	Givry premier cru Les Grandes Vignes	AOC -	AOP -	{"fra": "Givry premier cru Les Grandes Vignes blanc"}	Givry premier cru Les Grandes Vignes blanc	\N
8561	584	Givry premier cru Les Grandes Vignes	AOC -	AOP -	{"fra": "Givry premier cru Les Grandes Vignes rouge"}	Givry premier cru Les Grandes Vignes rouge	\N
8562	585	Givry premier cru Les Grands Prétans	AOC -	AOP -	{"fra": "Givry premier cru Les Grands Prétans blanc"}	Givry premier cru Les Grands Prétans blanc	\N
8563	585	Givry premier cru Les Grands Prétans	AOC -	AOP -	{"fra": "Givry premier cru Les Grands Prétans rouge"}	Givry premier cru Les Grands Prétans rouge	\N
8564	586	Givry premier cru Petit Marole	AOC -	AOP -	{"fra": "Givry premier cru Petit Marole blanc"}	Givry premier cru Petit Marole blanc	\N
8565	586	Givry premier cru Petit Marole	AOC -	AOP -	{"fra": "Givry premier cru Petit Marole rouge"}	Givry premier cru Petit Marole rouge	\N
8567	587	Givry premier cru Servoisine	AOC -	AOP -	{"fra": "Givry premier cru Servoisine blanc"}	Givry premier cru Servoisine blanc	\N
8568	587	Givry premier cru Servoisine	AOC -	AOP -	{"fra": "Givry premier cru Servoisine rouge"}	Givry premier cru Servoisine rouge	\N
7764	1334	Grand Roussillon	AOC -	AOP -	{"fra": "Grand Roussillon blanc"}	Grand Roussillon blanc	\N
9214	1334	Grand Roussillon	AOC -	AOP -	{"fra": "Grand Roussillon rancio"}	Grand Roussillon rancio	\N
9215	1334	Grand Roussillon	AOC -	AOP -	{"fra": "Grand Roussillon rosé"}	Grand Roussillon rosé	\N
9216	1334	Grand Roussillon	AOC -	AOP -	{"fra": "Grand Roussillon rouge"}	Grand Roussillon rouge	\N
10208	2188	Grands-Echezeaux	AOC -	AOP -	{"fra": "Grands-Echezeaux"}	Grands-Echezeaux	\N
14986	86	Graves	AOC -	AOP -	{"fra": "Graves blanc"}	Graves blanc	\N
14987	86	Graves	AOC -	AOP -	{"fra": "Graves rouge"}	Graves rouge	\N
14988	86	Graves	AOC -	AOP -	{"fra": "Graves supérieures"}	Graves supérieures	\N
8019	87	Graves de Vayres	AOC -	AOP -	{"fra": "Graves de Vayres blanc"}	Graves de Vayres blanc	\N
8020	87	Graves de Vayres	AOC -	AOP -	{"fra": "Graves de Vayres blanc sec"}	Graves de Vayres blanc sec	\N
8021	87	Graves de Vayres	AOC -	AOP -	{"fra": "Graves de Vayres rouge"}	Graves de Vayres rouge	\N
8362	2123	Grignan-les-Adhémar	AOC -	AOP -	{"fra": "Grignan-les-Adhémar blanc"}	Grignan-les-Adhémar blanc	\N
8363	2123	Grignan-les-Adhémar	AOC -	AOP -	{"fra": "Grignan-les-Adhémar primeur ou nouveau blanc"}	Grignan-les-Adhémar primeur ou nouveau blanc	\N
8364	2123	Grignan-les-Adhémar	AOC -	AOP -	{"fra": "Grignan-les-Adhémar primeur ou nouveau rosé"}	Grignan-les-Adhémar primeur ou nouveau rosé	\N
8365	2123	Grignan-les-Adhémar	AOC -	AOP -	{"fra": "Grignan-les-Adhémar primeur ou nouveau rouge"}	Grignan-les-Adhémar primeur ou nouveau rouge	\N
8366	2123	Grignan-les-Adhémar	AOC -	AOP -	{"fra": "Grignan-les-Adhémar rosé"}	Grignan-les-Adhémar rosé	\N
8367	2123	Grignan-les-Adhémar	AOC -	AOP -	{"fra": "Grignan-les-Adhémar rouge"}	Grignan-les-Adhémar rouge	\N
7721	600	Griotte-Chambertin	AOC -	AOP -	{"fra": "Griotte-Chambertin"}	Griotte-Chambertin	\N
15255	2171	Gros Plant du Pays nantais	AOC -	AOP -	{"fra": "Gros Plant du Pays nantais"}	Gros Plant du Pays nantais	\N
15256	2171	Gros Plant du Pays nantais	AOC -	AOP -	{"fra": "Gros Plant du Pays nantais sur lie"}	Gros Plant du Pays nantais sur lie	\N
4500	2138	Gruyère (IGP)	\N	IGP -	{"fra": "Gruyère"}	Gruyère	\N
3404	1532	Haricot tarbais	\N	IGP -	{"fra": "Haricot tarbais"}	Haricot tarbais	IG/15/96
13390	1957	Haut Armagnac	AOC -	IG - 	{"fra": "Haut Armagnac"}	Haut Armagnac	\N
15206	88	Haut-Médoc	AOC -	AOP -	{"fra": "Haut-Médoc"}	Haut-Médoc	\N
12975	1666	Haut-Montravel	AOC -	AOP -	{"fra": "Haut-Montravel"}	Haut-Montravel	\N
14162	2143	Haut-Poitou	AOC -	AOP -	{"fra": "Haut-Poitou blanc"}	Haut-Poitou blanc	\N
14163	2143	Haut-Poitou	AOC -	AOP -	{"fra": "Haut-Poitou rosé"}	Haut-Poitou rosé	\N
14164	2143	Haut-Poitou	AOC -	AOP -	{"fra": "Haut-Poitou rouge"}	Haut-Poitou rouge	\N
7856	2090	Haute Vallée de l'Aude	\N	IGP -	{"fra": "Haute Vallée de l'Aude blanc"}	Haute Vallée de l'Aude blanc	\N
8428	2090	Haute Vallée de l'Aude	\N	IGP -	{"fra": "Haute Vallée de l'Aude rosé"}	Haute Vallée de l'Aude rosé	\N
8429	2090	Haute Vallée de l'Aude	\N	IGP -	{"fra": "Haute Vallée de l'Aude rouge"}	Haute Vallée de l'Aude rouge	\N
10866	2090	Haute Vallée de l'Aude	\N	IGP -	{"fra": "Haute Vallée de l'Aude primeur ou nouveau blanc"}	Haute Vallée de l'Aude primeur ou nouveau blanc	\N
10867	2090	Haute Vallée de l'Aude	\N	IGP -	{"fra": "Haute Vallée de l'Aude primeur ou nouveau rosé"}	Haute Vallée de l'Aude primeur ou nouveau rosé	\N
10868	2090	Haute Vallée de l'Aude	\N	IGP -	{"fra": "Haute Vallée de l'Aude primeur ou nouveau rouge"}	Haute Vallée de l'Aude primeur ou nouveau rouge	\N
7822	2109	Haute Vallée de l'Orb	\N	IGP -	{"fra": "Haute Vallée de l'Orb blanc"}	Haute Vallée de l'Orb blanc	\N
8409	2109	Haute Vallée de l'Orb	\N	IGP -	{"fra": "Haute Vallée de l'Orb rosé"}	Haute Vallée de l'Orb rosé	\N
8410	2109	Haute Vallée de l'Orb	\N	IGP -	{"fra": "Haute Vallée de l'Orb rouge"}	Haute Vallée de l'Orb rouge	\N
10869	2109	Haute Vallée de l'Orb	\N	IGP -	{"fra": "Haute Vallée de l'Orb surmûri blanc"}	Haute Vallée de l'Orb surmûri blanc	\N
10870	2109	Haute Vallée de l'Orb	\N	IGP -	{"fra": "Haute Vallée de l'Orb surmûri rosé"}	Haute Vallée de l'Orb surmûri rosé	\N
10871	2109	Haute Vallée de l'Orb	\N	IGP -	{"fra": "Haute Vallée de l'Orb surmûri rouge"}	Haute Vallée de l'Orb surmûri rouge	\N
10872	2109	Haute Vallée de l'Orb	\N	IGP -	{"fra": "Haute Vallée de l'Orb mousseux de qualité blanc"}	Haute Vallée de l'Orb mousseux de qualité blanc	\N
10873	2109	Haute Vallée de l'Orb	\N	IGP -	{"fra": "Haute Vallée de l'Orb mousseux de qualité rosé"}	Haute Vallée de l'Orb mousseux de qualité rosé	\N
10874	2109	Haute Vallée de l'Orb	\N	IGP -	{"fra": "Haute Vallée de l'Orb mousseux de qualité rouge"}	Haute Vallée de l'Orb mousseux de qualité rouge	\N
10875	2109	Haute Vallée de l'Orb	\N	IGP -	{"fra": "Haute Vallée de l'Orb primeur ou nouveau blanc"}	Haute Vallée de l'Orb primeur ou nouveau blanc	\N
10876	2109	Haute Vallée de l'Orb	\N	IGP -	{"fra": "Haute Vallée de l'Orb primeur ou nouveau rosé"}	Haute Vallée de l'Orb primeur ou nouveau rosé	\N
10877	2109	Haute Vallée de l'Orb	\N	IGP -	{"fra": "Haute Vallée de l'Orb primeur ou nouveau rouge"}	Haute Vallée de l'Orb primeur ou nouveau rouge	\N
7812	2049	Haute-Marne	\N	IGP -	{"fra": "Haute-Marne blanc"}	Haute-Marne blanc	\N
8869	2049	Haute-Marne	\N	IGP -	{"fra": "Haute-Marne rosé"}	Haute-Marne rosé	\N
8870	2049	Haute-Marne	\N	IGP -	{"fra": "Haute-Marne rouge"}	Haute-Marne rouge	\N
10878	2049	Haute-Marne	\N	IGP -	{"fra": "Haute-Marne primeur ou nouveau blanc"}	Haute-Marne primeur ou nouveau blanc	\N
10879	2049	Haute-Marne	\N	IGP -	{"fra": "Haute-Marne primeur ou nouveau rosé"}	Haute-Marne primeur ou nouveau rosé	\N
10880	2049	Haute-Marne	\N	IGP -	{"fra": "Haute-Marne primeur ou nouveau rouge"}	Haute-Marne primeur ou nouveau rouge	\N
8830	2085	Haute-Vienne	\N	IGP -	{"fra": "Haute-Vienne blanc"}	Haute-Vienne blanc	\N
8831	2085	Haute-Vienne	\N	IGP -	{"fra": "Haute-Vienne rosé"}	Haute-Vienne rosé	\N
8832	2085	Haute-Vienne	\N	IGP -	{"fra": "Haute-Vienne rouge"}	Haute-Vienne rouge	\N
10888	2085	Haute-Vienne	\N	IGP -	{"fra": "Haute-Vienne primeur ou nouveau blanc"}	Haute-Vienne primeur ou nouveau blanc	\N
10889	2085	Haute-Vienne	\N	IGP -	{"fra": "Haute-Vienne primeur ou nouveau rosé"}	Haute-Vienne primeur ou nouveau rosé	\N
10890	2085	Haute-Vienne	\N	IGP -	{"fra": "Haute-Vienne primeur ou nouveau rouge"}	Haute-Vienne primeur ou nouveau rouge	\N
7857	1975	Hautes-Alpes	\N	IGP -	{"fra": "Hautes-Alpes blanc"}	Hautes-Alpes blanc	\N
8843	1975	Hautes-Alpes	\N	IGP -	{"fra": "Hautes-Alpes rosé"}	Hautes-Alpes rosé	\N
8844	1975	Hautes-Alpes	\N	IGP -	{"fra": "Hautes-Alpes rouge"}	Hautes-Alpes rouge	\N
10881	1975	Hautes-Alpes	\N	IGP -	{"fra": "Hautes-Alpes mousseux de qualité blanc"}	Hautes-Alpes mousseux de qualité blanc	\N
10882	1975	Hautes-Alpes	\N	IGP -	{"fra": "Hautes-Alpes mousseux de qualité rosé"}	Hautes-Alpes mousseux de qualité rosé	\N
10883	1975	Hautes-Alpes	\N	IGP -	{"fra": "Hautes-Alpes mousseux de qualité rouge"}	Hautes-Alpes mousseux de qualité rouge	\N
10884	1975	Hautes-Alpes	\N	IGP -	{"fra": "Hautes-Alpes primeur ou nouveau blanc"}	Hautes-Alpes primeur ou nouveau blanc	\N
10885	1975	Hautes-Alpes	\N	IGP -	{"fra": "Hautes-Alpes primeur ou nouveau rosé"}	Hautes-Alpes primeur ou nouveau rosé	\N
10887	1975	Hautes-Alpes	\N	IGP -	{"fra": "Hautes-Alpes primeur ou nouveau rouge"}	Hautes-Alpes primeur ou nouveau rouge	\N
5993	1308	Hermitage	AOC -	AOP -	{"fra": "Hermitage ou Ermitage ou l'Hermitage ou l'Ermitage rouge"}	Hermitage ou Ermitage ou l'Hermitage ou l'Ermitage rouge	\N
9384	1308	Hermitage	AOC -	AOP -	{"fra": "Hermitage ou Ermitage ou l'Hermitage ou l'Ermitage vin de paille"}	Hermitage ou Ermitage ou l'Hermitage ou l'Ermitage vin de paille	\N
9385	1308	Hermitage	AOC -	AOP -	{"fra": "Hermitage ou Ermitage ou l'Hermitage ou l'Ermitage blanc"}	Hermitage ou Ermitage ou l'Hermitage ou l'Ermitage blanc	\N
4509	1512	Huile d'olive d'Aix-en-Provence	AOC -	AOP -	{"fra": "Huile d'olive d'Aix-en-Provence"}	Huile d'olive d'Aix-en-Provence	\N
14484	1611	Huile d'olive de Corse - Oliu di Corsica	AOC -	AOP -	{"fra": "Huile d'olive de Corse - Oliu di Corsica"}	Huile d'olive de Corse - Oliu di Corsica	\N
4510	1513	Huile d'olive de Haute-Provence	AOC -	AOP -	{"fra": "Huile d'olive de Haute-Provence"}	Huile d'olive de Haute-Provence	\N
4511	1507	Huile d'olive de la vallée des Baux-de-Provence	AOC -	AOP -	{"fra": "Huile d'olive de la vallée des Baux-de-Provence"}	Huile d'olive de la vallée des Baux-de-Provence	\N
4513	1507	Huile d'olive de la vallée des Baux-de-Provence	AOC -	AOP -	{"fra": "Olives cassées de la vallée des Baux-de-Provence"}	Olives cassées de la vallée des Baux-de-Provence	\N
13087	2361	Mirabelle d'Alsace	\N	IG - 	{"fra": "Mirabelle d'Alsace"}	Mirabelle d'Alsace	\N
4514	1507	Huile d'olive de la vallée des Baux-de-Provence	AOC -	AOP -	{"fra": "Olives noires de la vallée des Baux-de-Provence"}	Olives noires de la vallée des Baux-de-Provence	\N
4512	1613	Huile d'olive de Nice	AOC -	AOP -	{"fra": "Huile d'olive de Nice"}	Huile d'olive de Nice	\N
7111	1610	Huile d'olive de Nîmes	AOC -	AOP -	{"fra": "Huile d'olive de Nïmes"}	Huile d'olive de Nïmes	\N
7934	1499	Huile d'olive de Nyons	AOC -	AOP -	{"fra": "Huile d'olive de Nyons"}	Huile d'olive de Nyons	\N
13661	1499	Huile d'olive de Nyons	AOC -	AOP -	{"fra": "Olives noires de Nyons"}	Olives noires de Nyons	\N
16106	1650	Huile d'olive de Provence	AOC -	AOP -	{"fra": "Huile d'olive de Provence"}	Huile d'olive de Provence	\N
4301	1706	Huile de noix du Périgord	AOC -	\N	{"fra": "Huile de noix du Périgord"}	Huile de noix du Périgord	\N
14037	1508	Huile essentielle de lavande de Haute-Provence	AOC -	AOP -	{"fra": "Huile essentielle de lavande de Haute-Provence ou Essence de lavande de Haute-Provence"}	Huile essentielle de lavande de Haute-Provence ou Essence de lavande de Haute-Provence	\N
4157	1824	Huîtres Marennes Oléron	\N	IGP -	{"fra": "Huîtres Marennes Oléron"}	Huîtres Marennes Oléron	IG/13/00
8827	2000	Ile de Beauté	\N	IGP -	{"fra": "Ile de Beauté blanc"}	Ile de Beauté blanc	\N
8828	2000	Ile de Beauté	\N	IGP -	{"fra": "Ile de Beauté rosé"}	Ile de Beauté rosé	\N
8829	2000	Ile de Beauté	\N	IGP -	{"fra": "Ile de Beauté rouge"}	Ile de Beauté rouge	\N
10891	2000	Ile de Beauté	\N	IGP -	{"fra": "Ile de Beauté primeur ou nouveau blanc"}	Ile de Beauté primeur ou nouveau blanc	\N
10892	2000	Ile de Beauté	\N	IGP -	{"fra": "Ile de Beauté primeur ou nouveau rosé"}	Ile de Beauté primeur ou nouveau rosé	\N
10893	2000	Ile de Beauté	\N	IGP -	{"fra": "Ile de Beauté primeur ou nouveau rouge"}	Ile de Beauté primeur ou nouveau rouge	\N
7698	1233	Irancy	AOC -	AOP -	{"fra": "Irancy"}	Irancy	\N
9386	90	Irouléguy	AOC -	AOP -	{"fra": "Irouléguy blanc"}	Irouléguy blanc	\N
9387	90	Irouléguy	AOC -	AOP -	{"fra": "Irouléguy rosé"}	Irouléguy rosé	\N
9388	90	Irouléguy	AOC -	AOP -	{"fra": "Irouléguy rouge"}	Irouléguy rouge	\N
10894	2238	Isère Balmes dauphinoises	\N	IGP -	{"fra": "Isère Balmes dauphinoises blanc"}	Isère Balmes dauphinoises blanc	\N
10896	2238	Isère Balmes dauphinoises	\N	IGP -	{"fra": "Isère Balmes dauphinoises rosé"}	Isère Balmes dauphinoises rosé	\N
10897	2238	Isère Balmes dauphinoises	\N	IGP -	{"fra": "Isère Balmes dauphinoises rouge"}	Isère Balmes dauphinoises rouge	\N
10895	2239	Isère Côteaux du Grésivaudan	\N	IGP -	{"fra": "Isère Côteaux du Grésivaudan blanc"}	Isère Côteaux du Grésivaudan blanc	\N
10898	2239	Isère Côteaux du Grésivaudan	\N	IGP -	{"fra": "Isère Isère Côteaux du Grésivaudan rosé"}	Isère Isère Côteaux du Grésivaudan rosé	\N
10899	2239	Isère Côteaux du Grésivaudan	\N	IGP -	{"fra": "Isère Isère Côteaux du Grésivaudan rouge"}	Isère Isère Côteaux du Grésivaudan rouge	\N
4179	2406	Jambon d'Auvergne	\N	IGP -	{"fra": "Jambon d'Auvergne"}	Jambon d'Auvergne	\N
16083	1533	Jambon de Bayonne	\N	IGP -	{"fra": "Jambon de Bayonne"}	Jambon de Bayonne	IG/01/95
12009	1825	Jambon de l'Ardèche	\N	IGP -	{"fra": "Jambon de l'Ardèche"}	Jambon de l'Ardèche	IG/09/05
15306	1729	Jambon de Lacaune	\N	IGP -	{"fra": "Jambon de Lacaune"}	Jambon de Lacaune	\N
4373	1782	Jambon de Vendée	\N	IGP -	{"fra": "Jambon de Vendée"}	Jambon de Vendée	\N
13955	2413	Jambon du Kintoa	AOC -	AOP -	{"fra": "Jambon du Kintoa"}	Jambon du Kintoa	\N
4399	1805	Jambon noir de Bigorre	AOC -	AOP -	{"fra": "Jambon noir de Bigorre"}	Jambon noir de Bigorre	\N
3669	1679	Jambon sec de Corse ou Jambon sec de Corse - Prisuttu	AOC -	AOP -	{"fra": "Jambon sec de Corse ou Jambon sec de Corse - Prisuttu"}	Jambon sec de Corse ou Jambon sec de Corse - Prisuttu	\N
13466	1534	Jambon sec des Ardennes ou Noix de jambon sec des Ardennes	\N	IGP -	{"fra": "Jambon sec des Ardennes ou Noix de jambon sec des Ardennes"}	Jambon sec des Ardennes ou Noix de jambon sec des Ardennes	IG/22/95
8944	179	Jasnières	AOC -	AOP -	{"fra": "Jasnières"}	Jasnières	\N
10246	601	Juliénas	AOC -	AOP -	{"fra": "Juliénas ou Juliénas cru du Beaujolais"}	Juliénas ou Juliénas cru du Beaujolais	\N
9030	91	Jurançon	AOC -	AOP -	{"fra": "Jurançon"}	Jurançon	\N
9031	91	Jurançon	AOC -	AOP -	{"fra": "Jurançon sec"}	Jurançon sec	\N
9032	91	Jurançon	AOC -	AOP -	{"fra": "Jurançon vendanges tardives"}	Jurançon vendanges tardives	\N
13954	2412	Kintoa	AOC -	AOP -	{"fra": "Kintoa"}	Kintoa	\N
13093	1676	Kirsch de Fougerolles	AOC -	IG - 	{"fra": "Kirsch de Fougerolles"}	Kirsch de Fougerolles	\N
13090	2364	Kirsch d’Alsace	\N	IG - 	{"fra": "Kirsch d’Alsace"}	Kirsch d’Alsace	\N
4359	1768	Kiwi de Corse	\N	IGP -	{"fra": "Kiwi de Corse"}	Kiwi de Corse	IG/
12252	1858	Kiwi de l'Adour	\N	IGP -	{"fra": "Kiwi de l'Adour"}	Kiwi de l'Adour	IG/01/00
12546	606	L'Etoile	AOC -	AOP -	{"fra": "L'Etoile blanc"}	L'Etoile blanc	\N
12547	606	L'Etoile	AOC -	AOP -	{"fra": "L'Etoile vin jaune"}	L'Etoile vin jaune	\N
12548	606	L'Etoile	AOC -	AOP -	{"fra": "L'Etoile vin de paille"}	L'Etoile vin de paille	\N
4527	1839	La Clape	AOC -	AOP -	{"fra": "La Clape blanc"}	La Clape blanc	\N
13749	1839	La Clape	AOC -	AOP -	{"fra": "La Clape rouge"}	La Clape rouge	\N
7735	607	La Grande Rue	AOC -	AOP -	{"fra": "La Grande Rue"}	La Grande Rue	\N
9236	1277	La Livinière	AOC -	AOP -	{"fra": "Minervois-La Livinière"}	Minervois-La Livinière	\N
7732	608	La Romanée	AOC -	AOP -	{"fra": "La Romanée"}	La Romanée	\N
7733	609	La Tâche	AOC -	AOP -	{"fra": "La Tâche"}	La Tâche	\N
7703	610	Ladoix	AOC -	AOP -	{"fra": "Ladoix blanc"}	Ladoix blanc	\N
8918	610	Ladoix	AOC -	AOP -	{"fra": "Ladoix rouge ou Ladoix Côte de Beaune"}	Ladoix rouge ou Ladoix Côte de Beaune	\N
8896	618	Ladoix premier cru	AOC -	AOP -	{"fra": "Ladoix premier cru blanc"}	Ladoix premier cru blanc	\N
8917	618	Ladoix premier cru	AOC -	AOP -	{"fra": "Ladoix premier cru rouge"}	Ladoix premier cru rouge	\N
8894	611	Ladoix premier cru Basses Mourottes	AOC -	AOP -	{"fra": "Ladoix premier cru Basses Mourottes blanc"}	Ladoix premier cru Basses Mourottes blanc	\N
8895	611	Ladoix premier cru Basses Mourottes	AOC -	AOP -	{"fra": "Ladoix premier cru Basses Mourottes rouge"}	Ladoix premier cru Basses Mourottes rouge	\N
8898	612	Ladoix premier cru Bois Roussot	AOC -	AOP -	{"fra": "Ladoix premier cru Bois Roussot rouge"}	Ladoix premier cru Bois Roussot rouge	\N
8899	1814	Ladoix premier cru En Naget	AOC -	AOP -	{"fra": "Ladoix premier cru En Naget blanc"}	Ladoix premier cru En Naget blanc	\N
8901	613	Ladoix premier cru Hautes Mourottes	AOC -	AOP -	{"fra": "Ladoix premier cru Hautes Mourottes blanc"}	Ladoix premier cru Hautes Mourottes blanc	\N
8902	613	Ladoix premier cru Hautes Mourottes	AOC -	AOP -	{"fra": "Ladoix premier cru Hautes Mourottes rouge"}	Ladoix premier cru Hautes Mourottes rouge	\N
8903	614	Ladoix premier cru La Corvée	AOC -	AOP -	{"fra": "Ladoix premier cru La Corvée blanc"}	Ladoix premier cru La Corvée blanc	\N
8904	614	Ladoix premier cru La Corvée	AOC -	AOP -	{"fra": "Ladoix premier cru La Corvée rouge"}	Ladoix premier cru La Corvée rouge	\N
8905	615	Ladoix premier cru La Micaude	AOC -	AOP -	{"fra": "Ladoix premier cru La Micaude blanc"}	Ladoix premier cru La Micaude blanc	\N
8906	615	Ladoix premier cru La Micaude	AOC -	AOP -	{"fra": "Ladoix premier cru La Micaude rouge"}	Ladoix premier cru La Micaude rouge	\N
8907	616	Ladoix premier cru Le Clou d'Orge	AOC -	AOP -	{"fra": "Ladoix premier cru Le Clou d'Orge blanc"}	Ladoix premier cru Le Clou d'Orge blanc	\N
8908	616	Ladoix premier cru Le Clou d'Orge	AOC -	AOP -	{"fra": "Ladoix premier cru Le Clou d'Orge rouge"}	Ladoix premier cru Le Clou d'Orge rouge	\N
8909	1813	Ladoix premier cru Le Rognet et Corton	AOC -	AOP -	{"fra": "Ladoix premier cru Le Rognet et Corton blanc"}	Ladoix premier cru Le Rognet et Corton blanc	\N
8912	1815	Ladoix premier cru Les Buis	AOC -	AOP -	{"fra": "Ladoix premier cru Les Buis rouge"}	Ladoix premier cru Les Buis rouge	\N
8913	1816	Ladoix premier cru Les Grêchons et Foutrières	AOC -	AOP -	{"fra": "Ladoix premier cru Les Grêchons et Foutrières blanc"}	Ladoix premier cru Les Grêchons et Foutrières blanc	\N
8916	617	Ladoix premier cru Les Joyeuses	AOC -	AOP -	{"fra": "Ladoix premier cru Les Joyeuses rouge"}	Ladoix premier cru Les Joyeuses rouge	\N
14231	1470	Laguiole	AOC -	AOP -	{"fra": "Laguiole"}	Laguiole	\N
8207	92	Lalande-de-Pomerol	AOC -	AOP -	{"fra": "Lalande-de-Pomerol"}	Lalande-de-Pomerol	\N
7858	2037	Landes	\N	IGP -	{"fra": "Landes blanc"}	Landes blanc	\N
8595	2037	Landes	\N	IGP -	{"fra": "Landes rosé"}	Landes rosé	\N
8596	2037	Landes	\N	IGP -	{"fra": "Landes rouge"}	Landes rouge	\N
10900	2037	Landes	\N	IGP -	{"fra": "Landes surmûri blanc"}	Landes surmûri blanc	\N
10901	2037	Landes	\N	IGP -	{"fra": "Landes mousseux de qualité blanc"}	Landes mousseux de qualité blanc	\N
10902	2037	Landes	\N	IGP -	{"fra": "Landes mousseux de qualité rosé"}	Landes mousseux de qualité rosé	\N
10903	2037	Landes	\N	IGP -	{"fra": "Landes mousseux de qualité rouge"}	Landes mousseux de qualité rouge	\N
10904	2037	Landes	\N	IGP -	{"fra": "Landes primeur ou nouveau blanc"}	Landes primeur ou nouveau blanc	\N
10905	2037	Landes	\N	IGP -	{"fra": "Landes primeur ou nouveau rosé"}	Landes primeur ou nouveau rosé	\N
10906	2037	Landes	\N	IGP -	{"fra": "Landes primeur ou nouveau rouge"}	Landes primeur ou nouveau rouge	\N
10907	2241	Landes Coteaux de Chalosse	\N	IGP -	{"fra": "Landes Coteaux de Chalosse blanc"}	Landes Coteaux de Chalosse blanc	\N
10910	2241	Landes Coteaux de Chalosse	\N	IGP -	{"fra": "Landes Coteaux de Chalosse rosé"}	Landes Coteaux de Chalosse rosé	\N
10911	2241	Landes Coteaux de Chalosse	\N	IGP -	{"fra": "Landes Coteaux de Chalosse rouge"}	Landes Coteaux de Chalosse rouge	\N
10912	2241	Landes Coteaux de Chalosse	\N	IGP -	{"fra": "Landes Coteaux de Chalosse surmûri blanc"}	Landes Coteaux de Chalosse surmûri blanc	\N
10913	2241	Landes Coteaux de Chalosse	\N	IGP -	{"fra": "Landes Coteaux de Chalosse mousseux de qualité blanc"}	Landes Coteaux de Chalosse mousseux de qualité blanc	\N
10914	2241	Landes Coteaux de Chalosse	\N	IGP -	{"fra": "Landes Coteaux de Chalosse mousseux de qualité rosé"}	Landes Coteaux de Chalosse mousseux de qualité rosé	\N
10915	2241	Landes Coteaux de Chalosse	\N	IGP -	{"fra": "Landes Coteaux de Chalosse mousseux de qualité rouge"}	Landes Coteaux de Chalosse mousseux de qualité rouge	\N
10916	2241	Landes Coteaux de Chalosse	\N	IGP -	{"fra": "Landes Coteaux de Chalosse primeur ou nouveau blanc"}	Landes Coteaux de Chalosse primeur ou nouveau blanc	\N
10917	2241	Landes Coteaux de Chalosse	\N	IGP -	{"fra": "Landes Coteaux de Chalosse primeur ou nouveau rosé"}	Landes Coteaux de Chalosse primeur ou nouveau rosé	\N
10918	2241	Landes Coteaux de Chalosse	\N	IGP -	{"fra": "Landes Coteaux de Chalosse primeur ou nouveau rouge"}	Landes Coteaux de Chalosse primeur ou nouveau rouge	\N
10908	2242	Landes Côtes de l'Adour	\N	IGP -	{"fra": "Landes Côtes de l'Adour blanc"}	Landes Côtes de l'Adour blanc	\N
10919	2242	Landes Côtes de l'Adour	\N	IGP -	{"fra": "Landes Côtes de l'Adour rosé"}	Landes Côtes de l'Adour rosé	\N
10920	2242	Landes Côtes de l'Adour	\N	IGP -	{"fra": "Landes Côtes de l'Adour rouge"}	Landes Côtes de l'Adour rouge	\N
10921	2242	Landes Côtes de l'Adour	\N	IGP -	{"fra": "Landes Côtes de l'Adour surmûri blanc"}	Landes Côtes de l'Adour surmûri blanc	\N
10922	2242	Landes Côtes de l'Adour	\N	IGP -	{"fra": "Landes Côtes de l'Adour mousseux de qualité blanc"}	Landes Côtes de l'Adour mousseux de qualité blanc	\N
10923	2242	Landes Côtes de l'Adour	\N	IGP -	{"fra": "Landes Côtes de l'Adour mousseux de qualité rosé"}	Landes Côtes de l'Adour mousseux de qualité rosé	\N
10924	2242	Landes Côtes de l'Adour	\N	IGP -	{"fra": "Landes Côtes de l'Adour mousseux de qualité rouge"}	Landes Côtes de l'Adour mousseux de qualité rouge	\N
10925	2242	Landes Côtes de l'Adour	\N	IGP -	{"fra": "Landes Côtes de l'Adour primeur ou nouveau blanc"}	Landes Côtes de l'Adour primeur ou nouveau blanc	\N
10926	2242	Landes Côtes de l'Adour	\N	IGP -	{"fra": "Landes Côtes de l'Adour primeur ou nouveau rosé"}	Landes Côtes de l'Adour primeur ou nouveau rosé	\N
10927	2242	Landes Côtes de l'Adour	\N	IGP -	{"fra": "Landes Côtes de l'Adour primeur ou nouveau rouge"}	Landes Côtes de l'Adour primeur ou nouveau rouge	\N
10909	2243	Landes Sables de l'Océan	\N	IGP -	{"fra": "Landes Sables de l'Océan blanc"}	Landes Sables de l'Océan blanc	\N
10928	2243	Landes Sables de l'Océan	\N	IGP -	{"fra": "Landes Sables de l'Océan rosé"}	Landes Sables de l'Océan rosé	\N
10929	2243	Landes Sables de l'Océan	\N	IGP -	{"fra": "Landes Sables de l'Océan rouge"}	Landes Sables de l'Océan rouge	\N
10930	2243	Landes Sables de l'Océan	\N	IGP -	{"fra": "Landes Sables de l'Océan surmûri blanc"}	Landes Sables de l'Océan surmûri blanc	\N
10931	2243	Landes Sables de l'Océan	\N	IGP -	{"fra": "Landes Sables de l'Océan mousseux de qualité blanc"}	Landes Sables de l'Océan mousseux de qualité blanc	\N
10932	2243	Landes Sables de l'Océan	\N	IGP -	{"fra": "Landes Sables de l'Océan mousseux de qualité rosé"}	Landes Sables de l'Océan mousseux de qualité rosé	\N
10933	2243	Landes Sables de l'Océan	\N	IGP -	{"fra": "Landes Sables de l'Océan primeur ou nouveau blanc"}	Landes Sables de l'Océan primeur ou nouveau blanc	\N
10934	2243	Landes Sables de l'Océan	\N	IGP -	{"fra": "Landes Sables de l'Océan primeur ou nouveau rosé"}	Landes Sables de l'Océan primeur ou nouveau rosé	\N
10935	2243	Landes Sables de l'Océan	\N	IGP -	{"fra": "Landes Sables de l'Océan primeur ou nouveau rouge"}	Landes Sables de l'Océan primeur ou nouveau rouge	\N
10936	2244	Landes Sables fauves	\N	IGP -	{"fra": "Landes Sables fauves blanc"}	Landes Sables fauves blanc	\N
10937	2244	Landes Sables fauves	\N	IGP -	{"fra": "Landes Sables fauves rosé"}	Landes Sables fauves rosé	\N
10938	2244	Landes Sables fauves	\N	IGP -	{"fra": "Landes Sables fauves rouge"}	Landes Sables fauves rouge	\N
10939	2244	Landes Sables fauves	\N	IGP -	{"fra": "Landes Sables fauves surmûri blanc"}	Landes Sables fauves surmûri blanc	\N
10940	2244	Landes Sables fauves	\N	IGP -	{"fra": "Landes Sables fauves mousseux de qualité blanc"}	Landes Sables fauves mousseux de qualité blanc	\N
10941	2244	Landes Sables fauves	\N	IGP -	{"fra": "Landes Sables fauves mousseux de qualité rosé"}	Landes Sables fauves mousseux de qualité rosé	\N
10942	2244	Landes Sables fauves	\N	IGP -	{"fra": "Landes Sables fauves mousseux de qualité rouge"}	Landes Sables fauves mousseux de qualité rouge	\N
10943	2244	Landes Sables fauves	\N	IGP -	{"fra": "Landes Sables fauves primeur ou nouveau blanc"}	Landes Sables fauves primeur ou nouveau blanc	\N
10944	2244	Landes Sables fauves	\N	IGP -	{"fra": "Landes Sables fauves primeur ou nouveau rosé"}	Landes Sables fauves primeur ou nouveau rosé	\N
10945	2244	Landes Sables fauves	\N	IGP -	{"fra": "Landes Sables fauves primeur ou nouveau rouge"}	Landes Sables fauves primeur ou nouveau rouge	\N
4202	1471	Langres	AOC -	AOP -	{"fra": "Langres"}	Langres	\N
15919	2352	Languedoc	AOC -	AOP -	{"fra": "Languedoc primeur ou nouveau rosé"}	Languedoc primeur ou nouveau rosé	\N
15920	2352	Languedoc	AOC -	AOP -	{"fra": "Languedoc primeur ou nouveau rouge"}	Languedoc primeur ou nouveau rouge	\N
15922	2352	Languedoc	AOC -	AOP -	{"fra": "Languedoc rosé"}	Languedoc rosé	\N
15923	2352	Languedoc	AOC -	AOP -	{"fra": "Languedoc rouge"}	Languedoc rouge	\N
15912	1265	Languedoc blanc	AOC -	AOP -	{"fra": "Languedoc blanc"}	Languedoc blanc	\N
15913	1253	Languedoc Cabrières	AOC -	AOP -	{"fra": "Languedoc Cabrières rosé"}	Languedoc Cabrières rosé	\N
15914	1253	Languedoc Cabrières	AOC -	AOP -	{"fra": "Languedoc Cabrières rouge"}	Languedoc Cabrières rouge	\N
15915	1517	Languedoc Grès de Montpellier	AOC -	AOP -	{"fra": "Languedoc Grès de Montpellier"}	Languedoc Grès de Montpellier	\N
15916	1255	Languedoc La Méjanelle	AOC -	AOP -	{"fra": "Languedoc La Méjanelle rouge"}	Languedoc La Méjanelle rouge	\N
15917	1256	Languedoc Montpeyroux	AOC -	AOP -	{"fra": "Languedoc Montpeyroux rouge"}	Languedoc Montpeyroux rouge	\N
15918	1654	Languedoc Pézenas	AOC -	AOP -	{"fra": "Languedoc Pézenas"}	Languedoc Pézenas	\N
15921	1259	Languedoc Quatourze	AOC -	AOP -	{"fra": "Languedoc Quatourze rouge"}	Languedoc Quatourze rouge	\N
15924	1260	Languedoc Saint-Christol	AOC -	AOP -	{"fra": "Languedoc Saint-Christol rouge"}	Languedoc Saint-Christol rouge	\N
15925	1261	Languedoc Saint-Drézéry	AOC -	AOP -	{"fra": "Languedoc Saint-Drézéry rouge"}	Languedoc Saint-Drézéry rouge	\N
15926	1262	Languedoc Saint-Georges-d'Orques	AOC -	AOP -	{"fra": "Languedoc Saint-Georges-d'Orques rouge"}	Languedoc Saint-Georges-d'Orques rouge	\N
15927	1263	Languedoc Saint-Saturnin	AOC -	AOP -	{"fra": "Languedoc Saint-Saturnin rouge"}	Languedoc Saint-Saturnin rouge	\N
15928	1856	Languedoc Sommières	AOC -	AOP -	{"fra": "Languedoc Sommières"}	Languedoc Sommières	\N
7722	619	Latricières-Chambertin	AOC -	AOP -	{"fra": "Latricières-Chambertin"}	Latricières-Chambertin	\N
8865	1718	Lavilledieu	\N	IGP -	{"fra": "Lavilledieu Rosé"}	Lavilledieu Rosé	\N
8866	1718	Lavilledieu	\N	IGP -	{"fra": "Lavilledieu Rouge"}	Lavilledieu Rouge	\N
14149	1503	Lentille verte du Puy	AOC -	AOP -	{"fra": "Lentille verte du Puy"}	Lentille verte du Puy	\N
4579	1535	Lentilles vertes du Berry	\N	IGP -	{"fra": "Lentilles vertes du Berry"}	Lentilles vertes du Berry	IG/08/95
7762	1331	Les Baux de Provence	AOC -	AOP -	{"fra": "Les Baux de Provence rosé"}	Les Baux de Provence rosé	\N
8934	1331	Les Baux de Provence	AOC -	AOP -	{"fra": "Les Baux de Provence rouge"}	Les Baux de Provence rouge	\N
10198	1331	Les Baux de Provence	AOC -	AOP -	{"fra": "Les Baux de Provence blanc"}	Les Baux de Provence blanc	\N
9585	1235	Limoux	AOC -	AOP -	{"fra": "Limoux blanc"}	Limoux blanc	\N
9586	1235	Limoux	AOC -	AOP -	{"fra": "Limoux blanquette de Limoux"}	Limoux blanquette de Limoux	\N
9587	1235	Limoux	AOC -	AOP -	{"fra": "Limoux méthode ancestrale"}	Limoux méthode ancestrale	\N
9588	1235	Limoux	AOC -	AOP -	{"fra": "Limoux rouge"}	Limoux rouge	\N
12987	1669	Lingot du Nord	\N	IGP -	{"fra": "Lingot du Nord"}	Lingot du Nord	IG/15/97
14643	1309	Lirac	AOC -	AOP -	{"fra": "Lirac blanc"}	Lirac blanc	\N
14644	1309	Lirac	AOC -	AOP -	{"fra": "Lirac rosé"}	Lirac rosé	\N
14645	1309	Lirac	AOC -	AOP -	{"fra": "Lirac rouge"}	Lirac rouge	\N
8570	93	Listrac-Médoc	AOC -	AOP -	{"fra": "Listrac-Médoc"}	Listrac-Médoc	\N
4593	1472	Livarot	AOC -	AOP -	{"fra": "Livarot"}	Livarot	\N
4268	2140	Lonzo de Corse ou Lonzo de Corse - Lonzu	AOC -	AOP -	{"fra": "Lonzo de Corse ou Lonzo de Corse - Lonzu"}	Lonzo de Corse ou Lonzo de Corse - Lonzu	\N
7874	2043	Lot	\N	IGP -	{"fra": "Côtes du Lot blanc"}	Côtes du Lot blanc	\N
8443	2043	Lot	\N	IGP -	{"fra": "Côtes du Lot rosé"}	Côtes du Lot rosé	\N
8444	2043	Lot	\N	IGP -	{"fra": "Côtes du Lot rouge"}	Côtes du Lot rouge	\N
10946	2043	Lot	\N	IGP -	{"fra": "Côtes du Lot mousseux de qualité blanc"}	Côtes du Lot mousseux de qualité blanc	\N
10947	2043	Lot	\N	IGP -	{"fra": "Côtes du Lot mousseux de qualité rosé"}	Côtes du Lot mousseux de qualité rosé	\N
10948	2043	Lot	\N	IGP -	{"fra": "Côtes du Lot primeur ou nouveau blanc"}	Côtes du Lot primeur ou nouveau blanc	\N
10949	2043	Lot	\N	IGP -	{"fra": "Côtes du Lot primeur ou nouveau rosé"}	Côtes du Lot primeur ou nouveau rosé	\N
10950	2043	Lot	\N	IGP -	{"fra": "Côtes du Lot primeur ou nouveau rouge"}	Côtes du Lot primeur ou nouveau rouge	\N
8307	94	Loupiac	AOC -	AOP -	{"fra": "Loupiac"}	Loupiac	\N
14875	1862	Luberon	AOC -	AOP -	{"fra": "Luberon blanc"}	Luberon blanc	\N
14876	1862	Luberon	AOC -	AOP -	{"fra": "Luberon rosé"}	Luberon rosé	\N
14877	1862	Luberon	AOC -	AOP -	{"fra": "Luberon rouge"}	Luberon rouge	\N
4269	1678	Lucques du Languedoc	AOC -	AOP -	{"fra": "Lucques du Languedoc"}	Lucques du Languedoc	\N
14978	95	Lussac-Saint-Emilion	AOC -	AOP -	{"fra": "Lussac-Saint-Emilion"}	Lussac-Saint-Emilion	\N
14036	1536	Mâche nantaise	\N	IGP -	{"fra": "Mâche nantaise"}	Mâche nantaise	IG/09/96
15467	2216	Mâcon	AOC -	AOP -	{"fra": "Mâcon blanc"}	Mâcon blanc	\N
15468	2216	Mâcon	AOC -	AOP -	{"fra": "Mâcon blanc primeur ou nouveau"}	Mâcon blanc primeur ou nouveau	\N
15469	2216	Mâcon	AOC -	AOP -	{"fra": "Mâcon rouge"}	Mâcon rouge	\N
15470	2216	Mâcon	AOC -	AOP -	{"fra": "Mâcon rosé"}	Mâcon rosé	\N
15471	2216	Mâcon	AOC -	AOP -	{"fra": "Mâcon rosé primeur ou nouveau"}	Mâcon rosé primeur ou nouveau	\N
15472	622	Mâcon Azé	AOC -	AOP -	{"fra": "Mâcon Azé blanc"}	Mâcon Azé blanc	\N
15473	622	Mâcon Azé	AOC -	AOP -	{"fra": "Mâcon Azé rosé"}	Mâcon Azé rosé	\N
15474	622	Mâcon Azé	AOC -	AOP -	{"fra": "Mâcon Azé rouge"}	Mâcon Azé rouge	\N
15475	622	Mâcon Azé	AOC -	AOP -	{"fra": "Mâcon Azé blanc primeur ou nouveau"}	Mâcon Azé blanc primeur ou nouveau	\N
15476	1629	Mâcon Bray	AOC -	AOP -	{"fra": "Mâcon Bray blanc"}	Mâcon Bray blanc	\N
15477	1629	Mâcon Bray	AOC -	AOP -	{"fra": "Mâcon Bray blanc primeur ou nouveau"}	Mâcon Bray blanc primeur ou nouveau	\N
15478	1629	Mâcon Bray	AOC -	AOP -	{"fra": "Mâcon Bray rosé"}	Mâcon Bray rosé	\N
15479	1629	Mâcon Bray	AOC -	AOP -	{"fra": "Mâcon Bray rouge"}	Mâcon Bray rouge	\N
15480	626	Mâcon Burgy	AOC -	AOP -	{"fra": "Mâcon Burgy blanc"}	Mâcon Burgy blanc	\N
15481	626	Mâcon Burgy	AOC -	AOP -	{"fra": "Mâcon Burgy blanc primeur ou nouveau"}	Mâcon Burgy blanc primeur ou nouveau	\N
15482	671	Mâcon Burgy	AOC -	AOP -	{"fra": "Mâcon Burgy rosé"}	Mâcon Burgy rosé	\N
15483	671	Mâcon Burgy	AOC -	AOP -	{"fra": "Mâcon Burgy rouge"}	Mâcon Burgy rouge	\N
15484	627	Mâcon Bussières	AOC -	AOP -	{"fra": "Mâcon Bussières blanc"}	Mâcon Bussières blanc	\N
15485	627	Mâcon Bussières	AOC -	AOP -	{"fra": "Mâcon Bussières blanc primeur ou nouveau"}	Mâcon Bussières blanc primeur ou nouveau	\N
15486	627	Mâcon Bussières	AOC -	AOP -	{"fra": "Mâcon Bussières rosé"}	Mâcon Bussières rosé	\N
15487	627	Mâcon Bussières	AOC -	AOP -	{"fra": "Mâcon Bussières rouge"}	Mâcon Bussières rouge	\N
15488	1631	Mâcon Chaintré	AOC -	AOP -	{"fra": "Mâcon Chaintré blanc"}	Mâcon Chaintré blanc	\N
15489	1631	Mâcon Chaintré	AOC -	AOP -	{"fra": "Mâcon Chaintré blanc primeur ou nouveau"}	Mâcon Chaintré blanc primeur ou nouveau	\N
15490	1631	Mâcon Chaintré	AOC -	AOP -	{"fra": "Mâcon Chaintré rosé"}	Mâcon Chaintré rosé	\N
15491	1631	Mâcon Chaintré	AOC -	AOP -	{"fra": "Mâcon Chaintré rouge"}	Mâcon Chaintré rouge	\N
15492	630	Mâcon Chardonnay	AOC -	AOP -	{"fra": "Mâcon Chardonnay blanc"}	Mâcon Chardonnay blanc	\N
15493	630	Mâcon Chardonnay	AOC -	AOP -	{"fra": "Mâcon Chardonnay blanc primeur ou nouveau"}	Mâcon Chardonnay blanc primeur ou nouveau	\N
15494	630	Mâcon Chardonnay	AOC -	AOP -	{"fra": "Mâcon Chardonnay rosé"}	Mâcon Chardonnay rosé	\N
15495	630	Mâcon Chardonnay	AOC -	AOP -	{"fra": "Mâcon Chardonnay rouge"}	Mâcon Chardonnay rouge	\N
15496	631	Mâcon Charnay-lès-Mâcon	AOC -	AOP -	{"fra": "Mâcon Charnay-lès-Mâcon blanc"}	Mâcon Charnay-lès-Mâcon blanc	\N
15497	631	Mâcon Charnay-lès-Mâcon	AOC -	AOP -	{"fra": "Mâcon Charnay-lès-Mâcon blanc primeur ou nouveau"}	Mâcon Charnay-lès-Mâcon blanc primeur ou nouveau	\N
15498	631	Mâcon Charnay-lès-Mâcon	AOC -	AOP -	{"fra": "Mâcon Charnay-lès-Mâcon rosé"}	Mâcon Charnay-lès-Mâcon rosé	\N
15499	631	Mâcon Charnay-lès-Mâcon	AOC -	AOP -	{"fra": "Mâcon Charnay-lès-Mâcon rouge"}	Mâcon Charnay-lès-Mâcon rouge	\N
15500	636	Mâcon Cruzille	AOC -	AOP -	{"fra": "Mâcon Cruzille blanc"}	Mâcon Cruzille blanc	\N
15501	636	Mâcon Cruzille	AOC -	AOP -	{"fra": "Mâcon Cruzille blanc primeur ou nouveau"}	Mâcon Cruzille blanc primeur ou nouveau	\N
15502	636	Mâcon Cruzille	AOC -	AOP -	{"fra": "Mâcon Cruzille rosé"}	Mâcon Cruzille rosé	\N
15503	636	Mâcon Cruzille	AOC -	AOP -	{"fra": "Mâcon Cruzille rouge"}	Mâcon Cruzille rouge	\N
15504	637	Mâcon Davayé	AOC -	AOP -	{"fra": "Mâcon Davayé blanc"}	Mâcon Davayé blanc	\N
15505	637	Mâcon Davayé	AOC -	AOP -	{"fra": "Mâcon Davayé blanc primeur ou nouveau"}	Mâcon Davayé blanc primeur ou nouveau	\N
15506	637	Mâcon Davayé	AOC -	AOP -	{"fra": "Mâcon Davayé rosé"}	Mâcon Davayé rosé	\N
15507	637	Mâcon Davayé	AOC -	AOP -	{"fra": "Mâcon Davayé rouge"}	Mâcon Davayé rouge	\N
15508	638	Mâcon Fuissé	AOC -	AOP -	{"fra": "Mâcon Fuissé blanc"}	Mâcon Fuissé blanc	\N
15509	638	Mâcon Fuissé	AOC -	AOP -	{"fra": "Mâcon Fuissé blanc primeur ou nouveau"}	Mâcon Fuissé blanc primeur ou nouveau	\N
15510	641	Mâcon Igé	AOC -	AOP -	{"fra": "Mâcon Igé blanc"}	Mâcon Igé blanc	\N
15511	641	Mâcon Igé	AOC -	AOP -	{"fra": "Mâcon Igé blanc primeur ou nouveau"}	Mâcon Igé blanc primeur ou nouveau	\N
15512	641	Mâcon Igé	AOC -	AOP -	{"fra": "Mâcon Igé rosé"}	Mâcon Igé rosé	\N
15513	641	Mâcon Igé	AOC -	AOP -	{"fra": "Mâcon Igé rouge"}	Mâcon Igé rouge	\N
15514	642	Mâcon La Roche-Vineuse	AOC -	AOP -	{"fra": "Mâcon La Roche-Vineuse blanc"}	Mâcon La Roche-Vineuse blanc	\N
15515	642	Mâcon La Roche-Vineuse	AOC -	AOP -	{"fra": "Mâcon La Roche-Vineuse blanc primeur ou nouveau"}	Mâcon La Roche-Vineuse blanc primeur ou nouveau	\N
15516	642	Mâcon La Roche-Vineuse	AOC -	AOP -	{"fra": "Mâcon La Roche-Vineuse rosé"}	Mâcon La Roche-Vineuse rosé	\N
15517	642	Mâcon La Roche-Vineuse	AOC -	AOP -	{"fra": "Mâcon La Roche-Vineuse rouge"}	Mâcon La Roche-Vineuse rouge	\N
15518	644	Mâcon Loché	AOC -	AOP -	{"fra": "Mâcon Loché blanc"}	Mâcon Loché blanc	\N
15519	644	Mâcon Loché	AOC -	AOP -	{"fra": "Mâcon Loché blanc primeur ou nouveau"}	Mâcon Loché blanc primeur ou nouveau	\N
15520	645	Mâcon Lugny	AOC -	AOP -	{"fra": "Mâcon Lugny blanc"}	Mâcon Lugny blanc	\N
15521	645	Mâcon Lugny	AOC -	AOP -	{"fra": "Mâcon Lugny blanc primeur ou nouveau"}	Mâcon Lugny blanc primeur ou nouveau	\N
15522	645	Mâcon Lugny	AOC -	AOP -	{"fra": "Mâcon Lugny rosé"}	Mâcon Lugny rosé	\N
15523	645	Mâcon Lugny	AOC -	AOP -	{"fra": "Mâcon Lugny rouge"}	Mâcon Lugny rouge	\N
15524	715	Mâcon Mancey	AOC -	AOP -	{"fra": "Mâcon Mancey blanc"}	Mâcon Mancey blanc	\N
15525	715	Mâcon Mancey	AOC -	AOP -	{"fra": "Mâcon Mancey blanc primeur ou nouveau"}	Mâcon Mancey blanc primeur ou nouveau	\N
15526	715	Mâcon Mancey	AOC -	AOP -	{"fra": "Mâcon Mancey rosé"}	Mâcon Mancey rosé	\N
15527	715	Mâcon Mancey	AOC -	AOP -	{"fra": "Mâcon Mancey rouge"}	Mâcon Mancey rouge	\N
15528	646	Mâcon Milly-Lamartine	AOC -	AOP -	{"fra": "Mâcon Milly-Lamartine blanc"}	Mâcon Milly-Lamartine blanc	\N
15529	646	Mâcon Milly-Lamartine	AOC -	AOP -	{"fra": "Mâcon Milly-Lamartine blanc primeur ou nouveau"}	Mâcon Milly-Lamartine blanc primeur ou nouveau	\N
15530	646	Mâcon Milly-Lamartine	AOC -	AOP -	{"fra": "Mâcon Milly-Lamartine rosé"}	Mâcon Milly-Lamartine rosé	\N
15531	646	Mâcon Milly-Lamartine	AOC -	AOP -	{"fra": "Mâcon Milly-Lamartine rouge"}	Mâcon Milly-Lamartine rouge	\N
15532	647	Mâcon Montbellet	AOC -	AOP -	{"fra": "Mâcon Montbellet blanc"}	Mâcon Montbellet blanc	\N
15533	647	Mâcon Montbellet	AOC -	AOP -	{"fra": "Mâcon Montbellet blanc primeur ou nouveau"}	Mâcon Montbellet blanc primeur ou nouveau	\N
15534	648	Mâcon Péronne	AOC -	AOP -	{"fra": "Mâcon Péronne blanc"}	Mâcon Péronne blanc	\N
15535	648	Mâcon Péronne	AOC -	AOP -	{"fra": "Mâcon Péronne blanc primeur ou nouveau"}	Mâcon Péronne blanc primeur ou nouveau	\N
15536	648	Mâcon Péronne	AOC -	AOP -	{"fra": "Mâcon Péronne rosé"}	Mâcon Péronne rosé	\N
15537	648	Mâcon Péronne	AOC -	AOP -	{"fra": "Mâcon Péronne rouge"}	Mâcon Péronne rouge	\N
15538	649	Mâcon Pierreclos	AOC -	AOP -	{"fra": "Mâcon Pierreclos blanc"}	Mâcon Pierreclos blanc	\N
15539	649	Mâcon Pierreclos	AOC -	AOP -	{"fra": "Mâcon Pierreclos blanc primeur ou nouveau"}	Mâcon Pierreclos blanc primeur ou nouveau	\N
15540	649	Mâcon Pierreclos	AOC -	AOP -	{"fra": "Mâcon Pierreclos rosé"}	Mâcon Pierreclos rosé	\N
15541	649	Mâcon Pierreclos	AOC -	AOP -	{"fra": "Mâcon Pierreclos rouge"}	Mâcon Pierreclos rouge	\N
15542	650	Mâcon Prissé	AOC -	AOP -	{"fra": "Mâcon Prissé blanc"}	Mâcon Prissé blanc	\N
15543	650	Mâcon Prissé	AOC -	AOP -	{"fra": "Mâcon Prissé blanc primeur ou nouveau"}	Mâcon Prissé blanc primeur ou nouveau	\N
15544	650	Mâcon Prissé	AOC -	AOP -	{"fra": "Mâcon Prissé rosé"}	Mâcon Prissé rosé	\N
15545	650	Mâcon Prissé	AOC -	AOP -	{"fra": "Mâcon Prissé rouge"}	Mâcon Prissé rouge	\N
15546	730	Mâcon Saint-Gengoux-le-National	AOC -	AOP -	{"fra": "Mâcon Saint-Gengoux-le-National blanc"}	Mâcon Saint-Gengoux-le-National blanc	\N
15547	730	Mâcon Saint-Gengoux-le-National	AOC -	AOP -	{"fra": "Mâcon Saint-Gengoux-le-National blanc primeur ou nouveau"}	Mâcon Saint-Gengoux-le-National blanc primeur ou nouveau	\N
15548	730	Mâcon Saint-Gengoux-le-National	AOC -	AOP -	{"fra": "Mâcon Saint-Gengoux-le-National rosé"}	Mâcon Saint-Gengoux-le-National rosé	\N
15549	730	Mâcon Saint-Gengoux-le-National	AOC -	AOP -	{"fra": "Mâcon Saint-Gengoux-le-National rouge"}	Mâcon Saint-Gengoux-le-National rouge	\N
15550	738	Mâcon Serrières	AOC -	AOP -	{"fra": "Mâcon Serrières rosé"}	Mâcon Serrières rosé	\N
15551	738	Mâcon Serrières	AOC -	AOP -	{"fra": "Mâcon Serrières rouge"}	Mâcon Serrières rouge	\N
15552	653	Mâcon Solutré-Pouilly	AOC -	AOP -	{"fra": "Mâcon Solutré-Pouilly blanc"}	Mâcon Solutré-Pouilly blanc	\N
15553	653	Mâcon Solutré-Pouilly	AOC -	AOP -	{"fra": "Mâcon Solutré-Pouilly blanc primeur ou nouveau"}	Mâcon Solutré-Pouilly blanc primeur ou nouveau	\N
15554	654	Mâcon Uchizy	AOC -	AOP -	{"fra": "Mâcon Uchizy blanc"}	Mâcon Uchizy blanc	\N
15555	654	Mâcon Uchizy	AOC -	AOP -	{"fra": "Mâcon Uchizy blanc primeur ou nouveau"}	Mâcon Uchizy blanc primeur ou nouveau	\N
15556	655	Mâcon Vergisson	AOC -	AOP -	{"fra": "Mâcon Vergisson blanc"}	Mâcon Vergisson blanc	\N
15557	655	Mâcon Vergisson	AOC -	AOP -	{"fra": "Mâcon Vergisson blanc primeur ou nouveau"}	Mâcon Vergisson blanc primeur ou nouveau	\N
15558	656	Mâcon Verzé	AOC -	AOP -	{"fra": "Mâcon Verzé blanc"}	Mâcon Verzé blanc	\N
15559	656	Mâcon Verzé	AOC -	AOP -	{"fra": "Mâcon Verzé blanc primeur ou nouveau"}	Mâcon Verzé blanc primeur ou nouveau	\N
15560	656	Mâcon Verzé	AOC -	AOP -	{"fra": "Mâcon Verzé rosé"}	Mâcon Verzé rosé	\N
15561	656	Mâcon Verzé	AOC -	AOP -	{"fra": "Mâcon Verzé rouge"}	Mâcon Verzé rouge	\N
15562	1630	Mâcon Villages	AOC -	AOP -	{"fra": "Mâcon Villages"}	Mâcon Villages	\N
15563	1630	Mâcon Villages	AOC -	AOP -	{"fra": "Mâcon Villages primeur ou nouveau"}	Mâcon Villages primeur ou nouveau	\N
15564	657	Mâcon Vinzelles	AOC -	AOP -	{"fra": "Mâcon Vinzelles blanc"}	Mâcon Vinzelles blanc	\N
15565	657	Mâcon Vinzelles	AOC -	AOP -	{"fra": "Mâcon Vinzelles blanc primeur ou nouveau"}	Mâcon Vinzelles blanc primeur ou nouveau	\N
7110	1643	Mâconnais	AOC -	AOP -	{"fra": "Mâconnais"}	Mâconnais	\N
7976	1874	Macvin du Jura	AOC -	AOP -	{"fra": "Macvin du Jura blanc"}	Macvin du Jura blanc	\N
7977	1874	Macvin du Jura	AOC -	AOP -	{"fra": "Macvin du Jura rosé"}	Macvin du Jura rosé	\N
7978	1874	Macvin du Jura	AOC -	AOP -	{"fra": "Macvin du Jura rouge"}	Macvin du Jura rouge	\N
13315	96	Madiran	AOC -	AOP -	{"fra": "Madiran"}	Madiran	\N
3479	1609	Maine-Anjou	AOC -	AOP -	{"fra": "Maine-Anjou"}	Maine-Anjou	\N
7988	1414	Malepère	AOC -	AOP -	{"fra": "Malepère rosé"}	Malepère rosé	\N
7989	1414	Malepère	AOC -	AOP -	{"fra": "Malepère rouge"}	Malepère rouge	\N
7691	749	Maranges	AOC -	AOP -	{"fra": "Maranges"}	Maranges	\N
9141	749	Maranges	AOC -	AOP -	{"fra": "Maranges rouge ou Maranges Côte de Beaune"}	Maranges rouge ou Maranges Côte de Beaune	\N
9125	757	Maranges premier cru	AOC -	AOP -	{"fra": "Maranges premier cru blanc"}	Maranges premier cru blanc	\N
9140	757	Maranges premier cru	AOC -	AOP -	{"fra": "Maranges premier cru rouge"}	Maranges premier cru rouge	\N
9126	750	Maranges premier cru Clos de la Boutière	AOC -	AOP -	{"fra": "Maranges premier cru Clos de la Boutière blanc"}	Maranges premier cru Clos de la Boutière blanc	\N
9127	750	Maranges premier cru Clos de la Boutière	AOC -	AOP -	{"fra": "Maranges premier cru Clos de la Boutière rouge"}	Maranges premier cru Clos de la Boutière rouge	\N
9128	751	Maranges premier cru Clos de la Fussière	AOC -	AOP -	{"fra": "Maranges premier cru Clos de la Fussière blanc"}	Maranges premier cru Clos de la Fussière blanc	\N
9129	751	Maranges premier cru Clos de la Fussière	AOC -	AOP -	{"fra": "Maranges premier cru Clos de la Fussière rouge"}	Maranges premier cru Clos de la Fussière rouge	\N
9130	752	Maranges premier cru La Fussière	AOC -	AOP -	{"fra": "Maranges premier cru La Fussière blanc"}	Maranges premier cru La Fussière blanc	\N
9131	752	Maranges premier cru La Fussière	AOC -	AOP -	{"fra": "Maranges premier cru La Fussière rouge"}	Maranges premier cru La Fussière rouge	\N
9132	753	Maranges premier cru Le Clos des Loyères	AOC -	AOP -	{"fra": "Maranges premier cru Le Clos des Loyères blanc"}	Maranges premier cru Le Clos des Loyères blanc	\N
9133	753	Maranges premier cru Le Clos des Loyères	AOC -	AOP -	{"fra": "Maranges premier cru Le Clos des Loyères rouge"}	Maranges premier cru Le Clos des Loyères rouge	\N
9134	754	Maranges premier cru Le Clos des Rois	AOC -	AOP -	{"fra": "Maranges premier cru Le Clos des Rois blanc"}	Maranges premier cru Le Clos des Rois blanc	\N
9135	754	Maranges premier cru Le Clos des Rois	AOC -	AOP -	{"fra": "Maranges premier cru Le Clos des Rois rouge"}	Maranges premier cru Le Clos des Rois rouge	\N
9136	755	Maranges premier cru Le Croix Moines	AOC -	AOP -	{"fra": "Maranges premier cru Le Croix Moines blanc"}	Maranges premier cru Le Croix Moines blanc	\N
9137	755	Maranges premier cru Le Croix Moines	AOC -	AOP -	{"fra": "Maranges premier cru Le Croix Moines rouge"}	Maranges premier cru Le Croix Moines rouge	\N
9138	756	Maranges premier cru Les Clos Roussots	AOC -	AOP -	{"fra": "Maranges premier cru Les Clos Roussots blanc"}	Maranges premier cru Les Clos Roussots blanc	\N
9139	756	Maranges premier cru Les Clos Roussots	AOC -	AOP -	{"fra": "Maranges premier cru Les Clos Roussots rouge"}	Maranges premier cru Les Clos Roussots rouge	\N
13046	2132	Marc d'Alsace 	AOC -	IG - 	{"fra": "Marc d'Alsace Gewurztraminer "}	Marc d'Alsace Gewurztraminer 	\N
13117	2381	Marc d'Auvergne	\N	IG - 	{"fra": "Marc d'Auvergne"}	Marc d'Auvergne	\N
13047	1946	Marc de Bourgogne	AOC -	IG - 	{"fra": "Marc de Bourgogne"}	Marc de Bourgogne	\N
13109	1447	Marc de Champagne ou Marc champenois ou Eau-de-vie de marc champenois	\N	IG - 	{"fra": "Marc de Champagne ou Marc champenois ou Eau-de-vie de marc champenois"}	Marc de Champagne ou Marc champenois ou Eau-de-vie de marc champenois	\N
13123	2386	Marc de Provence ou Eau-de-vie de marc de Provence	\N	IG - 	{"fra": "Marc de Provence ou Eau-de-vie de marc de Provence"}	Marc de Provence ou Eau-de-vie de marc de Provence	\N
13118	2382	Marc de Savoie	\N	IG - 	{"fra": "Marc de Savoie"}	Marc de Savoie	\N
13111	2377	Marc des Côtes du Rhône ou Eau-de-vie de marc des Côtes du Rhône	\N	IG - 	{"fra": "Marc des Côtes du Rhône  ou  Eau-de-vie de marc des Côtes du Rhône"}	Marc des Côtes du Rhône  ou  Eau-de-vie de marc des Côtes du Rhône	\N
13119	2383	Marc du Bugey	\N	IG - 	{"fra": "Marc du Bugey"}	Marc du Bugey	\N
4328	1737	Marc du Jura	AOC -	IG - 	{"fra": "Marc du Jura"}	Marc du Jura	\N
13097	2368	Marc du Languedoc ou Eau-de-vie de marc du Languedoc	\N	IG - 	{"fra": "Marc du Languedoc ou Eau-de-vie de marc du Languedoc"}	Marc du Languedoc ou Eau-de-vie de marc du Languedoc	\N
8152	98	Marcillac	AOC -	AOP -	{"fra": "Marcillac rosé"}	Marcillac rosé	\N
8153	98	Marcillac	AOC -	AOP -	{"fra": "Marcillac rouge"}	Marcillac rouge	\N
7673	99	Margaux	AOC -	AOP -	{"fra": "Margaux"}	Margaux	\N
13200	1473	Maroilles	AOC -	AOP -	{"fra": "Maroilles ou Marolles"}	Maroilles ou Marolles	\N
5461	758	Marsannay	AOC -	AOP -	{"fra": "Marsannay blanc"}	Marsannay blanc	\N
8154	758	Marsannay	AOC -	AOP -	{"fra": "Marsannay rosé"}	Marsannay rosé	\N
8155	758	Marsannay	AOC -	AOP -	{"fra": "Marsannay rouge"}	Marsannay rouge	\N
7834	2077	Maures	\N	IGP -	{"fra": "Maures blanc"}	Maures blanc	\N
8591	2077	Maures	\N	IGP -	{"fra": "Maures rosé"}	Maures rosé	\N
8592	2077	Maures	\N	IGP -	{"fra": "Maures rouge"}	Maures rouge	\N
10960	2077	Maures	\N	IGP -	{"fra": "Maures primeur ou nouveau blanc"}	Maures primeur ou nouveau blanc	\N
10961	2077	Maures	\N	IGP -	{"fra": "Maures primeur ou nouveau rosé"}	Maures primeur ou nouveau rosé	\N
10962	2077	Maures	\N	IGP -	{"fra": "Maures primeur ou nouveau rouge"}	Maures primeur ou nouveau rouge	\N
7765	1335	Maury	AOC -	AOP -	{"fra": "Maury blanc"}	Maury blanc	\N
9033	1335	Maury	AOC -	AOP -	{"fra": "Maury ambré"}	Maury ambré	\N
9034	1335	Maury	AOC -	AOP -	{"fra": "Maury ambré hors d'age"}	Maury ambré hors d'age	\N
9035	1335	Maury	AOC -	AOP -	{"fra": "Maury ambré rancio hors d'âge"}	Maury ambré rancio hors d'âge	\N
9036	1335	Maury	AOC -	AOP -	{"fra": "Maury ambré rancio"}	Maury ambré rancio	\N
9037	1335	Maury	AOC -	AOP -	{"fra": "Maury grenat"}	Maury grenat	\N
9038	1335	Maury	AOC -	AOP -	{"fra": "Maury tuilé"}	Maury tuilé	\N
9039	1335	Maury	AOC -	AOP -	{"fra": "Maury tuilé rancio hors d'âge"}	Maury tuilé rancio hors d'âge	\N
9040	1335	Maury	AOC -	AOP -	{"fra": "Maury tuilé hors d'âge"}	Maury tuilé hors d'âge	\N
9041	1335	Maury	AOC -	AOP -	{"fra": "Maury tuilé rancio"}	Maury tuilé rancio	\N
9042	1335	Maury	AOC -	AOP -	{"fra": "Maury rouge"}	Maury rouge	\N
7723	760	Mazis-Chambertin	AOC -	AOP -	{"fra": "Mazis-Chambertin"}	Mazis-Chambertin	\N
7724	761	Mazoyères-Chambertin	AOC -	AOP -	{"fra": "Mazoyères-Chambertin"}	Mazoyères-Chambertin	\N
14216	1968	Méditerranée	\N	IGP -	{"fra": "Méditerranée blanc"}	Méditerranée blanc	\N
14217	1968	Méditerranée	\N	IGP -	{"fra": "Méditerranée rosé"}	Méditerranée rosé	\N
14218	1968	Méditerranée	\N	IGP -	{"fra": "Méditerranée rouge"}	Méditerranée rouge	\N
14415	1968	Méditerranée	\N	IGP -	{"fra": "Méditerranée primeur ou nouveau rouge"}	Méditerranée primeur ou nouveau rouge	\N
14420	1968	Méditerranée	\N	IGP -	{"fra": "Méditerranée primeur ou nouveau rosé"}	Méditerranée primeur ou nouveau rosé	\N
14422	1968	Méditerranée	\N	IGP -	{"fra": "Méditerranée primeur ou nouveau blanc"}	Méditerranée primeur ou nouveau blanc	\N
14424	1968	Méditerranée	\N	IGP -	{"fra": "Méditerranée mousseux de qualité rouge"}	Méditerranée mousseux de qualité rouge	\N
14426	1968	Méditerranée	\N	IGP -	{"fra": "Méditerranée mousseux de qualité rosé"}	Méditerranée mousseux de qualité rosé	\N
14229	2246	Méditérranée Comté de Grignan	\N	IGP -	{"fra": "Méditérranée Comté de Grignan blanc"}	Méditérranée Comté de Grignan blanc	\N
14401	2246	Méditérranée Comté de Grignan	\N	IGP -	{"fra": "Méditérranée Comté de Grignan mousseux de qualité blanc"}	Méditérranée Comté de Grignan mousseux de qualité blanc	\N
14402	2246	Méditérranée Comté de Grignan	\N	IGP -	{"fra": "Méditérranée Comté de Grignan mousseux de qualité rosé"}	Méditérranée Comté de Grignan mousseux de qualité rosé	\N
14403	2246	Méditérranée Comté de Grignan	\N	IGP -	{"fra": "Méditérranée Comté de Grignan mousseux de qualité rouge"}	Méditérranée Comté de Grignan mousseux de qualité rouge	\N
14404	2246	Méditérranée Comté de Grignan	\N	IGP -	{"fra": "Méditérranée Comté de Grignan primeur ou nouveau blanc"}	Méditérranée Comté de Grignan primeur ou nouveau blanc	\N
14405	2246	Méditérranée Comté de Grignan	\N	IGP -	{"fra": "Méditérranée Comté de Grignan primeur ou nouveau rosé"}	Méditérranée Comté de Grignan primeur ou nouveau rosé	\N
14406	2246	Méditérranée Comté de Grignan	\N	IGP -	{"fra": "Méditérranée Comté de Grignan primeur ou nouveau rouge"}	Méditérranée Comté de Grignan primeur ou nouveau rouge	\N
14407	2246	Méditérranée Comté de Grignan	\N	IGP -	{"fra": "Méditérranée Comté de Grignan rosé"}	Méditérranée Comté de Grignan rosé	\N
14408	2246	Méditérranée Comté de Grignan	\N	IGP -	{"fra": "Méditérranée Comté de Grignan rouge"}	Méditérranée Comté de Grignan rouge	\N
14409	2247	Méditérranée Coteaux de Montélimar	\N	IGP -	{"fra": "Méditérranée Coteaux de Montélimar  mousseux de qualité rosé"}	Méditérranée Coteaux de Montélimar  mousseux de qualité rosé	\N
14410	2247	Méditérranée Coteaux de Montélimar	\N	IGP -	{"fra": "Méditérranée Coteaux de Montélimar blanc"}	Méditérranée Coteaux de Montélimar blanc	\N
14411	2247	Méditérranée Coteaux de Montélimar	\N	IGP -	{"fra": "Méditérranée Coteaux de Montélimar mousseux de qualité blanc"}	Méditérranée Coteaux de Montélimar mousseux de qualité blanc	\N
14412	2247	Méditérranée Coteaux de Montélimar	\N	IGP -	{"fra": "Méditérranée Coteaux de Montélimar mousseux de qualité rouge"}	Méditérranée Coteaux de Montélimar mousseux de qualité rouge	\N
14413	2247	Méditérranée Coteaux de Montélimar	\N	IGP -	{"fra": "Méditérranée Coteaux de Montélimar primeur ou nouveau blanc"}	Méditérranée Coteaux de Montélimar primeur ou nouveau blanc	\N
14414	2247	Méditérranée Coteaux de Montélimar	\N	IGP -	{"fra": "Méditérranée Coteaux de Montélimar primeur ou nouveau rosé"}	Méditérranée Coteaux de Montélimar primeur ou nouveau rosé	\N
14416	2247	Méditérranée Coteaux de Montélimar	\N	IGP -	{"fra": "Méditérranée Coteaux de Montélimar primeur ou nouveau rouge"}	Méditérranée Coteaux de Montélimar primeur ou nouveau rouge	\N
14417	2247	Méditérranée Coteaux de Montélimar	\N	IGP -	{"fra": "Méditérranée Coteaux de Montélimar rosé"}	Méditérranée Coteaux de Montélimar rosé	\N
14421	2247	Méditérranée Coteaux de Montélimar	\N	IGP -	{"fra": "Méditérranée Coteaux de Montélimar rouge"}	Méditérranée Coteaux de Montélimar rouge	\N
15113	2408	Méditerranée mousseux (Clairette de Die AOC)	\N	IGP -	{"fra": "Méditerranée mousseux de qualité blanc"}	Méditerranée mousseux de qualité blanc	\N
15209	100	Médoc	AOC -	AOP -	{"fra": "Médoc"}	Médoc	\N
3681	2131	Melon de Guadeloupe	\N	IGP -	{"fra": "Melon de Guadeloupe"}	Melon de Guadeloupe	\N
7795	1537	Melon du Haut Poitou	\N	IGP -	{"fra": "Melon du Haut Poitou"}	Melon du Haut Poitou	IG/14/95
14227	1606	Melon du Quercy	\N	IGP -	{"fra": "Melon du Quercy"}	Melon du Quercy	IG/19/96
7985	180	Menetou-Salon	AOC -	AOP -	{"fra": "Menetou-Salon blanc"}	Menetou-Salon blanc	\N
7986	180	Menetou-Salon	AOC -	AOP -	{"fra": "Menetou-Salon rosé"}	Menetou-Salon rosé	\N
7987	180	Menetou-Salon	AOC -	AOP -	{"fra": "Menetou-Salon rouge"}	Menetou-Salon rouge	\N
7739	762	Mercurey	AOC -	AOP -	{"fra": "Mercurey blanc"}	Mercurey blanc	\N
8085	762	Mercurey	AOC -	AOP -	{"fra": "Mercurey rouge"}	Mercurey rouge	\N
14234	2434	Mercurey Clos des Montaigus	AOC -	AOP -	{"fra": "Mercurey premier cru Clos des Montaigus blanc"}	Mercurey premier cru Clos des Montaigus blanc	\N
14236	2434	Mercurey Clos des Montaigus	AOC -	AOP -	{"fra": "Mercurey premier cru Clos du Château de Montaigu blanc"}	Mercurey premier cru Clos du Château de Montaigu blanc	\N
8023	795	Mercurey premier cru	AOC -	AOP -	{"fra": "Mercurey premier cru blanc"}	Mercurey premier cru blanc	\N
8082	795	Mercurey premier cru	AOC -	AOP -	{"fra": "Mercurey premier cru rouge"}	Mercurey premier cru rouge	\N
8024	766	Mercurey premier cru Clos de Paradis	AOC -	AOP -	{"fra": "Mercurey premier cru Clos de Paradis blanc"}	Mercurey premier cru Clos de Paradis blanc	\N
8025	766	Mercurey premier cru Clos de Paradis	AOC -	AOP -	{"fra": "Mercurey premier cru Clos de Paradis rouge"}	Mercurey premier cru Clos de Paradis rouge	\N
8026	767	Mercurey premier cru Clos des Barraults	AOC -	AOP -	{"fra": "Mercurey premier cru Clos des Barraults blanc"}	Mercurey premier cru Clos des Barraults blanc	\N
8027	767	Mercurey premier cru Clos des Barraults	AOC -	AOP -	{"fra": "Mercurey premier cru Clos des Barraults rouge"}	Mercurey premier cru Clos des Barraults rouge	\N
8028	768	Mercurey premier cru Clos des grands Voyens	AOC -	AOP -	{"fra": "Mercurey premier cru Clos des grands Voyens blanc"}	Mercurey premier cru Clos des grands Voyens blanc	\N
8029	768	Mercurey premier cru Clos des grands Voyens	AOC -	AOP -	{"fra": "Mercurey premier cru Clos des grands Voyens rouge"}	Mercurey premier cru Clos des grands Voyens rouge	\N
8030	770	Mercurey premier cru Clos des Myglands	AOC -	AOP -	{"fra": "Mercurey premier cru Clos des Myglands blanc"}	Mercurey premier cru Clos des Myglands blanc	\N
8031	770	Mercurey premier cru Clos des Myglands	AOC -	AOP -	{"fra": "Mercurey premier cru Clos des Myglands rouge"}	Mercurey premier cru Clos des Myglands rouge	\N
14237	771	Mercurey premier cru Clos du Château de Montaigu	AOC -	AOP -	{"fra": "Mercurey premier cru Clos du Château de Montaigu rouge"}	Mercurey premier cru Clos du Château de Montaigu rouge	\N
8032	763	Mercurey premier cru Clos Marcilly	AOC -	AOP -	{"fra": "Mercurey premier cru Clos Marcilly blanc"}	Mercurey premier cru Clos Marcilly blanc	\N
8033	763	Mercurey premier cru Clos Marcilly	AOC -	AOP -	{"fra": "Mercurey premier cru Clos Marcilly rouge"}	Mercurey premier cru Clos Marcilly rouge	\N
8034	764	Mercurey premier cru Clos Tonnerre	AOC -	AOP -	{"fra": "Mercurey premier cru Clos Tonnerre blanc"}	Mercurey premier cru Clos Tonnerre blanc	\N
8035	764	Mercurey premier cru Clos Tonnerre	AOC -	AOP -	{"fra": "Mercurey premier cru Clos Tonnerre rouge"}	Mercurey premier cru Clos Tonnerre rouge	\N
8036	765	Mercurey premier cru Clos Voyens	AOC -	AOP -	{"fra": "Mercurey premier cru Clos Voyens blanc"}	Mercurey premier cru Clos Voyens blanc	\N
8037	765	Mercurey premier cru Clos Voyens	AOC -	AOP -	{"fra": "Mercurey premier cru Clos Voyens rouge"}	Mercurey premier cru Clos Voyens rouge	\N
8038	772	Mercurey premier cru Grand Clos Fortoul	AOC -	AOP -	{"fra": "Mercurey premier cru Grand Clos Fortoul blanc"}	Mercurey premier cru Grand Clos Fortoul blanc	\N
8039	772	Mercurey premier cru Grand Clos Fortoul	AOC -	AOP -	{"fra": "Mercurey premier cru Grand Clos Fortoul rouge"}	Mercurey premier cru Grand Clos Fortoul rouge	\N
8040	773	Mercurey premier cru Griffères	AOC -	AOP -	{"fra": "Mercurey premier cru Griffères blanc"}	Mercurey premier cru Griffères blanc	\N
8041	773	Mercurey premier cru Griffères	AOC -	AOP -	{"fra": "Mercurey premier cru Griffères rouge"}	Mercurey premier cru Griffères rouge	\N
8042	774	Mercurey premier cru La Bondue	AOC -	AOP -	{"fra": "Mercurey premier cru La Bondue blanc"}	Mercurey premier cru La Bondue blanc	\N
8043	774	Mercurey premier cru La Bondue	AOC -	AOP -	{"fra": "Mercurey premier cru La Bondue rouge"}	Mercurey premier cru La Bondue rouge	\N
8044	775	Mercurey premier cru La Cailloute	AOC -	AOP -	{"fra": "Mercurey premier cru La Cailloute blanc"}	Mercurey premier cru La Cailloute blanc	\N
8045	775	Mercurey premier cru La Cailloute	AOC -	AOP -	{"fra": "Mercurey premier cru La Cailloute rouge"}	Mercurey premier cru La Cailloute rouge	\N
8046	776	Mercurey premier cru La Chassière	AOC -	AOP -	{"fra": "Mercurey premier cru La Chassière blanc"}	Mercurey premier cru La Chassière blanc	\N
8047	776	Mercurey premier cru La Chassière	AOC -	AOP -	{"fra": "Mercurey premier cru La Chassière rouge"}	Mercurey premier cru La Chassière rouge	\N
8048	777	Mercurey premier cru La Levrière	AOC -	AOP -	{"fra": "Mercurey premier cru La Levrière blanc"}	Mercurey premier cru La Levrière blanc	\N
8049	777	Mercurey premier cru La Levrière	AOC -	AOP -	{"fra": "Mercurey premier cru La Levrière rouge"}	Mercurey premier cru La Levrière rouge	\N
8050	778	Mercurey premier cru La Mission	AOC -	AOP -	{"fra": "Mercurey premier cru La Mission blanc"}	Mercurey premier cru La Mission blanc	\N
8051	778	Mercurey premier cru La Mission	AOC -	AOP -	{"fra": "Mercurey premier cru La Mission rouge"}	Mercurey premier cru La Mission rouge	\N
8052	779	Mercurey premier cru Le Clos du Roy	AOC -	AOP -	{"fra": "Mercurey premier cru Le Clos du Roy blanc"}	Mercurey premier cru Le Clos du Roy blanc	\N
8053	779	Mercurey premier cru Le Clos du Roy	AOC -	AOP -	{"fra": "Mercurey premier cru Le Clos du Roy rouge"}	Mercurey premier cru Le Clos du Roy rouge	\N
8054	780	Mercurey premier cru Le Clos l'Evêque	AOC -	AOP -	{"fra": "Mercurey premier cru Le Clos l'Evêque blanc"}	Mercurey premier cru Le Clos l'Evêque blanc	\N
8055	780	Mercurey premier cru Le Clos l'Evêque	AOC -	AOP -	{"fra": "Mercurey premier cru Le Clos l'Evêque rouge"}	Mercurey premier cru Le Clos l'Evêque rouge	\N
8056	781	Mercurey premier cru Les Byots	AOC -	AOP -	{"fra": "Mercurey premier cru Les Byots blanc"}	Mercurey premier cru Les Byots blanc	\N
8057	781	Mercurey premier cru Les Byots	AOC -	AOP -	{"fra": "Mercurey premier cru Les Byots rouge"}	Mercurey premier cru Les Byots rouge	\N
8058	782	Mercurey premier cru Les Champs Martin	AOC -	AOP -	{"fra": "Mercurey premier cru Les Champs Martin blanc"}	Mercurey premier cru Les Champs Martin blanc	\N
8059	782	Mercurey premier cru Les Champs Martin	AOC -	AOP -	{"fra": "Mercurey premier cru Les Champs Martin rouge"}	Mercurey premier cru Les Champs Martin rouge	\N
8060	783	Mercurey premier cru Les Combins	AOC -	AOP -	{"fra": "Mercurey premier cru Les Combins blanc"}	Mercurey premier cru Les Combins blanc	\N
8061	783	Mercurey premier cru Les Combins	AOC -	AOP -	{"fra": "Mercurey premier cru Les Combins rouge"}	Mercurey premier cru Les Combins rouge	\N
8062	785	Mercurey premier cru Les Crêts	AOC -	AOP -	{"fra": "Mercurey premier cru Les Crêts blanc"}	Mercurey premier cru Les Crêts blanc	\N
8063	785	Mercurey premier cru Les Crêts	AOC -	AOP -	{"fra": "Mercurey premier cru Les Crêts rouge"}	Mercurey premier cru Les Crêts rouge	\N
8064	784	Mercurey premier cru Les Croichots	AOC -	AOP -	{"fra": "Mercurey premier cru Les Croichots blanc"}	Mercurey premier cru Les Croichots blanc	\N
8065	784	Mercurey premier cru Les Croichots	AOC -	AOP -	{"fra": "Mercurey premier cru Les Croichots rouge"}	Mercurey premier cru Les Croichots rouge	\N
8066	786	Mercurey premier cru Les Fourneaux	AOC -	AOP -	{"fra": "Mercurey premier cru Les Fourneaux blanc"}	Mercurey premier cru Les Fourneaux blanc	\N
8067	786	Mercurey premier cru Les Fourneaux	AOC -	AOP -	{"fra": "Mercurey premier cru Les Fourneaux rouge"}	Mercurey premier cru Les Fourneaux rouge	\N
8068	787	Mercurey premier cru Les Montaigus	AOC -	AOP -	{"fra": "Mercurey premier cru Les Montaigus blanc"}	Mercurey premier cru Les Montaigus blanc	\N
8069	787	Mercurey premier cru Les Montaigus	AOC -	AOP -	{"fra": "Mercurey premier cru Les Montaigus rouge"}	Mercurey premier cru Les Montaigus rouge	\N
14235	787	Mercurey premier cru Les Montaigus	AOC -	AOP -	{"fra": "Mercurey premier cru Clos des Montaigus rouge"}	Mercurey premier cru Clos des Montaigus rouge	\N
8070	788	Mercurey premier cru Les Naugues	AOC -	AOP -	{"fra": "Mercurey premier cru Les Naugues blanc"}	Mercurey premier cru Les Naugues blanc	\N
8071	788	Mercurey premier cru Les Naugues	AOC -	AOP -	{"fra": "Mercurey premier cru Les Naugues rouge"}	Mercurey premier cru Les Naugues rouge	\N
8072	793	Mercurey premier cru Les Puillets	AOC -	AOP -	{"fra": "Mercurey premier cru Les Puillets blanc"}	Mercurey premier cru Les Puillets blanc	\N
8073	793	Mercurey premier cru Les Puillets	AOC -	AOP -	{"fra": "Mercurey premier cru Les Puillets rouge"}	Mercurey premier cru Les Puillets rouge	\N
8074	789	Mercurey premier cru Les Ruelles	AOC -	AOP -	{"fra": "Mercurey premier cru Les Ruelles blanc"}	Mercurey premier cru Les Ruelles blanc	\N
8075	789	Mercurey premier cru Les Ruelles	AOC -	AOP -	{"fra": "Mercurey premier cru Les Ruelles rouge"}	Mercurey premier cru Les Ruelles rouge	\N
8076	794	Mercurey premier cru Les Saumonts	AOC -	AOP -	{"fra": "Mercurey premier cru Les Saumonts blanc"}	Mercurey premier cru Les Saumonts blanc	\N
8077	794	Mercurey premier cru Les Saumonts	AOC -	AOP -	{"fra": "Mercurey premier cru Les Saumonts rouge"}	Mercurey premier cru Les Saumonts rouge	\N
8078	790	Mercurey premier cru Les Vasées	AOC -	AOP -	{"fra": "Mercurey premier cru Les Vasées blanc"}	Mercurey premier cru Les Vasées blanc	\N
8079	790	Mercurey premier cru Les Vasées	AOC -	AOP -	{"fra": "Mercurey premier cru Les Vasées rouge"}	Mercurey premier cru Les Vasées rouge	\N
8080	791	Mercurey premier cru Les Velley	AOC -	AOP -	{"fra": "Mercurey premier cru Les Velley blanc"}	Mercurey premier cru Les Velley blanc	\N
8081	791	Mercurey premier cru Les Velley	AOC -	AOP -	{"fra": "Mercurey premier cru Les Velley rouge"}	Mercurey premier cru Les Velley rouge	\N
8083	792	Mercurey premier cru Sazenay	AOC -	AOP -	{"fra": "Mercurey premier cru Sazenay blanc"}	Mercurey premier cru Sazenay blanc	\N
8084	792	Mercurey premier cru Sazenay	AOC -	AOP -	{"fra": "Mercurey premier cru Sazenay rouge"}	Mercurey premier cru Sazenay rouge	\N
7712	796	Meursault	AOC -	AOP -	{"fra": "Meursault blanc"}	Meursault blanc	\N
9115	796	Meursault	AOC -	AOP -	{"fra": "Meursault rouge ou Meursault Côte de Beaune"}	Meursault rouge ou Meursault Côte de Beaune	\N
9076	814	Meursault premier cru	AOC -	AOP -	{"fra": "Meursault premier cru blanc"}	Meursault premier cru blanc	\N
9110	814	Meursault premier cru	AOC -	AOP -	{"fra": "Meursault premier cru rouge"}	Meursault premier cru rouge	\N
9112	2221	Meursault premier cru Blagny	AOC -	AOP -	{"fra": "Meursault premier cru Blagny blanc"}	Meursault premier cru Blagny blanc	\N
9077	797	Meursault premier cru Charmes	AOC -	AOP -	{"fra": "Meursault premier cru Charmes blanc"}	Meursault premier cru Charmes blanc	\N
9078	797	Meursault premier cru Charmes	AOC -	AOP -	{"fra": "Meursault premier cru Charmes rouge"}	Meursault premier cru Charmes rouge	\N
9079	798	Meursault premier cru Clos des Perrières	AOC -	AOP -	{"fra": "Meursault premier cru Clos des Perrières blanc"}	Meursault premier cru Clos des Perrières blanc	\N
9080	798	Meursault premier cru Clos des Perrières	AOC -	AOP -	{"fra": "Meursault premier cru Clos des Perrières rouge"}	Meursault premier cru Clos des Perrières rouge	\N
9081	799	Meursault premier cru Genevrières	AOC -	AOP -	{"fra": "Meursault premier cru Genevrières blanc"}	Meursault premier cru Genevrières blanc	\N
9082	799	Meursault premier cru Genevrières	AOC -	AOP -	{"fra": "Meursault premier cru Genevrières rouge"}	Meursault premier cru Genevrières rouge	\N
9083	800	Meursault premier cru La Jeunellotte	AOC -	AOP -	{"fra": "Meursault premier cru La Jeunellotte blanc"}	Meursault premier cru La Jeunellotte blanc	\N
9085	801	Meursault premier cru La Pièce sous le Bois	AOC -	AOP -	{"fra": "Meursault premier cru La Pièce sous le Bois blanc"}	Meursault premier cru La Pièce sous le Bois blanc	\N
9087	802	Meursault premier cru Le Porusot	AOC -	AOP -	{"fra": "Meursault premier cru Le Porusot blanc"}	Meursault premier cru Le Porusot blanc	\N
9088	802	Meursault premier cru Le Porusot	AOC -	AOP -	{"fra": "Meursault premier cru Le Porusot rouge"}	Meursault premier cru Le Porusot rouge	\N
9089	803	Meursault premier cru Les Bouchères	AOC -	AOP -	{"fra": "Meursault premier cru Les Bouchères blanc"}	Meursault premier cru Les Bouchères blanc	\N
9090	803	Meursault premier cru Les Bouchères	AOC -	AOP -	{"fra": "Meursault premier cru Les Bouchères rouge"}	Meursault premier cru Les Bouchères rouge	\N
9091	804	Meursault premier cru Les Caillerets	AOC -	AOP -	{"fra": "Meursault premier cru Les Caillerets blanc"}	Meursault premier cru Les Caillerets blanc	\N
9092	804	Meursault premier cru Les Caillerets	AOC -	AOP -	{"fra": "Meursault premier cru Les Caillerets rouge"}	Meursault premier cru Les Caillerets rouge	\N
9093	805	Meursault premier cru Les Cras	AOC -	AOP -	{"fra": "Meursault premier cru Les Cras blanc"}	Meursault premier cru Les Cras blanc	\N
9094	805	Meursault premier cru Les Cras	AOC -	AOP -	{"fra": "Meursault premier cru Les Cras rouge"}	Meursault premier cru Les Cras rouge	\N
9096	806	Meursault premier cru Les Gouttes d'Or	AOC -	AOP -	{"fra": "Meursault premier cru Les Gouttes d'Or rouge"}	Meursault premier cru Les Gouttes d'Or rouge	\N
9097	806	Meursault premier cru Les Gouttes d'Or	AOC -	AOP -	{"fra": "Meursault premier cru Les Gouttes d'Or blanc"}	Meursault premier cru Les Gouttes d'Or blanc	\N
9098	807	Meursault premier cru Les Plures	AOC -	AOP -	{"fra": "Meursault premier cru Les Plures blanc"}	Meursault premier cru Les Plures blanc	\N
9100	1817	Meursault premier cru Les Ravelles	AOC -	AOP -	{"fra": "Meursault premier cru Les Ravelles blanc"}	Meursault premier cru Les Ravelles blanc	\N
9102	808	Meursault premier cru Les Santenots Blancs	AOC -	AOP -	{"fra": "Meursault premier cru Les Santenots Blancs blanc"}	Meursault premier cru Les Santenots Blancs blanc	\N
9104	809	Meursault premier cru Les Santenots du Milieu	AOC -	AOP -	{"fra": "Meursault premier cru Les Santenots du Milieu blanc"}	Meursault premier cru Les Santenots du Milieu blanc	\N
9106	810	Meursault premier cru Perrières	AOC -	AOP -	{"fra": "Meursault premier cru Perrières blanc"}	Meursault premier cru Perrières blanc	\N
9107	810	Meursault premier cru Perrières	AOC -	AOP -	{"fra": "Meursault premier cru Perrières rouge"}	Meursault premier cru Perrières rouge	\N
9108	811	Meursault premier cru Porusot	AOC -	AOP -	{"fra": "Meursault premier cru Porusot blanc"}	Meursault premier cru Porusot blanc	\N
9109	811	Meursault premier cru Porusot	AOC -	AOP -	{"fra": "Meursault premier cru Porusot rouge"}	Meursault premier cru Porusot rouge	\N
9111	812	Meursault premier cru Sous Blagny	AOC -	AOP -	{"fra": "Meursault premier cru Sous Blagny blanc"}	Meursault premier cru Sous Blagny blanc	\N
9113	813	Meursault premier cru Sous le Dos d'Ane	AOC -	AOP -	{"fra": "Meursault premier cru Sous le Dos d'Ane blanc"}	Meursault premier cru Sous le Dos d'Ane blanc	\N
3490	1619	Miel d'Alsace	\N	IGP -	{"fra": "Miel d'Alsace"}	Miel d'Alsace	IG/07/96
4668	1509	Miel de Corse - Mele di Corsica	AOC -	AOP -	{"fra": "Miel de Corse - Mele di Corsica"}	Miel de Corse - Mele di Corsica	\N
3512	1634	Miel de Provence	\N	IGP -	{"fra": "Miel de Provence"}	Miel de Provence	IG/03/95
13162	1502	Miel de sapin des Vosges	AOC -	AOP -	{"fra": "Miel de sapin des Vosges"}	Miel de sapin des Vosges	\N
15403	1840	Miel des Cévennes	\N	IGP -	{"fra": "Miel des Cévennes"}	Miel des Cévennes	\N
8818	1274	Minervois	AOC -	AOP -	{"fra": "Minervois blanc"}	Minervois blanc	\N
8819	1274	Minervois	AOC -	AOP -	{"fra": "Minervois rosé"}	Minervois rosé	\N
8820	1274	Minervois	AOC -	AOP -	{"fra": "Minervois rouge"}	Minervois rouge	\N
4289	1438	Mirabelle de Lorraine	AOC -	IG - 	{"fra": "Mirabelle de Lorraine"}	Mirabelle de Lorraine	\N
4486	1538	Mirabelles de Lorraine	\N	IGP -	{"fra": "Mirabelles de Lorraine"}	Mirabelles de Lorraine	IG/45/94
13706	2122	Mogette de Vendée	\N	IGP -	{"fra": "Mogette de Vendée"}	Mogette de Vendée	IG/05/00
8208	101	Monbazillac	AOC -	AOP -	{"fra": "Monbazillac"}	Monbazillac	\N
8209	101	Monbazillac	AOC -	AOP -	{"fra": "Monbazillac Sélection de grains nobles"}	Monbazillac Sélection de grains nobles	\N
7838	2075	Mont Caume	\N	IGP -	{"fra": "Mont Caume blanc"}	Mont Caume blanc	\N
8589	2075	Mont Caume	\N	IGP -	{"fra": "Mont Caume rosé"}	Mont Caume rosé	\N
8590	2075	Mont Caume	\N	IGP -	{"fra": "Mont Caume rouge"}	Mont Caume rouge	\N
10987	2075	Mont Caume	\N	IGP -	{"fra": "Mont Caume mousseux de qualité blanc"}	Mont Caume mousseux de qualité blanc	\N
10988	2075	Mont Caume	\N	IGP -	{"fra": "Mont Caume mousseux de qualité rosé"}	Mont Caume mousseux de qualité rosé	\N
10989	2075	Mont Caume	\N	IGP -	{"fra": "Mont Caume mousseux de qualité rouge"}	Mont Caume mousseux de qualité rouge	\N
10990	2075	Mont Caume	\N	IGP -	{"fra": "Mont Caume primeur ou nouveau blanc"}	Mont Caume primeur ou nouveau blanc	\N
10991	2075	Mont Caume	\N	IGP -	{"fra": "Mont Caume primeur ou nouveau rosé"}	Mont Caume primeur ou nouveau rosé	\N
10992	2075	Mont Caume	\N	IGP -	{"fra": "Mont Caume primeur ou nouveau rouge"}	Mont Caume primeur ou nouveau rouge	\N
10687	1474	Mont d'Or ou Vacherin du Haut-Doubs	AOC -	AOP -	{"fra": "Mont d'Or ou Vacherin du Haut-Doubs"}	Mont d'Or ou Vacherin du Haut-Doubs	\N
15427	102	Montagne-Saint-Emilion	AOC -	AOP -	{"fra": "Montagne-Saint-Emilion"}	Montagne-Saint-Emilion	\N
7742	815	Montagny	AOC -	AOP -	{"fra": "Montagny"}	Montagny	\N
8695	865	Montagny premier cru	AOC -	AOP -	{"fra": "Montagny premier cru"}	Montagny premier cru	\N
8696	816	Montagny premier cru Champ Toizeau	AOC -	AOP -	{"fra": "Montagny premier cru Champ Toizeau"}	Montagny premier cru Champ Toizeau	\N
8697	817	Montagny premier cru Chazelle	AOC -	AOP -	{"fra": "Montagny premier cru Chazelle"}	Montagny premier cru Chazelle	\N
8698	818	Montagny premier cru Cornevent	AOC -	AOP -	{"fra": "Montagny premier cru Cornevent"}	Montagny premier cru Cornevent	\N
8699	819	Montagny premier cru Creux de Beaux Champs	AOC -	AOP -	{"fra": "Montagny premier cru Creux de Beaux Champs"}	Montagny premier cru Creux de Beaux Champs	\N
8734	820	Montagny premier cru L'Epaule	AOC -	AOP -	{"fra": "Montagny premier cru L'Epaule"}	Montagny premier cru L'Epaule	\N
8700	821	Montagny premier cru La Condemine du Vieux Château	AOC -	AOP -	{"fra": "Montagny premier cru La Condemine du Vieux Château"}	Montagny premier cru La Condemine du Vieux Château	\N
8701	822	Montagny premier cru La Grande Pièce	AOC -	AOP -	{"fra": "Montagny premier cru La Grande Pièce"}	Montagny premier cru La Grande Pièce	\N
8702	823	Montagny premier cru La Moullière	AOC -	AOP -	{"fra": "Montagny premier cru La Moullière"}	Montagny premier cru La Moullière	\N
8703	824	Montagny premier cru Le Clos Chaudron	AOC -	AOP -	{"fra": "Montagny premier cru Le Clos Chaudron"}	Montagny premier cru Le Clos Chaudron	\N
8704	835	Montagny premier cru Le Cloux	AOC -	AOP -	{"fra": "Montagny premier cru Le Cloux"}	Montagny premier cru Le Cloux	\N
8705	825	Montagny premier cru Le Clouzot	AOC -	AOP -	{"fra": "Montagny premier cru Le Clouzot"}	Montagny premier cru Le Clouzot	\N
8706	826	Montagny premier cru Le Vieux Château	AOC -	AOP -	{"fra": "Montagny premier cru Le Vieux Château"}	Montagny premier cru Le Vieux Château	\N
8707	827	Montagny premier cru Les Bassets	AOC -	AOP -	{"fra": "Montagny premier cru Les Bassets"}	Montagny premier cru Les Bassets	\N
8708	828	Montagny premier cru Les Beaux Champs	AOC -	AOP -	{"fra": "Montagny premier cru Les Beaux Champs"}	Montagny premier cru Les Beaux Champs	\N
8709	829	Montagny premier cru Les Bonneveaux	AOC -	AOP -	{"fra": "Montagny premier cru Les Bonneveaux"}	Montagny premier cru Les Bonneveaux	\N
8710	830	Montagny premier cru Les Bordes	AOC -	AOP -	{"fra": "Montagny premier cru Les Bordes"}	Montagny premier cru Les Bordes	\N
8711	831	Montagny premier cru Les Bouchots	AOC -	AOP -	{"fra": "Montagny premier cru Les Bouchots"}	Montagny premier cru Les Bouchots	\N
8712	832	Montagny premier cru Les Burnins	AOC -	AOP -	{"fra": "Montagny premier cru Les Burnins"}	Montagny premier cru Les Burnins	\N
8713	833	Montagny premier cru Les Chaniots	AOC -	AOP -	{"fra": "Montagny premier cru Les Chaniots"}	Montagny premier cru Les Chaniots	\N
8714	834	Montagny premier cru Les Chaumelottes	AOC -	AOP -	{"fra": "Montagny premier cru Les Chaumelottes"}	Montagny premier cru Les Chaumelottes	\N
8715	838	Montagny premier cru Les Coères	AOC -	AOP -	{"fra": "Montagny premier cru Les Coères"}	Montagny premier cru Les Coères	\N
8716	836	Montagny premier cru Les Combes	AOC -	AOP -	{"fra": "Montagny premier cru Les Combes"}	Montagny premier cru Les Combes	\N
8717	837	Montagny premier cru Les Coudrettes	AOC -	AOP -	{"fra": "Montagny premier cru Les Coudrettes"}	Montagny premier cru Les Coudrettes	\N
8718	839	Montagny premier cru Les Craboulettes	AOC -	AOP -	{"fra": "Montagny premier cru Les Craboulettes"}	Montagny premier cru Les Craboulettes	\N
8719	840	Montagny premier cru Les Garchères	AOC -	AOP -	{"fra": "Montagny premier cru Les Garchères"}	Montagny premier cru Les Garchères	\N
8720	841	Montagny premier cru Les Gouresses	AOC -	AOP -	{"fra": "Montagny premier cru Les Gouresses"}	Montagny premier cru Les Gouresses	\N
8721	842	Montagny premier cru Les Jardins	AOC -	AOP -	{"fra": "Montagny premier cru Les Jardins"}	Montagny premier cru Les Jardins	\N
8722	843	Montagny premier cru Les Las	AOC -	AOP -	{"fra": "Montagny premier cru Les Las"}	Montagny premier cru Les Las	\N
8723	844	Montagny premier cru Les Macles	AOC -	AOP -	{"fra": "Montagny premier cru Les Macles"}	Montagny premier cru Les Macles	\N
8724	845	Montagny premier cru Les Maroques	AOC -	AOP -	{"fra": "Montagny premier cru Les Maroques"}	Montagny premier cru Les Maroques	\N
8725	846	Montagny premier cru Les Paquiers	AOC -	AOP -	{"fra": "Montagny premier cru Les Paquiers"}	Montagny premier cru Les Paquiers	\N
8726	847	Montagny premier cru Les Perrières	AOC -	AOP -	{"fra": "Montagny premier cru Les Perrières"}	Montagny premier cru Les Perrières	\N
8727	848	Montagny premier cru Les Pidances	AOC -	AOP -	{"fra": "Montagny premier cru Les Pidances"}	Montagny premier cru Les Pidances	\N
7979	1338	Muscat de Mireval	AOC -	AOP -	{"fra": "Muscat de Mireval"}	Muscat de Mireval	\N
8728	849	Montagny premier cru Les Platières	AOC -	AOP -	{"fra": "Montagny premier cru Les Platières"}	Montagny premier cru Les Platières	\N
8729	850	Montagny premier cru Les Resses	AOC -	AOP -	{"fra": "Montagny premier cru Les Resses"}	Montagny premier cru Les Resses	\N
8730	851	Montagny premier cru Les Treuffères	AOC -	AOP -	{"fra": "Montagny premier cru Les Treuffères"}	Montagny premier cru Les Treuffères	\N
8731	852	Montagny premier cru Les Vignes Derrière	AOC -	AOP -	{"fra": "Montagny premier cru Les Vignes Derrière"}	Montagny premier cru Les Vignes Derrière	\N
8732	854	Montagny premier cru Les Vignes des Prés	AOC -	AOP -	{"fra": "Montagny premier cru Les Vignes des Prés"}	Montagny premier cru Les Vignes des Prés	\N
8733	853	Montagny premier cru Les Vignes longues	AOC -	AOP -	{"fra": "Montagny premier cru Les Vignes longues"}	Montagny premier cru Les Vignes longues	\N
8735	857	Montagny premier cru Mont Laurent	AOC -	AOP -	{"fra": "Montagny premier cru Mont Laurent"}	Montagny premier cru Mont Laurent	\N
8736	856	Montagny premier cru Montcuchot	AOC -	AOP -	{"fra": "Montagny premier cru Montcuchot"}	Montagny premier cru Montcuchot	\N
8737	858	Montagny premier cru Montorge	AOC -	AOP -	{"fra": "Montagny premier cru Montorge"}	Montagny premier cru Montorge	\N
8738	860	Montagny premier cru Saint-Ytages	AOC -	AOP -	{"fra": "Montagny premier cru Saint-Ytages"}	Montagny premier cru Saint-Ytages	\N
8739	859	Montagny premier cru Sainte-Morille	AOC -	AOP -	{"fra": "Montagny premier cru Sainte-Morille"}	Montagny premier cru Sainte-Morille	\N
8740	861	Montagny premier cru Sous les Feilles	AOC -	AOP -	{"fra": "Montagny premier cru Sous les Feilles"}	Montagny premier cru Sous les Feilles	\N
8741	862	Montagny premier cru Vigne du soleil	AOC -	AOP -	{"fra": "Montagny premier cru Vigne du soleil"}	Montagny premier cru Vigne du soleil	\N
8742	863	Montagny premier cru Vignes Couland	AOC -	AOP -	{"fra": "Montagny premier cru Vignes Couland"}	Montagny premier cru Vignes Couland	\N
8743	864	Montagny premier cru Vignes Saint-Pierre	AOC -	AOP -	{"fra": "Montagny premier cru Vignes Saint-Pierre"}	Montagny premier cru Vignes Saint-Pierre	\N
8744	855	Montagny premier cru Vignes sur le Cloux	AOC -	AOP -	{"fra": "Montagny premier cru Vignes sur le Cloux"}	Montagny premier cru Vignes sur le Cloux	\N
7738	866	Monthélie	AOC -	AOP -	{"fra": "Monthélie blanc"}	Monthélie blanc	\N
9457	866	Monthélie	AOC -	AOP -	{"fra": "Monthélie rouge (ou Monthélie Côte de Beaune)"}	Monthélie rouge (ou Monthélie Côte de Beaune)	\N
9425	878	Monthélie premier cru	AOC -	AOP -	{"fra": "Monthélie premier cru blanc"}	Monthélie premier cru blanc	\N
9454	878	Monthélie premier cru	AOC -	AOP -	{"fra": "Monthélie premier cru rouge"}	Monthélie premier cru rouge	\N
9426	1818	Monthélie premier cru Clos des Toisières	AOC -	AOP -	{"fra": "Monthélie premier cru Clos des Toisières blanc"}	Monthélie premier cru Clos des Toisières blanc	\N
9427	1818	Monthélie premier cru Clos des Toisières	AOC -	AOP -	{"fra": "Monthélie premier cru Clos des Toisières rouge"}	Monthélie premier cru Clos des Toisières rouge	\N
9428	867	Monthélie premier cru La Taupine	AOC -	AOP -	{"fra": "Monthélie premier cru La Taupine blanc"}	Monthélie premier cru La Taupine blanc	\N
9429	867	Monthélie premier cru La Taupine	AOC -	AOP -	{"fra": "Monthélie premier cru La Taupine rouge"}	Monthélie premier cru La Taupine rouge	\N
9430	868	Monthélie premier cru Le Cas Rougeot	AOC -	AOP -	{"fra": "Monthélie premier cru Le Cas Rougeot blanc"}	Monthélie premier cru Le Cas Rougeot blanc	\N
9431	868	Monthélie premier cru Le Cas Rougeot	AOC -	AOP -	{"fra": "Monthélie premier cru Le Cas Rougeot rouge"}	Monthélie premier cru Le Cas Rougeot rouge	\N
9432	869	Monthélie premier cru Le Château Gaillard	AOC -	AOP -	{"fra": "Monthélie premier cru Le Château Gaillard blanc"}	Monthélie premier cru Le Château Gaillard blanc	\N
9433	869	Monthélie premier cru Le Château Gaillard	AOC -	AOP -	{"fra": "Monthélie premier cru Le Château Gaillard rouge"}	Monthélie premier cru Le Château Gaillard rouge	\N
9434	870	Monthélie premier cru Le Clos Gauthey	AOC -	AOP -	{"fra": "Monthélie premier cru Le Clos Gauthey blanc"}	Monthélie premier cru Le Clos Gauthey blanc	\N
9435	870	Monthélie premier cru Le Clos Gauthey	AOC -	AOP -	{"fra": "Monthélie premier cru Le Clos Gauthey rouge"}	Monthélie premier cru Le Clos Gauthey rouge	\N
9436	1819	Monthélie premier cru Le Clou des Chênes	AOC -	AOP -	{"fra": "Monthélie premier cru Le Clou des Chênes blanc"}	Monthélie premier cru Le Clou des Chênes blanc	\N
9437	1819	Monthélie premier cru Le Clou des Chênes	AOC -	AOP -	{"fra": "Monthélie premier cru Le Clou des Chênes rouge"}	Monthélie premier cru Le Clou des Chênes rouge	\N
9438	871	Monthélie premier cru Le Meix Bataille	AOC -	AOP -	{"fra": "Monthélie premier cru Le Meix Bataille blanc"}	Monthélie premier cru Le Meix Bataille blanc	\N
9439	871	Monthélie premier cru Le Meix Bataille	AOC -	AOP -	{"fra": "Monthélie premier cru Le Meix Bataille rouge"}	Monthélie premier cru Le Meix Bataille rouge	\N
9440	872	Monthélie premier cru Le Village	AOC -	AOP -	{"fra": "Monthélie premier cru Le Village blanc"}	Monthélie premier cru Le Village blanc	\N
9441	872	Monthélie premier cru Le Village	AOC -	AOP -	{"fra": "Monthélie premier cru Le Village rouge"}	Monthélie premier cru Le Village rouge	\N
9442	1820	Monthélie premier cru Les Barbières	AOC -	AOP -	{"fra": "Monthélie premier cru Les Barbières blanc"}	Monthélie premier cru Les Barbières blanc	\N
9443	1820	Monthélie premier cru Les Barbières	AOC -	AOP -	{"fra": "Monthélie premier cru Les Barbières rouge"}	Monthélie premier cru Les Barbières rouge	\N
9444	873	Monthélie premier cru Les Champs Fulliots	AOC -	AOP -	{"fra": "Monthélie premier cru Les Champs Fulliots blanc"}	Monthélie premier cru Les Champs Fulliots blanc	\N
9445	873	Monthélie premier cru Les Champs Fulliots	AOC -	AOP -	{"fra": "Monthélie premier cru Les Champs Fulliots rouge"}	Monthélie premier cru Les Champs Fulliots rouge	\N
9446	1821	Monthélie premier cru Les Clous	AOC -	AOP -	{"fra": "Monthélie premier cru Les Clous blanc"}	Monthélie premier cru Les Clous blanc	\N
9447	1821	Monthélie premier cru Les Clous	AOC -	AOP -	{"fra": "Monthélie premier cru Les Clous rouge"}	Monthélie premier cru Les Clous rouge	\N
9448	874	Monthélie premier cru Les Duresses	AOC -	AOP -	{"fra": "Monthélie premier cru Les Duresses blanc"}	Monthélie premier cru Les Duresses blanc	\N
9449	874	Monthélie premier cru Les Duresses	AOC -	AOP -	{"fra": "Monthélie premier cru Les Duresses rouge"}	Monthélie premier cru Les Duresses rouge	\N
9450	875	Monthélie premier cru Les Riottes	AOC -	AOP -	{"fra": "Monthélie premier cru Les Riottes blanc"}	Monthélie premier cru Les Riottes blanc	\N
9451	875	Monthélie premier cru Les Riottes	AOC -	AOP -	{"fra": "Monthélie premier cru Les Riottes rouge"}	Monthélie premier cru Les Riottes rouge	\N
9452	876	Monthélie premier cru Les Vignes Rondes	AOC -	AOP -	{"fra": "Monthélie premier cru Les Vignes Rondes blanc"}	Monthélie premier cru Les Vignes Rondes blanc	\N
9453	876	Monthélie premier cru Les Vignes Rondes	AOC -	AOP -	{"fra": "Monthélie premier cru Les Vignes Rondes rouge"}	Monthélie premier cru Les Vignes Rondes rouge	\N
9455	877	Monthélie premier cru Sur la Velle	AOC -	AOP -	{"fra": "Monthélie premier cru Sur la Velle blanc"}	Monthélie premier cru Sur la Velle blanc	\N
9456	877	Monthélie premier cru Sur la Velle	AOC -	AOP -	{"fra": "Monthélie premier cru Sur la Velle rouge"}	Monthélie premier cru Sur la Velle rouge	\N
7970	191	Montlouis-sur-Loire	AOC -	AOP -	{"fra": "Montlouis-sur-Loire"}	Montlouis-sur-Loire	\N
7971	191	Montlouis-sur-Loire	AOC -	AOP -	{"fra": "Montlouis-sur-Loire mousseux"}	Montlouis-sur-Loire mousseux	\N
7972	191	Montlouis-sur-Loire	AOC -	AOP -	{"fra": "Montlouis-sur-Loire pétillant"}	Montlouis-sur-Loire pétillant	\N
7677	879	Montrachet	AOC -	AOP -	{"fra": "Montrachet"}	Montrachet	\N
10233	103	Montravel	AOC -	AOP -	{"fra": "Montravel blanc"}	Montravel blanc	\N
13320	103	Montravel	AOC -	AOP -	{"fra": "Montravel rouge"}	Montravel rouge	\N
13160	2223	Morbier	AOC -	AOP -	{"fra": "Morbier"}	Morbier	\N
7711	880	Morey-Saint-Denis	AOC -	AOP -	{"fra": "Morey-Saint-Denis blanc"}	Morey-Saint-Denis blanc	\N
9284	880	Morey-Saint-Denis	AOC -	AOP -	{"fra": "Morey-Saint-Denis rouge"}	Morey-Saint-Denis rouge	\N
9247	901	Morey-Saint-Denis premier cru	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru blanc"}	Morey-Saint-Denis premier cru blanc	\N
9283	901	Morey-Saint-Denis premier cru	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru rouge"}	Morey-Saint-Denis premier cru rouge	\N
9243	881	Morey-Saint-Denis premier cru Aux Charmes	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Aux Charmes blanc"}	Morey-Saint-Denis premier cru Aux Charmes blanc	\N
9244	881	Morey-Saint-Denis premier cru Aux Charmes	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Aux Charmes rouge"}	Morey-Saint-Denis premier cru Aux Charmes rouge	\N
9245	882	Morey-Saint-Denis premier cru Aux Cheseaux	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Aux Cheseaux blanc"}	Morey-Saint-Denis premier cru Aux Cheseaux blanc	\N
9246	882	Morey-Saint-Denis premier cru Aux Cheseaux	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Aux Cheseaux rouge"}	Morey-Saint-Denis premier cru Aux Cheseaux rouge	\N
9248	883	Morey-Saint-Denis premier cru Clos Baulet	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Clos Baulet blanc"}	Morey-Saint-Denis premier cru Clos Baulet blanc	\N
9249	883	Morey-Saint-Denis premier cru Clos Baulet	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Clos Baulet rouge"}	Morey-Saint-Denis premier cru Clos Baulet rouge	\N
9250	885	Morey-Saint-Denis premier cru Clos des Ormes	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Clos des Ormes blanc"}	Morey-Saint-Denis premier cru Clos des Ormes blanc	\N
9251	885	Morey-Saint-Denis premier cru Clos des Ormes	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Clos des Ormes rouge"}	Morey-Saint-Denis premier cru Clos des Ormes rouge	\N
9252	884	Morey-Saint-Denis premier cru Clos Sorbè	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Clos Sorbè blanc"}	Morey-Saint-Denis premier cru Clos Sorbè blanc	\N
9253	884	Morey-Saint-Denis premier cru Clos Sorbè	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Clos Sorbè rouge"}	Morey-Saint-Denis premier cru Clos Sorbè rouge	\N
5632	886	Morey-Saint-Denis premier cru Côte Rotie	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Côte Rotie rouge"}	Morey-Saint-Denis premier cru Côte Rotie rouge	\N
9254	886	Morey-Saint-Denis premier cru Côte Rotie	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Côte Rotie blanc"}	Morey-Saint-Denis premier cru Côte Rotie blanc	\N
9255	887	Morey-Saint-Denis premier cru La Bussière	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru La Bussière blanc"}	Morey-Saint-Denis premier cru La Bussière blanc	\N
9256	887	Morey-Saint-Denis premier cru La Bussière	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru La Bussière rouge"}	Morey-Saint-Denis premier cru La Bussière rouge	\N
9257	888	Morey-Saint-Denis premier cru La Riotte	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru La Riotte blanc"}	Morey-Saint-Denis premier cru La Riotte blanc	\N
9258	888	Morey-Saint-Denis premier cru La Riotte	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru La Riotte rouge"}	Morey-Saint-Denis premier cru La Riotte rouge	\N
8456	2005	Périgord	\N	IGP -	{"fra": "Périgord rouge"}	Périgord rouge	\N
9259	889	Morey-Saint-Denis premier cru Le Village	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Le Village blanc"}	Morey-Saint-Denis premier cru Le Village blanc	\N
9260	889	Morey-Saint-Denis premier cru Le Village	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Le Village rouge"}	Morey-Saint-Denis premier cru Le Village rouge	\N
9261	890	Morey-Saint-Denis premier cru Les Blanchards	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Les Blanchards blanc"}	Morey-Saint-Denis premier cru Les Blanchards blanc	\N
9262	890	Morey-Saint-Denis premier cru Les Blanchards	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Les Blanchards rouge"}	Morey-Saint-Denis premier cru Les Blanchards rouge	\N
9263	891	Morey-Saint-Denis premier cru Les Chaffots	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Les Chaffots blanc"}	Morey-Saint-Denis premier cru Les Chaffots blanc	\N
9264	891	Morey-Saint-Denis premier cru Les Chaffots	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Les Chaffots rouge"}	Morey-Saint-Denis premier cru Les Chaffots rouge	\N
9265	892	Morey-Saint-Denis premier cru Les Charrières	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Les Charrières blanc"}	Morey-Saint-Denis premier cru Les Charrières blanc	\N
9266	892	Morey-Saint-Denis premier cru Les Charrières	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Les Charrières rouge"}	Morey-Saint-Denis premier cru Les Charrières rouge	\N
9267	893	Morey-Saint-Denis premier cru Les Chenevery	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Les Chenevery blanc"}	Morey-Saint-Denis premier cru Les Chenevery blanc	\N
9268	893	Morey-Saint-Denis premier cru Les Chenevery	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Les Chenevery rouge"}	Morey-Saint-Denis premier cru Les Chenevery rouge	\N
9269	894	Morey-Saint-Denis premier cru Les Faconnières	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Les Faconnières blanc"}	Morey-Saint-Denis premier cru Les Faconnières blanc	\N
9270	894	Morey-Saint-Denis premier cru Les Faconnières	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Les Faconnières rouge"}	Morey-Saint-Denis premier cru Les Faconnières rouge	\N
9271	895	Morey-Saint-Denis premier cru Les Genavrières	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Les Genavrières blanc"}	Morey-Saint-Denis premier cru Les Genavrières blanc	\N
9272	895	Morey-Saint-Denis premier cru Les Genavrières	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Les Genavrières rouge"}	Morey-Saint-Denis premier cru Les Genavrières rouge	\N
9273	896	Morey-Saint-Denis premier cru Les Gruenchers	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Les Gruenchers blanc"}	Morey-Saint-Denis premier cru Les Gruenchers blanc	\N
9274	896	Morey-Saint-Denis premier cru Les Gruenchers	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Les Gruenchers rouge"}	Morey-Saint-Denis premier cru Les Gruenchers rouge	\N
9275	897	Morey-Saint-Denis premier cru Les Millandes	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Les Millandes blanc"}	Morey-Saint-Denis premier cru Les Millandes blanc	\N
9276	897	Morey-Saint-Denis premier cru Les Millandes	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Les Millandes rouge"}	Morey-Saint-Denis premier cru Les Millandes rouge	\N
9277	898	Morey-Saint-Denis premier cru Les Ruchots	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Les Ruchots blanc"}	Morey-Saint-Denis premier cru Les Ruchots blanc	\N
9278	898	Morey-Saint-Denis premier cru Les Ruchots	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Les Ruchots rouge"}	Morey-Saint-Denis premier cru Les Ruchots rouge	\N
9279	899	Morey-Saint-Denis premier cru Les Sorbès	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Les Sorbès blanc"}	Morey-Saint-Denis premier cru Les Sorbès blanc	\N
9280	899	Morey-Saint-Denis premier cru Les Sorbès	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Les Sorbès rouge"}	Morey-Saint-Denis premier cru Les Sorbès rouge	\N
9281	900	Morey-Saint-Denis premier cru Monts Luisants	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Monts Luisants blanc"}	Morey-Saint-Denis premier cru Monts Luisants blanc	\N
9282	900	Morey-Saint-Denis premier cru Monts Luisants	AOC -	AOP -	{"fra": "Morey-Saint-Denis premier cru Monts Luisants rouge"}	Morey-Saint-Denis premier cru Monts Luisants rouge	\N
10247	902	Morgon	AOC -	AOP -	{"fra": "Morgon ou Morgon cru du Beaujolais"}	Morgon ou Morgon cru du Beaujolais	\N
15019	1684	Moselle	AOC -	AOP -	{"fra": "Moselle blanc"}	Moselle blanc	\N
15020	1684	Moselle	AOC -	AOP -	{"fra": "Moselle rosé"}	Moselle rosé	\N
15021	1684	Moselle	AOC -	AOP -	{"fra": "Moselle rouge"}	Moselle rouge	\N
13973	2417	Moules	LR - 	\N	{"fra": "Moules"}	Moules	LA/03/16
14638	1640	Moules de bouchot de la baie du Mont-Saint-Michel	AOC -	AOP -	{"fra": "Moules de bouchot de la baie du Mont-Saint-Michel"}	Moules de bouchot de la baie du Mont-Saint-Michel	\N
12984	2358	Moules de filières élevées en pleine mer 	LR - 	\N	{"fra": "Moules de filières élevées en pleine mer"}	Moules de filières élevées en pleine mer	LA/06/14
10248	910	Moulin-à-Vent	AOC -	AOP -	{"fra": "Moulin-à-Vent ou Moulin-à-Vent cru du Beaujolais"}	Moulin-à-Vent ou Moulin-à-Vent cru du Beaujolais	\N
13125	2390	Moulis	AOC -	AOP -	{"fra": "Moulis ou Moulis-en-Médoc"}	Moulis ou Moulis-en-Médoc	\N
4160	1894	Moutarde de Bourgogne	\N	IGP -	{"fra": "Moutarde de Bourgogne"}	Moutarde de Bourgogne	IG/11/98
14652	1475	Munster	AOC -	AOP -	{"fra": "Munster"}	Munster	\N
15221	2341	Muscadet	AOC -	AOP -	{"fra": "Muscadet"}	Muscadet	\N
15222	2341	Muscadet	AOC -	AOP -	{"fra": "Muscadet primeur"}	Muscadet primeur	\N
15997	2341	Muscadet	AOC -	AOP -	{"fra": "Muscadet sur lie"}	Muscadet sur lie	\N
15239	2342	Muscadet Coteaux de la Loire	AOC -	AOP -	{"fra": "Muscadet Coteaux de la Loire"}	Muscadet Coteaux de la Loire	\N
15240	2342	Muscadet Coteaux de la Loire	AOC -	AOP -	{"fra": "Muscadet Coteaux de la Loire sur lie"}	Muscadet Coteaux de la Loire sur lie	\N
15237	194	Muscadet Côtes de Grandlieu	AOC -	AOP -	{"fra": "Muscadet Côtes de Grandlieu"}	Muscadet Côtes de Grandlieu	\N
15238	194	Muscadet Côtes de Grandlieu	AOC -	AOP -	{"fra": "Muscadet Côtes de Grandlieu sur lie"}	Muscadet Côtes de Grandlieu sur lie	\N
15223	195	Muscadet Sèvre et Maine	AOC -	AOP -	{"fra": "Muscadet Sèvre et Maine"}	Muscadet Sèvre et Maine	\N
15231	195	Muscadet Sèvre et Maine	AOC -	AOP -	{"fra": "Muscadet Sèvre et Maine sur lie"}	Muscadet Sèvre et Maine sur lie	\N
15233	2453	Muscadet Sèvre et Maine Château-Thébaud	AOC -	AOP -	{"fra": "Muscadet Sèvre et Maine Château-Thébaud"}	Muscadet Sèvre et Maine Château-Thébaud	\N
15224	2332	Muscadet Sèvre et Maine Clisson	AOC -	AOP -	{"fra": "Muscadet Sèvre et Maine Clisson"}	Muscadet Sèvre et Maine Clisson	\N
15229	2334	Muscadet Sèvre et Maine Gorges	AOC -	AOP -	{"fra": "Muscadet Sèvre et Maine Gorges"}	Muscadet Sèvre et Maine Gorges	\N
15232	2452	Muscadet Sèvre et Maine Goulaine	AOC -	AOP -	{"fra": "Muscadet Sèvre et Maine Goulaine"}	Muscadet Sèvre et Maine Goulaine	\N
15230	2335	Muscadet Sèvre et Maine Le Pallet	AOC -	AOP -	{"fra": "Muscadet Sèvre et Maine Le Pallet"}	Muscadet Sèvre et Maine Le Pallet	\N
15234	2454	Muscadet Sèvre et Maine Monnières - Saint-Fiacre	AOC -	AOP -	{"fra": "Muscadet Sèvre et Maine Monnières - Saint-Fiacre"}	Muscadet Sèvre et Maine Monnières - Saint-Fiacre	\N
15235	2455	Muscadet Sèvre et Maine Mouzillon - Tillières	AOC -	AOP -	{"fra": "Muscadet Sèvre et Maine Mouzillon - Tillières"}	Muscadet Sèvre et Maine Mouzillon - Tillières	\N
9221	1336	Muscat de Beaumes-de-Venise	AOC -	AOP -	{"fra": "Muscat de Beaumes-de-Venise blanc"}	Muscat de Beaumes-de-Venise blanc	\N
9222	1336	Muscat de Beaumes-de-Venise	AOC -	AOP -	{"fra": "Muscat de Beaumes-de-Venise rosé"}	Muscat de Beaumes-de-Venise rosé	\N
9223	1336	Muscat de Beaumes-de-Venise	AOC -	AOP -	{"fra": "Muscat de Beaumes-de-Venise rouge"}	Muscat de Beaumes-de-Venise rouge	\N
7766	1333	Muscat de Frontignan ou Frontignan ou Vin de Frontignan	AOC -	AOP -	{"fra": "Muscat de Frontignan ou Frontignan ou Vin de Frontignan vin de liqueur"}	Muscat de Frontignan ou Frontignan ou Vin de Frontignan vin de liqueur	\N
9838	1333	Muscat de Frontignan ou Frontignan ou Vin de Frontignan	AOC -	AOP -	{"fra": "Muscat de Frontignan ou Frontignan ou Vin de Frontignan vin doux naturel"}	Muscat de Frontignan ou Frontignan ou Vin de Frontignan vin doux naturel	\N
9220	1337	Muscat de Lunel	AOC -	AOP -	{"fra": "Muscat de Lunel"}	Muscat de Lunel	\N
7767	1873	Muscat de Rivesaltes	AOC -	AOP -	{"fra": "Muscat de Rivesaltes"}	Muscat de Rivesaltes	\N
9197	1873	Muscat de Rivesaltes	AOC -	AOP -	{"fra": "Muscat de Rivesaltes Muscat de Noël"}	Muscat de Rivesaltes Muscat de Noël	\N
7768	1339	Muscat de Saint-Jean-de-Minervois	AOC -	AOP -	{"fra": "Muscat de Saint-Jean-de-Minervois"}	Muscat de Saint-Jean-de-Minervois	\N
6423	1340	Muscat du Cap Corse	AOC -	AOP -	{"fra": "Muscat du Cap Corse"}	Muscat du Cap Corse	\N
10018	1506	Muscat du Ventoux	AOC -	AOP -	{"fra": "Muscat du Ventoux"}	Muscat du Ventoux	\N
7709	925	Musigny	AOC -	AOP -	{"fra": "Musigny blanc"}	Musigny blanc	\N
8368	925	Musigny	AOC -	AOP -	{"fra": "Musigny rouge"}	Musigny rouge	\N
13169	1476	Neufchâtel	AOC -	AOP -	{"fra": "Neufchâtel"}	Neufchâtel	\N
4361	1770	Noisette de Cervione - nuciola di Cervioni	\N	IGP -	{"fra": "Noisette de Cervione - nuciola di Cervioni"}	Noisette de Cervione - nuciola di Cervioni	\N
10277	1501	Noix de Grenoble	AOC -	AOP -	{"fra": "Noix de Grenoble"}	Noix de Grenoble	\N
6431	1516	Noix du Périgord	AOC -	AOP -	{"fra": "Noix du Périgord"}	Noix du Périgord	\N
7701	926	Nuits-Saint-Georges	AOC -	AOP -	{"fra": "Nuits-Saint-Georges blanc"}	Nuits-Saint-Georges blanc	\N
9923	926	Nuits-Saint-Georges	AOC -	AOP -	{"fra": "Nuits-Saint-Georges rouge"}	Nuits-Saint-Georges rouge	\N
9859	968	Nuits-Saint-Georges premier cru	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru blanc"}	Nuits-Saint-Georges premier cru blanc	\N
9920	968	Nuits-Saint-Georges premier cru	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru rouge"}	Nuits-Saint-Georges premier cru rouge	\N
9839	927	Nuits-Saint-Georges premier cru Aux Argillas	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Aux Argillas blanc"}	Nuits-Saint-Georges premier cru Aux Argillas blanc	\N
9840	927	Nuits-Saint-Georges premier cru Aux Argillas	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Aux Argillas rouge"}	Nuits-Saint-Georges premier cru Aux Argillas rouge	\N
9841	928	Nuits-Saint-Georges premier cru Aux Boudots	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Aux Boudots blanc"}	Nuits-Saint-Georges premier cru Aux Boudots blanc	\N
9842	928	Nuits-Saint-Georges premier cru Aux Boudots	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Aux Boudots rouge"}	Nuits-Saint-Georges premier cru Aux Boudots rouge	\N
9843	929	Nuits-Saint-Georges premier cru Aux Bousselots	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Aux Bousselots blanc"}	Nuits-Saint-Georges premier cru Aux Bousselots blanc	\N
9844	929	Nuits-Saint-Georges premier cru Aux Bousselots	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Aux Bousselots rouge"}	Nuits-Saint-Georges premier cru Aux Bousselots rouge	\N
9845	930	Nuits-Saint-Georges premier cru Aux Chaignots	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Aux Chaignots blanc"}	Nuits-Saint-Georges premier cru Aux Chaignots blanc	\N
9846	930	Nuits-Saint-Georges premier cru Aux Chaignots	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Aux Chaignots rouge"}	Nuits-Saint-Georges premier cru Aux Chaignots rouge	\N
9847	931	Nuits-Saint-Georges premier cru Aux Champs Perdrix	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Aux Champs Perdrix blanc"}	Nuits-Saint-Georges premier cru Aux Champs Perdrix blanc	\N
9848	931	Nuits-Saint-Georges premier cru Aux Champs Perdrix	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Aux Champs Perdrix rouge"}	Nuits-Saint-Georges premier cru Aux Champs Perdrix rouge	\N
9849	932	Nuits-Saint-Georges premier cru Aux Cras	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Aux Cras blanc"}	Nuits-Saint-Georges premier cru Aux Cras blanc	\N
9850	932	Nuits-Saint-Georges premier cru Aux Cras	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Aux Cras rouge"}	Nuits-Saint-Georges premier cru Aux Cras rouge	\N
9851	933	Nuits-Saint-Georges premier cru Aux Murgers	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Aux Murgers blanc"}	Nuits-Saint-Georges premier cru Aux Murgers blanc	\N
9852	933	Nuits-Saint-Georges premier cru Aux Murgers	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Aux Murgers rouge"}	Nuits-Saint-Georges premier cru Aux Murgers rouge	\N
9853	934	Nuits-Saint-Georges premier cru Aux Perdrix	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Aux Perdrix blanc"}	Nuits-Saint-Georges premier cru Aux Perdrix blanc	\N
9854	934	Nuits-Saint-Georges premier cru Aux Perdrix	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Aux Perdrix rouge"}	Nuits-Saint-Georges premier cru Aux Perdrix rouge	\N
9855	935	Nuits-Saint-Georges premier cru Aux Thorey	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Aux Thorey blanc"}	Nuits-Saint-Georges premier cru Aux Thorey blanc	\N
9856	935	Nuits-Saint-Georges premier cru Aux Thorey	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Aux Thorey rouge"}	Nuits-Saint-Georges premier cru Aux Thorey rouge	\N
9857	936	Nuits-Saint-Georges premier cru Aux Vignerondes	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Aux Vignerondes blanc"}	Nuits-Saint-Georges premier cru Aux Vignerondes blanc	\N
9858	936	Nuits-Saint-Georges premier cru Aux Vignerondes	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Aux Vignerondes rouge"}	Nuits-Saint-Georges premier cru Aux Vignerondes rouge	\N
9860	937	Nuits-Saint-Georges premier cru Chaines Carteaux	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Chaines Carteaux blanc"}	Nuits-Saint-Georges premier cru Chaines Carteaux blanc	\N
9861	937	Nuits-Saint-Georges premier cru Chaines Carteaux	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Chaines Carteaux rouge"}	Nuits-Saint-Georges premier cru Chaines Carteaux rouge	\N
9862	938	Nuits-Saint-Georges premier cru Château Gris	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Château Gris blanc"}	Nuits-Saint-Georges premier cru Château Gris blanc	\N
9863	938	Nuits-Saint-Georges premier cru Château Gris	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Château Gris rouge"}	Nuits-Saint-Georges premier cru Château Gris rouge	\N
9864	939	Nuits-Saint-Georges premier cru Clos Arlot	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Clos Arlot blanc"}	Nuits-Saint-Georges premier cru Clos Arlot blanc	\N
9865	939	Nuits-Saint-Georges premier cru Clos Arlot	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Clos Arlot rouge"}	Nuits-Saint-Georges premier cru Clos Arlot rouge	\N
9866	941	Nuits-Saint-Georges premier cru Clos de la Maréchale	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Clos de la Maréchale blanc"}	Nuits-Saint-Georges premier cru Clos de la Maréchale blanc	\N
9867	941	Nuits-Saint-Georges premier cru Clos de la Maréchale	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Clos de la Maréchale rouge"}	Nuits-Saint-Georges premier cru Clos de la Maréchale rouge	\N
9868	942	Nuits-Saint-Georges premier cru Clos des Argillières	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Clos des Argillières blanc"}	Nuits-Saint-Georges premier cru Clos des Argillières blanc	\N
9869	942	Nuits-Saint-Georges premier cru Clos des Argillières	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Clos des Argillières rouge"}	Nuits-Saint-Georges premier cru Clos des Argillières rouge	\N
9870	943	Nuits-Saint-Georges premier cru Clos des Corvées	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Clos des Corvées blanc"}	Nuits-Saint-Georges premier cru Clos des Corvées blanc	\N
9873	943	Nuits-Saint-Georges premier cru Clos des Corvées	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Clos des Corvées rouge"}	Nuits-Saint-Georges premier cru Clos des Corvées rouge	\N
9871	944	Nuits-Saint-Georges premier cru Clos des Corvées Pagets	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Clos des Corvées Pagets blanc"}	Nuits-Saint-Georges premier cru Clos des Corvées Pagets blanc	\N
9872	944	Nuits-Saint-Georges premier cru Clos des Corvées Pagets	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Clos des Corvées Pagets rouge"}	Nuits-Saint-Georges premier cru Clos des Corvées Pagets rouge	\N
9874	945	Nuits-Saint-Georges premier cru Clos des Forêts Saint-Georges	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Clos des Forêts Saint-Georges blanc"}	Nuits-Saint-Georges premier cru Clos des Forêts Saint-Georges blanc	\N
9875	945	Nuits-Saint-Georges premier cru Clos des Forêts Saint-Georges	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Clos des Forêts Saint-Georges rouge"}	Nuits-Saint-Georges premier cru Clos des Forêts Saint-Georges rouge	\N
9876	946	Nuits-Saint-Georges premier cru Clos des Grandes Vignes	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Clos des Grandes Vignes blanc"}	Nuits-Saint-Georges premier cru Clos des Grandes Vignes blanc	\N
9877	946	Nuits-Saint-Georges premier cru Clos des Grandes Vignes	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Clos des Grandes Vignes rouge"}	Nuits-Saint-Georges premier cru Clos des Grandes Vignes rouge	\N
9878	947	Nuits-Saint-Georges premier cru Clos des Porrets-Saint-Georges	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Clos des Porrets-Saint-Georges blanc"}	Nuits-Saint-Georges premier cru Clos des Porrets-Saint-Georges blanc	\N
9879	947	Nuits-Saint-Georges premier cru Clos des Porrets-Saint-Georges	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Clos des Porrets-Saint-Georges rouge"}	Nuits-Saint-Georges premier cru Clos des Porrets-Saint-Georges rouge	\N
9880	940	Nuits-Saint-Georges premier cru Clos Saint-Marc	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Clos Saint-Marc blanc"}	Nuits-Saint-Georges premier cru Clos Saint-Marc blanc	\N
9881	940	Nuits-Saint-Georges premier cru Clos Saint-Marc	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Clos Saint-Marc rouge"}	Nuits-Saint-Georges premier cru Clos Saint-Marc rouge	\N
9882	948	Nuits-Saint-Georges premier cru En la Perrière Noblot	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru En la Perrière Noblot blanc"}	Nuits-Saint-Georges premier cru En la Perrière Noblot blanc	\N
9883	948	Nuits-Saint-Georges premier cru En la Perrière Noblot	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru En la Perrière Noblot rouge"}	Nuits-Saint-Georges premier cru En la Perrière Noblot rouge	\N
9884	949	Nuits-Saint-Georges premier cru La Richemone	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru La Richemone blanc"}	Nuits-Saint-Georges premier cru La Richemone blanc	\N
9885	949	Nuits-Saint-Georges premier cru La Richemone	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru La Richemone rouge"}	Nuits-Saint-Georges premier cru La Richemone rouge	\N
13561	2248	Pays d'Hérault Bénovie	\N	IGP -	{"fra": "Pays d'Hérault Bénovie primeur ou nouveau blanc"}	Pays d'Hérault Bénovie primeur ou nouveau blanc	\N
9886	950	Nuits-Saint-Georges premier cru Les Argillières	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Les Argillières blanc"}	Nuits-Saint-Georges premier cru Les Argillières blanc	\N
9887	950	Nuits-Saint-Georges premier cru Les Argillières	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Les Argillières rouge"}	Nuits-Saint-Georges premier cru Les Argillières rouge	\N
9888	951	Nuits-Saint-Georges premier cru Les Cailles	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Les Cailles blanc"}	Nuits-Saint-Georges premier cru Les Cailles blanc	\N
9889	951	Nuits-Saint-Georges premier cru Les Cailles	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Les Cailles rouge"}	Nuits-Saint-Georges premier cru Les Cailles rouge	\N
9890	952	Nuits-Saint-Georges premier cru Les Chabœufs	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Les Chabœufs blanc"}	Nuits-Saint-Georges premier cru Les Chabœufs blanc	\N
9891	952	Nuits-Saint-Georges premier cru Les Chabœufs	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Les Chabœufs rouge"}	Nuits-Saint-Georges premier cru Les Chabœufs rouge	\N
9892	953	Nuits-Saint-Georges premier cru Les Crots	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Les Crots blanc"}	Nuits-Saint-Georges premier cru Les Crots blanc	\N
9893	953	Nuits-Saint-Georges premier cru Les Crots	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Les Crots rouge"}	Nuits-Saint-Georges premier cru Les Crots rouge	\N
9894	954	Nuits-Saint-Georges premier cru Les Damodes	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Les Damodes blanc"}	Nuits-Saint-Georges premier cru Les Damodes blanc	\N
9895	954	Nuits-Saint-Georges premier cru Les Damodes	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Les Damodes rouge"}	Nuits-Saint-Georges premier cru Les Damodes rouge	\N
9896	955	Nuits-Saint-Georges premier cru Les Didiers	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Les Didiers blanc"}	Nuits-Saint-Georges premier cru Les Didiers blanc	\N
9897	955	Nuits-Saint-Georges premier cru Les Didiers	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Les Didiers rouge"}	Nuits-Saint-Georges premier cru Les Didiers rouge	\N
9898	956	Nuits-Saint-Georges premier cru Les Hauts Pruliers	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Les Hauts Pruliers blanc"}	Nuits-Saint-Georges premier cru Les Hauts Pruliers blanc	\N
9899	956	Nuits-Saint-Georges premier cru Les Hauts Pruliers	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Les Hauts Pruliers rouge"}	Nuits-Saint-Georges premier cru Les Hauts Pruliers rouge	\N
9900	957	Nuits-Saint-Georges premier cru Les Perrières	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Les Perrières blanc"}	Nuits-Saint-Georges premier cru Les Perrières blanc	\N
9901	957	Nuits-Saint-Georges premier cru Les Perrières	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Les Perrières rouge"}	Nuits-Saint-Georges premier cru Les Perrières rouge	\N
11100	2264	Périgord Dordogne	\N	IGP -	{"fra": "Périgord Dordogne rouge"}	Périgord Dordogne rouge	\N
9902	958	Nuits-Saint-Georges premier cru Les Porrets-Saint-Georges	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Les Porrets-Saint-Georges blanc"}	Nuits-Saint-Georges premier cru Les Porrets-Saint-Georges blanc	\N
9903	958	Nuits-Saint-Georges premier cru Les Porrets-Saint-Georges	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Les Porrets-Saint-Georges rouge"}	Nuits-Saint-Georges premier cru Les Porrets-Saint-Georges rouge	\N
9904	959	Nuits-Saint-Georges premier cru Les Poulettes	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Les Poulettes blanc"}	Nuits-Saint-Georges premier cru Les Poulettes blanc	\N
9905	959	Nuits-Saint-Georges premier cru Les Poulettes	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Les Poulettes rouge"}	Nuits-Saint-Georges premier cru Les Poulettes rouge	\N
9906	960	Nuits-Saint-Georges premier cru Les Procès	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Les Procès blanc"}	Nuits-Saint-Georges premier cru Les Procès blanc	\N
9907	960	Nuits-Saint-Georges premier cru Les Procès	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Les Procès rouge"}	Nuits-Saint-Georges premier cru Les Procès rouge	\N
9908	961	Nuits-Saint-Georges premier cru Les Pruliers	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Les Pruliers blanc"}	Nuits-Saint-Georges premier cru Les Pruliers blanc	\N
9909	961	Nuits-Saint-Georges premier cru Les Pruliers	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Les Pruliers rouge"}	Nuits-Saint-Georges premier cru Les Pruliers rouge	\N
9910	962	Nuits-Saint-Georges premier cru Les Saints-Georges	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Les Saints-Georges blanc"}	Nuits-Saint-Georges premier cru Les Saints-Georges blanc	\N
9911	962	Nuits-Saint-Georges premier cru Les Saints-Georges	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Les Saints-Georges rouge"}	Nuits-Saint-Georges premier cru Les Saints-Georges rouge	\N
9912	963	Nuits-Saint-Georges premier cru Les Terres Blanches	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Les Terres Blanches blanc"}	Nuits-Saint-Georges premier cru Les Terres Blanches blanc	\N
9913	963	Nuits-Saint-Georges premier cru Les Terres Blanches	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Les Terres Blanches rouge"}	Nuits-Saint-Georges premier cru Les Terres Blanches rouge	\N
9914	964	Nuits-Saint-Georges premier cru Les Vallerots	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Les Vallerots blanc"}	Nuits-Saint-Georges premier cru Les Vallerots blanc	\N
9915	964	Nuits-Saint-Georges premier cru Les Vallerots	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Les Vallerots rouge"}	Nuits-Saint-Georges premier cru Les Vallerots rouge	\N
9916	965	Nuits-Saint-Georges premier cru Les Vaucrains	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Les Vaucrains blanc"}	Nuits-Saint-Georges premier cru Les Vaucrains blanc	\N
9917	965	Nuits-Saint-Georges premier cru Les Vaucrains	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Les Vaucrains rouge"}	Nuits-Saint-Georges premier cru Les Vaucrains rouge	\N
9918	966	Nuits-Saint-Georges premier cru Roncière	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Roncière blanc"}	Nuits-Saint-Georges premier cru Roncière blanc	\N
9919	966	Nuits-Saint-Georges premier cru Roncière	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Roncière rouge"}	Nuits-Saint-Georges premier cru Roncière rouge	\N
9921	967	Nuits-Saint-Georges premier cru Rue de Chaux	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Rue de Chaux blanc"}	Nuits-Saint-Georges premier cru Rue de Chaux blanc	\N
9922	967	Nuits-Saint-Georges premier cru Rue de Chaux	AOC -	AOP -	{"fra": "Nuits-Saint-Georges premier cru Rue de Chaux rouge"}	Nuits-Saint-Georges premier cru Rue de Chaux rouge	\N
4165	2139	Oie d'Anjou	\N	IGP -	{"fra": "Oie d'Anjou"}	Oie d'Anjou	IG/08/02
7935	1878	Oignon de Roscoff	AOC -	AOP -	{"fra": "Oignon de Roscoff"}	Oignon de Roscoff	\N
14074	1579	Oignon doux des Cévennes	AOC -	AOP -	{"fra": "Oignon doux des Cévennes"}	Oignon doux des Cévennes	\N
3342	1515	Olive de Nice	AOC -	AOP -	{"fra": "Pâte d'olive de Nice"}	Pâte d'olive de Nice	\N
9067	1515	Olive de Nice	AOC -	AOP -	{"fra": "Olive de Nice"}	Olive de Nice	\N
14005	1644	Olive de Nîmes	AOC -	AOP -	{"fra": "Olive de Nîmes"}	Olive de Nîmes	\N
8354	1395	Orléans	AOC -	AOP -	{"fra": "Orléans blanc"}	Orléans blanc	\N
8355	1395	Orléans	AOC -	AOP -	{"fra": "Orléans rosé"}	Orléans rosé	\N
8356	1395	Orléans	AOC -	AOP -	{"fra": "Orléans rouge"}	Orléans rouge	\N
8308	1396	Orléans-Cléry	AOC -	AOP -	{"fra": "Orléans-Cléry"}	Orléans-Cléry	\N
13705	1477	Ossau-Iraty	AOC -	AOP -	{"fra": "Ossau-Iraty"}	Ossau-Iraty	\N
14579	97	Pacherenc du Vic-Bilh	AOC -	AOP -	{"fra": "Pacherenc du Vic-Bilh"}	Pacherenc du Vic-Bilh	\N
14580	97	Pacherenc du Vic-Bilh	AOC -	AOP -	{"fra": "Pacherenc du Vic-Bilh sec"}	Pacherenc du Vic-Bilh sec	\N
14208	1323	Palette	AOC -	AOP -	{"fra": "Palette blanc"}	Palette blanc	\N
14210	1323	Palette	AOC -	AOP -	{"fra": "Palette rosé"}	Palette rosé	\N
14211	1323	Palette	AOC -	AOP -	{"fra": "Palette rouge"}	Palette rouge	\N
3514	1636	Pâtes d'Alsace	\N	IGP -	{"fra": "Pâtes d'Alsace"}	Pâtes d'Alsace	IG/20/95
6422	1324	Patrimonio	AOC -	AOP -	{"fra": "Patrimonio blanc"}	Patrimonio blanc	\N
7916	1324	Patrimonio	AOC -	AOP -	{"fra": "Patrimonio rosé"}	Patrimonio rosé	\N
7917	1324	Patrimonio	AOC -	AOP -	{"fra": "Patrimonio rouge"}	Patrimonio rouge	\N
15174	106	Pauillac	AOC -	AOP -	{"fra": "Pauillac"}	Pauillac	\N
13070	1361	Pays d'Auge	AOC -	AOP -	{"fra": "Pays d'Auge"}	Pays d'Auge	\N
13071	1887	Pays d'Auge Cambremer	AOC -	AOP -	{"fra": "Pays d'Auge Cambremer ou de Cambremer"}	Pays d'Auge Cambremer ou de Cambremer	\N
13391	2024	Pays d'Hérault	\N	IGP -	{"fra": "Pays d'Hérault blanc"}	Pays d'Hérault blanc	\N
13656	2024	Pays d'Hérault	\N	IGP -	{"fra": "Pays d'Hérault primeur ou nouveau blanc"}	Pays d'Hérault primeur ou nouveau blanc	\N
13657	2024	Pays d'Hérault	\N	IGP -	{"fra": "Pays d'Hérault primeur ou nouveau rosé"}	Pays d'Hérault primeur ou nouveau rosé	\N
13658	2024	Pays d'Hérault	\N	IGP -	{"fra": "Pays d'Hérault primeur ou nouveau rouge"}	Pays d'Hérault primeur ou nouveau rouge	\N
13659	2024	Pays d'Hérault	\N	IGP -	{"fra": "Pays d'Hérault rosé"}	Pays d'Hérault rosé	\N
13660	2024	Pays d'Hérault	\N	IGP -	{"fra": "Pays d'Hérault rouge"}	Pays d'Hérault rouge	\N
13560	2248	Pays d'Hérault Bénovie	\N	IGP -	{"fra": "Pays d'Hérault Bénovie blanc"}	Pays d'Hérault Bénovie blanc	\N
13562	2248	Pays d'Hérault Bénovie	\N	IGP -	{"fra": "Pays d'Hérault Bénovie primeur ou nouveau rosé"}	Pays d'Hérault Bénovie primeur ou nouveau rosé	\N
13563	2248	Pays d'Hérault Bénovie	\N	IGP -	{"fra": "Pays d'Hérault Bénovie primeur ou nouveau rouge"}	Pays d'Hérault Bénovie primeur ou nouveau rouge	\N
13564	2248	Pays d'Hérault Bénovie	\N	IGP -	{"fra": "Pays d'Hérault Bénovie rosé"}	Pays d'Hérault Bénovie rosé	\N
13565	2248	Pays d'Hérault Bénovie	\N	IGP -	{"fra": "Pays d'Hérault Bénovie rouge"}	Pays d'Hérault Bénovie rouge	\N
13566	2249	Pays d'Hérault Bérange	\N	IGP -	{"fra": "Pays d'Hérault Bérange blanc"}	Pays d'Hérault Bérange blanc	\N
13567	2249	Pays d'Hérault Bérange	\N	IGP -	{"fra": "Pays d'Hérault Bérange primeur ou nouveau blanc"}	Pays d'Hérault Bérange primeur ou nouveau blanc	\N
13568	2249	Pays d'Hérault Bérange	\N	IGP -	{"fra": "Pays d'Hérault Bérange primeur ou nouveau rosé"}	Pays d'Hérault Bérange primeur ou nouveau rosé	\N
13569	2249	Pays d'Hérault Bérange	\N	IGP -	{"fra": "Pays d'Hérault Bérange primeur ou nouveau rouge"}	Pays d'Hérault Bérange primeur ou nouveau rouge	\N
13570	2249	Pays d'Hérault Bérange	\N	IGP -	{"fra": "Pays d'Hérault Bérange rosé"}	Pays d'Hérault Bérange rosé	\N
13571	2249	Pays d'Hérault Bérange	\N	IGP -	{"fra": "Pays d'Hérault Bérange rouge"}	Pays d'Hérault Bérange rouge	\N
13572	2250	Pays d'Hérault Cassan	\N	IGP -	{"fra": "Pays d'Hérault Cassan blanc"}	Pays d'Hérault Cassan blanc	\N
13573	2250	Pays d'Hérault Cassan	\N	IGP -	{"fra": "Pays d'Hérault Cassan rosé"}	Pays d'Hérault Cassan rosé	\N
13574	2250	Pays d'Hérault Cassan	\N	IGP -	{"fra": "Pays d'Hérault Cassan rouge"}	Pays d'Hérault Cassan rouge	\N
13575	2250	Pays d'Hérault Cassan	\N	IGP -	{"fra": "Pays d'Hérault Cassan primeur ou nouveau blanc"}	Pays d'Hérault Cassan primeur ou nouveau blanc	\N
13576	2250	Pays d'Hérault Cassan	\N	IGP -	{"fra": "Pays d'Hérault Cassan primeur ou nouveau rosé"}	Pays d'Hérault Cassan primeur ou nouveau rosé	\N
13577	2250	Pays d'Hérault Cassan	\N	IGP -	{"fra": "Pays d'Hérault Cassan primeur ou nouveau rouge"}	Pays d'Hérault Cassan primeur ou nouveau rouge	\N
13578	2251	Pays d'Hérault Cessenon	\N	IGP -	{"fra": "Pays d'Hérault Cessenon blanc"}	Pays d'Hérault Cessenon blanc	\N
13579	2251	Pays d'Hérault Cessenon	\N	IGP -	{"fra": "Pays d'Hérault Cessenon primeur ou nouveau blanc"}	Pays d'Hérault Cessenon primeur ou nouveau blanc	\N
13580	2251	Pays d'Hérault Cessenon	\N	IGP -	{"fra": "Pays d'Hérault Cessenon primeur ou nouveau rosé"}	Pays d'Hérault Cessenon primeur ou nouveau rosé	\N
13581	2251	Pays d'Hérault Cessenon	\N	IGP -	{"fra": "Pays d'Hérault Cessenon primeur ou nouveau rouge"}	Pays d'Hérault Cessenon primeur ou nouveau rouge	\N
13582	2251	Pays d'Hérault Cessenon	\N	IGP -	{"fra": "Pays d'Hérault Cessenon rosé"}	Pays d'Hérault Cessenon rosé	\N
13583	2251	Pays d'Hérault Cessenon	\N	IGP -	{"fra": "Pays d'Hérault Cessenon rouge"}	Pays d'Hérault Cessenon rouge	\N
13584	2252	Pays d'Hérault Collines de la Moure	\N	IGP -	{"fra": "Pays d'Hérault Collines de la Moure blanc"}	Pays d'Hérault Collines de la Moure blanc	\N
13585	2252	Pays d'Hérault Collines de la Moure	\N	IGP -	{"fra": "Pays d'Hérault Collines de la Moure primeur ou nouveau blanc"}	Pays d'Hérault Collines de la Moure primeur ou nouveau blanc	\N
13586	2252	Pays d'Hérault Collines de la Moure	\N	IGP -	{"fra": "Pays d'Hérault Collines de la Moure primeur ou nouveau rosé"}	Pays d'Hérault Collines de la Moure primeur ou nouveau rosé	\N
13587	2252	Pays d'Hérault Collines de la Moure	\N	IGP -	{"fra": "Pays d'Hérault Collines de la Moure primeur ou nouveau rouge"}	Pays d'Hérault Collines de la Moure primeur ou nouveau rouge	\N
13588	2252	Pays d'Hérault Collines de la Moure	\N	IGP -	{"fra": "Pays d'Hérault Collines de la Moure rosé"}	Pays d'Hérault Collines de la Moure rosé	\N
13589	2252	Pays d'Hérault Collines de la Moure	\N	IGP -	{"fra": "Pays d'Hérault Collines de la Moure rouge"}	Pays d'Hérault Collines de la Moure rouge	\N
13590	2253	Pays d'Hérault Coteaux de Bessilles	\N	IGP -	{"fra": "Pays d'Hérault Coteaux de Bessilles blanc"}	Pays d'Hérault Coteaux de Bessilles blanc	\N
13591	2253	Pays d'Hérault Coteaux de Bessilles	\N	IGP -	{"fra": "Pays d'Hérault Coteaux de Bessilles primeur ou nouveau blanc"}	Pays d'Hérault Coteaux de Bessilles primeur ou nouveau blanc	\N
13592	2253	Pays d'Hérault Coteaux de Bessilles	\N	IGP -	{"fra": "Pays d'Hérault Coteaux de Bessilles primeur ou nouveau rosé"}	Pays d'Hérault Coteaux de Bessilles primeur ou nouveau rosé	\N
13593	2253	Pays d'Hérault Coteaux de Bessilles	\N	IGP -	{"fra": "Pays d'Hérault Coteaux de Bessilles primeur ou nouveau rouge"}	Pays d'Hérault Coteaux de Bessilles primeur ou nouveau rouge	\N
13594	2253	Pays d'Hérault Coteaux de Bessilles	\N	IGP -	{"fra": "Pays d'Hérault Coteaux de Bessilles rosé"}	Pays d'Hérault Coteaux de Bessilles rosé	\N
13595	2253	Pays d'Hérault Coteaux de Bessilles	\N	IGP -	{"fra": "Pays d'Hérault Coteaux de Bessilles rouge"}	Pays d'Hérault Coteaux de Bessilles rouge	\N
13596	2254	Pays d'Hérault Coteaux de Fontcaude	\N	IGP -	{"fra": "Pays d'Hérault Coteaux de Fontcaude blanc"}	Pays d'Hérault Coteaux de Fontcaude blanc	\N
13597	2254	Pays d'Hérault Coteaux de Fontcaude	\N	IGP -	{"fra": "Pays d'Hérault Coteaux de Fontcaude primeur ou nouveau blanc"}	Pays d'Hérault Coteaux de Fontcaude primeur ou nouveau blanc	\N
13598	2254	Pays d'Hérault Coteaux de Fontcaude	\N	IGP -	{"fra": "Pays d'Hérault Coteaux de Fontcaude primeur ou nouveau rosé"}	Pays d'Hérault Coteaux de Fontcaude primeur ou nouveau rosé	\N
13599	2254	Pays d'Hérault Coteaux de Fontcaude	\N	IGP -	{"fra": "Pays d'Hérault Coteaux de Fontcaude primeur ou nouveau rouge"}	Pays d'Hérault Coteaux de Fontcaude primeur ou nouveau rouge	\N
13600	2254	Pays d'Hérault Coteaux de Fontcaude	\N	IGP -	{"fra": "Pays d'Hérault Coteaux de Fontcaude rosé"}	Pays d'Hérault Coteaux de Fontcaude rosé	\N
13601	2254	Pays d'Hérault Coteaux de Fontcaude	\N	IGP -	{"fra": "Pays d'Hérault Coteaux de Fontcaude rouge"}	Pays d'Hérault Coteaux de Fontcaude rouge	\N
13602	2255	Pays d'Hérault Coteaux de Laurens	\N	IGP -	{"fra": "Pays d'Hérault Coteaux de Laurens blanc"}	Pays d'Hérault Coteaux de Laurens blanc	\N
13603	2255	Pays d'Hérault Coteaux de Laurens	\N	IGP -	{"fra": "Pays d'Hérault Coteaux de Laurens primeur ou nouveau blanc"}	Pays d'Hérault Coteaux de Laurens primeur ou nouveau blanc	\N
13604	2255	Pays d'Hérault Coteaux de Laurens	\N	IGP -	{"fra": "Pays d'Hérault Coteaux de Laurens primeur ou nouveau rosé"}	Pays d'Hérault Coteaux de Laurens primeur ou nouveau rosé	\N
13605	2255	Pays d'Hérault Coteaux de Laurens	\N	IGP -	{"fra": "Pays d'Hérault Coteaux de Laurens primeur ou nouveau rouge"}	Pays d'Hérault Coteaux de Laurens primeur ou nouveau rouge	\N
13606	2255	Pays d'Hérault Coteaux de Laurens	\N	IGP -	{"fra": "Pays d'Hérault Coteaux de Laurens rosé"}	Pays d'Hérault Coteaux de Laurens rosé	\N
13607	2255	Pays d'Hérault Coteaux de Laurens	\N	IGP -	{"fra": "Pays d'Hérault Coteaux de Laurens rouge"}	Pays d'Hérault Coteaux de Laurens rouge	\N
13608	2256	Pays d'Hérault Coteaux de Murviel	\N	IGP -	{"fra": "Pays d'Hérault Coteaux de Murviel blanc"}	Pays d'Hérault Coteaux de Murviel blanc	\N
13609	2256	Pays d'Hérault Coteaux de Murviel	\N	IGP -	{"fra": "Pays d'Hérault Coteaux de Murviel primeur ou nouveau blanc"}	Pays d'Hérault Coteaux de Murviel primeur ou nouveau blanc	\N
13610	2256	Pays d'Hérault Coteaux de Murviel	\N	IGP -	{"fra": "Pays d'Hérault Coteaux de Murviel primeur ou nouveau rosé"}	Pays d'Hérault Coteaux de Murviel primeur ou nouveau rosé	\N
13611	2256	Pays d'Hérault Coteaux de Murviel	\N	IGP -	{"fra": "Pays d'Hérault Coteaux de Murviel primeur ou nouveau rouge"}	Pays d'Hérault Coteaux de Murviel primeur ou nouveau rouge	\N
13612	2256	Pays d'Hérault Coteaux de Murviel	\N	IGP -	{"fra": "Pays d'Hérault Coteaux de Murviel rosé"}	Pays d'Hérault Coteaux de Murviel rosé	\N
13613	2256	Pays d'Hérault Coteaux de Murviel	\N	IGP -	{"fra": "Pays d'Hérault Coteaux de Murviel rouge"}	Pays d'Hérault Coteaux de Murviel rouge	\N
13614	2257	Pays d'Hérault Coteaux du Salagou	\N	IGP -	{"fra": "Pays d'Hérault Coteaux du Salagou blanc"}	Pays d'Hérault Coteaux du Salagou blanc	\N
13615	2257	Pays d'Hérault Coteaux du Salagou	\N	IGP -	{"fra": "Pays d'Hérault Coteaux du Salagou primeur ou nouveau blanc"}	Pays d'Hérault Coteaux du Salagou primeur ou nouveau blanc	\N
13616	2257	Pays d'Hérault Coteaux du Salagou	\N	IGP -	{"fra": "Pays d'Hérault Coteaux du Salagou primeur ou nouveau rosé"}	Pays d'Hérault Coteaux du Salagou primeur ou nouveau rosé	\N
13617	2257	Pays d'Hérault Coteaux du Salagou	\N	IGP -	{"fra": "Pays d'Hérault Coteaux du Salagou primeur ou nouveau rouge"}	Pays d'Hérault Coteaux du Salagou primeur ou nouveau rouge	\N
13618	2257	Pays d'Hérault Coteaux du Salagou	\N	IGP -	{"fra": "Pays d'Hérault Coteaux du Salagou rosé"}	Pays d'Hérault Coteaux du Salagou rosé	\N
13619	2257	Pays d'Hérault Coteaux du Salagou	\N	IGP -	{"fra": "Pays d'Hérault Coteaux du Salagou rouge"}	Pays d'Hérault Coteaux du Salagou rouge	\N
13620	2258	Pays d'Hérault Côtes du Brian	\N	IGP -	{"fra": "Pays d'Hérault Côtes du Brian blanc"}	Pays d'Hérault Côtes du Brian blanc	\N
13621	2258	Pays d'Hérault Côtes du Brian	\N	IGP -	{"fra": "Pays d'Hérault Côtes du Brian primeur ou nouveau blanc"}	Pays d'Hérault Côtes du Brian primeur ou nouveau blanc	\N
13622	2258	Pays d'Hérault Côtes du Brian	\N	IGP -	{"fra": "Pays d'Hérault Côtes du Brian primeur ou nouveau rosé"}	Pays d'Hérault Côtes du Brian primeur ou nouveau rosé	\N
13623	2258	Pays d'Hérault Côtes du Brian	\N	IGP -	{"fra": "Pays d'Hérault Côtes du Brian primeur ou nouveau rouge"}	Pays d'Hérault Côtes du Brian primeur ou nouveau rouge	\N
13624	2258	Pays d'Hérault Côtes du Brian	\N	IGP -	{"fra": "Pays d'Hérault Côtes du Brian rosé"}	Pays d'Hérault Côtes du Brian rosé	\N
13625	2258	Pays d'Hérault Côtes du Brian	\N	IGP -	{"fra": "Pays d'Hérault Côtes du Brian rouge"}	Pays d'Hérault Côtes du Brian rouge	\N
13626	2259	Pays d'Hérault Côtes du Ceressou	\N	IGP -	{"fra": "Pays d'Hérault Côtes du Ceressou blanc"}	Pays d'Hérault Côtes du Ceressou blanc	\N
13627	2259	Pays d'Hérault Côtes du Ceressou	\N	IGP -	{"fra": "Pays d'Hérault Côtes du Ceressou primeur ou nouveau blanc"}	Pays d'Hérault Côtes du Ceressou primeur ou nouveau blanc	\N
13628	2259	Pays d'Hérault Côtes du Ceressou	\N	IGP -	{"fra": "Pays d'Hérault Côtes du Ceressou primeur ou nouveau rosé"}	Pays d'Hérault Côtes du Ceressou primeur ou nouveau rosé	\N
13629	2259	Pays d'Hérault Côtes du Ceressou	\N	IGP -	{"fra": "Pays d'Hérault Côtes du Ceressou primeur ou nouveau rouge"}	Pays d'Hérault Côtes du Ceressou primeur ou nouveau rouge	\N
13630	2259	Pays d'Hérault Côtes du Ceressou	\N	IGP -	{"fra": "Pays d'Hérault Côtes du Ceressou rosé"}	Pays d'Hérault Côtes du Ceressou rosé	\N
13631	2259	Pays d'Hérault Côtes du Ceressou	\N	IGP -	{"fra": "Pays d'Hérault Côtes du Ceressou rouge"}	Pays d'Hérault Côtes du Ceressou rouge	\N
13632	2260	Pays d'Hérault Mont Baudile	\N	IGP -	{"fra": "Pays d'Hérault Mont Baudile blanc"}	Pays d'Hérault Mont Baudile blanc	\N
13633	2260	Pays d'Hérault Mont Baudile	\N	IGP -	{"fra": "Pays d'Hérault Mont Baudile primeur ou nouveau blanc"}	Pays d'Hérault Mont Baudile primeur ou nouveau blanc	\N
13634	2260	Pays d'Hérault Mont Baudile	\N	IGP -	{"fra": "Pays d'Hérault Mont Baudile primeur ou nouveau rosé"}	Pays d'Hérault Mont Baudile primeur ou nouveau rosé	\N
13635	2260	Pays d'Hérault Mont Baudile	\N	IGP -	{"fra": "Pays d'Hérault Mont Baudile primeur ou nouveau rouge"}	Pays d'Hérault Mont Baudile primeur ou nouveau rouge	\N
13636	2260	Pays d'Hérault Mont Baudile	\N	IGP -	{"fra": "Pays d'Hérault Mont Baudile rosé"}	Pays d'Hérault Mont Baudile rosé	\N
13637	2260	Pays d'Hérault Mont Baudile	\N	IGP -	{"fra": "Pays d'Hérault Mont Baudile rouge"}	Pays d'Hérault Mont Baudile rouge	\N
13638	2261	Pays d'Hérault Monts de la Grage	\N	IGP -	{"fra": "Pays d'Hérault Monts de la Grage blanc"}	Pays d'Hérault Monts de la Grage blanc	\N
13639	2261	Pays d'Hérault Monts de la Grage	\N	IGP -	{"fra": "Pays d'Hérault Monts de la Grage primeur ou nouveau blanc"}	Pays d'Hérault Monts de la Grage primeur ou nouveau blanc	\N
13640	2261	Pays d'Hérault Monts de la Grage	\N	IGP -	{"fra": "Pays d'Hérault Monts de la Grage primeur ou nouveau rosé"}	Pays d'Hérault Monts de la Grage primeur ou nouveau rosé	\N
13641	2261	Pays d'Hérault Monts de la Grage	\N	IGP -	{"fra": "Pays d'Hérault Monts de la Grage primeur ou nouveau rouge"}	Pays d'Hérault Monts de la Grage primeur ou nouveau rouge	\N
13642	2261	Pays d'Hérault Monts de la Grage	\N	IGP -	{"fra": "Pays d'Hérault Monts de la Grage rosé"}	Pays d'Hérault Monts de la Grage rosé	\N
13643	2261	Pays d'Hérault Monts de la Grage	\N	IGP -	{"fra": "Pays d'Hérault Monts de la Grage rouge"}	Pays d'Hérault Monts de la Grage rouge	\N
13644	2262	Pays d'Hérault Pays de Bessan	\N	IGP -	{"fra": "Pays d'Hérault Pays de Bessan blanc"}	Pays d'Hérault Pays de Bessan blanc	\N
13645	2262	Pays d'Hérault Pays de Bessan	\N	IGP -	{"fra": "Pays d'Hérault Pays de Bessan blanc  Primeur ou Nouveau"}	Pays d'Hérault Pays de Bessan blanc  Primeur ou Nouveau	\N
13646	2262	Pays d'Hérault Pays de Bessan	\N	IGP -	{"fra": "Pays d'Hérault Pays de Bessan primeur ou nouveau rosé"}	Pays d'Hérault Pays de Bessan primeur ou nouveau rosé	\N
13647	2262	Pays d'Hérault Pays de Bessan	\N	IGP -	{"fra": "Pays d'Hérault Pays de Bessan primeur ou nouveau rouge"}	Pays d'Hérault Pays de Bessan primeur ou nouveau rouge	\N
13648	2262	Pays d'Hérault Pays de Bessan	\N	IGP -	{"fra": "Pays d'Hérault Pays de Bessan rosé"}	Pays d'Hérault Pays de Bessan rosé	\N
13649	2262	Pays d'Hérault Pays de Bessan	\N	IGP -	{"fra": "Pays d'Hérault Pays de Bessan rouge"}	Pays d'Hérault Pays de Bessan rouge	\N
13650	2263	Pays d'Hérault Pays de Caux	\N	IGP -	{"fra": "Pays d'Hérault Pays de Caux blanc"}	Pays d'Hérault Pays de Caux blanc	\N
13651	2263	Pays d'Hérault Pays de Caux	\N	IGP -	{"fra": "Pays d'Hérault Pays de Caux primeur ou nouveau blanc"}	Pays d'Hérault Pays de Caux primeur ou nouveau blanc	\N
13652	2263	Pays d'Hérault Pays de Caux	\N	IGP -	{"fra": "Pays d'Hérault Pays de Caux primeur ou nouveau rosé"}	Pays d'Hérault Pays de Caux primeur ou nouveau rosé	\N
13653	2263	Pays d'Hérault Pays de Caux	\N	IGP -	{"fra": "Pays d'Hérault Pays de Caux primeur ou nouveau rouge"}	Pays d'Hérault Pays de Caux primeur ou nouveau rouge	\N
13654	2263	Pays d'Hérault Pays de Caux	\N	IGP -	{"fra": "Pays d'Hérault Pays de Caux rosé "}	Pays d'Hérault Pays de Caux rosé 	\N
13655	2263	Pays d'Hérault Pays de Caux	\N	IGP -	{"fra": "Pays d'Hérault Pays de Caux rouge"}	Pays d'Hérault Pays de Caux rouge	\N
15404	1964	Pays d'Oc	\N	IGP -	{"fra": "Pays d'Oc blanc"}	Pays d'Oc blanc	\N
15405	1964	Pays d'Oc	\N	IGP -	{"fra": "Pays d'Oc gris"}	Pays d'Oc gris	\N
15406	1964	Pays d'Oc	\N	IGP -	{"fra": "Pays d'Oc gris de gris"}	Pays d'Oc gris de gris	\N
15408	1964	Pays d'Oc	\N	IGP -	{"fra": "Pays d'Oc mousseux de qualité gris"}	Pays d'Oc mousseux de qualité gris	\N
15409	1964	Pays d'Oc	\N	IGP -	{"fra": "Pays d'Oc mousseux de qualité gris de gris"}	Pays d'Oc mousseux de qualité gris de gris	\N
15410	1964	Pays d'Oc	\N	IGP -	{"fra": "Pays d'Oc mousseux de qualité rosé"}	Pays d'Oc mousseux de qualité rosé	\N
15411	1964	Pays d'Oc	\N	IGP -	{"fra": "Pays d'Oc mousseux de qualité rouge"}	Pays d'Oc mousseux de qualité rouge	\N
15412	1964	Pays d'Oc	\N	IGP -	{"fra": "Pays d'Oc primeur ou nouveau blanc"}	Pays d'Oc primeur ou nouveau blanc	\N
15413	1964	Pays d'Oc	\N	IGP -	{"fra": "Pays d'Oc primeur ou nouveau rosé"}	Pays d'Oc primeur ou nouveau rosé	\N
15414	1964	Pays d'Oc	\N	IGP -	{"fra": "Pays d'Oc primeur ou nouveau rouge"}	Pays d'Oc primeur ou nouveau rouge	\N
15415	1964	Pays d'Oc	\N	IGP -	{"fra": "Pays d'Oc rosé"}	Pays d'Oc rosé	\N
15416	1964	Pays d'Oc	\N	IGP -	{"fra": "Pays d'Oc rouge"}	Pays d'Oc rouge	\N
15417	1964	Pays d'Oc	\N	IGP -	{"fra": "Pays d'Oc sur lie blanc "}	Pays d'Oc sur lie blanc 	\N
15418	1964	Pays d'Oc	\N	IGP -	{"fra": "Pays d'Oc sur lie rosé"}	Pays d'Oc sur lie rosé	\N
15419	1964	Pays d'Oc	\N	IGP -	{"fra": "Pays d'Oc Surmûri gris"}	Pays d'Oc Surmûri gris	\N
15420	1964	Pays d'Oc	\N	IGP -	{"fra": "Pays d'Oc Surmûri gris de gris"}	Pays d'Oc Surmûri gris de gris	\N
15421	1964	Pays d'Oc	\N	IGP -	{"fra": "Pays d'Oc surmûris blanc"}	Pays d'Oc surmûris blanc	\N
15422	1964	Pays d'Oc	\N	IGP -	{"fra": "Pays d'Oc surmûris rosé"}	Pays d'Oc surmûris rosé	\N
15423	1964	Pays d'Oc	\N	IGP -	{"fra": "Pays d'Oc surmûris rouge"}	Pays d'Oc surmûris rouge	\N
14110	2421	Pays de Brive	\N	IGP -	{"fra": "Pays de Brive blanc"}	Pays de Brive blanc	\N
14111	2421	Pays de Brive	\N	IGP -	{"fra": "Pays de Brive rosé"}	Pays de Brive rosé	\N
14112	2421	Pays de Brive	\N	IGP -	{"fra": "Pays de Brive rouge"}	Pays de Brive rouge	\N
14113	2421	Pays de Brive	\N	IGP -	{"fra": "Pays de Brive surmûri rouge"}	Pays de Brive surmûri rouge	\N
14114	2421	Pays de Brive	\N	IGP -	{"fra": "Pays de Brive surmûri blanc"}	Pays de Brive surmûri blanc	\N
14115	2421	Pays de Brive	\N	IGP -	{"fra": "Pays de Brive primeur ou nouveau blanc"}	Pays de Brive primeur ou nouveau blanc	\N
14574	2421	Pays de Brive	\N	IGP -	{"fra": "Pays de Brive primeur ou nouveau rosé"}	Pays de Brive primeur ou nouveau rosé	\N
14575	2421	Pays de Brive	\N	IGP -	{"fra": "Pays de Brive primeur ou nouveau rouge"}	Pays de Brive primeur ou nouveau rouge	\N
12805	1990	Pays des Bouches-du-Rhône	\N	IGP -	{"fra": "Pays des Bouches-du-Rhône"}	Pays des Bouches-du-Rhône	\N
13691	1990	Pays des Bouches-du-Rhône	\N	IGP -	{"fra": "Pays des Bouches-du-Rhône primeur ou nouveau blanc"}	Pays des Bouches-du-Rhône primeur ou nouveau blanc	\N
13692	1990	Pays des Bouches-du-Rhône	\N	IGP -	{"fra": "Pays des Bouches-du-Rhône primeur ou nouveau rosé"}	Pays des Bouches-du-Rhône primeur ou nouveau rosé	\N
13693	1990	Pays des Bouches-du-Rhône	\N	IGP -	{"fra": "Pays des Bouches-du-Rhône primeur ou nouveau rouge"}	Pays des Bouches-du-Rhône primeur ou nouveau rouge	\N
13694	1990	Pays des Bouches-du-Rhône	\N	IGP -	{"fra": "Pays des Bouches-du-Rhône rosé"}	Pays des Bouches-du-Rhône rosé	\N
13695	1990	Pays des Bouches-du-Rhône	\N	IGP -	{"fra": "Pays des Bouches-du-Rhône rouge"}	Pays des Bouches-du-Rhône rouge	\N
12806	2305	Pays des Bouches-du-Rhône Terre de Camargue	\N	IGP -	{"fra": "Pays des Bouches-du-Rhône Terre de Camargue blanc"}	Pays des Bouches-du-Rhône Terre de Camargue blanc	\N
13699	2305	Pays des Bouches-du-Rhône Terre de Camargue	\N	IGP -	{"fra": "Pays des Bouches-du-Rhône Terre de Camargue primeur ou nouveau blanc"}	Pays des Bouches-du-Rhône Terre de Camargue primeur ou nouveau blanc	\N
13700	2305	Pays des Bouches-du-Rhône Terre de Camargue	\N	IGP -	{"fra": "Pays des Bouches-du-Rhône Terre de Camargue primeur ou nouveau rosé"}	Pays des Bouches-du-Rhône Terre de Camargue primeur ou nouveau rosé	\N
13701	2305	Pays des Bouches-du-Rhône Terre de Camargue	\N	IGP -	{"fra": "Pays des Bouches-du-Rhône Terre de Camargue primeur ou nouveau rouge"}	Pays des Bouches-du-Rhône Terre de Camargue primeur ou nouveau rouge	\N
13702	2305	Pays des Bouches-du-Rhône Terre de Camargue	\N	IGP -	{"fra": "Pays des Bouches-du-Rhône Terre de Camargue rosé"}	Pays des Bouches-du-Rhône Terre de Camargue rosé	\N
13703	2305	Pays des Bouches-du-Rhône Terre de Camargue	\N	IGP -	{"fra": "Pays des Bouches-du-Rhône Terre de Camargue rouge"}	Pays des Bouches-du-Rhône Terre de Camargue rouge	\N
14907	107	Pécharmant	AOC -	AOP -	{"fra": "Pécharmant"}	Pécharmant	\N
4532	1492	Pélardon	AOC -	AOP -	{"fra": "Pélardon"}	Pélardon	\N
7860	2005	Périgord	\N	IGP -	{"fra": "Périgord blanc"}	Périgord blanc	\N
8455	2005	Périgord	\N	IGP -	{"fra": "Périgord rosé"}	Périgord rosé	\N
11095	2005	Périgord	\N	IGP -	{"fra": "Périgord primeur ou nouveau blanc"}	Périgord primeur ou nouveau blanc	\N
11096	2005	Périgord	\N	IGP -	{"fra": "Périgord primeur ou nouveau rosé"}	Périgord primeur ou nouveau rosé	\N
11097	2005	Périgord	\N	IGP -	{"fra": "Périgord  primeur ou nouveau rouge"}	Périgord  primeur ou nouveau rouge	\N
11098	2264	Périgord Dordogne	\N	IGP -	{"fra": "Périgord Dordogne blanc"}	Périgord Dordogne blanc	\N
11099	2264	Périgord Dordogne	\N	IGP -	{"fra": "Périgord Dordogne rosé"}	Périgord Dordogne rosé	\N
11101	2264	Périgord Dordogne	\N	IGP -	{"fra": "Périgord Dordogne primeur ou nouveau blanc"}	Périgord Dordogne primeur ou nouveau blanc	\N
11102	2264	Périgord Dordogne	\N	IGP -	{"fra": "Périgord Dordogne primeur ou nouveau rosé"}	Périgord Dordogne primeur ou nouveau rosé	\N
11103	2264	Périgord Dordogne	\N	IGP -	{"fra": "Périgord Dordogne primeur ou nouveau rouge"}	Périgord Dordogne primeur ou nouveau rouge	\N
8668	2118	Périgord Vin de Domme	\N	IGP -	{"fra": "Périgord Vin de Domme blanc"}	Périgord Vin de Domme blanc	\N
8669	2118	Périgord Vin de Domme	\N	IGP -	{"fra": "Périgord Vin de Domme rosé"}	Périgord Vin de Domme rosé	\N
8670	2118	Périgord Vin de Domme	\N	IGP -	{"fra": "Périgord Vin de Domme rouge"}	Périgord Vin de Domme rouge	\N
11104	2118	Périgord Vin de Domme	\N	IGP -	{"fra": "Périgord Vin de Domme primeur ou nouveau blanc"}	Périgord Vin de Domme primeur ou nouveau blanc	\N
11105	2118	Périgord Vin de Domme	\N	IGP -	{"fra": "Périgord Vin de Domme primeur ou nouveau rosé"}	Périgord Vin de Domme primeur ou nouveau rosé	\N
11106	2118	Périgord Vin de Domme	\N	IGP -	{"fra": "Périgord Vin de Domme primeur ou nouveau rouge"}	Périgord Vin de Domme primeur ou nouveau rouge	\N
7710	969	Pernand-Vergelesses	AOC -	AOP -	{"fra": "Pernand-Vergelesses blanc"}	Pernand-Vergelesses blanc	\N
9479	969	Pernand-Vergelesses	AOC -	AOP -	{"fra": "Pernand-Vergelesses rouge ou Pernand-Vergelesses Côte de Beaune"}	Pernand-Vergelesses rouge ou Pernand-Vergelesses Côte de Beaune	\N
9461	975	Pernand-Vergelesses premier cru	AOC -	AOP -	{"fra": "Pernand-Vergelesses premier cru blanc"}	Pernand-Vergelesses premier cru blanc	\N
9472	975	Pernand-Vergelesses premier cru	AOC -	AOP -	{"fra": "Pernand-Vergelesses premier cru rouge"}	Pernand-Vergelesses premier cru rouge	\N
9462	1811	Pernand-Vergelesses premier cru Clos Berthet 	AOC -	AOP -	{"fra": "Pernand-Vergelesses premier cru Clos Berthet blanc"}	Pernand-Vergelesses premier cru Clos Berthet blanc	\N
9464	970	Pernand-Vergelesses premier cru Creux de la Net	AOC -	AOP -	{"fra": "Pernand-Vergelesses premier cru Creux de la Net blanc"}	Pernand-Vergelesses premier cru Creux de la Net blanc	\N
9465	970	Pernand-Vergelesses premier cru Creux de la Net	AOC -	AOP -	{"fra": "Pernand-Vergelesses premier cru Creux de la Net rouge"}	Pernand-Vergelesses premier cru Creux de la Net rouge	\N
9466	971	Pernand-Vergelesses premier cru En Caradeux	AOC -	AOP -	{"fra": "Pernand-Vergelesses premier cru En Caradeux blanc"}	Pernand-Vergelesses premier cru En Caradeux blanc	\N
9467	971	Pernand-Vergelesses premier cru En Caradeux	AOC -	AOP -	{"fra": "Pernand-Vergelesses premier cru En Caradeux rouge"}	Pernand-Vergelesses premier cru En Caradeux rouge	\N
9468	972	Pernand-Vergelesses premier cru Ile des Vergelesses	AOC -	AOP -	{"fra": "Pernand-Vergelesses premier cru Ile des Vergelesses blanc"}	Pernand-Vergelesses premier cru Ile des Vergelesses blanc	\N
9469	972	Pernand-Vergelesses premier cru Ile des Vergelesses	AOC -	AOP -	{"fra": "Pernand-Vergelesses premier cru Ile des Vergelesses rouge"}	Pernand-Vergelesses premier cru Ile des Vergelesses rouge	\N
9470	973	Pernand-Vergelesses premier cru Les Fichots	AOC -	AOP -	{"fra": "Pernand-Vergelesses premier cru Les Fichots blanc"}	Pernand-Vergelesses premier cru Les Fichots blanc	\N
9471	973	Pernand-Vergelesses premier cru Les Fichots	AOC -	AOP -	{"fra": "Pernand-Vergelesses premier cru Les Fichots rouge"}	Pernand-Vergelesses premier cru Les Fichots rouge	\N
9473	1810	Pernand-Vergelesses premier cru Sous Frétille 	AOC -	AOP -	{"fra": "Pernand-Vergelesses premier cru Sous Frétille blanc"}	Pernand-Vergelesses premier cru Sous Frétille blanc	\N
9475	974	Pernand-Vergelesses premier cru Vergelesses	AOC -	AOP -	{"fra": "Pernand-Vergelesses premier cru Vergelesses blanc"}	Pernand-Vergelesses premier cru Vergelesses blanc	\N
9476	974	Pernand-Vergelesses premier cru Vergelesses	AOC -	AOP -	{"fra": "Pernand-Vergelesses premier cru Vergelesses rouge"}	Pernand-Vergelesses premier cru Vergelesses rouge	\N
9477	1812	Pernand-Vergelesses premier cru Village de Pernand	AOC -	AOP -	{"fra": "Pernand-Vergelesses premier cru Village de Pernand blanc"}	Pernand-Vergelesses premier cru Village de Pernand blanc	\N
5095	108	Pessac-Léognan	AOC -	AOP -	{"fra": "Pessac-Léognan blanc"}	Pessac-Léognan blanc	\N
5096	108	Pessac-Léognan	AOC -	AOP -	{"fra": "Pessac-Léognan rouge"}	Pessac-Léognan rouge	\N
6350	2189	Petit Chablis	AOC -	AOP -	{"fra": "Petit Chablis"}	Petit Chablis	\N
4155	1895	Petit épeautre de haute Provence	\N	IGP -	{"fra": "Petit épeautre de haute Provence"}	Petit épeautre de haute Provence	IG/02/04
14185	1841	Pic Saint-Loup	AOC -	AOP -	{"fra": "Pic Saint-Loup rosé"}	Pic Saint-Loup rosé	\N
14186	1841	Pic Saint-Loup	AOC -	AOP -	{"fra": "Pic Saint-Loup rouge"}	Pic Saint-Loup rouge	\N
4229	1478	Picodon	AOC -	AOP -	{"fra": "Picodon"}	Picodon	\N
4315	1725	Picpoul de Pinet	AOC -	\N	{"fra": "Picpoul de Pinet"}	Picpoul de Pinet	\N
5997	1851	Pierrevert	AOC -	AOP -	{"fra": "Pierrevert blanc"}	Pierrevert blanc	\N
5998	1851	Pierrevert	AOC -	AOP -	{"fra": "Pierrevert rosé"}	Pierrevert rosé	\N
5999	1851	Pierrevert	AOC -	AOP -	{"fra": "Pierrevert rouge"}	Pierrevert rouge	\N
12820	1514	Piment d'Espelette ou Piment d'Espelette - Ezpeletako Biperra	AOC -	AOP -	{"fra": "Piment d'Espelette ou Piment d'Espelette - Ezpeletako Biperra"}	Piment d'Espelette ou Piment d'Espelette - Ezpeletako Biperra	\N
14889	2137	Pineau des Charentes	AOC -	AOP -	{"fra": "Pineau des Charentes blanc"}	Pineau des Charentes blanc	\N
14890	2137	Pineau des Charentes	AOC -	AOP -	{"fra": "Pineau des Charentes rosé"}	Pineau des Charentes rosé	\N
15933	2137	Pineau des Charentes	AOC -	AOP -	{"fra": "Pineau des Charentes rouge"}	Pineau des Charentes rouge	\N
4176	2432	Pintade de l’Ardèche	\N	IGP -	{"fra": "Pintade de l’Ardèche"}	Pintade de l’Ardèche	\N
4182	1860	Pintadeau de la Drôme	\N	IGP -	{"fra": "Pintadeau de la Drôme"}	Pintadeau de la Drôme	\N
3411	1539	Poireaux de Créances	\N	IGP -	{"fra": "Poireaux de Créances"}	Poireaux de Créances	IG/48/94
4621	1831	Pomelo de Corse	\N	IGP -	{"fra": "Pomelo de Corse"}	Pomelo de Corse	\N
13210	109	Pomerol	AOC -	AOP -	{"fra": "Pomerol"}	Pomerol	\N
7702	977	Pommard	AOC -	AOP -	{"fra": "Pommard"}	Pommard	\N
8599	1006	Pommard premier cru	AOC -	AOP -	{"fra": "Pommard premier cru"}	Pommard premier cru	\N
8600	978	Pommard premier cru Clos Blanc	AOC -	AOP -	{"fra": "Pommard premier cru Clos Blanc"}	Pommard premier cru Clos Blanc	\N
8601	980	Pommard premier cru Clos de la Commaraine	AOC -	AOP -	{"fra": "Pommard premier cru Clos de la Commaraine"}	Pommard premier cru Clos de la Commaraine	\N
8602	979	Pommard premier cru Clos de Verger	AOC -	AOP -	{"fra": "Pommard premier cru Clos de Verger"}	Pommard premier cru Clos de Verger	\N
8603	981	Pommard premier cru Clos des Epeneaux	AOC -	AOP -	{"fra": "Pommard premier cru Clos des Epeneaux"}	Pommard premier cru Clos des Epeneaux	\N
8604	982	Pommard premier cru Derrière Saint-Jean	AOC -	AOP -	{"fra": "Pommard premier cru Derrière Saint-Jean"}	Pommard premier cru Derrière Saint-Jean	\N
8605	983	Pommard premier cru En Largillière	AOC -	AOP -	{"fra": "Pommard premier cru En Largillière"}	Pommard premier cru En Largillière	\N
8606	984	Pommard premier cru La Chanière	AOC -	AOP -	{"fra": "Pommard premier cru La Chanière"}	Pommard premier cru La Chanière	\N
8607	985	Pommard premier cru La Platière	AOC -	AOP -	{"fra": "Pommard premier cru La Platière"}	Pommard premier cru La Platière	\N
8608	986	Pommard premier cru La Refène	AOC -	AOP -	{"fra": "Pommard premier cru La Refène"}	Pommard premier cru La Refène	\N
8609	987	Pommard premier cru Le Clos Micot	AOC -	AOP -	{"fra": "Pommard premier cru Le Clos Micot"}	Pommard premier cru Le Clos Micot	\N
8610	988	Pommard premier cru Le Village	AOC -	AOP -	{"fra": "Pommard premier cru Le Village"}	Pommard premier cru Le Village	\N
8611	989	Pommard premier cru Les Arvelets	AOC -	AOP -	{"fra": "Pommard premier cru Les Arvelets"}	Pommard premier cru Les Arvelets	\N
8612	990	Pommard premier cru Les Bertins	AOC -	AOP -	{"fra": "Pommard premier cru Les Bertins"}	Pommard premier cru Les Bertins	\N
8613	991	Pommard premier cru Les Boucherottes	AOC -	AOP -	{"fra": "Pommard premier cru Les Boucherottes"}	Pommard premier cru Les Boucherottes	\N
8614	992	Pommard premier cru Les Chanlins-Bas	AOC -	AOP -	{"fra": "Pommard premier cru Les Chanlins-Bas"}	Pommard premier cru Les Chanlins-Bas	\N
8615	993	Pommard premier cru Les Chaponnières	AOC -	AOP -	{"fra": "Pommard premier cru Les Chaponnières"}	Pommard premier cru Les Chaponnières	\N
8616	994	Pommard premier cru Les Charmots	AOC -	AOP -	{"fra": "Pommard premier cru Les Charmots"}	Pommard premier cru Les Charmots	\N
8617	995	Pommard premier cru Les Combes Dessus	AOC -	AOP -	{"fra": "Pommard premier cru Les Combes Dessus"}	Pommard premier cru Les Combes Dessus	\N
8618	996	Pommard premier cru Les Croix Noires	AOC -	AOP -	{"fra": "Pommard premier cru Les Croix Noires"}	Pommard premier cru Les Croix Noires	\N
8619	997	Pommard premier cru Les Fremiers	AOC -	AOP -	{"fra": "Pommard premier cru Les Fremiers"}	Pommard premier cru Les Fremiers	\N
8620	998	Pommard premier cru Les Grands Epenots	AOC -	AOP -	{"fra": "Pommard premier cru Les Grands Epenots"}	Pommard premier cru Les Grands Epenots	\N
8621	999	Pommard premier cru Les Jarolières	AOC -	AOP -	{"fra": "Pommard premier cru Les Jarolières"}	Pommard premier cru Les Jarolières	\N
8622	1000	Pommard premier cru Les Petits Epenots	AOC -	AOP -	{"fra": "Pommard premier cru Les Petits Epenots"}	Pommard premier cru Les Petits Epenots	\N
8623	1002	Pommard premier cru Les Pézerolles	AOC -	AOP -	{"fra": "Pommard premier cru Les Pézerolles"}	Pommard premier cru Les Pézerolles	\N
8624	1001	Pommard premier cru Les Poutures	AOC -	AOP -	{"fra": "Pommard premier cru Les Poutures"}	Pommard premier cru Les Poutures	\N
8625	1003	Pommard premier cru Les Rugiens Bas	AOC -	AOP -	{"fra": "Pommard premier cru Les Rugiens Bas"}	Pommard premier cru Les Rugiens Bas	\N
8626	1004	Pommard premier cru Les Rugiens Hauts	AOC -	AOP -	{"fra": "Pommard premier cru Les Rugiens Hauts"}	Pommard premier cru Les Rugiens Hauts	\N
8627	1005	Pommard premier cru Les Saussilles	AOC -	AOP -	{"fra": "Pommard premier cru Les Saussilles"}	Pommard premier cru Les Saussilles	\N
13961	1510	Pomme de terre de l'Ile de Ré	AOC -	AOP -	{"fra": "Pomme de terre de l'Ile de Ré"}	Pomme de terre de l'Ile de Ré	\N
4598	1847	Pomme de terre de Noirmoutier	\N	IGP -	{"fra": "Pomme de terre de Noirmoutier"}	Pomme de terre de Noirmoutier	\N
12767	1612	Pomme du Limousin	AOC -	AOP -	{"fra": "Pomme du Limousin"}	Pomme du Limousin	\N
13094	2367	Pommeau de Bretagne	AOC -	IG - 	{"fra": "Pommeau de Bretagne"}	Pommeau de Bretagne	\N
13113	2378	Pommeau de Normandie	AOC -	IG - 	{"fra": "Pommeau de Normandie"}	Pommeau de Normandie	\N
13104	1888	Pommeau du Maine	AOC -	IG - 	{"fra": "Pommeau du Maine"}	Pommeau du Maine	\N
3412	1540	Pommes de terre de Merville	\N	IGP -	{"fra": "Pommes de terre de Merville"}	Pommes de terre de Merville	IG/46/94
4173	1672	Pommes des Alpes de Haute Durance	\N	IGP -	{"fra": "Pommes des Alpes de Haute Durance"}	Pommes des Alpes de Haute Durance	\N
12988	1541	Pommes et Poires de Savoie ou Pommes de Savoie ou Poires de Savoie	\N	IGP -	{"fra": "Pommes et Poires de Savoie ou Pommes de Savoie ou Poires de Savoie"}	Pommes et Poires de Savoie ou Pommes de Savoie ou Poires de Savoie	IG/49/94
13477	1951	Pont-l'Évêque	AOC -	AOP -	{"fra": "Pont-l'Évêque"}	Pont-l'Évêque	\N
4137	1658	Porc d'Auvergne	\N	IGP -	{"fra": "Porc d'Auvergne"}	Porc d'Auvergne	IG/04/98
4185	1945	Porc de Franche-Comté	\N	IGP -	{"fra": "Porc de Franche-Comté"}	Porc de Franche-Comté	IG/24/95
3414	1542	Porc de la Sarthe	\N	IGP -	{"fra": "Porc de la Sarthe"}	Porc de la Sarthe	IG/42/94
3415	1543	Porc de Normandie	\N	IGP -	{"fra": "Porc de Normandie"}	Porc de Normandie	IG/41/94
3416	1544	Porc de Vendée	\N	IGP -	{"fra": "Porc de Vendée"}	Porc de Vendée	IG/43/94
3417	1545	Porc du Limousin	\N	IGP -	{"fra": "Porc du Limousin"}	Porc du Limousin	IG/40/94
4166	2429	Porc du Sud-Ouest	\N	IGP -	{"fra": "Porc du Sud-Ouest"}	Porc du Sud-Ouest	IG/14/01
14485	2415	Porc noir de Bigorre	AOC -	AOP -	{"fra": "Porc noir de Bigorre"}	Porc noir de Bigorre	\N
7743	1007	Pouilly-Fuissé	AOC -	AOP -	{"fra": "Pouilly-Fuissé"}	Pouilly-Fuissé	\N
9413	1007	Pouilly-Fuissé	AOC -	AOP -	{"fra": "Pouilly-Fuissé complété par une dénomination de climat"}	Pouilly-Fuissé complété par une dénomination de climat	\N
7912	196	Pouilly-Fumé ou Blanc Fumé de Pouilly et Pouilly-sur-Loire	AOC -	AOP -	{"fra": "Pouilly-sur-Loire"}	Pouilly-sur-Loire	\N
7913	196	Pouilly-Fumé ou Blanc Fumé de Pouilly et Pouilly-sur-Loire	AOC -	AOP -	{"fra": "Pouilly-Fumé ou Blanc Fumé de Pouilly"}	Pouilly-Fumé ou Blanc Fumé de Pouilly	\N
7745	1008	Pouilly-Loché	AOC -	AOP -	{"fra": "Pouilly-Loché"}	Pouilly-Loché	\N
9235	1008	Pouilly-Loché	AOC -	AOP -	{"fra": "Pouilly-Loché complété par une dénomination de climat"}	Pouilly-Loché complété par une dénomination de climat	\N
7746	1009	Pouilly-Vinzelles	AOC -	AOP -	{"fra": "Pouilly-Vinzelles"}	Pouilly-Vinzelles	\N
9234	1009	Pouilly-Vinzelles	AOC -	AOP -	{"fra": "Pouilly-Vinzelles complété par une dénomination de climat"}	Pouilly-Vinzelles complété par une dénomination de climat	\N
13460	2397	Poularde du Périgord	\N	IGP -	{"fra": "Poularde du Périgord"}	Poularde du Périgord	\N
14586	2346	Poulet blanc fermier 94 jours et découpe, frais ou surgelé LR/01/11	LR - 	\N	{"fra": " Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé"}	 Poulet blanc fermier élevé en plein air, entier et découpes, frais ou surgelé	LA/07/13
4175	2427	Poulet de l'Ardèche ou Chapon de l'Ardèche	\N	IGP -	{"fra": "Poulet de l'Ardèche ou Chapon de l'Ardèche"}	Poulet de l'Ardèche ou Chapon de l'Ardèche	\N
4174	2400	Poulet des Cévennes ou Chapon des Cévennes	\N	IGP -	{"fra": "Poulet des Cévennes ou Chapon des Cévennes "}	Poulet des Cévennes ou Chapon des Cévennes 	\N
4555	1843	Poulet du Périgord	\N	IGP -	{"fra": "Poulet du Périgord"}	Poulet du Périgord	\N
3288	1480	Pouligny-Saint-Pierre	AOC -	AOP -	{"fra": "Pouligny-Saint-Pierre"}	Pouligny-Saint-Pierre	\N
14913	111	Premières Côtes de Bordeaux	AOC -	AOP -	{"fra": "Premières Côtes de Bordeaux"}	Premières Côtes de Bordeaux	\N
7925	1651	Prés-salés de la baie de Somme	AOC -	AOP -	{"fra": "Prés-salés de la baie de Somme"}	Prés-salés de la baie de Somme	\N
13172	1674	Prés-salés du Mont-Saint-Michel	AOC -	AOP -	{"fra": "Prés-salés du Mont-Saint-Michel"}	Prés-salés du Mont-Saint-Michel	\N
14179	1546	Pruneaux d'Agen	\N	IGP -	{"fra": "Pruneaux d'Agen"}	Pruneaux d'Agen	IG/02/96
14977	148	Puisseguin-Saint-Emilion	AOC -	AOP -	{"fra": "Puisseguin-Saint-Emilion"}	Puisseguin-Saint-Emilion	\N
7694	1010	Puligny-Montrachet	AOC -	AOP -	{"fra": "Puligny-Montrachet blanc"}	Puligny-Montrachet blanc	\N
8121	1010	Puligny-Montrachet	AOC -	AOP -	{"fra": "Puligny-Montrachet rouge ou Puligny-Montrachet Côte de Beaune"}	Puligny-Montrachet rouge ou Puligny-Montrachet Côte de Beaune	\N
8088	1028	Puligny-Montrachet premier cru	AOC -	AOP -	{"fra": "Puligny-Montrachet premier cru blanc"}	Puligny-Montrachet premier cru blanc	\N
8119	1028	Puligny-Montrachet premier cru	AOC -	AOP -	{"fra": "Puligny-Montrachet premier cru rouge"}	Puligny-Montrachet premier cru rouge	\N
8089	1011	Puligny-Montrachet premier cru Champ Canet	AOC -	AOP -	{"fra": "Puligny-Montrachet premier cru Champ Canet blanc"}	Puligny-Montrachet premier cru Champ Canet blanc	\N
8090	1011	Puligny-Montrachet premier cru Champ Canet	AOC -	AOP -	{"fra": "Puligny-Montrachet premier cru Champ Canet rouge"}	Puligny-Montrachet premier cru Champ Canet rouge	\N
8091	1012	Puligny-Montrachet premier cru Champ Gain	AOC -	AOP -	{"fra": "Puligny-Montrachet premier cru Champ Gain blanc"}	Puligny-Montrachet premier cru Champ Gain blanc	\N
8092	1012	Puligny-Montrachet premier cru Champ Gain	AOC -	AOP -	{"fra": "Puligny-Montrachet premier cru Champ Gain rouge"}	Puligny-Montrachet premier cru Champ Gain rouge	\N
8093	1013	Puligny-Montrachet premier cru Clavaillon	AOC -	AOP -	{"fra": "Puligny-Montrachet premier cru Clavaillon blanc"}	Puligny-Montrachet premier cru Clavaillon blanc	\N
8094	1013	Puligny-Montrachet premier cru Clavaillon	AOC -	AOP -	{"fra": "Puligny-Montrachet premier cru Clavaillon rouge"}	Puligny-Montrachet premier cru Clavaillon rouge	\N
8095	1014	Puligny-Montrachet premier cru Clos de la Garenne	AOC -	AOP -	{"fra": "Puligny-Montrachet premier cru Clos de la Garenne blanc"}	Puligny-Montrachet premier cru Clos de la Garenne blanc	\N
8096	1014	Puligny-Montrachet premier cru Clos de la Garenne	AOC -	AOP -	{"fra": "Puligny-Montrachet premier cru Clos de la Garenne rouge"}	Puligny-Montrachet premier cru Clos de la Garenne rouge	\N
8097	1015	Puligny-Montrachet premier cru Clos de la Mouchère	AOC -	AOP -	{"fra": "Puligny-Montrachet premier cru Clos de la Mouchère blanc"}	Puligny-Montrachet premier cru Clos de la Mouchère blanc	\N
8098	1015	Puligny-Montrachet premier cru Clos de la Mouchère	AOC -	AOP -	{"fra": "Puligny-Montrachet premier cru Clos de la Mouchère rouge"}	Puligny-Montrachet premier cru Clos de la Mouchère rouge	\N
8099	1016	Puligny-Montrachet premier cru Hameau de Blagny	AOC -	AOP -	{"fra": "Puligny-Montrachet premier cru Hameau de Blagny blanc"}	Puligny-Montrachet premier cru Hameau de Blagny blanc	\N
8100	1017	Puligny-Montrachet premier cru La Garenne	AOC -	AOP -	{"fra": "Puligny-Montrachet premier cru La Garenne blanc"}	Puligny-Montrachet premier cru La Garenne blanc	\N
8101	1018	Puligny-Montrachet premier cru La Truffière	AOC -	AOP -	{"fra": "Puligny-Montrachet premier cru La Truffière blanc"}	Puligny-Montrachet premier cru La Truffière blanc	\N
8102	1018	Puligny-Montrachet premier cru La Truffière	AOC -	AOP -	{"fra": "Puligny-Montrachet premier cru La Truffière rouge"}	Puligny-Montrachet premier cru La Truffière rouge	\N
7690	1074	Saint-Aubin	AOC -	AOP -	{"fra": "Saint-Aubin blanc"}	Saint-Aubin blanc	\N
8103	1019	Puligny-Montrachet premier cru Le Cailleret	AOC -	AOP -	{"fra": "Puligny-Montrachet premier cru Le Cailleret blanc"}	Puligny-Montrachet premier cru Le Cailleret blanc	\N
8104	1019	Puligny-Montrachet premier cru Le Cailleret	AOC -	AOP -	{"fra": "Puligny-Montrachet premier cru Le Cailleret rouge"}	Puligny-Montrachet premier cru Le Cailleret rouge	\N
8105	1020	Puligny-Montrachet premier cru Les Chalumaux	AOC -	AOP -	{"fra": "Puligny-Montrachet premier cru Les Chalumaux blanc"}	Puligny-Montrachet premier cru Les Chalumaux blanc	\N
8106	1020	Puligny-Montrachet premier cru Les Chalumaux	AOC -	AOP -	{"fra": "Puligny-Montrachet premier cru Les Chalumaux rouge"}	Puligny-Montrachet premier cru Les Chalumaux rouge	\N
8107	1021	Puligny-Montrachet premier cru Les Combettes	AOC -	AOP -	{"fra": "Puligny-Montrachet premier cru Les Combettes blanc"}	Puligny-Montrachet premier cru Les Combettes blanc	\N
8108	1021	Puligny-Montrachet premier cru Les Combettes	AOC -	AOP -	{"fra": "Puligny-Montrachet premier cru Les Combettes rouge"}	Puligny-Montrachet premier cru Les Combettes rouge	\N
8109	1022	Puligny-Montrachet premier cru Les Demoiselles	AOC -	AOP -	{"fra": "Puligny-Montrachet premier cru Les Demoiselles blanc"}	Puligny-Montrachet premier cru Les Demoiselles blanc	\N
8110	1022	Puligny-Montrachet premier cru Les Demoiselles	AOC -	AOP -	{"fra": "Puligny-Montrachet premier cru Les Demoiselles rouge"}	Puligny-Montrachet premier cru Les Demoiselles rouge	\N
8111	1023	Puligny-Montrachet premier cru Les Folatières	AOC -	AOP -	{"fra": "Puligny-Montrachet premier cru Les Folatières blanc"}	Puligny-Montrachet premier cru Les Folatières blanc	\N
8112	1023	Puligny-Montrachet premier cru Les Folatières	AOC -	AOP -	{"fra": "Puligny-Montrachet premier cru Les Folatières rouge"}	Puligny-Montrachet premier cru Les Folatières rouge	\N
7730	1034	Romanée-Saint-Vivant	AOC -	AOP -	{"fra": "Romanée-Saint-Vivant"}	Romanée-Saint-Vivant	\N
8113	1024	Puligny-Montrachet premier cru Les Perrières	AOC -	AOP -	{"fra": "Puligny-Montrachet premier cru Les Perrières blanc"}	Puligny-Montrachet premier cru Les Perrières blanc	\N
8114	1024	Puligny-Montrachet premier cru Les Perrières	AOC -	AOP -	{"fra": "Puligny-Montrachet premier cru Les Perrières rouge"}	Puligny-Montrachet premier cru Les Perrières rouge	\N
8115	1025	Puligny-Montrachet premier cru Les Pucelles	AOC -	AOP -	{"fra": "Puligny-Montrachet premier cru Les Pucelles blanc"}	Puligny-Montrachet premier cru Les Pucelles blanc	\N
8116	1025	Puligny-Montrachet premier cru Les Pucelles	AOC -	AOP -	{"fra": "Puligny-Montrachet premier cru Les Pucelles rouge"}	Puligny-Montrachet premier cru Les Pucelles rouge	\N
8117	1026	Puligny-Montrachet premier cru Les Referts	AOC -	AOP -	{"fra": "Puligny-Montrachet premier cru Les Referts blanc"}	Puligny-Montrachet premier cru Les Referts blanc	\N
8118	1026	Puligny-Montrachet premier cru Les Referts	AOC -	AOP -	{"fra": "Puligny-Montrachet premier cru Les Referts rouge"}	Puligny-Montrachet premier cru Les Referts rouge	\N
8120	1027	Puligny-Montrachet premier cru Sous le Puits	AOC -	AOP -	{"fra": "Puligny-Montrachet premier cru Sous le Puits blanc"}	Puligny-Montrachet premier cru Sous le Puits blanc	\N
7861	2056	Puy-de-Dôme	\N	IGP -	{"fra": "Puy-de-Dôme blanc"}	Puy-de-Dôme blanc	\N
8445	2056	Puy-de-Dôme	\N	IGP -	{"fra": "Puy-de-Dôme rosé"}	Puy-de-Dôme rosé	\N
8446	2056	Puy-de-Dôme	\N	IGP -	{"fra": "Puy-de-Dôme rouge"}	Puy-de-Dôme rouge	\N
11107	2056	Puy-de-Dôme	\N	IGP -	{"fra": "Puy-de-Dôme primeur ou nouveau blanc"}	Puy-de-Dôme primeur ou nouveau blanc	\N
11108	2056	Puy-de-Dôme	\N	IGP -	{"fra": "Puy-de-Dôme primeur ou nouveau rosé"}	Puy-de-Dôme primeur ou nouveau rosé	\N
11109	2056	Puy-de-Dôme	\N	IGP -	{"fra": "Puy-de-Dôme primeur ou nouveau rouge"}	Puy-de-Dôme primeur ou nouveau rouge	\N
15169	197	Quarts de Chaume	AOC -	AOP -	{"fra": "Quarts de Chaume"}	Quarts de Chaume	\N
13089	2363	Quetsch d’Alsace	\N	IG - 	{"fra": "Quetsch d’Alsace"}	Quetsch d’Alsace	\N
7984	198	Quincy	AOC -	AOP -	{"fra": "Quincy"}	Quincy	\N
4344	1753	Raclette de Savoie	\N	IGP -	{"fra": "Raclette de Savoie"}	Raclette de Savoie	\N
15566	1341	Rasteau	AOC -	AOP -	{"fra": "Rasteau ambré"}	Rasteau ambré	\N
15567	1341	Rasteau	AOC -	AOP -	{"fra": "Rasteau ambré hors d'âge"}	Rasteau ambré hors d'âge	\N
15568	1341	Rasteau	AOC -	AOP -	{"fra": "Rasteau ambré rancio"}	Rasteau ambré rancio	\N
15569	1341	Rasteau	AOC -	AOP -	{"fra": "Rasteau ambré rancio hors d'äge"}	Rasteau ambré rancio hors d'äge	\N
15570	1341	Rasteau	AOC -	AOP -	{"fra": "Rasteau blanc"}	Rasteau blanc	\N
15571	1341	Rasteau	AOC -	AOP -	{"fra": "Rasteau grenat"}	Rasteau grenat	\N
15572	1341	Rasteau	AOC -	AOP -	{"fra": "Rasteau rosé"}	Rasteau rosé	\N
15573	1341	Rasteau	AOC -	AOP -	{"fra": "Rasteau tuilé"}	Rasteau tuilé	\N
15574	1341	Rasteau	AOC -	AOP -	{"fra": "Rasteau tuilé hors d'âge"}	Rasteau tuilé hors d'âge	\N
15575	1341	Rasteau	AOC -	AOP -	{"fra": "Rasteau tuilé rancio"}	Rasteau tuilé rancio	\N
15576	1341	Rasteau	AOC -	AOP -	{"fra": "Rasteau tuilé rancio hors âge"}	Rasteau tuilé rancio hors âge	\N
15577	1341	Rasteau	AOC -	AOP -	{"fra": "Rasteau rouge sec"}	Rasteau rouge sec	\N
13116	2380	Ratafia de Champagne ou Ratafia champenois	\N	IG - 	{"fra": "Ratafia de Champagne ou Ratafia champenois"}	Ratafia de Champagne ou Ratafia champenois	\N
4181	1872	Raviole du Dauphiné	\N	IGP -	{"fra": "Raviole du Dauphiné"}	Raviole du Dauphiné	\N
4201	1481	Reblochon de Savoie	AOC -	AOP -	{"fra": "Reblochon ou Reblochon de Savoie"}	Reblochon ou Reblochon de Savoie	\N
10249	1029	Régnié	AOC -	AOP -	{"fra": "Régnié ou Régnié cru du Beaujolais"}	Régnié ou Régnié cru du Beaujolais	\N
5753	199	Reuilly	AOC -	AOP -	{"fra": "Reuilly blanc"}	Reuilly blanc	\N
5754	199	Reuilly	AOC -	AOP -	{"fra": "Reuilly rosé"}	Reuilly rosé	\N
5755	199	Reuilly	AOC -	AOP -	{"fra": "Reuilly rouge"}	Reuilly rouge	\N
14212	2433	Rhum de la Gouadeloupe Marie Galante	\N	IG - 	{"fra": "Rhum de la Guadeloupe Marie Galante"}	Rhum de la Guadeloupe Marie Galante	\N
13102	2372	Rhum de la Guadeloupe	\N	IG - 	{"fra": "Rhum de la Guadeloupe blanc"}	Rhum de la Guadeloupe blanc	\N
13101	2371	Rhum de la Guyane ou Rhum de Guyane ou Rhum Guyane	\N	IG - 	{"fra": "Rhum de la Guyane ou Rhum de Guyane ou Rhum Guyane"}	Rhum de la Guyane ou Rhum de Guyane ou Rhum Guyane	\N
13103	2373	Rhum de la Martinique	AOC -	IG - 	{"fra": "Rhum de la Martinique"}	Rhum de la Martinique	\N
13100	2370	Rhum de La Réunion ou Rhum de Réunion ou Rhum Réunion ou Rhum de l'Ile	\N	IG - 	{"fra": "Rhum de La Réunion ou Rhum de Réunion ou Rhum Réunion ou Rhum de l'Ile de La Réunion"}	Rhum de La Réunion ou Rhum de Réunion ou Rhum Réunion ou Rhum de l'Ile de La Réunion	\N
13092	2366	Rhum de sucrerie de la Baie du Galion ou Rhum de la Baie du Gali	\N	IG - 	{"fra": "Rhum de sucrerie de la Baie du Galion ou Rhum de la Baie du Galion ou Rhum Baie du Galion"}	Rhum de sucrerie de la Baie du Galion ou Rhum de la Baie du Galion ou Rhum Baie du Galion	\N
13091	2365	Rhum des Antilles françaises	\N	IG - 	{"fra": "Rhum des Antilles françaises"}	Rhum des Antilles françaises	\N
13099	2369	Rhum des départements français d'outre-mer ou Rhum de l'outre-mer fran	\N	IG - 	{"fra": "Rhum des départements français d'outre-mer ou Rhum de l'outre-mer français"}	Rhum des départements français d'outre-mer ou Rhum de l'outre-mer français	\N
7734	1032	Richebourg	AOC -	AOP -	{"fra": "Richebourg"}	Richebourg	\N
4197	1647	Rigotte de Condrieu	AOC -	AOP -	{"fra": "Rigotte de Condrieu"}	Rigotte de Condrieu	\N
13300	1800	Rillettes de Tours	\N	IGP -	{"fra": "Rillettes de Tours"}	Rillettes de Tours	IG/01/99
6088	1342	Rivesaltes	AOC -	AOP -	{"fra": "Rivesaltes ambré"}	Rivesaltes ambré	\N
6089	1342	Rivesaltes	AOC -	AOP -	{"fra": "Rivesaltes grenat"}	Rivesaltes grenat	\N
6090	1342	Rivesaltes	AOC -	AOP -	{"fra": "Rivesaltes tuilé"}	Rivesaltes tuilé	\N
6091	1342	Rivesaltes	AOC -	AOP -	{"fra": "Rivesaltes ambré hors d'âge"}	Rivesaltes ambré hors d'âge	\N
6092	1342	Rivesaltes	AOC -	AOP -	{"fra": "Rivesaltes tuilé hors d'âge"}	Rivesaltes tuilé hors d'âge	\N
6093	1342	Rivesaltes	AOC -	AOP -	{"fra": "Rivesaltes rancio"}	Rivesaltes rancio	\N
4535	1547	Riz de Camargue	\N	IGP -	{"fra": "Riz de Camargue"}	Riz de Camargue	IG/20/96
13352	1482	Rocamadour	AOC -	AOP -	{"fra": "Rocamadour"}	Rocamadour	\N
7731	1033	Romanée-Conti	AOC -	AOP -	{"fra": "Romanée-Conti"}	Romanée-Conti	\N
15063	200	Rosé de Loire	AOC -	AOP -	{"fra": "Rosé de Loire"}	Rosé de Loire	\N
13082	1961	Rosé des Riceys	AOC -	AOP -	{"fra": "Rosé des Riceys"}	Rosé des Riceys	\N
13478	2401	Rosée des Pyrénées catalanes	\N	IGP -	{"fra": "Rosée des Pyrénées catalanes"}	Rosée des Pyrénées catalanes	\N
8309	149	Rosette	AOC -	AOP -	{"fra": "Rosette"}	Rosette	\N
5812	1885	Roussette de Savoie	AOC -	AOP -	{"fra": "Roussette de Savoie"}	Roussette de Savoie	\N
7962	1147	Roussette de Savoie Frangy	AOC -	AOP -	{"fra": "Roussette de Savoie Frangy"}	Roussette de Savoie Frangy	\N
7963	1148	Roussette de Savoie Marestel	AOC -	AOP -	{"fra": "Roussette de Savoie Marestel"}	Roussette de Savoie Marestel	\N
7964	1149	Roussette de Savoie Monterminod	AOC -	AOP -	{"fra": "Roussette de Savoie Monterminod"}	Roussette de Savoie Monterminod	\N
7965	1150	Roussette de Savoie Monthoux	AOC -	AOP -	{"fra": "Roussette de Savoie Monthoux"}	Roussette de Savoie Monthoux	\N
9199	1884	Roussette du Bugey	AOC -	AOP -	{"fra": "Roussette du Bugey"}	Roussette du Bugey	\N
9200	1402	Roussette du Bugey Montagnieu	AOC -	AOP -	{"fra": "Roussette du Bugey Montagnieu"}	Roussette du Bugey Montagnieu	\N
9201	1601	Roussette du Bugey Virieu-le-Grand	AOC -	AOP -	{"fra": "Roussette du Bugey Virieu-le-Grand"}	Roussette du Bugey Virieu-le-Grand	\N
7725	1035	Ruchottes-Chambertin	AOC -	AOP -	{"fra": "Ruchottes-Chambertin"}	Ruchottes-Chambertin	\N
7740	1036	Rully	AOC -	AOP -	{"fra": "Rully blanc"}	Rully blanc	\N
9190	1036	Rully	AOC -	AOP -	{"fra": "Rully rouge"}	Rully rouge	\N
9144	1060	Rully premier cru	AOC -	AOP -	{"fra": "Rully premier cru blanc"}	Rully premier cru blanc	\N
9187	1060	Rully premier cru	AOC -	AOP -	{"fra": "Rully premier cru rouge"}	Rully premier cru rouge	\N
9142	1037	Rully premier cru Agneux	AOC -	AOP -	{"fra": "Rully premier cru Agneux blanc"}	Rully premier cru Agneux blanc	\N
9143	1037	Rully premier cru Agneux	AOC -	AOP -	{"fra": "Rully premier cru Agneux rouge"}	Rully premier cru Agneux rouge	\N
9145	1038	Rully premier cru Champs Cloux	AOC -	AOP -	{"fra": "Rully premier cru Champs Cloux blanc"}	Rully premier cru Champs Cloux blanc	\N
9146	1038	Rully premier cru Champs Cloux	AOC -	AOP -	{"fra": "Rully premier cru Champs Cloux rouge"}	Rully premier cru Champs Cloux rouge	\N
9147	1039	Rully premier cru Chapitre	AOC -	AOP -	{"fra": "Rully premier cru Chapitre blanc"}	Rully premier cru Chapitre blanc	\N
9148	1039	Rully premier cru Chapitre	AOC -	AOP -	{"fra": "Rully premier cru Chapitre rouge"}	Rully premier cru Chapitre rouge	\N
9149	1041	Rully premier cru Clos du Chaigne	AOC -	AOP -	{"fra": "Rully premier cru Clos du Chaigne blanc"}	Rully premier cru Clos du Chaigne blanc	\N
9150	1041	Rully premier cru Clos du Chaigne	AOC -	AOP -	{"fra": "Rully premier cru Clos du Chaigne rouge"}	Rully premier cru Clos du Chaigne rouge	\N
9151	1040	Rully premier cru Clos St Jacques	AOC -	AOP -	{"fra": "Rully premier cru Clos St Jacques blanc"}	Rully premier cru Clos St Jacques blanc	\N
9152	1040	Rully premier cru Clos St Jacques	AOC -	AOP -	{"fra": "Rully premier cru Clos St Jacques rouge"}	Rully premier cru Clos St Jacques rouge	\N
9153	1042	Rully premier cru Cloux	AOC -	AOP -	{"fra": "Rully premier cru Cloux blanc"}	Rully premier cru Cloux blanc	\N
9154	1042	Rully premier cru Cloux	AOC -	AOP -	{"fra": "Rully premier cru Cloux rouge"}	Rully premier cru Cloux rouge	\N
9155	1043	Rully premier cru Grésigny	AOC -	AOP -	{"fra": "Rully premier cru Grésigny blanc"}	Rully premier cru Grésigny blanc	\N
9156	1043	Rully premier cru Grésigny	AOC -	AOP -	{"fra": "Rully premier cru Grésigny rouge"}	Rully premier cru Grésigny rouge	\N
9157	1044	Rully premier cru La Bressande	AOC -	AOP -	{"fra": "Rully premier cru La Bressande blanc"}	Rully premier cru La Bressande blanc	\N
9158	1044	Rully premier cru La Bressande	AOC -	AOP -	{"fra": "Rully premier cru La Bressande rouge"}	Rully premier cru La Bressande rouge	\N
9159	1045	Rully premier cru La Fosse	AOC -	AOP -	{"fra": "Rully premier cru La Fosse blanc"}	Rully premier cru La Fosse blanc	\N
9160	1045	Rully premier cru La Fosse	AOC -	AOP -	{"fra": "Rully premier cru La Fosse rouge"}	Rully premier cru La Fosse rouge	\N
9161	1046	Rully premier cru La Pucelle	AOC -	AOP -	{"fra": "Rully premier cru La Pucelle blanc"}	Rully premier cru La Pucelle blanc	\N
9162	1046	Rully premier cru La Pucelle	AOC -	AOP -	{"fra": "Rully premier cru La Pucelle rouge"}	Rully premier cru La Pucelle rouge	\N
9163	1047	Rully premier cru La Renarde	AOC -	AOP -	{"fra": "Rully premier cru La Renarde blanc"}	Rully premier cru La Renarde blanc	\N
9164	1047	Rully premier cru La Renarde	AOC -	AOP -	{"fra": "Rully premier cru La Renarde rouge"}	Rully premier cru La Renarde rouge	\N
9165	1051	Rully premier cru Le Meix Cadot	AOC -	AOP -	{"fra": "Rully premier cru Le Meix Cadot blanc"}	Rully premier cru Le Meix Cadot blanc	\N
9166	1051	Rully premier cru Le Meix Cadot	AOC -	AOP -	{"fra": "Rully premier cru Le Meix Cadot rouge"}	Rully premier cru Le Meix Cadot rouge	\N
9167	1052	Rully premier cru Le Meix Caillet	AOC -	AOP -	{"fra": "Rully premier cru Le Meix Caillet blanc"}	Rully premier cru Le Meix Caillet blanc	\N
9168	1052	Rully premier cru Le Meix Caillet	AOC -	AOP -	{"fra": "Rully premier cru Le Meix Caillet rouge"}	Rully premier cru Le Meix Caillet rouge	\N
9169	1048	Rully premier cru Les Pierres	AOC -	AOP -	{"fra": "Rully premier cru Les Pierres blanc"}	Rully premier cru Les Pierres blanc	\N
9170	1048	Rully premier cru Les Pierres	AOC -	AOP -	{"fra": "Rully premier cru Les Pierres rouge"}	Rully premier cru Les Pierres rouge	\N
9171	1049	Rully premier cru Margotés	AOC -	AOP -	{"fra": "Rully premier cru Margotés blanc"}	Rully premier cru Margotés blanc	\N
9172	1049	Rully premier cru Margotés	AOC -	AOP -	{"fra": "Rully premier cru Margotés rouge"}	Rully premier cru Margotés rouge	\N
9173	1050	Rully premier cru Marissou	AOC -	AOP -	{"fra": "Rully premier cru Marissou blanc"}	Rully premier cru Marissou blanc	\N
9174	1050	Rully premier cru Marissou	AOC -	AOP -	{"fra": "Rully premier cru Marissou rouge"}	Rully premier cru Marissou rouge	\N
9175	1053	Rully premier cru Molesme	AOC -	AOP -	{"fra": "Rully premier cru Molesme blanc"}	Rully premier cru Molesme blanc	\N
9176	1053	Rully premier cru Molesme	AOC -	AOP -	{"fra": "Rully premier cru Molesme rouge"}	Rully premier cru Molesme rouge	\N
9177	1054	Rully premier cru Montpalais	AOC -	AOP -	{"fra": "Rully premier cru Montpalais blanc"}	Rully premier cru Montpalais blanc	\N
9178	1054	Rully premier cru Montpalais	AOC -	AOP -	{"fra": "Rully premier cru Montpalais rouge"}	Rully premier cru Montpalais rouge	\N
9179	1055	Rully premier cru Pillot	AOC -	AOP -	{"fra": "Rully premier cru Pillot blanc"}	Rully premier cru Pillot blanc	\N
9180	1055	Rully premier cru Pillot	AOC -	AOP -	{"fra": "Rully premier cru Pillot rouge"}	Rully premier cru Pillot rouge	\N
9181	1056	Rully premier cru Préaux	AOC -	AOP -	{"fra": "Rully premier cru Préaux blanc"}	Rully premier cru Préaux blanc	\N
9182	1056	Rully premier cru Préaux	AOC -	AOP -	{"fra": "Rully premier cru Préaux rouge"}	Rully premier cru Préaux rouge	\N
9183	1057	Rully premier cru Rabourcé	AOC -	AOP -	{"fra": "Rully premier cru Rabourcé blanc"}	Rully premier cru Rabourcé blanc	\N
9184	1057	Rully premier cru Rabourcé	AOC -	AOP -	{"fra": "Rully premier cru Rabourcé rouge"}	Rully premier cru Rabourcé rouge	\N
9185	1058	Rully premier cru Raclot	AOC -	AOP -	{"fra": "Rully premier cru Raclot blanc"}	Rully premier cru Raclot blanc	\N
9186	1058	Rully premier cru Raclot	AOC -	AOP -	{"fra": "Rully premier cru Raclot rouge"}	Rully premier cru Raclot rouge	\N
9188	1059	Rully premier cru Vauvry	AOC -	AOP -	{"fra": "Rully premier cru Vauvry blanc"}	Rully premier cru Vauvry blanc	\N
9189	1059	Rully premier cru Vauvry	AOC -	AOP -	{"fra": "Rully premier cru Vauvry rouge"}	Rully premier cru Vauvry rouge	\N
7873	2153	Sable de Camargue	\N	IGP -	{"fra": "Sable de Camargue blanc"}	Sable de Camargue blanc	\N
8396	2153	Sable de Camargue	\N	IGP -	{"fra": "Sable de Camargue gris"}	Sable de Camargue gris	\N
8397	2153	Sable de Camargue	\N	IGP -	{"fra": "Sable de Camargue rosé"}	Sable de Camargue rosé	\N
8398	2153	Sable de Camargue	\N	IGP -	{"fra": "Sable de Camargue rouge"}	Sable de Camargue rouge	\N
8500	2153	Sable de Camargue	\N	IGP -	{"fra": "Sable de Camargue gris de gris"}	Sable de Camargue gris de gris	\N
8501	2153	Sable de Camargue	\N	IGP -	{"fra": "Sable de Camargue mousseux de qualité blanc"}	Sable de Camargue mousseux de qualité blanc	\N
8502	2153	Sable de Camargue	\N	IGP -	{"fra": "Sable de Camargue mousseux de qualité rosé"}	Sable de Camargue mousseux de qualité rosé	\N
8503	2153	Sable de Camargue	\N	IGP -	{"fra": "Sable de Camargue mousseux de qualité rouge"}	Sable de Camargue mousseux de qualité rouge	\N
8504	2153	Sable de Camargue	\N	IGP -	{"fra": "Sable de Camargue primeur ou nouveau blanc"}	Sable de Camargue primeur ou nouveau blanc	\N
8505	2153	Sable de Camargue	\N	IGP -	{"fra": "Sable de Camargue primeur ou nouveau gris"}	Sable de Camargue primeur ou nouveau gris	\N
8506	2153	Sable de Camargue	\N	IGP -	{"fra": "Sable de Camargue primeur ou nouveau gris de gris"}	Sable de Camargue primeur ou nouveau gris de gris	\N
8507	2153	Sable de Camargue	\N	IGP -	{"fra": "Sable de Camargue primeur ou nouveau rosé"}	Sable de Camargue primeur ou nouveau rosé	\N
8508	2153	Sable de Camargue	\N	IGP -	{"fra": "Sable de Camargue primeur ou nouveau rouge"}	Sable de Camargue primeur ou nouveau rouge	\N
8509	2153	Sable de Camargue	\N	IGP -	{"fra": "Sable de Camargue sur lie blanc"}	Sable de Camargue sur lie blanc	\N
8510	2153	Sable de Camargue	\N	IGP -	{"fra": "Sable de Camargue sur lie gris"}	Sable de Camargue sur lie gris	\N
8511	2153	Sable de Camargue	\N	IGP -	{"fra": "Sable de Camargue sur lie gris de gris"}	Sable de Camargue sur lie gris de gris	\N
8512	2153	Sable de Camargue	\N	IGP -	{"fra": "Sable de Camargue sur lie rosé "}	Sable de Camargue sur lie rosé 	\N
10250	1061	Saint-Amour	AOC -	AOP -	{"fra": "Saint-Amour ou Saint-Amour cru du Beaujolais"}	Saint-Amour ou Saint-Amour cru du Beaujolais	\N
9988	1074	Saint-Aubin	AOC -	AOP -	{"fra": "Saint-Aubin rouge ou Saint-Aubin Côte de Beaune"}	Saint-Aubin rouge ou Saint-Aubin Côte de Beaune	\N
9926	1105	Saint-Aubin premier cru	AOC -	AOP -	{"fra": "Saint-Aubin premier cru blanc"}	Saint-Aubin premier cru blanc	\N
9977	1105	Saint-Aubin premier cru	AOC -	AOP -	{"fra": "Saint-Aubin premier cru rouge"}	Saint-Aubin premier cru rouge	\N
9924	1075	Saint-Aubin premier cru Bas de Vermarain à l'Est	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Bas de Vermarain à l'Est blanc"}	Saint-Aubin premier cru Bas de Vermarain à l'Est blanc	\N
9925	1075	Saint-Aubin premier cru Bas de Vermarain à l'Est	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Bas de Vermarain à l'Est rouge"}	Saint-Aubin premier cru Bas de Vermarain à l'Est rouge	\N
9927	1076	Saint-Aubin premier cru Derrière Chez Edouard	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Derrière Chez Edouard blanc"}	Saint-Aubin premier cru Derrière Chez Edouard blanc	\N
9928	1076	Saint-Aubin premier cru Derrière Chez Edouard	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Derrière Chez Edouard rouge"}	Saint-Aubin premier cru Derrière Chez Edouard rouge	\N
9929	1077	Saint-Aubin premier cru Derrière la Tour	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Derrière la Tour blanc"}	Saint-Aubin premier cru Derrière la Tour blanc	\N
9930	1077	Saint-Aubin premier cru Derrière la Tour	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Derrière la Tour rouge"}	Saint-Aubin premier cru Derrière la Tour rouge	\N
9931	1078	Saint-Aubin premier cru Echaille	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Echaille blanc"}	Saint-Aubin premier cru Echaille blanc	\N
9932	1078	Saint-Aubin premier cru Echaille	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Echaille rouge"}	Saint-Aubin premier cru Echaille rouge	\N
9933	1079	Saint-Aubin premier cru En Créot	AOC -	AOP -	{"fra": "Saint-Aubin premier cru En Créot blanc"}	Saint-Aubin premier cru En Créot blanc	\N
9934	1079	Saint-Aubin premier cru En Créot	AOC -	AOP -	{"fra": "Saint-Aubin premier cru En Créot rouge"}	Saint-Aubin premier cru En Créot rouge	\N
9935	1083	Saint-Aubin premier cru En la Ranché	AOC -	AOP -	{"fra": "Saint-Aubin premier cru En la Ranché blanc"}	Saint-Aubin premier cru En la Ranché blanc	\N
9936	1083	Saint-Aubin premier cru En la Ranché	AOC -	AOP -	{"fra": "Saint-Aubin premier cru En la Ranché rouge"}	Saint-Aubin premier cru En la Ranché rouge	\N
9937	1080	Saint-Aubin premier cru En Montceau	AOC -	AOP -	{"fra": "Saint-Aubin premier cru En Montceau blanc"}	Saint-Aubin premier cru En Montceau blanc	\N
9938	1080	Saint-Aubin premier cru En Montceau	AOC -	AOP -	{"fra": "Saint-Aubin premier cru En Montceau rouge"}	Saint-Aubin premier cru En Montceau rouge	\N
9939	1081	Saint-Aubin premier cru En Remilly	AOC -	AOP -	{"fra": "Saint-Aubin premier cru En Remilly blanc"}	Saint-Aubin premier cru En Remilly blanc	\N
9940	1081	Saint-Aubin premier cru En Remilly	AOC -	AOP -	{"fra": "Saint-Aubin premier cru En Remilly rouge"}	Saint-Aubin premier cru En Remilly rouge	\N
9941	1082	Saint-Aubin premier cru En Vollon à l'Est	AOC -	AOP -	{"fra": "Saint-Aubin premier cru En Vollon à l'Est blanc"}	Saint-Aubin premier cru En Vollon à l'Est blanc	\N
9942	1082	Saint-Aubin premier cru En Vollon à l'Est	AOC -	AOP -	{"fra": "Saint-Aubin premier cru En Vollon à l'Est rouge"}	Saint-Aubin premier cru En Vollon à l'Est rouge	\N
9943	1084	Saint-Aubin premier cru Es Champs	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Es Champs blanc"}	Saint-Aubin premier cru Es Champs blanc	\N
9944	1084	Saint-Aubin premier cru Es Champs	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Es Champs rouge"}	Saint-Aubin premier cru Es Champs rouge	\N
9945	1085	Saint-Aubin premier cru La Chatenière	AOC -	AOP -	{"fra": "Saint-Aubin premier cru La Chatenière blanc"}	Saint-Aubin premier cru La Chatenière blanc	\N
9946	1085	Saint-Aubin premier cru La Chatenière	AOC -	AOP -	{"fra": "Saint-Aubin premier cru La Chatenière rouge"}	Saint-Aubin premier cru La Chatenière rouge	\N
9947	1086	Saint-Aubin premier cru Le Bas de Gamay à l'Est	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Le Bas de Gamay à l'Est blanc"}	Saint-Aubin premier cru Le Bas de Gamay à l'Est blanc	\N
9948	1086	Saint-Aubin premier cru Le Bas de Gamay à l'Est	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Le Bas de Gamay à l'Est rouge"}	Saint-Aubin premier cru Le Bas de Gamay à l'Est rouge	\N
9949	1087	Saint-Aubin premier cru Le Charmois	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Le Charmois blanc"}	Saint-Aubin premier cru Le Charmois blanc	\N
9950	1087	Saint-Aubin premier cru Le Charmois	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Le Charmois rouge"}	Saint-Aubin premier cru Le Charmois rouge	\N
9951	1088	Saint-Aubin premier cru Le Puits	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Le Puits blanc"}	Saint-Aubin premier cru Le Puits blanc	\N
9952	1088	Saint-Aubin premier cru Le Puits	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Le Puits rouge"}	Saint-Aubin premier cru Le Puits rouge	\N
9953	1089	Saint-Aubin premier cru Les Castets	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Les Castets blanc"}	Saint-Aubin premier cru Les Castets blanc	\N
9954	1089	Saint-Aubin premier cru Les Castets	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Les Castets rouge"}	Saint-Aubin premier cru Les Castets rouge	\N
9955	1090	Saint-Aubin premier cru Les Champlots	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Les Champlots blanc"}	Saint-Aubin premier cru Les Champlots blanc	\N
9956	1090	Saint-Aubin premier cru Les Champlots	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Les Champlots rouge"}	Saint-Aubin premier cru Les Champlots rouge	\N
9959	1091	Saint-Aubin premier cru Les Combes	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Les Combes blanc"}	Saint-Aubin premier cru Les Combes blanc	\N
9960	1091	Saint-Aubin premier cru Les Combes	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Les Combes rouge"}	Saint-Aubin premier cru Les Combes rouge	\N
9957	1092	Saint-Aubin premier cru Les Combes au Sud	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Les Combes au Sud blanc"}	Saint-Aubin premier cru Les Combes au Sud blanc	\N
9958	1092	Saint-Aubin premier cru Les Combes au Sud	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Les Combes au Sud rouge"}	Saint-Aubin premier cru Les Combes au Sud rouge	\N
9961	1093	Saint-Aubin premier cru Les Cortons	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Les Cortons blanc"}	Saint-Aubin premier cru Les Cortons blanc	\N
9964	1093	Saint-Aubin premier cru Les Cortons	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Les Cortons rouge"}	Saint-Aubin premier cru Les Cortons rouge	\N
9965	1094	Saint-Aubin premier cru Les Frionnes	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Les Frionnes blanc"}	Saint-Aubin premier cru Les Frionnes blanc	\N
9966	1094	Saint-Aubin premier cru Les Frionnes	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Les Frionnes rouge"}	Saint-Aubin premier cru Les Frionnes rouge	\N
9967	1095	Saint-Aubin premier cru Les Murgers des dents de chien	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Les Murgers des dents de chien blanc"}	Saint-Aubin premier cru Les Murgers des dents de chien blanc	\N
9968	1095	Saint-Aubin premier cru Les Murgers des dents de chien	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Les Murgers des dents de chien rouge"}	Saint-Aubin premier cru Les Murgers des dents de chien rouge	\N
9969	1096	Saint-Aubin premier cru Les Perrières	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Les Perrières blanc"}	Saint-Aubin premier cru Les Perrières blanc	\N
9970	1096	Saint-Aubin premier cru Les Perrières	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Les Perrières rouge"}	Saint-Aubin premier cru Les Perrières rouge	\N
9971	1097	Saint-Aubin premier cru Les Travers de Marinot	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Les Travers de Marinot blanc"}	Saint-Aubin premier cru Les Travers de Marinot blanc	\N
9972	1097	Saint-Aubin premier cru Les Travers de Marinot	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Les Travers de Marinot rouge"}	Saint-Aubin premier cru Les Travers de Marinot rouge	\N
9973	1098	Saint-Aubin premier cru Marinot	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Marinot blanc"}	Saint-Aubin premier cru Marinot blanc	\N
9974	1098	Saint-Aubin premier cru Marinot	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Marinot rouge"}	Saint-Aubin premier cru Marinot rouge	\N
9975	1099	Saint-Aubin premier cru Pitangeret	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Pitangeret blanc"}	Saint-Aubin premier cru Pitangeret blanc	\N
9976	1099	Saint-Aubin premier cru Pitangeret	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Pitangeret rouge"}	Saint-Aubin premier cru Pitangeret rouge	\N
9978	1100	Saint-Aubin premier cru Sous Roche Dumay	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Sous Roche Dumay blanc"}	Saint-Aubin premier cru Sous Roche Dumay blanc	\N
9979	1100	Saint-Aubin premier cru Sous Roche Dumay	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Sous Roche Dumay rouge"}	Saint-Aubin premier cru Sous Roche Dumay rouge	\N
9980	1101	Saint-Aubin premier cru Sur Gamay	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Sur Gamay blanc"}	Saint-Aubin premier cru Sur Gamay blanc	\N
9981	1101	Saint-Aubin premier cru Sur Gamay	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Sur Gamay rouge"}	Saint-Aubin premier cru Sur Gamay rouge	\N
9982	1102	Saint-Aubin premier cru Sur le sentier du Clou	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Sur le sentier du Clou blanc"}	Saint-Aubin premier cru Sur le sentier du Clou blanc	\N
9983	1102	Saint-Aubin premier cru Sur le sentier du Clou	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Sur le sentier du Clou rouge"}	Saint-Aubin premier cru Sur le sentier du Clou rouge	\N
7929	202	Sancerre	AOC -	AOP -	{"fra": "Sancerre blanc"}	Sancerre blanc	\N
4213	1960	Saint-Marcellin	\N	IGP -	{"fra": "Saint-Marcellin"}	Saint-Marcellin	\N
9984	1103	Saint-Aubin premier cru Vignes Moingeon	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Vignes Moingeon blanc"}	Saint-Aubin premier cru Vignes Moingeon blanc	\N
9985	1103	Saint-Aubin premier cru Vignes Moingeon	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Vignes Moingeon rouge"}	Saint-Aubin premier cru Vignes Moingeon rouge	\N
9986	1104	Saint-Aubin premier cru Village	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Village blanc"}	Saint-Aubin premier cru Village blanc	\N
9987	1104	Saint-Aubin premier cru Village	AOC -	AOP -	{"fra": "Saint-Aubin premier cru Village rouge"}	Saint-Aubin premier cru Village rouge	\N
7671	1230	Saint-Bris	AOC -	AOP -	{"fra": "Saint-Bris"}	Saint-Bris	\N
7919	1275	Saint-Chinian	AOC -	AOP -	{"fra": "Saint-Chinian blanc"}	Saint-Chinian blanc	\N
7921	1275	Saint-Chinian	AOC -	AOP -	{"fra": "Saint-Chinian rosé"}	Saint-Chinian rosé	\N
7922	1275	Saint-Chinian	AOC -	AOP -	{"fra": "Saint-Chinian rouge"}	Saint-Chinian rouge	\N
7918	1614	Saint-Chinian Berlou	AOC -	AOP -	{"fra": "Saint-Chinian Berlou"}	Saint-Chinian Berlou	\N
7920	1615	Saint-Chinian Roquebrun	AOC -	AOP -	{"fra": "Saint-Chinian Roquebrun"}	Saint-Chinian Roquebrun	\N
14975	150	Saint-Emilion	AOC -	AOP -	{"fra": "Saint-Emilion"}	Saint-Emilion	\N
14920	1882	Saint-Emilion grand cru	AOC -	AOP -	{"fra": "Saint-Emilion grand cru"}	Saint-Emilion grand cru	\N
14921	1882	Saint-Emilion grand cru	AOC -	AOP -	{"fra": "Saint-Emilion grand cru Grand cru classé"}	Saint-Emilion grand cru Grand cru classé	\N
14922	1882	Saint-Emilion grand cru	AOC -	AOP -	{"fra": "Saint-Emilion grand cru Premier grand cru classé"}	Saint-Emilion grand cru Premier grand cru classé	\N
7693	151	Saint-Estèphe	AOC -	AOP -	{"fra": "Saint-Estèphe"}	Saint-Estèphe	\N
8150	152	Saint-Georges-Saint-Emilion	AOC -	AOP -	{"fra": "Saint-Georges-Saint-Emilion"}	Saint-Georges-Saint-Emilion	\N
7824	2108	Saint-Guilhem-le-Désert	\N	IGP -	{"fra": "Saint-Guilhem-le-Désert blanc"}	Saint-Guilhem-le-Désert blanc	\N
8867	2108	Saint-Guilhem-le-Désert	\N	IGP -	{"fra": "Saint-Guilhem-le-Désert rosé"}	Saint-Guilhem-le-Désert rosé	\N
8868	2108	Saint-Guilhem-le-Désert	\N	IGP -	{"fra": "Saint-Guilhem-le-Désert rouge"}	Saint-Guilhem-le-Désert rouge	\N
11114	2108	Saint-Guilhem-le-Désert	\N	IGP -	{"fra": "Saint-Guilhem-le-Désert surmûri blanc"}	Saint-Guilhem-le-Désert surmûri blanc	\N
11115	2108	Saint-Guilhem-le-Désert	\N	IGP -	{"fra": "Saint-Guilhem-le-Désert surmûri rosé"}	Saint-Guilhem-le-Désert surmûri rosé	\N
11116	2108	Saint-Guilhem-le-Désert	\N	IGP -	{"fra": "Saint-Guilhem-le-Désert surmûri rouge"}	Saint-Guilhem-le-Désert surmûri rouge	\N
11117	2108	Saint-Guilhem-le-Désert	\N	IGP -	{"fra": "Saint-Guilhem-le-Désert primeur ou nouveau blanc"}	Saint-Guilhem-le-Désert primeur ou nouveau blanc	\N
11118	2108	Saint-Guilhem-le-Désert	\N	IGP -	{"fra": "Saint-Guilhem-le-Désert primeur ou nouveau rosé"}	Saint-Guilhem-le-Désert primeur ou nouveau rosé	\N
11119	2108	Saint-Guilhem-le-Désert	\N	IGP -	{"fra": "Saint-Guilhem-le-Désert primeur ou nouveau rouge"}	Saint-Guilhem-le-Désert primeur ou nouveau rouge	\N
11120	2265	Saint-Guilhem-le-Désert Cité d'Aniane	\N	IGP -	{"fra": "Saint-Guilhem-le-Désert Cité d'Aniane blanc"}	Saint-Guilhem-le-Désert Cité d'Aniane blanc	\N
11121	2265	Saint-Guilhem-le-Désert Cité d'Aniane	\N	IGP -	{"fra": "Saint-Guilhem-le-Désert Cité d'Aniane rosé"}	Saint-Guilhem-le-Désert Cité d'Aniane rosé	\N
11122	2265	Saint-Guilhem-le-Désert Cité d'Aniane	\N	IGP -	{"fra": "Saint-Guilhem-le-Désert Cité d'Aniane rouge"}	Saint-Guilhem-le-Désert Cité d'Aniane rouge	\N
11123	2265	Saint-Guilhem-le-Désert Cité d'Aniane	\N	IGP -	{"fra": "Saint-Guilhem-le-Désert Cité d'Aniane surmûri blanc"}	Saint-Guilhem-le-Désert Cité d'Aniane surmûri blanc	\N
11124	2265	Saint-Guilhem-le-Désert Cité d'Aniane	\N	IGP -	{"fra": "Saint-Guilhem-le-Désert Cité d'Aniane surmûri rosé"}	Saint-Guilhem-le-Désert Cité d'Aniane surmûri rosé	\N
11125	2265	Saint-Guilhem-le-Désert Cité d'Aniane	\N	IGP -	{"fra": "Saint-Guilhem-le-Désert Cité d'Aniane surmûri rouge"}	Saint-Guilhem-le-Désert Cité d'Aniane surmûri rouge	\N
11126	2265	Saint-Guilhem-le-Désert Cité d'Aniane	\N	IGP -	{"fra": "Saint-Guilhem-le-Désert Cité d'Aniane primeur ou nouveau blanc"}	Saint-Guilhem-le-Désert Cité d'Aniane primeur ou nouveau blanc	\N
11127	2265	Saint-Guilhem-le-Désert Cité d'Aniane	\N	IGP -	{"fra": "Saint-Guilhem-le-Désert Cité d'Aniane primeur ou nouveau rosé"}	Saint-Guilhem-le-Désert Cité d'Aniane primeur ou nouveau rosé	\N
11128	2265	Saint-Guilhem-le-Désert Cité d'Aniane	\N	IGP -	{"fra": "Saint-Guilhem-le-Désert Cité d'Aniane primeur ou nouveau rouge"}	Saint-Guilhem-le-Désert Cité d'Aniane primeur ou nouveau rouge	\N
11129	2266	Saint-Guilhem-le-Désert Val de Montferrand	\N	IGP -	{"fra": "Saint-Guilhem-le-Désert Val de Montferrand blanc"}	Saint-Guilhem-le-Désert Val de Montferrand blanc	\N
11130	2266	Saint-Guilhem-le-Désert Val de Montferrand	\N	IGP -	{"fra": "Saint-Guilhem-le-Désert Val de Montferrand rosé"}	Saint-Guilhem-le-Désert Val de Montferrand rosé	\N
11131	2266	Saint-Guilhem-le-Désert Val de Montferrand	\N	IGP -	{"fra": "Saint-Guilhem-le-Désert Val de Montferrand rouge"}	Saint-Guilhem-le-Désert Val de Montferrand rouge	\N
11132	2266	Saint-Guilhem-le-Désert Val de Montferrand	\N	IGP -	{"fra": "Saint-Guilhem-le-Désert Val de Montferrand surmûri blanc"}	Saint-Guilhem-le-Désert Val de Montferrand surmûri blanc	\N
11133	2266	Saint-Guilhem-le-Désert Val de Montferrand	\N	IGP -	{"fra": "Saint-Guilhem-le-Désert Val de Montferrand surmûri rosé"}	Saint-Guilhem-le-Désert Val de Montferrand surmûri rosé	\N
11134	2266	Saint-Guilhem-le-Désert Val de Montferrand	\N	IGP -	{"fra": "Saint-Guilhem-le-Désert Val de Montferrand surmûri rouge"}	Saint-Guilhem-le-Désert Val de Montferrand surmûri rouge	\N
11135	2266	Saint-Guilhem-le-Désert Val de Montferrand	\N	IGP -	{"fra": "Saint-Guilhem-le-Désert Val de Montferrand primeur ou nouveau blanc"}	Saint-Guilhem-le-Désert Val de Montferrand primeur ou nouveau blanc	\N
11137	2266	Saint-Guilhem-le-Désert Val de Montferrand	\N	IGP -	{"fra": "Saint-Guilhem-le-Désert Val de Montferrand primeur ou nouveau rosé"}	Saint-Guilhem-le-Désert Val de Montferrand primeur ou nouveau rosé	\N
11138	2266	Saint-Guilhem-le-Désert Val de Montferrand	\N	IGP -	{"fra": "Saint-Guilhem-le-Désert Val de Montferrand primeur ou nouveau rouge"}	Saint-Guilhem-le-Désert Val de Montferrand primeur ou nouveau rouge	\N
8357	1310	Saint-Joseph	AOC -	AOP -	{"fra": "Saint-Joseph blanc"}	Saint-Joseph blanc	\N
8358	1310	Saint-Joseph	AOC -	AOP -	{"fra": "Saint-Joseph rouge"}	Saint-Joseph rouge	\N
7676	153	Saint-Julien	AOC -	AOP -	{"fra": "Saint-Julien"}	Saint-Julien	\N
16112	1733	Saint-Mont	AOC -	AOP -	{"fra": "Saint-Mont blanc"}	Saint-Mont blanc	\N
16113	1733	Saint-Mont	AOC -	AOP -	{"fra": "Saint-Mont rosé"}	Saint-Mont rosé	\N
16114	1733	Saint-Mont	AOC -	AOP -	{"fra": "Saint-Mont rouge"}	Saint-Mont rouge	\N
14073	1484	Saint-Nectaire	AOC -	AOP -	{"fra": "Saint-Nectaire"}	Saint-Nectaire	\N
13968	201	Saint-Nicolas-de-Bourgueil	AOC -	AOP -	{"fra": "Saint-Nicolas-de-Bourgueil rouge"}	Saint-Nicolas-de-Bourgueil rouge	\N
14070	201	Saint-Nicolas-de-Bourgueil	AOC -	AOP -	{"fra": "Saint-Nicolas-de-Bourgueil rosé"}	Saint-Nicolas-de-Bourgueil rosé	\N
7672	1311	Saint-Péray	AOC -	AOP -	{"fra": "Saint-Péray"}	Saint-Péray	\N
8821	1311	Saint-Péray	AOC -	AOP -	{"fra": "Saint-Péray mousseux"}	Saint-Péray mousseux	\N
15585	1883	Saint-Pourçain	AOC -	AOP -	{"fra": "Saint-Pourçain blanc"}	Saint-Pourçain blanc	\N
15586	1883	Saint-Pourçain	AOC -	AOP -	{"fra": "Saint-Pourçain rosé"}	Saint-Pourçain rosé	\N
15587	1883	Saint-Pourçain	AOC -	AOP -	{"fra": "Saint-Pourçain rouge"}	Saint-Pourçain rouge	\N
7675	1106	Saint-Romain	AOC -	AOP -	{"fra": "Saint-Romain"}	Saint-Romain	\N
8310	1106	Saint-Romain	AOC -	AOP -	{"fra": "Saint-Romain rouge ou Saint-Romain Côte de Beaune"}	Saint-Romain rouge ou Saint-Romain Côte de Beaune	\N
8380	2337	Saint-Sardos	AOC -	AOP -	{"fra": "Saint-Sardos rosé"}	Saint-Sardos rosé	\N
8381	2337	Saint-Sardos	AOC -	AOP -	{"fra": "Saint-Sardos rouge"}	Saint-Sardos rouge	\N
7741	1107	Saint-Véran	AOC -	AOP -	{"fra": "Saint-Véran"}	Saint-Véran	\N
9193	1107	Saint-Véran	AOC -	AOP -	{"fra": "Saint-Véran complété par une dénomination de climat"}	Saint-Véran complété par une dénomination de climat	\N
8210	154	Sainte-Croix-du-Mont	AOC -	AOP -	{"fra": "Sainte-Croix-du-Mont"}	Sainte-Croix-du-Mont	\N
7813	2192	Sainte-Marie-la-Blanche	\N	IGP -	{"fra": "Sainte-Marie-la-Blanche blanc"}	Sainte-Marie-la-Blanche blanc	\N
8583	2192	Sainte-Marie-la-Blanche	\N	IGP -	{"fra": "Sainte-Marie-la-Blanche rosé"}	Sainte-Marie-la-Blanche rosé	\N
8584	2192	Sainte-Marie-la-Blanche	\N	IGP -	{"fra": "Sainte-Marie-la-Blanche rouge"}	Sainte-Marie-la-Blanche rouge	\N
11111	2192	Sainte-Marie-la-Blanche	\N	IGP -	{"fra": "Sainte-Marie-la-Blanche primeur ou nouveau blanc"}	Sainte-Marie-la-Blanche primeur ou nouveau blanc	\N
11112	2192	Sainte-Marie-la-Blanche	\N	IGP -	{"fra": "Sainte-Marie-la-Blanche primeur ou nouveau rosé"}	Sainte-Marie-la-Blanche primeur ou nouveau rosé	\N
11113	2192	Sainte-Marie-la-Blanche	\N	IGP -	{"fra": "Sainte-Marie-la-Blanche primeur ou nouveau rouge"}	Sainte-Marie-la-Blanche primeur ou nouveau rouge	\N
3293	1485	Sainte-Maure de Touraine	AOC -	AOP -	{"fra": "Sainte-Maure de Touraine"}	Sainte-Maure de Touraine	\N
3294	1486	Salers	AOC -	AOP -	{"fra": "Salers"}	Salers	\N
7930	202	Sancerre	AOC -	AOP -	{"fra": "Sancerre rosé"}	Sancerre rosé	\N
7931	202	Sancerre	AOC -	AOP -	{"fra": "Sancerre rouge"}	Sancerre rouge	\N
7699	1108	Santenay	AOC -	AOP -	{"fra": "Santenay blanc"}	Santenay blanc	\N
10015	1108	Santenay	AOC -	AOP -	{"fra": "Santenay rouge ou Santenay Côte de Beaune"}	Santenay rouge ou Santenay Côte de Beaune	\N
9993	1121	Santenay premier cru	AOC -	AOP -	{"fra": "Santenay premier cru blanc"}	Santenay premier cru blanc	\N
10014	1121	Santenay premier cru	AOC -	AOP -	{"fra": "Santenay premier cru rouge"}	Santenay premier cru rouge	\N
9989	1109	Santenay premier cru Beauregard	AOC -	AOP -	{"fra": "Santenay premier cru Beauregard blanc"}	Santenay premier cru Beauregard blanc	\N
9990	1109	Santenay premier cru Beauregard	AOC -	AOP -	{"fra": "Santenay premier cru Beauregard rouge"}	Santenay premier cru Beauregard rouge	\N
9991	1110	Santenay premier cru Beaurepaire	AOC -	AOP -	{"fra": "Santenay premier cru Beaurepaire blanc"}	Santenay premier cru Beaurepaire blanc	\N
9992	1110	Santenay premier cru Beaurepaire	AOC -	AOP -	{"fra": "Santenay premier cru Beaurepaire rouge"}	Santenay premier cru Beaurepaire rouge	\N
9994	1113	Santenay premier cru Clos de Tavannes	AOC -	AOP -	{"fra": "Santenay premier cru Clos de Tavannes blanc"}	Santenay premier cru Clos de Tavannes blanc	\N
9995	1113	Santenay premier cru Clos de Tavannes	AOC -	AOP -	{"fra": "Santenay premier cru Clos de Tavannes rouge"}	Santenay premier cru Clos de Tavannes rouge	\N
9996	1114	Santenay premier cru Clos des Mouches	AOC -	AOP -	{"fra": "Santenay premier cru Clos des Mouches blanc"}	Santenay premier cru Clos des Mouches blanc	\N
9997	1114	Santenay premier cru Clos des Mouches	AOC -	AOP -	{"fra": "Santenay premier cru Clos des Mouches rouge"}	Santenay premier cru Clos des Mouches rouge	\N
9998	1111	Santenay premier cru Clos Faubard	AOC -	AOP -	{"fra": "Santenay premier cru Clos Faubard blanc"}	Santenay premier cru Clos Faubard blanc	\N
9999	1111	Santenay premier cru Clos Faubard	AOC -	AOP -	{"fra": "Santenay premier cru Clos Faubard rouge"}	Santenay premier cru Clos Faubard rouge	\N
10000	1112	Santenay premier cru Clos Rousseau	AOC -	AOP -	{"fra": "Santenay premier cru Clos Rousseau blanc"}	Santenay premier cru Clos Rousseau blanc	\N
10001	1112	Santenay premier cru Clos Rousseau	AOC -	AOP -	{"fra": "Santenay premier cru Clos Rousseau rouge"}	Santenay premier cru Clos Rousseau rouge	\N
10002	1115	Santenay premier cru Grand Clos Rousseau	AOC -	AOP -	{"fra": "Santenay premier cru Grand Clos Rousseau blanc"}	Santenay premier cru Grand Clos Rousseau blanc	\N
10003	1115	Santenay premier cru Grand Clos Rousseau	AOC -	AOP -	{"fra": "Santenay premier cru Grand Clos Rousseau rouge"}	Santenay premier cru Grand Clos Rousseau rouge	\N
10004	1116	Santenay premier cru La Comme	AOC -	AOP -	{"fra": "Santenay premier cru La Comme blanc"}	Santenay premier cru La Comme blanc	\N
10005	1116	Santenay premier cru La Comme	AOC -	AOP -	{"fra": "Santenay premier cru La Comme rouge"}	Santenay premier cru La Comme rouge	\N
10006	1117	Santenay premier cru La Maladière	AOC -	AOP -	{"fra": "Santenay premier cru La Maladière blanc"}	Santenay premier cru La Maladière blanc	\N
10007	1117	Santenay premier cru La Maladière	AOC -	AOP -	{"fra": "Santenay premier cru La Maladière rouge"}	Santenay premier cru La Maladière rouge	\N
10008	1118	Santenay premier cru Les Gravières	AOC -	AOP -	{"fra": "Santenay premier cru Les Gravières blanc"}	Santenay premier cru Les Gravières blanc	\N
10009	1118	Santenay premier cru Les Gravières	AOC -	AOP -	{"fra": "Santenay premier cru Les Gravières rouge"}	Santenay premier cru Les Gravières rouge	\N
15640	2269	Val de Loire Allier	\N	IGP -	{"fra": "Val de Loire Allier primeur ou nouveau blanc"}	Val de Loire Allier primeur ou nouveau blanc	\N
10010	1119	Santenay premier cru Les Gravières-Clos de Tavannes	AOC -	AOP -	{"fra": "Santenay premier cru Les Gravières-Clos de Tavannes blanc"}	Santenay premier cru Les Gravières-Clos de Tavannes blanc	\N
10011	1119	Santenay premier cru Les Gravières-Clos de Tavannes	AOC -	AOP -	{"fra": "Santenay premier cru Les Gravières-Clos de Tavannes rouge"}	Santenay premier cru Les Gravières-Clos de Tavannes rouge	\N
10012	1120	Santenay premier cru Passetemps	AOC -	AOP -	{"fra": "Santenay premier cru Passetemps blanc"}	Santenay premier cru Passetemps blanc	\N
10013	1120	Santenay premier cru Passetemps	AOC -	AOP -	{"fra": "Santenay premier cru Passetemps rouge"}	Santenay premier cru Passetemps rouge	\N
7814	2191	Saône-et-Loire	\N	IGP -	{"fra": "Saône-et-Loire blanc"}	Saône-et-Loire blanc	\N
8449	2191	Saône-et-Loire	\N	IGP -	{"fra": "Saône-et-Loire rosé"}	Saône-et-Loire rosé	\N
8450	2191	Saône-et-Loire	\N	IGP -	{"fra": "Saône-et-Loire rouge"}	Saône-et-Loire rouge	\N
11139	2191	Saône-et-Loire	\N	IGP -	{"fra": "Saône-et-Loire primeur ou nouveau blanc"}	Saône-et-Loire primeur ou nouveau blanc	\N
11140	2191	Saône-et-Loire	\N	IGP -	{"fra": "Saône-et-Loire primeur ou nouveau rosé"}	Saône-et-Loire primeur ou nouveau rosé	\N
11141	2191	Saône-et-Loire	\N	IGP -	{"fra": "Saône-et-Loire primeur ou nouveau rouge"}	Saône-et-Loire primeur ou nouveau rouge	\N
4386	1795	Saucisse de Montbéliard	\N	IGP -	{"fra": "Saucisse de Montbéliard"}	Saucisse de Montbéliard	\N
14209	1859	Saucisse de Morteau ou Jésus de Morteau	\N	IGP -	{"fra": "Saucisse de Morteau ou Jésus de Morteau"}	Saucisse de Morteau ou Jésus de Morteau	IG/11/00
12606	1826	Saucisson de l'Ardèche	\N	IGP -	{"fra": "Saucisson de l'Ardèche"}	Saucisson de l'Ardèche	IG/10/05
4536	1842	Saucisson et saucisse sèche de Lacaune	\N	IGP -	{"fra": "Saucisson de Lacaune ou Saucisse de Lacaune"}	Saucisson de Lacaune ou Saucisse de Lacaune	\N
4180	2430	Saucisson sec d'Auvergne ou Saucisse sèche d'Auvergne	\N	IGP -	{"fra": "Saucisson sec d'Auvergne ou saucisse sèche d'Auvergne"}	Saucisson sec d'Auvergne ou saucisse sèche d'Auvergne	\N
15116	203	Saumur (vins tranquilles blancs et rosés)	AOC -	AOP -	{"fra": "Saumur blanc"}	Saumur blanc	\N
15121	203	Saumur (vins tranquilles blancs et rosés)	AOC -	AOP -	{"fra": "Saumur rosé"}	Saumur rosé	\N
15119	204	Saumur (vins tranquilles rouges)	AOC -	AOP -	{"fra": "Saumur primeur ou nouveau rosé"}	Saumur primeur ou nouveau rosé	\N
15122	204	Saumur (vins tranquilles rouges)	AOC -	AOP -	{"fra": "Saumur rouge"}	Saumur rouge	\N
15117	205	Saumur mousseux	AOC -	AOP -	{"fra": "Saumur mousseux blanc"}	Saumur mousseux blanc	\N
15118	205	Saumur mousseux	AOC -	AOP -	{"fra": "Saumur mousseux rosé"}	Saumur mousseux rosé	\N
15120	1868	Saumur Puy-Notre-Dame	AOC -	AOP -	{"fra": "Saumur Puy-Notre-Dame"}	Saumur Puy-Notre-Dame	\N
15114	215	Saumur-Champigny	AOC -	AOP -	{"fra": "Saumur-Champigny"}	Saumur-Champigny	\N
12206	1664	Saussignac	AOC -	AOP -	{"fra": "Saussignac"}	Saussignac	\N
9416	157	Sauternes	AOC -	AOP -	{"fra": "Sauternes"}	Sauternes	\N
15125	206	Savennières	AOC -	AOP -	{"fra": "Savennières"}	Savennières	\N
15126	206	Savennières	AOC -	AOP -	{"fra": "Savennières demi-sec"}	Savennières demi-sec	\N
15127	206	Savennières	AOC -	AOP -	{"fra": "Savennières moelleux ou doux"}	Savennières moelleux ou doux	\N
15128	208	Savennières Roche aux Moines	AOC -	AOP -	{"fra": "Savennières Roche aux Moines"}	Savennières Roche aux Moines	\N
15129	208	Savennières Roche aux Moines	AOC -	AOP -	{"fra": "Savennières Roche aux Moines moelleux ou doux"}	Savennières Roche aux Moines moelleux ou doux	\N
7729	1122	Savigny-lès-Beaune	AOC -	AOP -	{"fra": "Savigny-lès-Beaune blanc"}	Savigny-lès-Beaune blanc	\N
9526	1122	Savigny-lès-Beaune	AOC -	AOP -	{"fra": "Savigny-lès-Beaune rouge ou Savigny-lès-Beaune Côte de Beaune"}	Savigny-lès-Beaune rouge ou Savigny-lès-Beaune Côte de Beaune	\N
9494	1145	Savigny-lès-Beaune premier cru	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru blanc"}	Savigny-lès-Beaune premier cru blanc	\N
9525	1145	Savigny-lès-Beaune premier cru	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru rouge"}	Savigny-lès-Beaune premier cru rouge	\N
9480	1123	Savigny-lès-Beaune premier cru Aux Clous	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Aux Clous blanc"}	Savigny-lès-Beaune premier cru Aux Clous blanc	\N
9481	1123	Savigny-lès-Beaune premier cru Aux Clous	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Aux Clous rouge"}	Savigny-lès-Beaune premier cru Aux Clous rouge	\N
9482	1124	Savigny-lès-Beaune premier cru Aux Fourneaux	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Aux Fourneaux blanc"}	Savigny-lès-Beaune premier cru Aux Fourneaux blanc	\N
9483	1124	Savigny-lès-Beaune premier cru Aux Fourneaux	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Aux Fourneaux rouge"}	Savigny-lès-Beaune premier cru Aux Fourneaux rouge	\N
9484	1125	Savigny-lès-Beaune premier cru Aux Gravains	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Aux Gravains blanc"}	Savigny-lès-Beaune premier cru Aux Gravains blanc	\N
9485	1125	Savigny-lès-Beaune premier cru Aux Gravains	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Aux Gravains rouge"}	Savigny-lès-Beaune premier cru Aux Gravains rouge	\N
9486	1126	Savigny-lès-Beaune premier cru Aux Guettes	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Aux Guettes blanc"}	Savigny-lès-Beaune premier cru Aux Guettes blanc	\N
9487	1126	Savigny-lès-Beaune premier cru Aux Guettes	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Aux Guettes rouge"}	Savigny-lès-Beaune premier cru Aux Guettes rouge	\N
15448	209	Touraine	AOC -	AOP -	{"fra": "Touraine blanc"}	Touraine blanc	\N
9488	1127	Savigny-lès-Beaune premier cru Aux Serpentières	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Aux Serpentières blanc"}	Savigny-lès-Beaune premier cru Aux Serpentières blanc	\N
9489	1127	Savigny-lès-Beaune premier cru Aux Serpentières	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Aux Serpentières rouge"}	Savigny-lès-Beaune premier cru Aux Serpentières rouge	\N
9490	1128	Savigny-lès-Beaune premier cru Basses Vergelesses	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Basses Vergelesses blanc"}	Savigny-lès-Beaune premier cru Basses Vergelesses blanc	\N
9491	1128	Savigny-lès-Beaune premier cru Basses Vergelesses	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Basses Vergelesses rouge"}	Savigny-lès-Beaune premier cru Basses Vergelesses rouge	\N
9492	1129	Savigny-lès-Beaune premier cru Bataillère	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Bataillère blanc"}	Savigny-lès-Beaune premier cru Bataillère blanc	\N
9493	1129	Savigny-lès-Beaune premier cru Bataillère	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Bataillère rouge"}	Savigny-lès-Beaune premier cru Bataillère rouge	\N
9495	1130	Savigny-lès-Beaune premier cru Champ Chevrey	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Champ Chevrey blanc"}	Savigny-lès-Beaune premier cru Champ Chevrey blanc	\N
9496	1130	Savigny-lès-Beaune premier cru Champ Chevrey	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Champ Chevrey rouge"}	Savigny-lès-Beaune premier cru Champ Chevrey rouge	\N
9497	1131	Savigny-lès-Beaune premier cru La Dominode	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru La Dominode blanc"}	Savigny-lès-Beaune premier cru La Dominode blanc	\N
9498	1131	Savigny-lès-Beaune premier cru La Dominode	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru La Dominode rouge"}	Savigny-lès-Beaune premier cru La Dominode rouge	\N
9499	1132	Savigny-lès-Beaune premier cru Les Charnières	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Les Charnières blanc"}	Savigny-lès-Beaune premier cru Les Charnières blanc	\N
9500	1132	Savigny-lès-Beaune premier cru Les Charnières	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Les Charnières rouge"}	Savigny-lès-Beaune premier cru Les Charnières rouge	\N
9501	1133	Savigny-lès-Beaune premier cru Les Hauts Jarrons	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Les Hauts Jarrons blanc"}	Savigny-lès-Beaune premier cru Les Hauts Jarrons blanc	\N
9502	1133	Savigny-lès-Beaune premier cru Les Hauts Jarrons	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Les Hauts Jarrons rouge"}	Savigny-lès-Beaune premier cru Les Hauts Jarrons rouge	\N
9503	1134	Savigny-lès-Beaune premier cru Les Hauts Marconnets	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Les Hauts Marconnets blanc"}	Savigny-lès-Beaune premier cru Les Hauts Marconnets blanc	\N
9504	1134	Savigny-lès-Beaune premier cru Les Hauts Marconnets	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Les Hauts Marconnets rouge"}	Savigny-lès-Beaune premier cru Les Hauts Marconnets rouge	\N
9505	1135	Savigny-lès-Beaune premier cru Les Jarrons	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Les Jarrons blanc"}	Savigny-lès-Beaune premier cru Les Jarrons blanc	\N
9506	1135	Savigny-lès-Beaune premier cru Les Jarrons	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Les Jarrons rouge"}	Savigny-lès-Beaune premier cru Les Jarrons rouge	\N
9507	1136	Savigny-lès-Beaune premier cru Les Lavières	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Les Lavières blanc"}	Savigny-lès-Beaune premier cru Les Lavières blanc	\N
9508	1136	Savigny-lès-Beaune premier cru Les Lavières	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Les Lavières rouge"}	Savigny-lès-Beaune premier cru Les Lavières rouge	\N
9509	1137	Savigny-lès-Beaune premier cru Les Marconnets	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Les Marconnets blanc"}	Savigny-lès-Beaune premier cru Les Marconnets blanc	\N
9510	1137	Savigny-lès-Beaune premier cru Les Marconnets	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Les Marconnets rouge"}	Savigny-lès-Beaune premier cru Les Marconnets rouge	\N
9511	1138	Savigny-lès-Beaune premier cru Les Narbantons	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Les Narbantons blanc"}	Savigny-lès-Beaune premier cru Les Narbantons blanc	\N
9512	1138	Savigny-lès-Beaune premier cru Les Narbantons	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Les Narbantons rouge"}	Savigny-lès-Beaune premier cru Les Narbantons rouge	\N
9513	1139	Savigny-lès-Beaune premier cru Les Peuillets	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Les Peuillets blanc"}	Savigny-lès-Beaune premier cru Les Peuillets blanc	\N
9514	1139	Savigny-lès-Beaune premier cru Les Peuillets	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Les Peuillets rouge"}	Savigny-lès-Beaune premier cru Les Peuillets rouge	\N
9515	1140	Savigny-lès-Beaune premier cru Les Rouvrettes	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Les Rouvrettes blanc"}	Savigny-lès-Beaune premier cru Les Rouvrettes blanc	\N
9516	1140	Savigny-lès-Beaune premier cru Les Rouvrettes	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Les Rouvrettes rouge"}	Savigny-lès-Beaune premier cru Les Rouvrettes rouge	\N
9517	1141	Savigny-lès-Beaune premier cru Les Talmettes	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Les Talmettes blanc"}	Savigny-lès-Beaune premier cru Les Talmettes blanc	\N
9518	1141	Savigny-lès-Beaune premier cru Les Talmettes	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Les Talmettes rouge"}	Savigny-lès-Beaune premier cru Les Talmettes rouge	\N
9519	1142	Savigny-lès-Beaune premier cru Les Vergelesses	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Les Vergelesses blanc"}	Savigny-lès-Beaune premier cru Les Vergelesses blanc	\N
9520	1142	Savigny-lès-Beaune premier cru Les Vergelesses	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Les Vergelesses rouge"}	Savigny-lès-Beaune premier cru Les Vergelesses rouge	\N
9521	1143	Savigny-lès-Beaune premier cru Petits Godeaux	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Petits Godeaux blanc"}	Savigny-lès-Beaune premier cru Petits Godeaux blanc	\N
9522	1143	Savigny-lès-Beaune premier cru Petits Godeaux	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Petits Godeaux rouge"}	Savigny-lès-Beaune premier cru Petits Godeaux rouge	\N
9523	1144	Savigny-lès-Beaune premier cru Redrescul	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Redrescul blanc"}	Savigny-lès-Beaune premier cru Redrescul blanc	\N
9524	1144	Savigny-lès-Beaune premier cru Redrescul	AOC -	AOP -	{"fra": "Savigny-lès-Beaune premier cru Redrescul rouge"}	Savigny-lès-Beaune premier cru Redrescul rouge	\N
3665	2426	Sel de Guérance Fleur de Sel de Guérance	\N	IGP -	{"fra": "Sel de Guérande ou Fleur de sel de Guérande"}	Sel de Guérande ou Fleur de sel de Guérande	\N
13190	2402	Sel de Salies-de-Béarn	\N	IGP -	{"fra": "Sel de Salies-de-Béarn"}	Sel de Salies-de-Béarn	\N
13168	1487	Selles-sur-Cher	AOC -	AOP -	{"fra": "Selles-sur-Cher"}	Selles-sur-Cher	\N
13180	1146	Seyssel	AOC -	AOP -	{"fra": "Seyssel"}	Seyssel	\N
13520	1146	Seyssel	AOC -	AOP -	{"fra": "Seyssel molette"}	Seyssel molette	\N
13521	1146	Seyssel	AOC -	AOP -	{"fra": "Seyssel mousseux"}	Seyssel mousseux	\N
12991	2359	Soumaintrain	\N	IGP -	{"fra": "Soumaintrain"}	Soumaintrain	\N
12950	2353	Tartiflette au Reblochon ou Reblochon de Savoie 	LR - 	\N	{"fra": "Tartiflette au Reblochon ou Reblochon de Savoie"}	Tartiflette au Reblochon ou Reblochon de Savoie	LA/02/14
4537	1504	Taureau de Camargue	AOC -	AOP -	{"fra": "Taureau de Camargue"}	Taureau de Camargue	\N
8942	1312	Tavel	AOC -	AOP -	{"fra": "Tavel"}	Tavel	\N
1	1	-------	Vin de France -	VSIG	{"fra": "VSIG"}	VSIG	\N
4384	1793	Ternera de los Pirineos Catalanes Vedella dels Pirineus Catalans Vedel	\N	IGP -	{"fra": "Ternera de los Pirineos Catalanes ou Vedella dels Pirineus Catalans ou Vedell des Pyré"}	Ternera de los Pirineos Catalanes ou Vedella dels Pirineus Catalans ou Vedell des Pyré	IG/06/03
12972	2354	Terrasses du Larzac	AOC -	AOP -	{"fra": "Terrasses du Larzac"}	Terrasses du Larzac	\N
14989	2448	Terres du Midi	\N	IGP -	{"fra": "Terres du Midi blanc"}	Terres du Midi blanc	\N
14990	2448	Terres du Midi	\N	IGP -	{"fra": "Terres du Midi rosé"}	Terres du Midi rosé	\N
14991	2448	Terres du Midi	\N	IGP -	{"fra": "Terres du Midi rouge"}	Terres du Midi rouge	\N
14992	2448	Terres du Midi	\N	IGP -	{"fra": "Terres du Midi primeur ou nouveau blanc"}	Terres du Midi primeur ou nouveau blanc	\N
14993	2448	Terres du Midi	\N	IGP -	{"fra": "Terres du Midi primeur ou nouveau rosé"}	Terres du Midi primeur ou nouveau rosé	\N
14994	2448	Terres du Midi	\N	IGP -	{"fra": "Terres du Midi primeur ou nouveau rouge"}	Terres du Midi primeur ou nouveau rouge	\N
7862	2047	Thézac-Perricard	\N	IGP -	{"fra": "Thézac-Perricard blanc"}	Thézac-Perricard blanc	\N
8859	2047	Thézac-Perricard	\N	IGP -	{"fra": "Thézac-Perricard rosé"}	Thézac-Perricard rosé	\N
8860	2047	Thézac-Perricard	\N	IGP -	{"fra": "Thézac-Perricard rouge"}	Thézac-Perricard rouge	\N
11142	2047	Thézac-Perricard	\N	IGP -	{"fra": "Thézac-Perricard surmûri blanc"}	Thézac-Perricard surmûri blanc	\N
11143	2047	Thézac-Perricard	\N	IGP -	{"fra": "Thézac-Perricard primeur ou nouveau rouge"}	Thézac-Perricard primeur ou nouveau rouge	\N
13192	2393	Thym de Provence	\N	IGP -	{"fra": "Thym de Provence"}	Thym de Provence	\N
7886	1496	Tome des Bauges	AOC -	AOP -	{"fra": "Tome des Bauges"}	Tome des Bauges	\N
4506	1548	Tomme de Savoie	\N	IGP -	{"fra": "Tomme de Savoie"}	Tomme de Savoie	IG/52/94
3421	1549	Tomme des Pyrénées	\N	IGP -	{"fra": "Tomme des Pyrénées"}	Tomme des Pyrénées	IG/50/94
15454	209	Touraine	AOC -	AOP -	{"fra": "Touraine mousseux blanc"}	Touraine mousseux blanc	\N
15455	209	Touraine	AOC -	AOP -	{"fra": "Touraine mousseux rosé"}	Touraine mousseux rosé	\N
15457	209	Touraine	AOC -	AOP -	{"fra": "Touraine primeur rosé"}	Touraine primeur rosé	\N
15458	209	Touraine	AOC -	AOP -	{"fra": "Touraine primeur rouge"}	Touraine primeur rouge	\N
15459	209	Touraine	AOC -	AOP -	{"fra": "Touraine rosé"}	Touraine rosé	\N
15460	209	Touraine	AOC -	AOP -	{"fra": "Touraine rouge"}	Touraine rouge	\N
15443	210	Touraine Amboise	AOC -	AOP -	{"fra": "Touraine Amboise blanc"}	Touraine Amboise blanc	\N
15444	210	Touraine Amboise	AOC -	AOP -	{"fra": "Touraine Amboise rosé"}	Touraine Amboise rosé	\N
15445	210	Touraine Amboise	AOC -	AOP -	{"fra": "Touraine Amboise rouge"}	Touraine Amboise rouge	\N
15446	211	Touraine Azay-le-Rideau	AOC -	AOP -	{"fra": "Touraine Azay-le-Rideau blanc"}	Touraine Azay-le-Rideau blanc	\N
15447	211	Touraine Azay-le-Rideau	AOC -	AOP -	{"fra": "Touraine Azay-le-Rideau rosé"}	Touraine Azay-le-Rideau rosé	\N
15449	2174	Touraine Chenonceaux	AOC -	AOP -	{"fra": "Touraine Chenonceaux blanc"}	Touraine Chenonceaux blanc	\N
15450	2174	Touraine Chenonceaux	AOC -	AOP -	{"fra": "Touraine Chenonceaux rouge"}	Touraine Chenonceaux rouge	\N
15451	212	Touraine Mesland	AOC -	AOP -	{"fra": "Touraine Mesland blanc"}	Touraine Mesland blanc	\N
15452	212	Touraine Mesland	AOC -	AOP -	{"fra": "Touraine Mesland rosé"}	Touraine Mesland rosé	\N
15453	212	Touraine Mesland	AOC -	AOP -	{"fra": "Touraine Mesland rouge"}	Touraine Mesland rouge	\N
7891	216	Touraine Noble Joué	AOC -	AOP -	{"fra": "Touraine Noble Joué"}	Touraine Noble Joué	\N
15456	2173	Touraine Oisly	AOC -	AOP -	{"fra": "Touraine Oisly"}	Touraine Oisly	\N
8227	2144	Tursan	AOC -	AOP -	{"fra": "Tursan blanc"}	Tursan blanc	\N
8228	2144	Tursan	AOC -	AOP -	{"fra": "Tursan rosé"}	Tursan rosé	\N
8229	2144	Tursan	AOC -	AOP -	{"fra": "Tursan rouge"}	Tursan rouge	\N
7863	2040	Urfé	\N	IGP -	{"fra": "Urfé blanc"}	Urfé blanc	\N
8597	2040	Urfé	\N	IGP -	{"fra": "Urfé rosé"}	Urfé rosé	\N
8598	2040	Urfé	\N	IGP -	{"fra": "Urfé rouge"}	Urfé rouge	\N
11151	2040	Urfé	\N	IGP -	{"fra": "Urfé surmûri blanc"}	Urfé surmûri blanc	\N
11152	2040	Urfé	\N	IGP -	{"fra": "Urfé surmûri rosé"}	Urfé surmûri rosé	\N
11153	2040	Urfé	\N	IGP -	{"fra": "Urfé surmûri rouge"}	Urfé surmûri rouge	\N
11154	2040	Urfé	\N	IGP -	{"fra": "Urfé mousseux blanc"}	Urfé mousseux blanc	\N
11155	2040	Urfé	\N	IGP -	{"fra": "Urfé mousseux rosé"}	Urfé mousseux rosé	\N
11156	2040	Urfé	\N	IGP -	{"fra": "Urfé mousseux rouge"}	Urfé mousseux rouge	\N
11157	2267	Urfé Ambierle	\N	IGP -	{"fra": "Urfé Ambierle rosé"}	Urfé Ambierle rosé	\N
11158	2268	Urfé Trelins	\N	IGP -	{"fra": "Urfé Trelins rosé"}	Urfé Trelins rosé	\N
13438	1313	Vacqueyras	AOC -	AOP -	{"fra": "Vacqueyras blanc"}	Vacqueyras blanc	\N
13502	1313	Vacqueyras	AOC -	AOP -	{"fra": "Vacqueyras rosé"}	Vacqueyras rosé	\N
13503	1313	Vacqueyras	AOC -	AOP -	{"fra": "Vacqueyras rouge"}	Vacqueyras rouge	\N
15644	1970	Val de Loire	\N	IGP -	{"fra": "Val de Loire blanc"}	Val de Loire blanc	\N
15663	1970	Val de Loire	\N	IGP -	{"fra": "Val de Loire gris"}	Val de Loire gris	\N
15825	1970	Val de Loire	\N	IGP -	{"fra": "Val de Loire primeur ou nouveau blanc"}	Val de Loire primeur ou nouveau blanc	\N
15828	1970	Val de Loire	\N	IGP -	{"fra": "Val de Loire primeur ou nouveau gris"}	Val de Loire primeur ou nouveau gris	\N
15830	1970	Val de Loire	\N	IGP -	{"fra": "Val de Loire primeur ou nouveau rosé"}	Val de Loire primeur ou nouveau rosé	\N
15832	1970	Val de Loire	\N	IGP -	{"fra": "Val de Loire primeur ou nouveau rouge"}	Val de Loire primeur ou nouveau rouge	\N
15834	1970	Val de Loire	\N	IGP -	{"fra": "Val de Loire rosé"}	Val de Loire rosé	\N
15835	1970	Val de Loire	\N	IGP -	{"fra": "Val de Loire rouge"}	Val de Loire rouge	\N
15636	2269	Val de Loire Allier	\N	IGP -	{"fra": "Val de Loire Allier blanc"}	Val de Loire Allier blanc	\N
15637	2269	Val de Loire Allier	\N	IGP -	{"fra": "Val de Loire Allier rosé"}	Val de Loire Allier rosé	\N
15638	2269	Val de Loire Allier	\N	IGP -	{"fra": "Val de Loire Allier rouge"}	Val de Loire Allier rouge	\N
15639	2269	Val de Loire Allier	\N	IGP -	{"fra": "Val de Loire Allier gris"}	Val de Loire Allier gris	\N
15641	2269	Val de Loire Allier	\N	IGP -	{"fra": "Val de Loire Allier primeur ou nouveau gris"}	Val de Loire Allier primeur ou nouveau gris	\N
15642	2269	Val de Loire Allier	\N	IGP -	{"fra": "Val de Loire Allier primeur ou nouveau rosé"}	Val de Loire Allier primeur ou nouveau rosé	\N
15643	2269	Val de Loire Allier	\N	IGP -	{"fra": "Val de Loire Allier primeur ou nouveau rouge"}	Val de Loire Allier primeur ou nouveau rouge	\N
15647	2270	Val de Loire Cher	\N	IGP -	{"fra": "Val de Loire Cher blanc"}	Val de Loire Cher blanc	\N
15649	2270	Val de Loire Cher	\N	IGP -	{"fra": "Val de Loire Cher gris"}	Val de Loire Cher gris	\N
15651	2270	Val de Loire Cher	\N	IGP -	{"fra": "Val de Loire Cher primeur ou nouveau blanc"}	Val de Loire Cher primeur ou nouveau blanc	\N
15654	2270	Val de Loire Cher	\N	IGP -	{"fra": "Val de Loire Cher primeur ou nouveau gris"}	Val de Loire Cher primeur ou nouveau gris	\N
15656	2270	Val de Loire Cher	\N	IGP -	{"fra": "Val de Loire Cher primeur ou nouveau rosé"}	Val de Loire Cher primeur ou nouveau rosé	\N
15658	2270	Val de Loire Cher	\N	IGP -	{"fra": "Val de Loire Cher primeur ou nouveau rouge"}	Val de Loire Cher primeur ou nouveau rouge	\N
15660	2270	Val de Loire Cher	\N	IGP -	{"fra": "Val de Loire Cher rosé"}	Val de Loire Cher rosé	\N
15662	2270	Val de Loire Cher	\N	IGP -	{"fra": "Val de Loire Cher rouge"}	Val de Loire Cher rouge	\N
15666	2271	Val de Loire Indre	\N	IGP -	{"fra": "Val de Loire Indre blanc "}	Val de Loire Indre blanc 	\N
15669	2271	Val de Loire Indre	\N	IGP -	{"fra": "Val de Loire Indre gris"}	Val de Loire Indre gris	\N
15672	2271	Val de Loire Indre	\N	IGP -	{"fra": "Val de Loire Indre primeur ou nouveau blanc"}	Val de Loire Indre primeur ou nouveau blanc	\N
15674	2271	Val de Loire Indre	\N	IGP -	{"fra": "Val de Loire Indre primeur ou nouveau gris"}	Val de Loire Indre primeur ou nouveau gris	\N
15676	2271	Val de Loire Indre	\N	IGP -	{"fra": "Val de Loire Indre primeur ou nouveau rosé"}	Val de Loire Indre primeur ou nouveau rosé	\N
15678	2271	Val de Loire Indre	\N	IGP -	{"fra": "Val de Loire Indre primeur ou nouveau rouge"}	Val de Loire Indre primeur ou nouveau rouge	\N
15680	2271	Val de Loire Indre	\N	IGP -	{"fra": "Val de Loire Indre rosé"}	Val de Loire Indre rosé	\N
15682	2271	Val de Loire Indre	\N	IGP -	{"fra": "Val de Loire Indre rouge"}	Val de Loire Indre rouge	\N
15685	2272	Val de Loire Indre-et-Loire	\N	IGP -	{"fra": "Val de Loire Indre-et-Loire blanc"}	Val de Loire Indre-et-Loire blanc	\N
15687	2272	Val de Loire Indre-et-Loire	\N	IGP -	{"fra": "Val de Loire Indre-et-Loire gris"}	Val de Loire Indre-et-Loire gris	\N
15689	2272	Val de Loire Indre-et-Loire	\N	IGP -	{"fra": "Val de Loire Indre-et-Loire primeur ou nouveau blanc"}	Val de Loire Indre-et-Loire primeur ou nouveau blanc	\N
15691	2272	Val de Loire Indre-et-Loire	\N	IGP -	{"fra": "Val de Loire Indre-et-Loire primeur ou nouveau gris"}	Val de Loire Indre-et-Loire primeur ou nouveau gris	\N
15693	2272	Val de Loire Indre-et-Loire	\N	IGP -	{"fra": "Val de Loire Indre-et-Loire primeur ou nouveau rosé"}	Val de Loire Indre-et-Loire primeur ou nouveau rosé	\N
15695	2272	Val de Loire Indre-et-Loire	\N	IGP -	{"fra": "Val de Loire Indre-et-Loire primeur ou nouveau rouge"}	Val de Loire Indre-et-Loire primeur ou nouveau rouge	\N
15697	2272	Val de Loire Indre-et-Loire	\N	IGP -	{"fra": "Val de Loire Indre-et-Loire rosé"}	Val de Loire Indre-et-Loire rosé	\N
15699	2272	Val de Loire Indre-et-Loire	\N	IGP -	{"fra": "Val de Loire Indre-et-Loire rouge"}	Val de Loire Indre-et-Loire rouge	\N
15701	2275	Val de Loire Loir-et-Cher	\N	IGP -	{"fra": "Val de Loire Loir-et-Cher blanc"}	Val de Loire Loir-et-Cher blanc	\N
15703	2275	Val de Loire Loir-et-Cher	\N	IGP -	{"fra": "Val de Loire Loir-et-Cher gris"}	Val de Loire Loir-et-Cher gris	\N
15705	2275	Val de Loire Loir-et-Cher	\N	IGP -	{"fra": "Val de Loire Loir-et-Cher primeur ou nouveau blanc"}	Val de Loire Loir-et-Cher primeur ou nouveau blanc	\N
15707	2275	Val de Loire Loir-et-Cher	\N	IGP -	{"fra": "Val de Loire Loir-et-Cher primeur ou nouveau gris"}	Val de Loire Loir-et-Cher primeur ou nouveau gris	\N
15709	2275	Val de Loire Loir-et-Cher	\N	IGP -	{"fra": "Val de Loire Loir-et-Cher primeur ou nouveau rouge"}	Val de Loire Loir-et-Cher primeur ou nouveau rouge	\N
15711	2275	Val de Loire Loir-et-Cher	\N	IGP -	{"fra": "Val de Loire Loir-et-Cher rosé"}	Val de Loire Loir-et-Cher rosé	\N
15723	2275	Val de Loire Loir-et-Cher	\N	IGP -	{"fra": "Val de Loire Loir-et-Cher primeur ou nouveau rosé"}	Val de Loire Loir-et-Cher primeur ou nouveau rosé	\N
15724	2275	Val de Loire Loir-et-Cher	\N	IGP -	{"fra": "Val de Loire Loir-et-Cher rouge"}	Val de Loire Loir-et-Cher rouge	\N
15714	2273	Val de Loire Loire-Atlantique	\N	IGP -	{"fra": "Val de Loire Loire-Atlantique blanc"}	Val de Loire Loire-Atlantique blanc	\N
15718	2273	Val de Loire Loire-Atlantique	\N	IGP -	{"fra": "Val de Loire Loire-Atlantique gris"}	Val de Loire Loire-Atlantique gris	\N
15720	2273	Val de Loire Loire-Atlantique	\N	IGP -	{"fra": "Val de Loire Loire-Atlantique primeur ou nouveau blanc"}	Val de Loire Loire-Atlantique primeur ou nouveau blanc	\N
15722	2273	Val de Loire Loire-Atlantique	\N	IGP -	{"fra": "Val de Loire Loire-Atlantique primeur ou nouveau gris"}	Val de Loire Loire-Atlantique primeur ou nouveau gris	\N
15726	2273	Val de Loire Loire-Atlantique	\N	IGP -	{"fra": "Val de Loire Loire-Atlantique primeur ou nouveau rosé"}	Val de Loire Loire-Atlantique primeur ou nouveau rosé	\N
15728	2273	Val de Loire Loire-Atlantique	\N	IGP -	{"fra": "Val de Loire Loire-Atlantique primeur ou nouveau rouge"}	Val de Loire Loire-Atlantique primeur ou nouveau rouge	\N
15730	2273	Val de Loire Loire-Atlantique	\N	IGP -	{"fra": "Val de Loire Loire-Atlantique rosé"}	Val de Loire Loire-Atlantique rosé	\N
15750	2273	Val de Loire Loire-Atlantique	\N	IGP -	{"fra": "Val de Loire Loire-Atlantique rouge"}	Val de Loire Loire-Atlantique rouge	\N
15735	2274	Val de Loire Loiret	\N	IGP -	{"fra": "Val de Loire Loiret gris"}	Val de Loire Loiret gris	\N
15737	2274	Val de Loire Loiret	\N	IGP -	{"fra": "Val de Loire Loiret primeur ou nouveau blanc"}	Val de Loire Loiret primeur ou nouveau blanc	\N
15739	2274	Val de Loire Loiret	\N	IGP -	{"fra": "Val de Loire Loiret primeur ou nouveau gris"}	Val de Loire Loiret primeur ou nouveau gris	\N
15741	2274	Val de Loire Loiret	\N	IGP -	{"fra": "Val de Loire Loiret primeur ou nouveau rosé"}	Val de Loire Loiret primeur ou nouveau rosé	\N
15743	2274	Val de Loire Loiret	\N	IGP -	{"fra": "Val de Loire Loiret primeur ou nouveau rouge"}	Val de Loire Loiret primeur ou nouveau rouge	\N
15745	2274	Val de Loire Loiret	\N	IGP -	{"fra": "Val de Loire Loiret rosé"}	Val de Loire Loiret rosé	\N
15747	2274	Val de Loire Loiret	\N	IGP -	{"fra": "Val de Loire Loiret rouge"}	Val de Loire Loiret rouge	\N
15751	2274	Val de Loire Loiret	\N	IGP -	{"fra": "Val de Loire Loiret blanc"}	Val de Loire Loiret blanc	\N
15749	2276	Val de Loire Maine-et-Loire	\N	IGP -	{"fra": "Val de Loire Maine-et-Loire blanc"}	Val de Loire Maine-et-Loire blanc	\N
15753	2276	Val de Loire Maine-et-Loire	\N	IGP -	{"fra": "Val de Loire Maine-et-Loire gris"}	Val de Loire Maine-et-Loire gris	\N
15756	2276	Val de Loire Maine-et-Loire	\N	IGP -	{"fra": "Val de Loire Maine-et-Loire primeur ou nouveau blanc"}	Val de Loire Maine-et-Loire primeur ou nouveau blanc	\N
15758	2276	Val de Loire Maine-et-Loire	\N	IGP -	{"fra": "Val de Loire Maine-et-Loire primeur ou nouveau gris"}	Val de Loire Maine-et-Loire primeur ou nouveau gris	\N
15760	2276	Val de Loire Maine-et-Loire	\N	IGP -	{"fra": "Val de Loire Maine-et-Loire primeur ou nouveau rosé"}	Val de Loire Maine-et-Loire primeur ou nouveau rosé	\N
15762	2276	Val de Loire Maine-et-Loire	\N	IGP -	{"fra": "Val de Loire Maine-et-Loire primeur ou nouveau rouge"}	Val de Loire Maine-et-Loire primeur ou nouveau rouge	\N
15764	2276	Val de Loire Maine-et-Loire	\N	IGP -	{"fra": "Val de Loire Maine-et-Loire rosé"}	Val de Loire Maine-et-Loire rosé	\N
15766	2276	Val de Loire Maine-et-Loire	\N	IGP -	{"fra": "Val de Loire Maine-et-Loire rouge"}	Val de Loire Maine-et-Loire rouge	\N
15768	2277	Val de Loire Marches de Bretagne	\N	IGP -	{"fra": "Val de Loire Marches de Bretagne blanc"}	Val de Loire Marches de Bretagne blanc	\N
15770	2277	Val de Loire Marches de Bretagne	\N	IGP -	{"fra": "Val de Loire Marches de Bretagne gris"}	Val de Loire Marches de Bretagne gris	\N
15772	2277	Val de Loire Marches de Bretagne	\N	IGP -	{"fra": "Val de Loire Marches de Bretagne primeur ou nouveau blanc"}	Val de Loire Marches de Bretagne primeur ou nouveau blanc	\N
15774	2277	Val de Loire Marches de Bretagne	\N	IGP -	{"fra": "Val de Loire Marches de Bretagne primeur ou nouveau gris"}	Val de Loire Marches de Bretagne primeur ou nouveau gris	\N
15776	2277	Val de Loire Marches de Bretagne	\N	IGP -	{"fra": "Val de Loire Marches de Bretagne primeur ou nouveau rosé"}	Val de Loire Marches de Bretagne primeur ou nouveau rosé	\N
15778	2277	Val de Loire Marches de Bretagne	\N	IGP -	{"fra": "Val de Loire Marches de Bretagne primeur ou nouveau rouge"}	Val de Loire Marches de Bretagne primeur ou nouveau rouge	\N
15780	2277	Val de Loire Marches de Bretagne	\N	IGP -	{"fra": "Val de Loire Marches de Bretagne rosé"}	Val de Loire Marches de Bretagne rosé	\N
15782	2277	Val de Loire Marches de Bretagne	\N	IGP -	{"fra": "Val de Loire Marches de Bretagne rouge"}	Val de Loire Marches de Bretagne rouge	\N
15784	2278	Val de Loire Nièvre	\N	IGP -	{"fra": "Val de Loire Nièvre blanc"}	Val de Loire Nièvre blanc	\N
15786	2278	Val de Loire Nièvre	\N	IGP -	{"fra": "Val de Loire Nièvre gris"}	Val de Loire Nièvre gris	\N
15788	2278	Val de Loire Nièvre	\N	IGP -	{"fra": "Val de Loire Nièvre primeur ou nouveau blanc"}	Val de Loire Nièvre primeur ou nouveau blanc	\N
15790	2278	Val de Loire Nièvre	\N	IGP -	{"fra": "Val de Loire Nièvre primeur ou nouveau gris"}	Val de Loire Nièvre primeur ou nouveau gris	\N
15792	2278	Val de Loire Nièvre	\N	IGP -	{"fra": "Val de Loire Nièvre primeur ou nouveau rosé"}	Val de Loire Nièvre primeur ou nouveau rosé	\N
15798	2278	Val de Loire Nièvre	\N	IGP -	{"fra": "Val de Loire Nièvre primeur ou nouveau rouge"}	Val de Loire Nièvre primeur ou nouveau rouge	\N
15802	2278	Val de Loire Nièvre	\N	IGP -	{"fra": "Val de Loire Nièvre rosé"}	Val de Loire Nièvre rosé	\N
15807	2278	Val de Loire Nièvre	\N	IGP -	{"fra": "Val de Loire Nièvre rouge"}	Val de Loire Nièvre rouge	\N
15809	2279	Val de Loire Pays de Retz	\N	IGP -	{"fra": "Val de Loire Pays de Retz blanc"}	Val de Loire Pays de Retz blanc	\N
15811	2279	Val de Loire Pays de Retz	\N	IGP -	{"fra": "Val de Loire Pays de Retz gris"}	Val de Loire Pays de Retz gris	\N
15813	2279	Val de Loire Pays de Retz	\N	IGP -	{"fra": "Val de Loire Pays de Retz primeur ou nouveau blanc"}	Val de Loire Pays de Retz primeur ou nouveau blanc	\N
15815	2279	Val de Loire Pays de Retz	\N	IGP -	{"fra": "Val de Loire Pays de Retz primeur ou nouveau gris"}	Val de Loire Pays de Retz primeur ou nouveau gris	\N
15817	2279	Val de Loire Pays de Retz	\N	IGP -	{"fra": "Val de Loire Pays de Retz primeur ou nouveau rosé"}	Val de Loire Pays de Retz primeur ou nouveau rosé	\N
15819	2279	Val de Loire Pays de Retz	\N	IGP -	{"fra": "Val de Loire Pays de Retz primeur ou nouveau rouge"}	Val de Loire Pays de Retz primeur ou nouveau rouge	\N
15821	2279	Val de Loire Pays de Retz	\N	IGP -	{"fra": "Val de Loire Pays de Retz rosé"}	Val de Loire Pays de Retz rosé	\N
15823	2279	Val de Loire Pays de Retz	\N	IGP -	{"fra": "Val de Loire Pays de Retz rouge"}	Val de Loire Pays de Retz rouge	\N
15837	2280	Val de Loire Sarthe	\N	IGP -	{"fra": "Val de Loire Sarthe blanc"}	Val de Loire Sarthe blanc	\N
15839	2280	Val de Loire Sarthe	\N	IGP -	{"fra": "Val de Loire Sarthe gris"}	Val de Loire Sarthe gris	\N
15841	2280	Val de Loire Sarthe	\N	IGP -	{"fra": "Val de Loire Sarthe primeur ou nouveau blanc"}	Val de Loire Sarthe primeur ou nouveau blanc	\N
15843	2280	Val de Loire Sarthe	\N	IGP -	{"fra": "Val de Loire Sarthe primeur ou nouveau gris"}	Val de Loire Sarthe primeur ou nouveau gris	\N
15845	2280	Val de Loire Sarthe	\N	IGP -	{"fra": "Val de Loire Sarthe primeur ou nouveau rosé"}	Val de Loire Sarthe primeur ou nouveau rosé	\N
15847	2280	Val de Loire Sarthe	\N	IGP -	{"fra": "Val de Loire Sarthe primeur ou nouveau rouge"}	Val de Loire Sarthe primeur ou nouveau rouge	\N
15849	2280	Val de Loire Sarthe	\N	IGP -	{"fra": "Val de Loire Sarthe rosé"}	Val de Loire Sarthe rosé	\N
15851	2280	Val de Loire Sarthe	\N	IGP -	{"fra": "Val de Loire Sarthe rouge"}	Val de Loire Sarthe rouge	\N
15853	2281	Val de Loire Vendée	\N	IGP -	{"fra": "Val de Loire Vendée  primeur ou nouveau gris"}	Val de Loire Vendée  primeur ou nouveau gris	\N
15855	2281	Val de Loire Vendée	\N	IGP -	{"fra": "Val de Loire Vendée blanc"}	Val de Loire Vendée blanc	\N
15857	2281	Val de Loire Vendée	\N	IGP -	{"fra": "Val de Loire Vendée gris"}	Val de Loire Vendée gris	\N
15859	2281	Val de Loire Vendée	\N	IGP -	{"fra": "Val de Loire Vendée primeur ou nouveau blanc"}	Val de Loire Vendée primeur ou nouveau blanc	\N
15861	2281	Val de Loire Vendée	\N	IGP -	{"fra": "Val de Loire Vendée primeur ou nouveau rosé"}	Val de Loire Vendée primeur ou nouveau rosé	\N
15863	2281	Val de Loire Vendée	\N	IGP -	{"fra": "Val de Loire Vendée primeur ou nouveau rouge"}	Val de Loire Vendée primeur ou nouveau rouge	\N
15865	2281	Val de Loire Vendée	\N	IGP -	{"fra": "Val de Loire Vendée rosé"}	Val de Loire Vendée rosé	\N
15867	2281	Val de Loire Vendée	\N	IGP -	{"fra": "Val de Loire Vendée rouge"}	Val de Loire Vendée rouge	\N
15869	2282	Val de Loire Vienne	\N	IGP -	{"fra": "Val de Loire Vienne blanc"}	Val de Loire Vienne blanc	\N
15871	2282	Val de Loire Vienne	\N	IGP -	{"fra": "Val de Loire Vienne gris"}	Val de Loire Vienne gris	\N
15873	2282	Val de Loire Vienne	\N	IGP -	{"fra": "Val de Loire Vienne primeur ou nouveau blanc"}	Val de Loire Vienne primeur ou nouveau blanc	\N
15875	2282	Val de Loire Vienne	\N	IGP -	{"fra": "Val de Loire Vienne primeur ou nouveau gris"}	Val de Loire Vienne primeur ou nouveau gris	\N
15877	2282	Val de Loire Vienne	\N	IGP -	{"fra": "Val de Loire Vienne primeur ou nouveau rosé"}	Val de Loire Vienne primeur ou nouveau rosé	\N
15879	2282	Val de Loire Vienne	\N	IGP -	{"fra": "Val de Loire Vienne primeur ou nouveau rouge"}	Val de Loire Vienne primeur ou nouveau rouge	\N
15881	2282	Val de Loire Vienne	\N	IGP -	{"fra": "Val de Loire Vienne rosé"}	Val de Loire Vienne rosé	\N
15884	2282	Val de Loire Vienne	\N	IGP -	{"fra": "Val de Loire Vienne rouge"}	Val de Loire Vienne rouge	\N
5303	1596	Valençay	AOC -	AOP -	{"fra": "Valençay blanc"}	Valençay blanc	\N
5304	1596	Valençay	AOC -	AOP -	{"fra": "Valençay rosé"}	Valençay rosé	\N
5305	1596	Valençay	AOC -	AOP -	{"fra": "Valençay rouge"}	Valençay rouge	\N
13170	1491	Valençay	AOC -	AOP -	{"fra": "Valençay"}	Valençay	\N
7864	2096	Vallée du Paradis	\N	IGP -	{"fra": "Vallée du Paradis blanc"}	Vallée du Paradis blanc	\N
8434	2096	Vallée du Paradis	\N	IGP -	{"fra": "Vallée du Paradis rosé"}	Vallée du Paradis rosé	\N
8435	2096	Vallée du Paradis	\N	IGP -	{"fra": "Vallée du Paradis rouge"}	Vallée du Paradis rouge	\N
11386	2096	Vallée du Paradis	\N	IGP -	{"fra": "Vallée du Paradis primeur ou nouveau blanc"}	Vallée du Paradis primeur ou nouveau blanc	\N
11387	2096	Vallée du Paradis	\N	IGP -	{"fra": "Vallée du Paradis primeur ou nouveau rosé"}	Vallée du Paradis primeur ou nouveau rosé	\N
11388	2096	Vallée du Paradis	\N	IGP -	{"fra": "Vallée du Paradis primeur ou nouveau rouge"}	Vallée du Paradis primeur ou nouveau rouge	\N
11389	2096	Vallée du Paradis	\N	IGP -	{"fra": "Vallée du Paradis gris"}	Vallée du Paradis gris	\N
11390	2096	Vallée du Paradis	\N	IGP -	{"fra": "Vallée du Paradis gris de gris"}	Vallée du Paradis gris de gris	\N
7872	2169	Vallée du Torgan	\N	IGP -	{"fra": "Vallée du Torgan blanc"}	Vallée du Torgan blanc	\N
8825	2169	Vallée du Torgan	\N	IGP -	{"fra": "Vallée du Torgan rosé"}	Vallée du Torgan rosé	\N
8826	2169	Vallée du Torgan	\N	IGP -	{"fra": "Vallée du Torgan rouge"}	Vallée du Torgan rouge	\N
11144	2169	Vallée du Torgan	\N	IGP -	{"fra": "Vallée du Torgan gris"}	Vallée du Torgan gris	\N
11145	2169	Vallée du Torgan	\N	IGP -	{"fra": "Vallée du Torgan gris de gris"}	Vallée du Torgan gris de gris	\N
11146	2169	Vallée du Torgan	\N	IGP -	{"fra": "Vallée du Torgan primeur ou nouveau gris"}	Vallée du Torgan primeur ou nouveau gris	\N
11147	2169	Vallée du Torgan	\N	IGP -	{"fra": "Vallée du Torgan primeur ou nouveau gris de gris"}	Vallée du Torgan primeur ou nouveau gris de gris	\N
11148	2169	Vallée du Torgan	\N	IGP -	{"fra": "Vallée du Torgan primeur ou nouveau blanc"}	Vallée du Torgan primeur ou nouveau blanc	\N
11149	2169	Vallée du Torgan	\N	IGP -	{"fra": "Vallée du Torgan primeur ou nouveau rosé"}	Vallée du Torgan primeur ou nouveau rosé	\N
11150	2169	Vallée du Torgan	\N	IGP -	{"fra": "Vallée du Torgan primeur ou nouveau rouge"}	Vallée du Torgan primeur ou nouveau rouge	\N
15355	2074	Var	\N	IGP -	{"fra": "Var blanc"}	Var blanc	\N
15369	2074	Var	\N	IGP -	{"fra": "Var rouge"}	Var rouge	\N
15370	2074	Var	\N	IGP -	{"fra": "Var rosé"}	Var rosé	\N
15371	2074	Var	\N	IGP -	{"fra": "Var primeur ou nouveau rouge"}	Var primeur ou nouveau rouge	\N
15372	2074	Var	\N	IGP -	{"fra": "Var primeur ou nouveau rosé"}	Var primeur ou nouveau rosé	\N
15373	2074	Var	\N	IGP -	{"fra": "Var primeur ou nouveau blanc"}	Var primeur ou nouveau blanc	\N
15374	2074	Var	\N	IGP -	{"fra": "Var mousseux de qualité rouge"}	Var mousseux de qualité rouge	\N
15375	2074	Var	\N	IGP -	{"fra": "Var mousseux de qualité rosé"}	Var mousseux de qualité rosé	\N
15376	2074	Var	\N	IGP -	{"fra": "Var mousseux de qualité blanc"}	Var mousseux de qualité blanc	\N
15346	2283	Var Argens	\N	IGP -	{"fra": "Var Argens blanc"}	Var Argens blanc	\N
15347	2283	Var Argens	\N	IGP -	{"fra": "Var Argens mousseux de qualité blanc"}	Var Argens mousseux de qualité blanc	\N
15348	2283	Var Argens	\N	IGP -	{"fra": "Var Argens mousseux de qualité rosé"}	Var Argens mousseux de qualité rosé	\N
15349	2283	Var Argens	\N	IGP -	{"fra": "Var Argens mousseux de qualité rouge"}	Var Argens mousseux de qualité rouge	\N
15350	2283	Var Argens	\N	IGP -	{"fra": "Var Argens primeur ou nouveau blanc"}	Var Argens primeur ou nouveau blanc	\N
15351	2283	Var Argens	\N	IGP -	{"fra": "Var Argens primeur ou nouveau rosé"}	Var Argens primeur ou nouveau rosé	\N
15352	2283	Var Argens	\N	IGP -	{"fra": "Var Argens primeur ou nouveau rouge"}	Var Argens primeur ou nouveau rouge	\N
15353	2283	Var Argens	\N	IGP -	{"fra": "Var Argens rosé"}	Var Argens rosé	\N
15354	2283	Var Argens	\N	IGP -	{"fra": "Var Argens rouge"}	Var Argens rouge	\N
15356	2284	Var Coteaux du Verdon	\N	IGP -	{"fra": "Var Coteaux du Verdon blanc"}	Var Coteaux du Verdon blanc	\N
15357	2284	Var Coteaux du Verdon	\N	IGP -	{"fra": "Var Coteaux du Verdon mousseux de qualité blanc"}	Var Coteaux du Verdon mousseux de qualité blanc	\N
15358	2284	Var Coteaux du Verdon	\N	IGP -	{"fra": "Var Coteaux du Verdon mousseux de qualité rosé"}	Var Coteaux du Verdon mousseux de qualité rosé	\N
15359	2284	Var Coteaux du Verdon	\N	IGP -	{"fra": "Var Coteaux du Verdon mousseux de qualité rouge"}	Var Coteaux du Verdon mousseux de qualité rouge	\N
15360	2284	Var Coteaux du Verdon	\N	IGP -	{"fra": "Var Coteaux du Verdon primeur ou nouveau blanc"}	Var Coteaux du Verdon primeur ou nouveau blanc	\N
15361	2284	Var Coteaux du Verdon	\N	IGP -	{"fra": "Var Coteaux du Verdon primeur ou nouveau rosé"}	Var Coteaux du Verdon primeur ou nouveau rosé	\N
15377	2284	Var Coteaux du Verdon	\N	IGP -	{"fra": "Var Coteaux du Verdon rouge"}	Var Coteaux du Verdon rouge	\N
15378	2284	Var Coteaux du Verdon	\N	IGP -	{"fra": "Var Coteaux du Verdon rosé"}	Var Coteaux du Verdon rosé	\N
15379	2284	Var Coteaux du Verdon	\N	IGP -	{"fra": "Var Coteaux du Verdon primeur ou nouveau rouge"}	Var Coteaux du Verdon primeur ou nouveau rouge	\N
15362	2285	Var Sainte Baume	\N	IGP -	{"fra": "Var Sainte Baume primeur ou nouveau rouge"}	Var Sainte Baume primeur ou nouveau rouge	\N
15363	2285	Var Sainte Baume	\N	IGP -	{"fra": "Var Sainte Baume primeur ou nouveau rosé"}	Var Sainte Baume primeur ou nouveau rosé	\N
15364	2285	Var Sainte Baume	\N	IGP -	{"fra": "Var Sainte Baume primeur ou nouveau blanc"}	Var Sainte Baume primeur ou nouveau blanc	\N
15365	2285	Var Sainte Baume	\N	IGP -	{"fra": "Var Sainte Baume mousseux de qualité rouge"}	Var Sainte Baume mousseux de qualité rouge	\N
15366	2285	Var Sainte Baume	\N	IGP -	{"fra": "Var Sainte Baume mousseux de qualité rosé"}	Var Sainte Baume mousseux de qualité rosé	\N
15367	2285	Var Sainte Baume	\N	IGP -	{"fra": "Var Sainte Baume mousseux de qualité blanc"}	Var Sainte Baume mousseux de qualité blanc	\N
15368	2285	Var Sainte Baume	\N	IGP -	{"fra": "Var Sainte Baume blanc"}	Var Sainte Baume blanc	\N
15380	2285	Var Sainte Baume	\N	IGP -	{"fra": "Var Sainte Baume rosé"}	Var Sainte Baume rosé	\N
15381	2285	Var Sainte Baume	\N	IGP -	{"fra": "Var Sainte Baume rouge"}	Var Sainte Baume rouge	\N
7832	2080	Vaucluse	\N	IGP -	{"fra": "Vaucluse blanc"}	Vaucluse blanc	\N
8453	2080	Vaucluse	\N	IGP -	{"fra": "Vaucluse rosé"}	Vaucluse rosé	\N
8454	2080	Vaucluse	\N	IGP -	{"fra": "Vaucluse rouge"}	Vaucluse rouge	\N
11424	2080	Vaucluse	\N	IGP -	{"fra": "Vaucluse primeur ou nouveau blanc"}	Vaucluse primeur ou nouveau blanc	\N
11425	2080	Vaucluse	\N	IGP -	{"fra": "Vaucluse primeur ou nouveau rosé"}	Vaucluse primeur ou nouveau rosé	\N
11426	2080	Vaucluse	\N	IGP -	{"fra": "Vaucluse primeur ou nouveau rouge"}	Vaucluse primeur ou nouveau rouge	\N
11427	2286	Vaucluse Aigues	\N	IGP -	{"fra": "Vaucluse Aigues blanc"}	Vaucluse Aigues blanc	\N
11428	2286	Vaucluse Aigues	\N	IGP -	{"fra": "Vaucluse Aigues rosé"}	Vaucluse Aigues rosé	\N
11429	2286	Vaucluse Aigues	\N	IGP -	{"fra": "Vaucluse Aigues rouge"}	Vaucluse Aigues rouge	\N
11430	2286	Vaucluse Aigues	\N	IGP -	{"fra": "Vaucluse Aigues primeur ou nouveau blanc"}	Vaucluse Aigues primeur ou nouveau blanc	\N
11431	2286	Vaucluse Aigues	\N	IGP -	{"fra": "Vaucluse Aigues primeur ou nouveau rosé"}	Vaucluse Aigues primeur ou nouveau rosé	\N
11432	2286	Vaucluse Aigues	\N	IGP -	{"fra": "Vaucluse Aigues primeur ou nouveau rouge"}	Vaucluse Aigues primeur ou nouveau rouge	\N
11433	2287	Vaucluse Principauté d'Orange	\N	IGP -	{"fra": "Vaucluse Principauté d'Orange blanc"}	Vaucluse Principauté d'Orange blanc	\N
11434	2287	Vaucluse Principauté d'Orange	\N	IGP -	{"fra": "Vaucluse Principauté d'Orange rosé"}	Vaucluse Principauté d'Orange rosé	\N
11435	2287	Vaucluse Principauté d'Orange	\N	IGP -	{"fra": "Vaucluse Principauté d'Orange rouge"}	Vaucluse Principauté d'Orange rouge	\N
11436	2287	Vaucluse Principauté d'Orange	\N	IGP -	{"fra": "Vaucluse Principauté d'Orange primeur ou nouveau blanc"}	Vaucluse Principauté d'Orange primeur ou nouveau blanc	\N
11437	2287	Vaucluse Principauté d'Orange	\N	IGP -	{"fra": "Vaucluse Principauté d'Orange primeur ou nouveau rosé"}	Vaucluse Principauté d'Orange primeur ou nouveau rosé	\N
11438	2287	Vaucluse Principauté d'Orange	\N	IGP -	{"fra": "Vaucluse Principauté d'Orange primeur ou nouveau rouge"}	Vaucluse Principauté d'Orange primeur ou nouveau rouge	\N
3423	1551	Veau du Limousin	\N	IGP -	{"fra": "Veau du Limousin"}	Veau du Limousin	IG/39/94
3422	1550	Veau d’Aveyron et du Ségala	\N	IGP -	{"fra": "Veau d’Aveyron et du Ségala"}	Veau d’Aveyron et du Ségala	IG/38/94
8888	1305	Ventoux	AOC -	AOP -	{"fra": "Ventoux blanc"}	Ventoux blanc	\N
8889	1305	Ventoux	AOC -	AOP -	{"fra": "Ventoux primeur ou nouveau blanc"}	Ventoux primeur ou nouveau blanc	\N
8890	1305	Ventoux	AOC -	AOP -	{"fra": "Ventoux primeur ou nouveau rosé"}	Ventoux primeur ou nouveau rosé	\N
8891	1305	Ventoux	AOC -	AOP -	{"fra": "Ventoux primeur ou nouveau rouge"}	Ventoux primeur ou nouveau rouge	\N
8892	1305	Ventoux	AOC -	AOP -	{"fra": "Ventoux rosé"}	Ventoux rosé	\N
8893	1305	Ventoux	AOC -	AOP -	{"fra": "Ventoux rouge"}	Ventoux rouge	\N
14200	2428	Vézelay	AOC -	\N	{"fra": "Vézelay"}	Vézelay	\N
7865	2113	Vicomté d'Aumelas	\N	IGP -	{"fra": "Vicomté d'Aumelas blanc"}	Vicomté d'Aumelas blanc	\N
8411	2113	Vicomté d'Aumelas	\N	IGP -	{"fra": "Vicomté d'Aumelas rosé"}	Vicomté d'Aumelas rosé	\N
8412	2113	Vicomté d'Aumelas	\N	IGP -	{"fra": "Vicomté d'Aumelas rouge"}	Vicomté d'Aumelas rouge	\N
11439	2113	Vicomté d'Aumelas	\N	IGP -	{"fra": "Vicomté d'Aumelas primeur ou nouveau blanc"}	Vicomté d'Aumelas primeur ou nouveau blanc	\N
11440	2113	Vicomté d'Aumelas	\N	IGP -	{"fra": "Vicomté d'Aumelas primeur ou nouveau rosé"}	Vicomté d'Aumelas primeur ou nouveau rosé	\N
11441	2113	Vicomté d'Aumelas	\N	IGP -	{"fra": "Vicomté d'Aumelas primeur ou nouveau rouge"}	Vicomté d'Aumelas primeur ou nouveau rouge	\N
11442	2288	Vicomté d'Aumelas Vallée Dorée	\N	IGP -	{"fra": "Vicomté d'Aumelas Vallée Dorée blanc"}	Vicomté d'Aumelas Vallée Dorée blanc	\N
11443	2288	Vicomté d'Aumelas Vallée Dorée	\N	IGP -	{"fra": "Vicomté d'Aumelas Vallée Dorée rosé"}	Vicomté d'Aumelas Vallée Dorée rosé	\N
11444	2288	Vicomté d'Aumelas Vallée Dorée	\N	IGP -	{"fra": "Vicomté d'Aumelas Vallée Dorée rouge"}	Vicomté d'Aumelas Vallée Dorée rouge	\N
11445	2288	Vicomté d'Aumelas Vallée Dorée	\N	IGP -	{"fra": "Vicomté d'Aumelas Vallée Dorée primeur ou nouveau blanc"}	Vicomté d'Aumelas Vallée Dorée primeur ou nouveau blanc	\N
11446	2288	Vicomté d'Aumelas Vallée Dorée	\N	IGP -	{"fra": "Vicomté d'Aumelas Vallée Dorée primeur ou nouveau rosé"}	Vicomté d'Aumelas Vallée Dorée primeur ou nouveau rosé	\N
11447	2288	Vicomté d'Aumelas Vallée Dorée	\N	IGP -	{"fra": "Vicomté d'Aumelas Vallée Dorée primeur ou nouveau rouge"}	Vicomté d'Aumelas Vallée Dorée primeur ou nouveau rouge	\N
16057	1325	Vin de Corse ou Corse	AOC -	AOP -	{"fra": "Vin de Corse ou Corse blanc"}	Vin de Corse ou Corse blanc	\N
16060	1325	Vin de Corse ou Corse	AOC -	AOP -	{"fra": "Vin de Corse ou Corse rosé"}	Vin de Corse ou Corse rosé	\N
16061	1325	Vin de Corse ou Corse	AOC -	AOP -	{"fra": "Vin de Corse ou Corse rouge"}	Vin de Corse ou Corse rouge	\N
16058	1326	Vin de Corse ou Corse Calvi	AOC -	AOP -	{"fra": "Vin de Corse ou Corse Calvi blanc"}	Vin de Corse ou Corse Calvi blanc	\N
16062	1326	Vin de Corse ou Corse Calvi	AOC -	AOP -	{"fra": "Vin de Corse ou Corse Calvi rosé"}	Vin de Corse ou Corse Calvi rosé	\N
16063	1326	Vin de Corse ou Corse Calvi	AOC -	AOP -	{"fra": "Vin de Corse ou Corse Calvi rouge"}	Vin de Corse ou Corse Calvi rouge	\N
16072	1327	Vin de Corse ou Corse Coteaux du Cap Corse	AOC -	AOP -	{"fra": "Vin de Corse ou Corse Coteaux du Cap Corse blanc"}	Vin de Corse ou Corse Coteaux du Cap Corse blanc	\N
16073	1327	Vin de Corse ou Corse Coteaux du Cap Corse	AOC -	AOP -	{"fra": "Vin de Corse ou Corse Coteaux du Cap Corse rosé"}	Vin de Corse ou Corse Coteaux du Cap Corse rosé	\N
16074	1327	Vin de Corse ou Corse Coteaux du Cap Corse	AOC -	AOP -	{"fra": "Vin de Corse ou Corse Coteaux du Cap Corse rouge"}	Vin de Corse ou Corse Coteaux du Cap Corse rouge	\N
16064	1328	Vin de Corse ou Corse Figari	AOC -	AOP -	{"fra": "Vin de Corse ou Corse Figari blanc"}	Vin de Corse ou Corse Figari blanc	\N
16065	1328	Vin de Corse ou Corse Figari	AOC -	AOP -	{"fra": "Vin de Corse ou Corse Figari rosé"}	Vin de Corse ou Corse Figari rosé	\N
16066	1328	Vin de Corse ou Corse Figari	AOC -	AOP -	{"fra": "Vin de Corse ou Corse Figari rouge"}	Vin de Corse ou Corse Figari rouge	\N
16067	1329	Vin de Corse ou Corse Porto-Vecchio	AOC -	AOP -	{"fra": "Vin de Corse ou Corse Porto-Vecchio blanc"}	Vin de Corse ou Corse Porto-Vecchio blanc	\N
16068	1329	Vin de Corse ou Corse Porto-Vecchio	AOC -	AOP -	{"fra": "Vin de Corse ou Corse Porto-Vecchio rosé"}	Vin de Corse ou Corse Porto-Vecchio rosé	\N
16069	1329	Vin de Corse ou Corse Porto-Vecchio	AOC -	AOP -	{"fra": "Vin de Corse ou Corse Porto-Vecchio rouge"}	Vin de Corse ou Corse Porto-Vecchio rouge	\N
16059	1330	Vin de Corse ou Corse Sartène	AOC -	AOP -	{"fra": "Vin de Corse ou Corse Sartène rosé"}	Vin de Corse ou Corse Sartène rosé	\N
16070	1330	Vin de Corse ou Corse Sartène	AOC -	AOP -	{"fra": "Vin de Corse ou Corse Sartène blanc"}	Vin de Corse ou Corse Sartène blanc	\N
16071	1330	Vin de Corse ou Corse Sartène	AOC -	AOP -	{"fra": "Vin de Corse ou Corse Sartène rouge"}	Vin de Corse ou Corse Sartène rouge	\N
13179	1151	Vin de Savoie	AOC -	AOP -	{"fra": "Vin de Savoie ou Savoie blanc"}	Vin de Savoie ou Savoie blanc	\N
13679	1151	Vin de Savoie	AOC -	AOP -	{"fra": "Vin de Savoie mousseux blanc"}	Vin de Savoie mousseux blanc	\N
13680	1151	Vin de Savoie	AOC -	AOP -	{"fra": "Vin de Savoie mousseux rosé"}	Vin de Savoie mousseux rosé	\N
13681	1151	Vin de Savoie	AOC -	AOP -	{"fra": "Vin de Savoie ou Savoie rosé"}	Vin de Savoie ou Savoie rosé	\N
13682	1151	Vin de Savoie	AOC -	AOP -	{"fra": "Vin de Savoie ou Savoie rouge"}	Vin de Savoie ou Savoie rouge	\N
13683	1151	Vin de Savoie	AOC -	AOP -	{"fra": "Vin de Savoie pétillant blanc"}	Vin de Savoie pétillant blanc	\N
13684	1151	Vin de Savoie	AOC -	AOP -	{"fra": "Vin de Savoie pétillant rosé"}	Vin de Savoie pétillant rosé	\N
13314	1152	Vin de Savoie Abymes	AOC -	AOP -	{"fra": "Vin de Savoie Abymes ou Les Abymes"}	Vin de Savoie Abymes ou Les Abymes	\N
13662	1153	Vin de Savoie Apremont	AOC -	AOP -	{"fra": "Vin de Savoie Apremont"}	Vin de Savoie Apremont	\N
13663	1154	Vin de Savoie Arbin	AOC -	AOP -	{"fra": "Vin de Savoie Arbin"}	Vin de Savoie Arbin	\N
13664	1155	Vin de Savoie Ayze	AOC -	AOP -	{"fra": "Vin de Savoie Ayze"}	Vin de Savoie Ayze	\N
13665	1155	Vin de Savoie Ayze	AOC -	AOP -	{"fra": "Vin de Savoie Ayze mousseux"}	Vin de Savoie Ayze mousseux	\N
13666	1155	Vin de Savoie Ayze	AOC -	AOP -	{"fra": "Vin de Savoie Ayze pétillant"}	Vin de Savoie Ayze pétillant	\N
13667	1157	Vin de Savoie Chautagne	AOC -	AOP -	{"fra": "Vin de Savoie Chautagne blanc"}	Vin de Savoie Chautagne blanc	\N
13668	1157	Vin de Savoie Chautagne	AOC -	AOP -	{"fra": "Vin de Savoie Chautagne rouge"}	Vin de Savoie Chautagne rouge	\N
13669	1158	Vin de Savoie Chignin	AOC -	AOP -	{"fra": "Vin de Savoie Chignin blanc"}	Vin de Savoie Chignin blanc	\N
13670	1158	Vin de Savoie Chignin	AOC -	AOP -	{"fra": "Vin de Savoie Chignin rouge"}	Vin de Savoie Chignin rouge	\N
13671	1159	Vin de Savoie Chignin-Bergeron	AOC -	AOP -	{"fra": "Vin de Savoie Chignin-Bergeron"}	Vin de Savoie Chignin-Bergeron	\N
13672	519	Vin de Savoie Crépy	AOC -	AOP -	{"fra": "Vin de Savoie Crépy"}	Vin de Savoie Crépy	\N
13673	1160	Vin de Savoie Cruet	AOC -	AOP -	{"fra": "Vin de Savoie Cruet"}	Vin de Savoie Cruet	\N
13674	1161	Vin de Savoie Jongieux	AOC -	AOP -	{"fra": "Vin de Savoie Jongieux blanc"}	Vin de Savoie Jongieux blanc	\N
13675	1161	Vin de Savoie Jongieux	AOC -	AOP -	{"fra": "Vin de Savoie Jongieux rouge"}	Vin de Savoie Jongieux rouge	\N
13676	1162	Vin de Savoie Marignan	AOC -	AOP -	{"fra": "Vin de Savoie Marignan"}	Vin de Savoie Marignan	\N
13677	1163	Vin de Savoie Marin	AOC -	AOP -	{"fra": "Vin de Savoie Marin"}	Vin de Savoie Marin	\N
13678	1164	Vin de Savoie Montmélian	AOC -	AOP -	{"fra": "Vin de Savoie Montmélian"}	Vin de Savoie Montmélian	\N
13685	1165	Vin de Savoie Ripaille	AOC -	AOP -	{"fra": "Vin de Savoie Ripaille"}	Vin de Savoie Ripaille	\N
13686	1166	Vin de Savoie Saint-Jean-de-la-Porte	AOC -	AOP -	{"fra": "Vin de Savoie Saint-Jean-de-la-Porte"}	Vin de Savoie Saint-Jean-de-la-Porte	\N
13687	1167	Vin de Savoie Saint-Jeoire-Prieuré	AOC -	AOP -	{"fra": "Vin de Savoie Saint-Jeoire-Prieuré"}	Vin de Savoie Saint-Jeoire-Prieuré	\N
14251	2154	Vin des Allobroges	\N	IGP -	{"fra": "Vin des Allobroges blanc"}	Vin des Allobroges blanc	\N
14252	2154	Vin des Allobroges	\N	IGP -	{"fra": "Vin des Allobroges mousseux de qualité blanc"}	Vin des Allobroges mousseux de qualité blanc	\N
14253	2154	Vin des Allobroges	\N	IGP -	{"fra": "Vin des Allobroges mousseux de qualité rosé "}	Vin des Allobroges mousseux de qualité rosé 	\N
14254	2154	Vin des Allobroges	\N	IGP -	{"fra": "Vin des Allobroges passerillé blancs"}	Vin des Allobroges passerillé blancs	\N
14255	2154	Vin des Allobroges	\N	IGP -	{"fra": "Vin des Allobroges rosé"}	Vin des Allobroges rosé	\N
14256	2154	Vin des Allobroges	\N	IGP -	{"fra": "Vin des Allobroges rouge"}	Vin des Allobroges rouge	\N
14257	2154	Vin des Allobroges	\N	IGP -	{"fra": "Vin des Allobroges surmûris blanc"}	Vin des Allobroges surmûris blanc	\N
13745	2410	vins mousseux de qualité	\N	IGP -	{"fra": "Haute-Marne Mousseux de qualité blanc"}	Haute-Marne Mousseux de qualité blanc	\N
13746	2410	vins mousseux de qualité	\N	IGP -	{"fra": "Haute-Marne Mousseux de qualité rosé"}	Haute-Marne Mousseux de qualité rosé	\N
13747	2410	vins mousseux de qualité	\N	IGP -	{"fra": "Haute-Marne Mousseux de qualité rouge"}	Haute-Marne Mousseux de qualité rouge	\N
15407	2411	vins mousseux de qualité	\N	IGP -	{"fra": "Pays d'Oc mousseux de qualité blanc"}	Pays d'Oc mousseux de qualité blanc	\N
15269	1302	Vinsobres	AOC -	AOP -	{"fra": "Vinsobres"}	Vinsobres	\N
14457	1232	Viré-Clessé	AOC -	AOP -	{"fra": "Viré-Clessé"}	Viré-Clessé	\N
14458	1232	Viré-Clessé	AOC -	AOP -	{"fra": "Viré-Clessé complété par une dénomination de climat"}	Viré-Clessé complété par une dénomination de climat	\N
4206	1959	Volaille de Bresse ou poulet de Bresse, poularde de Bresse, chapon de 	AOC -	AOP -	{"fra": "Poularde de Bresse"}	Poularde de Bresse	\N
4207	1959	Volaille de Bresse ou poulet de Bresse, poularde de Bresse, chapon de 	AOC -	AOP -	{"fra": "Chapon de Bresse"}	Chapon de Bresse	\N
15225	1959	Volaille de Bresse ou poulet de Bresse, poularde de Bresse, chapon de 	AOC -	AOP -	{"fra": "Volaille de Bresse ou Poulet de Bresse"}	Volaille de Bresse ou Poulet de Bresse	\N
3456	1584	Volailles de Bourgogne	\N	IGP -	{"fra": "Volailles de Bourgogne"}	Volailles de Bourgogne	IG/07/94
3427	1555	Volailles de Bretagne	\N	IGP -	{"fra": "Volailles de Bretagne"}	Volailles de Bretagne	IG/08/94
3428	1556	Volailles de Challans	\N	IGP -	{"fra": "Volailles de Challans"}	Volailles de Challans	IG/09/94
3429	1557	Volailles de Cholet	\N	IGP -	{"fra": "Volailles de Cholet"}	Volailles de Cholet	IG/12/94
3430	1558	Volailles de Gascogne	\N	IGP -	{"fra": "Volailles de Gascogne"}	Volailles de Gascogne	IG/15/94
3431	1559	Volailles de Houdan	\N	IGP -	{"fra": "Volailles de Houdan"}	Volailles de Houdan	IG/18/94
3432	1560	Volailles de Janzé	\N	IGP -	{"fra": "Volailles de Janzé"}	Volailles de Janzé	IG/19/94
3433	1561	Volailles de la Champagne	\N	IGP -	{"fra": "Volailles de la Champagne"}	Volailles de la Champagne	IG/10/94
3434	1562	Volailles de la Drôme	\N	IGP -	{"fra": "Volailles de la Drôme"}	Volailles de la Drôme	IG/13/94
3435	1563	Volailles de Licques	\N	IGP -	{"fra": "Volailles de Licques"}	Volailles de Licques	IG/24/94
4575	1565	Volailles de Loué	\N	IGP -	{"fra": "Volailles de Loué"}	Volailles de Loué	IG/25/94
3457	1585	Volailles de l’Ain	\N	IGP -	{"fra": "Volailles de l’Ain"}	Volailles de l’Ain	IG/01/94
3436	1564	Volailles de l’Orléanais	\N	IGP -	{"fra": "Volailles de l’Orléanais"}	Volailles de l’Orléanais	IG/28/94
3453	1581	Volailles de Normandie	\N	IGP -	{"fra": "Volailles de Normandie"}	Volailles de Normandie	IG/27/94
3438	1566	Volailles de Vendée	\N	IGP -	{"fra": "Volailles de Vendée"}	Volailles de Vendée	IG/31/94
3439	1567	Volailles des Landes	\N	IGP -	{"fra": "Volailles des Landes"}	Volailles des Landes	IG/20/94
3440	1568	Volailles du Béarn	\N	IGP -	{"fra": "Volailles du Béarn"}	Volailles du Béarn	IG/05/94
3441	1569	Volailles du Berry	\N	IGP -	{"fra": "Volailles du Berry"}	Volailles du Berry	IG/06/94
3454	1586	Volailles du Charolais	\N	IGP -	{"fra": "Volailles du Charolais"}	Volailles du Charolais	IG/11/94
3455	1587	Volailles du Forez	\N	IGP -	{"fra": "Volailles du Forez"}	Volailles du Forez	IG/14/94
3443	1570	Volailles du Gâtinais	\N	IGP -	{"fra": "Volailles du Gâtinais"}	Volailles du Gâtinais	IG/16/94
3462	1591	Volailles du Gers	\N	IGP -	{"fra": "Volailles du Gers"}	Volailles du Gers	IG/17/94
3442	1571	Volailles du Languedoc	\N	IGP -	{"fra": "Volailles du Languedoc"}	Volailles du Languedoc	IG/22/94
3444	1572	Volailles du Lauragais	\N	IGP -	{"fra": "Volailles du Lauragais"}	Volailles du Lauragais	IG/23/94
3445	1573	Volailles du Maine	\N	IGP -	{"fra": "Volailles du Maine"}	Volailles du Maine	IG/26/94
3446	1574	Volailles du plateau de Langres	\N	IGP -	{"fra": "Volailles du plateau de Langres"}	Volailles du plateau de Langres	IG/21/94
3447	1575	Volailles du Val de Sèvres	\N	IGP -	{"fra": "Volailles du Val de Sèvres"}	Volailles du Val de Sèvres	IG/29/94
3448	1576	Volailles du Velay	\N	IGP -	{"fra": "Volailles du Velay"}	Volailles du Velay	IG/30/94
3424	1552	Volailles d’Alsace	\N	IGP -	{"fra": "Volailles d’Alsace"}	Volailles d’Alsace	IG/02/94
3425	1553	Volailles d’Ancenis	\N	IGP -	{"fra": "Volailles d’Ancenis"}	Volailles d’Ancenis	IG/03/94
3426	1554	Volailles d’Auvergne	\N	IGP -	{"fra": "Volailles d’Auvergne"}	Volailles d’Auvergne	IG/04/94
7726	1169	Volnay	AOC -	AOP -	{"fra": "Volnay"}	Volnay	\N
8749	1206	Volnay premier cru	AOC -	AOP -	{"fra": "Volnay premier cru"}	Volnay premier cru	\N
8750	1170	Volnay premier cru Carelle sous la Chapelle	AOC -	AOP -	{"fra": "Volnay premier cru Carelle sous la Chapelle"}	Volnay premier cru Carelle sous la Chapelle	\N
8751	1172	Volnay premier cru Champans	AOC -	AOP -	{"fra": "Volnay premier cru Champans"}	Volnay premier cru Champans	\N
8752	1175	Volnay premier cru Clos de l'Audignac	AOC -	AOP -	{"fra": "Volnay premier cru Clos de l'Audignac"}	Volnay premier cru Clos de l'Audignac	\N
8753	1176	Volnay premier cru Clos de la Barre	AOC -	AOP -	{"fra": "Volnay premier cru Clos de la Barre"}	Volnay premier cru Clos de la Barre	\N
8754	1177	Volnay premier cru Clos de la Bousse-d'Or	AOC -	AOP -	{"fra": "Volnay premier cru Clos de la Bousse-d'Or"}	Volnay premier cru Clos de la Bousse-d'Or	\N
8755	1178	Volnay premier cru Clos de la Cave des Ducs	AOC -	AOP -	{"fra": "Volnay premier cru Clos de la Cave des Ducs"}	Volnay premier cru Clos de la Cave des Ducs	\N
8756	1179	Volnay premier cru Clos de la Chapelle	AOC -	AOP -	{"fra": "Volnay premier cru Clos de la Chapelle"}	Volnay premier cru Clos de la Chapelle	\N
8757	1180	Volnay premier cru Clos de la Rougeotte	AOC -	AOP -	{"fra": "Volnay premier cru Clos de la Rougeotte"}	Volnay premier cru Clos de la Rougeotte	\N
8758	1197	Volnay premier cru Clos des 60 ouvrées	AOC -	AOP -	{"fra": "Volnay premier cru Clos des 60 ouvrées"}	Volnay premier cru Clos des 60 ouvrées	\N
8759	1181	Volnay premier cru Clos des Chênes	AOC -	AOP -	{"fra": "Volnay premier cru Clos des Chênes"}	Volnay premier cru Clos des Chênes	\N
8760	1182	Volnay premier cru Clos des Ducs	AOC -	AOP -	{"fra": "Volnay premier cru Clos des Ducs"}	Volnay premier cru Clos des Ducs	\N
8761	1183	Volnay premier cru Clos du Château des Ducs	AOC -	AOP -	{"fra": "Volnay premier cru Clos du Château des Ducs"}	Volnay premier cru Clos du Château des Ducs	\N
8762	1184	Volnay premier cru Clos du Verseuil	AOC -	AOP -	{"fra": "Volnay premier cru Clos du Verseuil"}	Volnay premier cru Clos du Verseuil	\N
8763	1185	Volnay premier cru En Chevret	AOC -	AOP -	{"fra": "Volnay premier cru En Chevret"}	Volnay premier cru En Chevret	\N
8764	1187	Volnay premier cru Frémiets	AOC -	AOP -	{"fra": "Volnay premier cru Frémiets"}	Volnay premier cru Frémiets	\N
8765	1188	Volnay premier cru Frémiets - Clos de la Rougeotte	AOC -	AOP -	{"fra": "Volnay premier cru Frémiets - Clos de la Rougeotte"}	Volnay premier cru Frémiets - Clos de la Rougeotte	\N
8766	1189	Volnay premier cru La Gigotte	AOC -	AOP -	{"fra": "Volnay premier cru La Gigotte"}	Volnay premier cru La Gigotte	\N
8767	1190	Volnay premier cru Lassolle	AOC -	AOP -	{"fra": "Volnay premier cru Lassolle"}	Volnay premier cru Lassolle	\N
8768	1191	Volnay premier cru Le Ronceret	AOC -	AOP -	{"fra": "Volnay premier cru Le Ronceret"}	Volnay premier cru Le Ronceret	\N
8769	1192	Volnay premier cru Le Village	AOC -	AOP -	{"fra": "Volnay premier cru Le Village"}	Volnay premier cru Le Village	\N
8770	1193	Volnay premier cru Les Angles	AOC -	AOP -	{"fra": "Volnay premier cru Les Angles"}	Volnay premier cru Les Angles	\N
8771	1195	Volnay premier cru Les Brouillards	AOC -	AOP -	{"fra": "Volnay premier cru Les Brouillards"}	Volnay premier cru Les Brouillards	\N
8772	1196	Volnay premier cru Les Caillerets	AOC -	AOP -	{"fra": "Volnay premier cru Les Caillerets"}	Volnay premier cru Les Caillerets	\N
8773	1199	Volnay premier cru Les Lurets	AOC -	AOP -	{"fra": "Volnay premier cru Les Lurets"}	Volnay premier cru Les Lurets	\N
8774	1200	Volnay premier cru Les Mitans	AOC -	AOP -	{"fra": "Volnay premier cru Les Mitans"}	Volnay premier cru Les Mitans	\N
8775	1201	Volnay premier cru Pitures Dessus	AOC -	AOP -	{"fra": "Volnay premier cru Pitures Dessus"}	Volnay premier cru Pitures Dessus	\N
8776	1203	Volnay premier cru Robardelle	AOC -	AOP -	{"fra": "Volnay premier cru Robardelle"}	Volnay premier cru Robardelle	\N
8777	1204	Volnay premier cru Santenots	AOC -	AOP -	{"fra": "Volnay premier cru Santenots"}	Volnay premier cru Santenots	\N
8778	1205	Volnay premier cru Taille Pieds	AOC -	AOP -	{"fra": "Volnay premier cru Taille Pieds"}	Volnay premier cru Taille Pieds	\N
7728	1207	Vosne-Romanée	AOC -	AOP -	{"fra": "Vosne-Romanée"}	Vosne-Romanée	\N
8873	1222	Vosne-Romanée premier cru	AOC -	AOP -	{"fra": "Vosne-Romanée premier cru"}	Vosne-Romanée premier cru	\N
8874	1208	Vosne-Romanée premier cru Au-dessus des Malconsorts	AOC -	AOP -	{"fra": "Vosne-Romanée premier cru Au-dessus des Malconsorts"}	Vosne-Romanée premier cru Au-dessus des Malconsorts	\N
8875	1209	Vosne-Romanée premier cru Aux Brulées	AOC -	AOP -	{"fra": "Vosne-Romanée premier cru Aux Brulées"}	Vosne-Romanée premier cru Aux Brulées	\N
8876	1210	Vosne-Romanée premier cru Aux Malconsorts	AOC -	AOP -	{"fra": "Vosne-Romanée premier cru Aux Malconsorts"}	Vosne-Romanée premier cru Aux Malconsorts	\N
8877	1211	Vosne-Romanée premier cru Aux Raignots	AOC -	AOP -	{"fra": "Vosne-Romanée premier cru Aux Raignots"}	Vosne-Romanée premier cru Aux Raignots	\N
8878	1213	Vosne-Romanée premier cru Clos des Réas	AOC -	AOP -	{"fra": "Vosne-Romanée premier cru Clos des Réas"}	Vosne-Romanée premier cru Clos des Réas	\N
8879	1212	Vosne-Romanée premier cru Cros Parantoux	AOC -	AOP -	{"fra": "Vosne-Romanée premier cru Cros Parantoux"}	Vosne-Romanée premier cru Cros Parantoux	\N
8880	1214	Vosne-Romanée premier cru En Orveaux	AOC -	AOP -	{"fra": "Vosne-Romanée premier cru En Orveaux"}	Vosne-Romanée premier cru En Orveaux	\N
8881	1215	Vosne-Romanée premier cru La Croix Rameau	AOC -	AOP -	{"fra": "Vosne-Romanée premier cru La Croix Rameau"}	Vosne-Romanée premier cru La Croix Rameau	\N
8882	1216	Vosne-Romanée premier cru Les Beaux Monts	AOC -	AOP -	{"fra": "Vosne-Romanée premier cru Les Beaux Monts"}	Vosne-Romanée premier cru Les Beaux Monts	\N
8883	1217	Vosne-Romanée premier cru Les Chaumes	AOC -	AOP -	{"fra": "Vosne-Romanée premier cru Les Chaumes"}	Vosne-Romanée premier cru Les Chaumes	\N
8884	1218	Vosne-Romanée premier cru Les Gaudichots	AOC -	AOP -	{"fra": "Vosne-Romanée premier cru Les Gaudichots"}	Vosne-Romanée premier cru Les Gaudichots	\N
8885	1219	Vosne-Romanée premier cru Les Petis Monts	AOC -	AOP -	{"fra": "Vosne-Romanée premier cru Les Petis Monts"}	Vosne-Romanée premier cru Les Petis Monts	\N
8886	1220	Vosne-Romanée premier cru Les Rouges	AOC -	AOP -	{"fra": "Vosne-Romanée premier cru Les Rouges"}	Vosne-Romanée premier cru Les Rouges	\N
8887	1221	Vosne-Romanée premier cru Les Suchots	AOC -	AOP -	{"fra": "Vosne-Romanée premier cru Les Suchots"}	Vosne-Romanée premier cru Les Suchots	\N
7684	1223	Vougeot	AOC -	AOP -	{"fra": "Vougeot blanc"}	Vougeot blanc	\N
8392	1223	Vougeot	AOC -	AOP -	{"fra": "Vougeot rouge"}	Vougeot rouge	\N
8382	1228	Vougeot premier cru	AOC -	AOP -	{"fra": "Vougeot premier cru blanc"}	Vougeot premier cru blanc	\N
8391	1228	Vougeot premier cru	AOC -	AOP -	{"fra": "Vougeot premier cru rouge"}	Vougeot premier cru rouge	\N
8383	1224	Vougeot premier cru Clos de la Perrière	AOC -	AOP -	{"fra": "Vougeot premier cru Clos de la Perrière blanc"}	Vougeot premier cru Clos de la Perrière blanc	\N
8384	1224	Vougeot premier cru Clos de la Perrière	AOC -	AOP -	{"fra": "Vougeot premier cru Clos de la Perrière rouge"}	Vougeot premier cru Clos de la Perrière rouge	\N
8385	1225	Vougeot premier cru Le Clos Blanc	AOC -	AOP -	{"fra": "Vougeot premier cru Le Clos Blanc blanc"}	Vougeot premier cru Le Clos Blanc blanc	\N
8386	1225	Vougeot premier cru Le Clos Blanc	AOC -	AOP -	{"fra": "Vougeot premier cru Le Clos Blanc rouge"}	Vougeot premier cru Le Clos Blanc rouge	\N
8387	1226	Vougeot premier cru Les Crâs	AOC -	AOP -	{"fra": "Vougeot premier cru Les Crâs blanc"}	Vougeot premier cru Les Crâs blanc	\N
8388	1226	Vougeot premier cru Les Crâs	AOC -	AOP -	{"fra": "Vougeot premier cru Les Crâs rouge"}	Vougeot premier cru Les Crâs rouge	\N
8389	1227	Vougeot premier cru Les Petits Vougeots	AOC -	AOP -	{"fra": "Vougeot premier cru Les Petits Vougeots blanc"}	Vougeot premier cru Les Petits Vougeots blanc	\N
8390	1227	Vougeot premier cru Les Petits Vougeots	AOC -	AOP -	{"fra": "Vougeot premier cru Les Petits Vougeots rouge"}	Vougeot premier cru Les Petits Vougeots rouge	\N
5259	214	Vouvray	AOC -	AOP -	{"fra": "Vouvray mousseux"}	Vouvray mousseux	\N
5260	214	Vouvray	AOC -	AOP -	{"fra": "Vouvray pétillant"}	Vouvray pétillant	\N
7892	214	Vouvray	AOC -	AOP -	{"fra": "Vouvray"}	Vouvray	\N
13115	2379	Whisky breton ou Whisky de Bretagne	\N	IG - 	{"fra": "Whisky breton ou Whisky de Bretagne"}	Whisky breton ou Whisky de Bretagne	\N
13121	2385	Whisky d'Alsace ou Whisky alsacien	\N	IG - 	{"fra": "Whisky d'Alsace ou Whisky alsacien"}	Whisky d'Alsace ou Whisky alsacien	\N
7815	2190	Yonne	\N	IGP -	{"fra": "Yonne blanc"}	Yonne blanc	\N
8447	2190	Yonne	\N	IGP -	{"fra": "Yonne rosé"}	Yonne rosé	\N
8448	2190	Yonne	\N	IGP -	{"fra": "Yonne rouge"}	Yonne rouge	\N
11448	2190	Yonne	\N	IGP -	{"fra": "Yonne primeur ou nouveau blanc"}	Yonne primeur ou nouveau blanc	\N
11449	2190	Yonne	\N	IGP -	{"fra": "Yonne primeur ou nouveau rosé"}	Yonne primeur ou nouveau rosé	\N
11450	2190	Yonne	\N	IGP -	{"fra": "Yonne primeur ou nouveau rouge"}	Yonne primeur ou nouveau rouge	\N
4140	1675	Œufs de Loué	\N	IGP -	{"fra": "Œufs de Loué"}	Œufs de Loué	IG/19/97
2	1	-------	Vin de France -	VSIG	{"fra": "VSIG rouge"}	VSIG rouge	\N
3	1	-------	Vin de France -	VSIG	{"fra": "VSIG blanc"}	VSIG blanc	\N
4	1	-------	Vin de France -	VSIG	{"fra": "VSIG rosé"}	VSIG rosé	\N
\.


--
-- PostgreSQL database dump complete
--

