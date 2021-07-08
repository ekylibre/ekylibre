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
-- Data for Name: master_crop_productions; Type: TABLE DATA; Schema: lexicon__5_0_0; Owner: lexicon
--

COPY lexicon__5_0_0.master_crop_productions (reference_name, specie, usage, started_on, stopped_on, agroedi_crop_code, season, life_duration, translation_id) FROM stdin;
alfalfa	medicago_sativa	fodder	2000-02-01	2001-01-31	ZCQ	\N	\N	crop_productions_alfalfa
angelica	angelica	plant	2000-11-01	2001-08-31	E21	\N	\N	crop_productions_angelica
anise	pimpinella_anisum	grain	2000-04-01	2000-09-30	E22	\N	\N	crop_productions_anise
annual_fruit	plant	fruit	2000-10-01	2001-08-31	J01	\N	\N	crop_productions_annual_fruit
annual_ornamental_plant_and_mapp	plant	plant	2000-10-01	2001-08-31	\N	\N	\N	crop_productions_annual_ornamental_plant_and_mapp
annual_vegetable	plant	vegetable	2000-10-01	2001-08-31	J01	\N	\N	crop_productions_annual_vegetable
apple	malus_domestica	fruit	2000-03-01	2000-06-30	G21	\N	\N	crop_productions_apple
apricot	prunus_armeniaca	fruit	2000-11-01	2001-08-31	E01	\N	\N	crop_productions_apricot
artichoke	cynara_scolymus	vegetable	2000-03-01	2000-10-31	ZAJ	\N	\N	crop_productions_artichoke
asparagus	asparagus_officianalis	vegetable	2000-03-01	2000-10-31	ZAK	\N	\N	crop_productions_asparagus
avocado	persea_americana	fruit	2000-10-01	2001-08-31	E27	\N	\N	crop_productions_avocado
banana	musa	fruit	2000-10-01	2001-08-31	E34	\N	\N	crop_productions_banana
basil	ocimum_basilicum	plant	2000-03-01	2000-10-31	E36	\N	\N	crop_productions_basil
batavia	lactuca_sativa_capitata	vegetable	2000-04-01	2000-10-31	ZCJ	\N	\N	crop_productions_batavia
beetroot	beta_vulgaris_vulgaris	vegetable	2000-04-01	2000-10-31	ZAP	\N	\N	crop_productions_beetroot
bilberry	vaccinium	fruit	2000-08-01	2001-07-31	F79	\N	\N	crop_productions_bilberry
birds_foot	ornithopus_sativus	fodder	2000-10-01	2001-08-31	ZEK	\N	\N	crop_productions_birds_foot
birds_foot_trefoil	lotus_corniculatus	fodder	2000-03-01	2000-08-31	H68	\N	\N	crop_productions_birds_foot_trefoil
black_elderberry	sambucus_nigra	flower	2000-06-01	2001-05-31	G58	\N	\N	crop_productions_black_elderberry
black_eyed_pea	vigna_unguiculata_unguiculata	grain	2000-10-01	2001-08-31	\N	\N	\N	crop_productions_black_eyed_pea
black_medick	medicago_lupulina	fodder	2000-08-01	2001-01-31	ZCY	\N	\N	crop_productions_black_medick
black_psyllium	plantago_afra	grain	2000-10-01	2001-08-31	G17	\N	\N	crop_productions_black_psyllium
blackberry	rubus	fruit	2000-08-01	2001-07-31	F73	\N	\N	crop_productions_blackberry
blackcurrant	ribes_nigrum	fruit	2000-03-01	2000-11-30	ZAW	\N	\N	crop_productions_blackcurrant
blond_psyllium	plantago_ovata	grain	2000-10-01	2001-08-31	F36	\N	\N	crop_productions_blond_psyllium
borage	borago	flower	2000-10-01	2001-08-31	E40	\N	\N	crop_productions_borage
border	plant	\N	2000-10-01	2001-08-31	\N	\N	\N	crop_productions_border
broad_bean	vicia_faba	grain	2000-10-01	2001-05-31	ZBS	\N	\N	crop_productions_broad_bean
broccoli	brassica_oleracea_italica	vegetable	2000-06-01	2000-10-30	ZBB	\N	\N	crop_productions_broccoli
bromus	bromus	fodder	2000-10-01	2001-08-31	ZAT	\N	\N	crop_productions_bromus
brussels_sprout	brassica_oleracea_gemmifera	vegetable	2000-04-01	2000-10-31	ZBB	\N	\N	crop_productions_brussels_sprout
buckwheat	fagopyrum_esculentum	grain	2000-05-01	2000-10-30	ZEH	\N	\N	crop_productions_buckwheat
bugle	ajuga_reptans	plant	2000-10-01	2001-08-31	E52	\N	\N	crop_productions_bugle
burdock	arctium	plant	2000-03-01	2000-08-31	E35	\N	\N	crop_productions_burdock
butternut_squash	cucurbita_moschata	vegetable	2000-08-01	2000-10-31	E90	\N	\N	crop_productions_butternut_squash
cabbage	brassica_oleracea	vegetable	2000-05-01	2001-01-31	ZBB	\N	\N	crop_productions_cabbage
camelina	camelina_sativa	grain	2000-10-01	2001-08-31	E54	\N	\N	crop_productions_camelina
caraway	carum_carvi	grain	2000-10-01	2001-08-31	E59	\N	\N	crop_productions_caraway
carob	ceratonia_siliqua	fruit	2000-10-01	2001-08-31	E57	\N	\N	crop_productions_carob
carrot	daucus_carota	vegetable	2000-03-01	2001-06-30	ZAV	\N	\N	crop_productions_carrot
cassava	manihot_esculenta	vegetable	2000-04-01	2000-11-30	I33	\N	\N	crop_productions_cassava
castor_bean	ricinus_communis	grain	2000-04-01	2000-10-31	ZOF	\N	\N	crop_productions_castor_bean
catjang	vigna_unguiculata_cylindrica	grain	2000-10-01	2001-08-31	\N	\N	\N	crop_productions_catjang
cauliflower	brassica_oleracea_botrytis	vegetable	2000-04-01	2001-03-31	ZBB	\N	\N	crop_productions_cauliflower
celeriac	apium_graveolens_rapaceum	vegetable	2000-03-01	2000-11-30	ZAX	\N	\N	crop_productions_celeriac
celery	apium_graveolens_dulce	vegetable	2000-03-01	2000-11-28	ZAX	\N	\N	crop_productions_celery
cereal	plant	grain	2000-10-01	2001-08-31	T90	\N	\N	crop_productions_cereal
cereal_mix	plant	grain	2000-10-01	2001-07-31	\N	\N	\N	crop_productions_cereal_mix
chamomile	chamaemelum	flower	2000-02-01	2000-11-30	E55	\N	\N	crop_productions_chamomile
chard	beta_vulgaris_cicla	vegetable	2000-05-01	2000-09-30	\N	\N	\N	crop_productions_chard
cherry	prunus_cerasus	fruit	2000-03-01	2000-11-28	E67	\N	\N	crop_productions_cherry
cherry_laurel	prunus_laurocerasus	\N	2000-04-01	2000-10-31	I51	\N	\N	crop_productions_cherry_laurel
chervil	anthriscus_cerefolium	plant	2000-10-01	2001-08-31	ZAY	\N	\N	crop_productions_chervil
chesnut	castanea	fruit	2000-05-01	2000-09-30	E69	\N	\N	crop_productions_chesnut
chickpea	cicer_arietinum	grain	2000-03-01	2000-08-31	ZOD	\N	\N	crop_productions_chickpea
chili	capsicum	vegetable	2000-05-01	2000-07-31	G11	\N	\N	crop_productions_chili
chive	allium_schoenoprasum	plant	2000-04-01	2000-11-30	E82	\N	\N	crop_productions_chive
citrus	rutaceae	fruit	2000-11-01	2001-10-31	\N	\N	\N	crop_productions_citrus
clementine	citrus_clementina	fruit	2000-03-01	2001-02-28	E85	\N	\N	crop_productions_clementine
clover	trifolium	fodder	2000-04-01	2000-10-31	ZMF	\N	\N	crop_productions_clover
cocksfoot	dactylis	fodder	2000-04-01	2000-09-30	ZBJ	\N	\N	crop_productions_cocksfoot
cocoa	theobroma_cacao	fruit	2000-10-01	2001-08-31	\N	\N	\N	crop_productions_cocoa
coffee	coffea	grain	2000-10-01	2001-08-31	\N	\N	\N	crop_productions_coffee
common_daisy	bellis_perennis	flower	2000-05-01	2001-04-30	\N	\N	\N	crop_productions_common_daisy
common_vetch	vicia_sativa	fodder	2000-03-01	2000-10-31	ZMK	\N	\N	crop_productions_common_vetch
coriander	coriandrum_sativum	grain	2000-04-01	2000-10-31	E88	\N	\N	crop_productions_coriander
cornflower	centaurea_cyanus	flower	2000-10-01	2001-08-31	E62	\N	\N	crop_productions_cornflower
cornsalad	valerianella_locusta	vegetable	2000-05-01	2001-03-31	ZCR	\N	\N	crop_productions_cornsalad
cotton	gossypium	plant	2000-04-01	2000-10-31	E89	\N	\N	crop_productions_cotton
cranberry	vaccinium	fruit	2000-11-01	2001-10-31	\N	\N	\N	crop_productions_cranberry
cress	lepidium_sativum	vegetable	2000-10-01	2001-08-31	E92	\N	\N	crop_productions_cress
crop_production	plant	plant	2000-01-01	2000-12-31	\N	\N	\N	crop_productions_crop_production
cucumber	cucumis_sativus	vegetable	2000-04-01	2000-10-31	ZBF	\N	\N	crop_productions_cucumber
cumin	cuminum	grain	2000-10-01	2001-08-31	E96	\N	\N	crop_productions_cumin
curly_endive	cichorium_endivia_crispum	vegetable	2000-07-01	2001-01-31	ZBA	\N	\N	crop_productions_curly_endive
dehydrated_alfalfa	medicago_sativa	fodder	2000-09-01	2001-10-31	ZCQ	\N	\N	crop_productions_dehydrated_alfalfa
dehydrated_birds_foot	ornithopus_sativus	fodder	2000-03-01	2000-09-30	ZEK	\N	\N	crop_productions_dehydrated_birds_foot
dehydrated_clover	trifolium	fodder	2000-04-01	2000-10-31	ZMF	\N	\N	crop_productions_dehydrated_clover
dehydrated_common_vetch	vicia_sativa	fodder	2000-10-01	2001-07-31	ZMK	\N	\N	crop_productions_dehydrated_common_vetch
dehydrated_melilot	melilotus	fodder	2000-06-01	2000-11-30	ZCV	\N	\N	crop_productions_dehydrated_melilot
dehydrated_sainfoin	onobrychis_viciifolia	fodder	2000-03-01	2001-02-28	ZEC	\N	\N	crop_productions_dehydrated_sainfoin
dehydrated_tufted_vetch	vicia_cracca	fodder	2000-10-01	2001-08-31	\N	\N	\N	crop_productions_dehydrated_tufted_vetch
dill	anethum_graveolens	plant	2000-04-01	2000-09-30	E20	\N	\N	crop_productions_dill
dried_bean	phaseolus_vulgaris	vegetable	2000-04-01	2000-10-31	ZCA	\N	\N	crop_productions_dried_bean
dried_lentil	lens_culinaris	grain	2000-05-01	2000-09-30	ZCK	\N	\N	crop_productions_dried_lentil
dried_pea	pisum_sativum	grain	2000-02-01	2000-07-31	ZDO	\N	\N	crop_productions_dried_pea
early_turnip	brassica_rapa_rapa	vegetable	2000-03-01	2000-06-30	ZDD	\N	\N	crop_productions_early_turnip
eggplant	solanum_melongena	vegetable	2000-03-01	2000-10-31	ZAL	\N	\N	crop_productions_eggplant
escarole	cichorium_endivia_latifolium	vegetable	2000-07-01	2001-01-31	ZBA	\N	\N	crop_productions_escarole
eucalyptus	eucalyptus	plant	2000-04-01	2000-08-31	I20	\N	\N	crop_productions_eucalyptus
fagopoyrum_cereal	fagopyrum	grain	2000-10-01	2001-08-31	T90	\N	\N	crop_productions_fagopoyrum_cereal
fallow	plant	\N	2000-10-01	2001-08-31	ZCF	\N	\N	crop_productions_fallow
fennel	foeniculum_vulgare	vegetable	2000-04-01	2000-08-31	ZBO	\N	\N	crop_productions_fennel
fenugreek	trigonella_foenum_graecum	grain	2000-10-01	2001-08-31	F12	\N	\N	crop_productions_fenugreek
fescue	festuca	fodder	2000-10-01	2001-08-31	ZBR	\N	\N	crop_productions_fescue
festulolium	x_festulolium	fodder	2000-04-01	2000-11-30	ZBP	\N	\N	crop_productions_festulolium
fiber_flax	linum_usitatissimum	plant	2000-03-01	2000-08-31	ZCL	\N	\N	crop_productions_fiber_flax
fig	ficus_carica	fruit	2000-02-01	2000-09-30	F17	\N	\N	crop_productions_fig
flageolet_bean	phaseolus_vulgaris	vegetable	2000-04-01	2000-10-31	ZCA	\N	\N	crop_productions_flageolet_bean
fodder_beetroot	beta_vulgaris_vulgaris	fodder	2000-03-01	2000-10-31	ZAP	\N	\N	crop_productions_fodder_beetroot
fodder_cabbage	brassica_oleracea	fodder	2000-05-01	2001-01-31	ZBB	\N	\N	crop_productions_fodder_cabbage
fodder_carrot	daucus_carota	fodder	2000-03-01	2000-11-30	ZAV	\N	\N	crop_productions_fodder_carrot
fodder_lentil	lens_culinaris	fodder	2000-07-01	2000-10-31	ZCK	\N	\N	crop_productions_fodder_lentil
fodder_radish	raphanus_sativus	fodder	2000-09-01	2001-02-28	ZDV	\N	\N	crop_productions_fodder_radish
fodder_specie	plant	fodder	2000-10-01	2001-08-31	J07	\N	\N	crop_productions_fodder_specie
fodder_species_mix	plant	fodder	2000-10-01	2001-08-31	\N	\N	\N	crop_productions_fodder_species_mix
fodder_turnip	brassica_rapa_rapa	fodder	2000-08-01	2001-03-31	ZDD	\N	\N	crop_productions_fodder_turnip
foxtail_millet	setaria_italica	grain	2000-06-01	2000-08-31	ZCZ	\N	\N	crop_productions_foxtail_millet
fresh_lentil	lens_culinaris	grain	2000-03-01	2000-08-31	ZCK	\N	\N	crop_productions_fresh_lentil
galium	galium	plant	2000-10-01	2001-08-31	F21	\N	\N	crop_productions_galium
garlic	allium_sativum	vegetable	2000-11-01	2001-08-31	ZAG	\N	\N	crop_productions_garlic
geranium	geranium	flower	2000-10-01	2001-08-31	\N	\N	\N	crop_productions_geranium
giant_granadilla	passiflora_quadrangularis	fruit	2000-04-01	2001-03-31	\N	\N	\N	crop_productions_giant_granadilla
grain_corn	zea_mays	grain	2000-04-01	2000-11-30	ZCS	\N	\N	crop_productions_grain_corn
grapefruit	citrus_maxima	fruit	2000-03-01	2000-12-31	F93	\N	\N	crop_productions_grapefruit
green_bean	phaseolus_vulgaris	vegetable	2000-04-01	2001-08-31	ZCA	\N	\N	crop_productions_green_bean
guava	psidium_guajava	fruit	2000-04-01	2001-03-31	F27	\N	\N	crop_productions_guava
hazelnut	corylus	fruit	2000-03-01	2000-06-30	F83	\N	\N	crop_productions_hazelnut
helianthus_oleaginous	helianthus	grain	2000-10-01	2001-08-31	\N	\N	\N	crop_productions_helianthus_oleaginous
hemp	cannabis_sativa	plant	2000-05-01	2000-09-30	ZAZ	\N	\N	crop_productions_hemp
hop	humulus_lupulus	flower	2000-03-01	2000-09-30	ZCC	\N	\N	crop_productions_hop
interrow	plant	\N	2000-10-01	2001-08-31	\N	\N	\N	crop_productions_interrow
jerusalem_artichoke	helianthus_tuberosus	vegetable	2000-03-01	2000-11-30	G64	\N	\N	crop_productions_jerusalem_artichoke
kiwi	actinidia	fruit	2000-12-01	2001-11-30	F42	\N	\N	crop_productions_kiwi
kohlrabi	brassica_oleracea_gongylodes	vegetable	2000-03-01	2000-11-30	ZBB	\N	\N	crop_productions_kohlrabi
lavandin	lavandula_x_intermedia	flower	2000-04-01	2000-10-31	F47	\N	\N	crop_productions_lavandin
lavender	lavandula	flower	2000-04-01	2000-10-31	F47	\N	\N	crop_productions_lavender
leek	allium_porrum	vegetable	2000-01-01	2000-12-31	ZDN	\N	\N	crop_productions_leek
leguminous_mix	fabaceae	fodder	2000-10-01	2001-08-31	\N	\N	\N	crop_productions_leguminous_mix
lemon	citrus_x_limon	fruit	2000-04-01	2000-11-30	E83	\N	\N	crop_productions_lemon
lemon_balm	melissa_officinalis	plant	2000-05-01	2000-10-31	F65	\N	\N	crop_productions_lemon_balm
lettuce	lactuca_sativa	vegetable	2000-04-01	2000-10-31	ZCJ	\N	\N	crop_productions_lettuce
longan	dimocarpus_longan	fruit	2000-09-01	2001-08-31	\N	\N	\N	crop_productions_longan
mallow	malva	flower	2000-03-01	2000-09-30	F60	\N	\N	crop_productions_mallow
mandarin	citrus_reticulata	fruit	2000-12-01	2001-11-30	F54	\N	\N	crop_productions_mandarin
marian_thistle	silybum_marianum	plant	2000-10-01	2001-08-31	E68	\N	\N	crop_productions_marian_thistle
marjoram	origanum_majorana	plant	2000-05-01	2000-09-30	F56	\N	\N	crop_productions_marjoram
meadow	plant	meadow	2000-04-01	2000-09-30	J07	\N	\N	crop_productions_meadow
melilot	melilotus	fodder	2000-06-01	2000-11-30	ZCV	\N	\N	crop_productions_melilot
melon	cucumis_melo	fruit	2000-03-01	2000-08-31	ZCW	\N	\N	crop_productions_melon
millet	panicum_miliaceum	grain	2000-05-01	2000-10-31	ZNG	\N	\N	crop_productions_millet
mint	mentha	plant	2000-03-01	2001-02-28	F66	\N	\N	crop_productions_mint
miscanthus	miscanthus	plant	2000-03-01	2000-08-31	F69	\N	\N	crop_productions_miscanthus
mulberry	morus	fruit	2000-08-01	2001-07-31	F72	\N	\N	crop_productions_mulberry
mustard	brassica_nigra	grain	2000-03-01	2000-08-31	ZDC	\N	\N	crop_productions_mustard
napa_cabbage	brassica_rapa_pekinensis	vegetable	2000-06-01	2000-08-31	ZNP	\N	\N	crop_productions_napa_cabbage
nectarine	prunus_persica_nucipersica	fruit	2000-09-01	2001-08-31	\N	\N	\N	crop_productions_nectarine
nettle	urtica	plant	2000-09-01	2001-05-31	F90	\N	\N	crop_productions_nettle
nursery	plant	seed	2000-01-01	2000-12-31	\N	\N	\N	crop_productions_nursery
nyger	guizotia_abyssinica	grain	2000-07-01	2000-12-31	\N	\N	\N	crop_productions_nyger
oak	quercus	meadow	2000-05-01	2000-09-30	I14	\N	\N	crop_productions_oak
oakleaf	lactuca_sativa_crispa	vegetable	2000-04-01	2000-10-31	ZCJ	\N	\N	crop_productions_oakleaf
oleaginous	plant	grain	2000-10-01	2001-08-31	\N	\N	\N	crop_productions_oleaginous
oleaginous_mix	plant	grain	2000-01-01	2000-12-31	\N	\N	\N	crop_productions_oleaginous_mix
olive	olea_europaea	fruit	2000-02-01	2000-09-30	F86	\N	\N	crop_productions_olive
onion	allium_cepa	vegetable	2000-02-01	2000-09-30	ZDG	\N	\N	crop_productions_onion
opium_poppy	papaver_somniferum	grain	2000-03-01	2000-08-31	ZDF	\N	\N	crop_productions_opium_poppy
orange	citrus_sinensis	fruit	2000-02-01	2000-09-30	F88	\N	\N	crop_productions_orange
orchard	plant	fruit	2000-10-01	2001-08-31	J01	\N	\N	crop_productions_orchard
oregano	origanum_vulgare	plant	2000-03-01	2000-10-31	F89	\N	\N	crop_productions_oregano
oxeye_daisy	leucanthemum	flower	2000-05-01	2001-04-30	\N	\N	\N	crop_productions_oxeye_daisy
panicum_cereal	panicum	grain	2000-10-01	2001-08-31	T90	\N	\N	crop_productions_panicum_cereal
pansy	viola	flower	2000-06-01	2000-11-30	G08	\N	\N	crop_productions_pansy
parsley	petroselinum_crispum	plant	2000-04-01	2001-03-31	ZDK	\N	\N	crop_productions_parsley
parsnip	pastinaca_sativa	vegetable	2000-03-01	2000-12-31	F94	\N	\N	crop_productions_parsnip
pea	pisum_sativum	grain	2000-02-01	2000-07-31	ZDO	\N	\N	crop_productions_pea
peach	prunus_persica	fruit	2000-03-01	2000-09-30	G07	\N	\N	crop_productions_peach
peanut	arachis_hypogaea	fruit	2000-11-01	2001-08-31	\N	\N	\N	crop_productions_peanut
pear	pyrus_communis	fruit	2000-05-01	2000-07-31	G20	\N	\N	crop_productions_pear
pepper	capsicum_annuum	vegetable	2000-05-01	2000-07-31	\N	\N	\N	crop_productions_pepper
perennial_vegetable	plant	vegetable	2000-10-01	2001-08-31	J01	\N	\N	crop_productions_perennial_vegetable
perrenial_ornamental_plant_and_mapp	plant	plant	2000-10-01	2001-08-31	\N	\N	\N	crop_productions_perrenial_ornamental_plant_and_mapp
persimmon	diospyros_kaki	fruit	2000-04-01	2001-03-31	F40	\N	\N	crop_productions_persimmon
phacelia	phacelia	meadow	2000-04-01	2000-10-31	ZDL	\N	\N	crop_productions_phacelia
phalaris_cereal	phalaris	grain	2000-10-01	2001-08-31	T90	\N	\N	crop_productions_phalaris_cereal
pickle	cucumis_sativus	vegetable	2000-04-01	2000-10-31	ZBH	\N	\N	crop_productions_pickle
pineapple	ananas_comosus	fruit	2000-11-01	2001-08-31	E17	\N	\N	crop_productions_pineapple
pistachio	pistacia_vera	fruit	2000-10-01	2001-09-30	G14	\N	\N	crop_productions_pistachio
plum	prunus_domestica	fruit	2000-04-01	2000-11-30	G28	\N	\N	crop_productions_plum
potato	solanum_tuberosum	vegetable	2000-04-01	2000-10-31	ZDS	\N	\N	crop_productions_potato
primrose	primula	flower	2000-05-01	2001-04-30	G26	\N	\N	crop_productions_primrose
proteaginous	fabaceae	grain	2000-10-01	2001-08-31	\N	\N	\N	crop_productions_proteaginous
proteaginous_mix	fabaceae	grain	2000-10-01	2001-07-31	\N	\N	\N	crop_productions_proteaginous_mix
pumpkin	cucurbita_pepo_pepo	vegetable	2000-04-01	2000-10-31	\N	\N	\N	crop_productions_pumpkin
purslane	portulaca_oleracea	plant	2000-06-01	2001-08-31	G24	\N	\N	crop_productions_purslane
quince	cydonia_oblonga	fruit	2000-04-01	2000-10-31	E86	\N	\N	crop_productions_quince
quinoa	chenopodium_quinoa	grain	2000-04-01	2000-11-30	J57	\N	\N	crop_productions_quinoa
radish	raphanus_sativus	vegetable	2000-03-01	2000-09-30	ZDV	\N	\N	crop_productions_radish
raspberry	rubus_idaeus	fruit	2000-03-01	2000-10-31	ZBW	\N	\N	crop_productions_raspberry
red_kuri	cucurbita_maxima	vegetable	2000-04-01	2000-11-30	\N	\N	\N	crop_productions_red_kuri
redcurrant	ribes	fruit	2000-03-01	2000-10-31	ZBZ	\N	\N	crop_productions_redcurrant
rhubarb	rheum_rhabarbarum	vegetable	2000-10-01	2001-09-30	ZOE	\N	\N	crop_productions_rhubarb
rice	oryza_sativa	grain	2000-03-01	2000-10-30	ZEA	\N	\N	crop_productions_rice
rocket	eruca_vesicaria	vegetable	2000-09-01	2001-06-30	G41	\N	\N	crop_productions_rocket
root_chicory	cichorium_intybus_sativum	vegetable	2000-04-01	2000-11-30	ZBA	\N	\N	crop_productions_root_chicory
rosemary	salvia_rosmarinus	plant	2000-04-01	2001-03-31	G40	\N	\N	crop_productions_rosemary
rough_bluegrass	poa_trivialis	fodder	2000-01-01	2000-03-31	ZDJ	\N	\N	crop_productions_rough_bluegrass
rutabaga	brassica_napus_rapifera	vegetable	2000-05-01	2001-02-28	ZEB	\N	\N	crop_productions_rutabaga
ryegrass	lolium	fodder	2000-09-01	2001-06-30	ZDX	\N	\N	crop_productions_ryegrass
sage	salvia	plant	2000-04-01	2000-08-31	G49	\N	\N	crop_productions_sage
sainfoin	onobrychis_viciifolia	fodder	2000-10-01	2001-08-31	ZEC	\N	\N	crop_productions_sainfoin
salsify	tragopogon_porrifolius	vegetable	2000-04-01	2001-02-28	ZED	\N	\N	crop_productions_salsify
savory	satureja	plant	2000-03-01	2000-09-30	G48	\N	\N	crop_productions_savory
setaria_cereal	setaria	grain	2000-10-01	2001-08-31	T90	\N	\N	crop_productions_setaria_cereal
shallot	allium_cepa_aggregatum	vegetable	2000-02-01	2000-08-31	ZBK	\N	\N	crop_productions_shallot
silage_corn	zea_mays	fodder	2000-04-01	2000-11-30	ZCS	\N	\N	crop_productions_silage_corn
sorghum	sorghum	grain	2000-05-01	2000-10-31	ZNE	\N	\N	crop_productions_sorghum
sorghum_cereal	sorghum	grain	2000-10-01	2001-08-31	T90	\N	\N	crop_productions_sorghum_cereal
sorrel	rumex	plant	2000-04-01	2001-03-31	F91	\N	\N	crop_productions_sorrel
soy	glycine_max	grain	2000-05-01	2000-10-31	ZEL	\N	\N	crop_productions_soy
speedwell	veronica	plant	2000-04-01	2001-03-31	G74	\N	\N	crop_productions_speedwell
spelt	triticum_spelta	grain	2000-10-01	2001-08-31	ZBM	\N	\N	crop_productions_spelt
spring_avena_cereal	avena	grain	2000-03-01	2000-08-31	T90	spring	\N	crop_productions_spring_avena_cereal
spring_barley	hordeum_vulgare	grain	2000-01-01	2000-07-31	ZDH	spring	\N	crop_productions_spring_barley
spring_brassica_napus_oleaginous	brassica_napus	grain	2000-10-01	2001-08-31	\N	spring	\N	crop_productions_spring_brassica_napus_oleaginous
spring_brassica_rapa_oleaginous	brassica_rapa	grain	2000-10-01	2001-08-31	\N	spring	\N	crop_productions_spring_brassica_rapa_oleaginous
spring_common_wheat	triticum_aestivum	grain	2000-03-01	2000-08-31	ZAR	spring	\N	crop_productions_spring_common_wheat
spring_field_bean	vicia_faba	grain	2000-02-01	2000-08-31	ZBT	spring	\N	crop_productions_spring_field_bean
spring_flax	linum_usitatissimum	grain	2000-03-01	2000-08-31	ZCL	spring	\N	crop_productions_spring_flax
spring_fodder_field_bean	vicia_faba	fodder	2000-02-01	2000-09-30	ZBT	spring	\N	crop_productions_spring_fodder_field_bean
spring_fodder_lupin	lupinus	fodder	2000-03-01	2000-09-30	ZCN	spring	\N	crop_productions_spring_fodder_lupin
spring_fodder_pea	pisum_sativum	fodder	2000-02-01	2000-09-30	ZDO	spring	\N	crop_productions_spring_fodder_pea
spring_hard_wheat	triticum_durum	grain	2000-03-01	2000-08-31	ZAQ	spring	\N	crop_productions_spring_hard_wheat
spring_hordeum_cereal	hordeum	grain	2000-03-01	2000-08-31	T90	spring	\N	crop_productions_spring_hordeum_cereal
spring_oat	avena_sativa	grain	2000-03-01	2000-08-31	ZAM	spring	\N	crop_productions_spring_oat
spring_proteaginous_pea	pisum_sativum	fodder	2000-02-01	2000-07-31	ZDO	spring	\N	crop_productions_spring_proteaginous_pea
spring_rape	brassica_napus_napus	grain	2000-03-01	2000-07-31	ZBE	spring	\N	crop_productions_spring_rape
spring_rye	secale_cereale	grain	2000-03-01	2000-07-31	ZEJ	spring	\N	crop_productions_spring_rye
spring_secale_cereal	secale	grain	2000-03-01	2000-08-31	T90	spring	\N	crop_productions_spring_secale_cereal
spring_spinach	spinacia_oleracea	vegetable	2000-02-01	2000-05-31	ZBN	spring	\N	crop_productions_spring_spinach
spring_sweet_lupin	lupinus	grain	2000-02-01	2000-09-30	ZCN	spring	\N	crop_productions_spring_sweet_lupin
spring_triticale	x_triticosecale	grain	2000-03-01	2000-07-31	ZMI	spring	\N	crop_productions_spring_triticale
spring_triticum_cereal	triticum	grain	2000-03-01	2000-08-31	T90	spring	\N	crop_productions_spring_triticum_cereal
spring_zea_cereal	zea	grain	2000-03-01	2000-08-31	T90	spring	\N	crop_productions_spring_zea_cereal
squash	cucurbita_moschata	vegetable	2000-05-01	2000-11-30	E90	\N	\N	crop_productions_squash
st_johns_wort	hypericum	flower	2000-04-01	2000-10-31	ZCX	\N	\N	crop_productions_st_johns_wort
strawberry	fragaria	fruit	2000-03-01	2000-10-31	ZBV	\N	\N	crop_productions_strawberry
sugar_cane	saccharum_officinarum	plant	2000-02-01	2000-11-30	I05	\N	\N	crop_productions_sugar_cane
sugar_pumpkin	cucurbita_maxima	vegetable	2000-04-01	2000-11-30	G23	\N	\N	crop_productions_sugar_pumpkin
summer_field_mustard	brassica_rapa_oleifera	grain	2000-04-01	2000-10-31	ZDE	summer	\N	crop_productions_summer_field_mustard
sunflower	helianthus_annuus	grain	2000-03-01	2000-10-31	ZMB	\N	\N	crop_productions_sunflower
sweet_corn	zea_mays_saccharata	grain	2000-04-01	2000-11-30	ZCS	\N	\N	crop_productions_sweet_corn
sweet_patato	ipomoea_batatas	vegetable	2000-03-01	2000-09-30	F98	\N	\N	crop_productions_sweet_patato
tarragon	artemisia_dracunculus	plant	2000-05-01	2000-09-30	F08	\N	\N	crop_productions_tarragon
thyme	thymus	plant	2000-04-01	2001-03-31	G62	\N	\N	crop_productions_thyme
timothy	phleum	fodder	2000-10-01	2001-08-31	ZBU	\N	\N	crop_productions_timothy
tobacco	nicotiana_tabacum	plant	2000-03-01	2000-07-31	ZEN	\N	\N	crop_productions_tobacco
tomato	solanum_lycopersicum	vegetable	2000-04-01	2000-10-31	ZMA	\N	\N	crop_productions_tomato
tufted_vetch	vicia_cracca	fodder	2000-10-01	2001-08-31	T92	\N	\N	crop_productions_tufted_vetch
turmeric	curcuma_longa	plant	2000-10-01	2001-08-31	\N	\N	\N	crop_productions_turmeric
valerian	valeriana	plant	2000-04-01	2001-03-31	ZMJ	\N	\N	crop_productions_valerian
vanilla	vanilla	fruit	2000-01-01	2000-12-31	G73	\N	\N	crop_productions_vanilla
vetiver	chrysopogon	plant	2000-04-01	2000-11-30	\N	\N	\N	crop_productions_vetiver
vine	vitis	fruit	2000-11-01	2001-10-31	ZMO	\N	70 years	crop_productions_vine
walnut	juglans	fruit	2000-03-01	2000-06-30	F84	\N	\N	crop_productions_walnut
watercress	nasturtium_officinale	vegetable	2000-03-01	2000-08-31	E94	\N	\N	crop_productions_watercress
watermelon	citrullus_lanatus	fruit	2000-03-01	2000-09-30	ZND	\N	\N	crop_productions_watermelon
white_cabbage	brassica_oleracea_capitata	vegetable	2000-06-01	2001-02-28	ZBB	\N	\N	crop_productions_white_cabbage
winter_avena_cereal	avena	grain	2000-10-01	2001-08-31	T90	winter	\N	crop_productions_winter_avena_cereal
winter_barley	hordeum_vulgare	grain	2000-09-01	2001-07-31	ZDH	winter	\N	crop_productions_winter_barley
winter_brassica_napus_oleaginous	brassica_napus	grain	2000-10-01	2001-08-31	\N	winter	\N	crop_productions_winter_brassica_napus_oleaginous
winter_brassica_rapa_oleaginous	brassica_rapa	grain	2000-10-01	2001-08-31	\N	winter	\N	crop_productions_winter_brassica_rapa_oleaginous
winter_common_wheat	triticum_aestivum	grain	2000-10-01	2001-08-31	ZAR	winter	\N	crop_productions_winter_common_wheat
winter_field_bean	vicia_faba	grain	2000-10-01	2001-08-31	ZBT	winter	\N	crop_productions_winter_field_bean
winter_field_mustard	brassica_rapa_oleifera	grain	2000-07-01	2000-12-31	ZDE	winter	\N	crop_productions_winter_field_mustard
winter_flax	linum_usitatissimum	grain	2000-03-01	2000-08-31	ZCL	winter	\N	crop_productions_winter_flax
winter_fodder_field_bean	vicia_faba	fodder	2000-11-01	2001-09-30	ZBT	winter	\N	crop_productions_winter_fodder_field_bean
winter_fodder_lupin	lupinus	fodder	2000-10-01	2001-09-30	ZCN	winter	\N	crop_productions_winter_fodder_lupin
winter_fodder_pea	pisum_sativum	fodder	2000-11-01	2001-08-31	ZDO	winter	\N	crop_productions_winter_fodder_pea
winter_hard_wheat	triticum_durum	grain	2000-10-01	2001-08-31	ZAQ	winter	\N	crop_productions_winter_hard_wheat
winter_hordeum_cereal	hordeum	grain	2000-10-01	2001-08-31	T90	winter	\N	crop_productions_winter_hordeum_cereal
winter_oat	avena_sativa	grain	2000-10-01	2001-08-31	ZAM	winter	\N	crop_productions_winter_oat
winter_proteaginous_pea	pisum_sativum	fodder	2000-11-01	2001-07-31	ZDO	winter	\N	crop_productions_winter_proteaginous_pea
winter_rape	brassica_napus_napus	grain	2000-08-01	2001-07-31	ZBE	winter	\N	crop_productions_winter_rape
winter_rye	secale_cereale	grain	2000-09-01	2001-07-31	ZEJ	winter	\N	crop_productions_winter_rye
winter_secale_cereal	secale	grain	2000-10-01	2001-08-31	T90	winter	\N	crop_productions_winter_secale_cereal
winter_spinach	spinacia_oleracea	vegetable	2000-06-01	2001-04-30	ZBN	winter	\N	crop_productions_winter_spinach
winter_sweet_lupin	lupinus	grain	2000-09-01	2001-08-31	ZCN	winter	\N	crop_productions_winter_sweet_lupin
winter_triticale	x_triticosecale	grain	2000-09-01	2001-07-31	ZMI	winter	\N	crop_productions_winter_triticale
winter_triticum_cereal	triticum	grain	2000-10-01	2001-08-31	T90	winter	\N	crop_productions_winter_triticum_cereal
winter_turnip	brassica_rapa_rapa	vegetable	2000-07-01	2001-02-28	ZDD	winter	\N	crop_productions_winter_turnip
withe_pea	lathyrus_sativus	grain	2000-10-01	2001-08-31	I24	\N	\N	crop_productions_withe_pea
witloof	cichorium_intybus_foliosum	vegetable	2000-04-01	2000-11-30	\N	\N	\N	crop_productions_witloof
wood	plant	wood	2000-01-01	2000-12-31	\N	\N	\N	crop_productions_wood
yam	dioscorea	vegetable	2000-05-01	2000-11-30	F33	\N	\N	crop_productions_yam
ylang_ylang	cananga_odorata	flower	2000-04-01	2001-03-31	\N	\N	\N	crop_productions_ylang_ylang
zucchini	cucurbita_pepo_pepo	vegetable	2000-04-01	2000-09-30	ZBI	\N	\N	crop_productions_zucchini
\.


--
-- Data for Name: master_crop_production_cap_codes; Type: TABLE DATA; Schema: lexicon__5_0_0; Owner: lexicon
--

COPY lexicon__5_0_0.master_crop_production_cap_codes (cap_code, cap_label, production, year) FROM stdin;
AVH	Avoine d’hiver	winter_oat	2017
AVP	Avoine de printemps	spring_oat	2017
BDH	Blé dur d’hiver	winter_hard_wheat	2017
BDP	Blé dur de printemps	spring_hard_wheat	2017
BDT	Blé dur de printemps semé tardivement (après le 31/05)	spring_hard_wheat	2017
BTH	Blé tendre d’hiver	winter_common_wheat	2017
BTP	Blé tendre de printemps	spring_common_wheat	2017
EPE	Épeautre	spelt	2017
MID	Maïs doux	sweet_corn	2017
MIE	Maïs ensilage	silage_corn	2017
MIS	Maïs	grain_corn	2017
MLT	Millet	millet	2017
MOH	Moha	foxtail_millet	2017
ORH	Orge d'hiver	winter_barley	2017
ORP	Orge de printemps	spring_barley	2017
RIZ	Riz	rice	2017
SRS	Sarrasin	buckwheat	2017
SGH	Seigle d’hiver	winter_rye	2017
SGP	Seigle de printemps	spring_rye	2017
SOG	Sorgho	sorghum	2017
TTH	Triticale d’hiver	winter_triticale	2017
TTP	Triticale de printemps	spring_triticale	2017
CHA	Autre céréale d’hiver de genre Avena	winter_avena_cereal	2017
CHH	Autre céréale d’hiver de genre Hordeum	winter_hordeum_cereal	2017
CHS	Autre céréale d’hiver de genre Secale	winter_secale_cereal	2017
CHT	Autre céréale d’hiver de genre Triticum	winter_triticum_cereal	2017
CPA	Autre céréale de printemps de genre Avena	spring_avena_cereal	2017
CPH	Autre céréale de printemps de genre Hordeum	spring_hordeum_cereal	2017
CPS	Autre céréale de printemps de genre Secale	spring_secale_cereal	2017
CPT	Autre céréale de printemps de genre Triticum	spring_triticum_cereal	2017
CPZ	Autre céréale de printemps de genre Zea	spring_zea_cereal	2017
CGH	Autre céréale de genre Phalaris	phalaris_cereal	2017
CGP	Autre céréale de genre Panicum	panicum_cereal	2017
CGO	Autre céréale de genre Sorghum	sorghum_cereal	2017
CGS	Autre céréale de genre Setaria	setaria_cereal	2017
CGF	Autre céréale de genre Fagopyrum	fagopoyrum_cereal	2017
CAG	Autre céréale d’un autre genre	cereal	2017
CAG	Autre céréale d’un autre genre	quinoa	2017
MCR	Mélange de céréales	cereal_mix	2017
CML	Cameline	camelina	2017
CZH	Colza d’hiver	winter_rape	2017
CZP	Colza de printemps	spring_rape	2017
LIH	Lin non textile d’hiver	winter_flax	2017
LIP	Lin non textile de printemps	spring_flax	2017
MOT	Moutarde	mustard	2017
NVE	Navette d’été	summer_field_mustard	2017
NVH	Navette d’hiver	winter_field_mustard	2017
NYG	Nyger	nyger	2017
OEI	Œillette	opium_poppy	2017
SOJ	Soja	soy	2017
TRN	Tournesol	sunflower	2017
OHN	Autre oléagineux d’hiver d’espèce Brassica napus	winter_brassica_napus_oleaginous	2017
OHR	Autre oléagineux d’hiver d’espèce Brassica rapa	winter_brassica_rapa_oleaginous	2017
OPN	Autre oléagineux de printemps d’espèce Brassica napus	spring_brassica_napus_oleaginous	2017
OPR	Autre oléagineux de printemps d’espèce Brassica rapa	spring_brassica_rapa_oleaginous	2017
OEH	Autre oléagineux d’espèce Helianthus	helianthus_oleaginous	2017
OAG	Autre oléagineux d’un autre genre	oleaginous	2017
OAG	Autre oléagineux d’un autre genre	castor_bean	2017
MOL	Mélange d’oléagineux	oleaginous_mix	2017
FVL	Féverole	winter_field_bean	2017
FVL	Féverole	spring_field_bean	2017
JOD	Jarosse déshydratée	dehydrated_tufted_vetch	2017
LDH	Lupin doux d’hiver	winter_sweet_lupin	2017
LDP	Lupin doux de printemps	spring_sweet_lupin	2017
LUD	Luzerne déshydratée	dehydrated_alfalfa	2017
MED	Mélilot déshydraté	dehydrated_melilot	2017
PHI	Pois d’hiver	winter_proteaginous_pea	2017
PPR	Pois de printemps	spring_proteaginous_pea	2017
SAD	Sainfoin déshydraté	dehydrated_sainfoin	2017
SED	Serradelle déshydratée	dehydrated_birds_foot	2017
TRD	Trèfle déshydraté	dehydrated_clover	2017
VED	Vesce déshydratée	dehydrated_common_vetch	2017
PAG	Autre protéagineux d’un autre genre	proteaginous	2017
MLD	Mélange de légumineuses déshydratées (entre elles)	leguminous_mix	2017
MPC	Mélange de protéagineux prépondérants (pois et/ou lupin et/ou féverole) et de céréales	fodder_species_mix	2017
CHV	Chanvre	hemp	2017
LIF	Lin fibres	fiber_flax	2017
J5M	Jachère de 5 ans ou moins	fallow	2017
J6S	Jachère de 6 ans ou plus déclarée comme SIE	fallow	2017
J6P	Jachère de 6 ans ou plus	fallow	2017
JNO	Jachère noire	fallow	2017
ARA	Arachide	peanut	2017
CRN	Cornille	black_eyed_pea	2017
DOL	Dolique	catjang	2017
FNU	Fenugrec	fenugreek	2017
GES	Gesse	withe_pea	2017
LEC	Lentille cultivée (non fourragère)	fresh_lentil	2017
LEC	Lentille cultivée (non fourragère)	dried_lentil	2017
LO7	Lotier implanté pour la récolte 2017	birds_foot_trefoil	2017
LOT	Autre lotier	birds_foot_trefoil	2017
MI7	Minette implanté pour la récolte 2017	black_medick	2017
MIN	Autre minette	black_medick	2017
PCH	Pois chiche	chickpea	2017
FF5	Féverole fourragère implantée pour la récolte 2015	winter_fodder_field_bean	2017
FF5	Féverole fourragère implantée pour la récolte 2015	spring_fodder_field_bean	2017
FF6	Féverole fourragère implantée pour la récolte 2016	winter_fodder_field_bean	2017
FF6	Féverole fourragère implantée pour la récolte 2016	spring_fodder_field_bean	2017
FF7	Féverole fourragère implantée pour la récolte 2017	winter_fodder_field_bean	2017
FF7	Féverole fourragère implantée pour la récolte 2017	spring_fodder_field_bean	2017
FFO	Autre féverole fourragère	winter_fodder_field_bean	2017
FFO	Autre féverole fourragère	spring_fodder_field_bean	2017
JO5	Jarosse implantée pour la récolte 2015	tufted_vetch	2017
JO6	Jarosse implantée pour la récolte 2016	tufted_vetch	2017
JO7	Jarosse implantée pour la récolte 2017	tufted_vetch	2017
JOS	Autre jarosse	tufted_vetch	2017
LH5	Lupin fourrager d’hiver implanté pour la récolte 2015	winter_fodder_lupin	2017
LH6	Lupin fourrager d’hiver implanté pour la récolte 2016	winter_fodder_lupin	2017
LH7	Lupin fourrager d’hiver implanté pour la récolte 2017	winter_fodder_lupin	2017
LFH	Autre lupin fourrager d’hiver	winter_fodder_lupin	2017
LP5	Lupin fourrager de printemps implanté pour la récolte 2015	spring_fodder_lupin	2017
LP6	Lupin fourrager de printemps implanté pour la récolte 2016	spring_fodder_lupin	2017
LP7	Lupin fourrager de printemps implanté pour la récolte 2017	spring_fodder_lupin	2017
LFP	Autre lupin fourrager de printemps	spring_fodder_lupin	2017
LU5	Luzerne implantée pour la récolte 2015	alfalfa	2017
LU6	Luzerne implantée pour la récolte 2016	alfalfa	2017
LU7	Luzerne implantée pour la récolte 2017	alfalfa	2017
LUZ	Autre luzerne	alfalfa	2017
ME5	Mélilot implanté pour la récolte 2015	melilot	2017
ME6	Mélilot implanté pour la récolte 2016	melilot	2017
ME7	Mélilot implanté pour la récolte 2017	melilot	2017
MEL	Autre mélilot	melilot	2017
PH5	Pois fourrager d’hiver implanté pour la récolte 2015	winter_fodder_pea	2017
PH6	Pois fourrager d’hiver implanté pour la récolte 2016	winter_fodder_pea	2017
PH7	Pois fourrager d’hiver implanté pour la récolte 2017	winter_fodder_pea	2017
PFH	Autre pois fourrager d’hiver	winter_fodder_pea	2017
PP5	Pois fourrager de printemps implanté pour la récolte 2015	spring_fodder_pea	2017
PP6	Pois fourrager de printemps implanté pour la récolte 2016	spring_fodder_pea	2017
PP7	Pois fourrager de printemps implanté pour la récolte 2017	spring_fodder_pea	2017
PFP	Autre pois fourrager de printemps	spring_fodder_pea	2017
SA5	Sainfoin implanté pour la récolte 2015	sainfoin	2017
SA6	Sainfoin implanté pour la récolte 2016	sainfoin	2017
SA7	Sainfoin implanté pour la récolte 2017	sainfoin	2017
SAI	Autre sainfoin	sainfoin	2017
SE5	Serradelle implantée pour la récolte 2015	birds_foot	2017
SE6	Serradelle implantée pour la récolte 2016	birds_foot	2017
SE7	Serradelle implantée pour la récolte 2017	birds_foot	2017
SER	Autre serradelle	birds_foot	2017
TR5	Trèfle implanté pour la récolte 2015	clover	2017
TR6	Trèfle implanté pour la récolte 2016	clover	2017
TR7	Trèfle implanté pour la récolte 2017	clover	2017
TRE	Autre trèfle	clover	2017
VE5	Vesce implantée pour la récolte 2015	common_vetch	2017
VE6	Vesce implantée pour la récolte 2016	common_vetch	2017
VE7	Vesce implantée pour la récolte 2017	common_vetch	2017
VES	Autre vesce	common_vetch	2017
ML5	Mélange de légumineuses fourragères implantées pour la récolte 2015 (entre elles)	leguminous_mix	2017
ML6	Mélange de légumineuses fourragères implantées pour la récolte 2016 (entre elles)	leguminous_mix	2017
ML7	Mélange de légumineuses fourragères implantées pour la récolte 2017 (entre elles)	leguminous_mix	2017
MC5	Mélange de légumineuses fourragères prépondérantes au semis implantées pour la récolte 2015 et de céréales	fodder_species_mix	2017
MC6	Mélange de légumineuses fourragères prépondérantes au semis implantées pour la récolte 2016 et de céréales	fodder_species_mix	2017
MC7	Mélange de légumineuses fourragères prépondérantes au semis implantées pour la récolte 2017 et de céréales et d’oléagineux	fodder_species_mix	2017
MH5	Mélange de légumineuses fourragères prépondérantes au semis implantées pour la récolte 2015 et d’herbacées ou de graminées fourragères	fodder_species_mix	2017
MH6	Mélange de légumineuses fourragères prépondérantes au semis implantées pour la récolte 2016 et d’herbacées ou de graminées fourragères	fodder_species_mix	2017
MH7	Mélange de légumineuses fourragères prépondérantes au semis implantées pour la récolte 2017 et d’herbacées ou de graminées fourragères	fodder_species_mix	2017
BVF	Betterave fourragère	fodder_beetroot	2017
CAF	Carotte fourragère	fodder_carrot	2017
CHF	Chou fourrager	fodder_cabbage	2017
LEF	Lentille fourragère	fodder_lentil	2017
NVF	Navet fourrager	fodder_turnip	2017
RDF	Radis fourrager	fodder_radish	2017
FSG	Autre plante fourragère sarclée d’un autre genre	fodder_specie	2017
FAG	Autre fourrage annuel d’un autre genre	fodder_specie	2017
CPL	Fourrage composé de céréales et/ou de protéagineux (en proportion < 50%) et/ou de légumineuses fourragères (en proportion < 50%)	fodder_species_mix	2017
BRH	Bourrache de 5 ans ou moins	borage	2017
BRO	Brôme de 5 ans ou moins	bromus	2017
CRA	Cresson alénois de 5 ans ou moins	cress	2017
DTY	Dactyle de 5 ans ou moins	cocksfoot	2017
FET	Fétuque de 5 ans ou moins	fescue	2017
FLO	Fléole de 5 ans ou moins	timothy	2017
PAT	Paturin commun de 5 ans ou moins	rough_bluegrass	2017
PCL	Phacélie de 5 ans ou moins	phacelia	2017
RGA	Ray-grass de 5 ans ou moins	ryegrass	2017
XFE	X-Festulolium de 5 ans ou moins	festulolium	2017
GFP	Autre graminée fourragère pure de 5 ans ou moins	meadow	2017
MLG	Mélange de légumineuses prépondérantes au semis et de graminées fourragères de 5 ans ou moins	meadow	2017
PTR	Autre prairie temporaire de 5 ans ou moins	meadow	2017
PRL	Prairie en rotation longue (6 ans ou plus)	meadow	2017
PPH	Prairie permanente - herbe prédominante (ressources fourragères ligneuses absentes ou peu présentes)	meadow	2017
SPL	Surface pastorale - ressources fourragères ligneuses prédominantes	meadow	2017
SPH	Surface pastorale - herbe prédominante et ressources fourragères ligneuses présentes	meadow	2017
BOP	Bois pâturé	meadow	2017
CAE	Châtaigneraie entretenue par des porcins ou des petits ruminants	chesnut	2017
CEE	Chênaie entretenue par des porcins ou des petits ruminants	oak	2017
ROS	Roselière	meadow	2017
AIL	Ail	garlic	2017
ART	Artichaut	artichoke	2017
AUB	Aubergine	eggplant	2017
AVO	Avocat	avocado	2017
BTN	Betterave non fourragère / Bette	beetroot	2017
BTN	Betterave non fourragère / Bette	chard	2017
CAR	Carotte	carrot	2017
CEL	Céleri	celery	2017
CEL	Céleri	celeriac	2017
CES	Chicorée / Endive / Scarole	root_chicory	2017
CES	Chicorée / Endive / Scarole	curly_endive	2017
CES	Chicorée / Endive / Scarole	witloof	2017
CES	Chicorée / Endive / Scarole	escarole	2017
CHU	Chou	cabbage	2017
CHU	Chou	broccoli	2017
CHU	Chou	napa_cabbage	2017
CHU	Chou	brussels_sprout	2017
CHU	Chou	white_cabbage	2017
CHU	Chou	cauliflower	2017
CHU	Chou	kohlrabi	2017
CCN	Concombre / Cornichon	cucumber	2017
CCN	Concombre / Cornichon	pickle	2017
CMB	Courge musquée / Butternut	squash	2017
CMB	Courge musquée / Butternut	butternut_squash	2017
CCT	Courgette / Citrouille	zucchini	2017
CCT	Courgette / Citrouille	pumpkin	2017
CRS	Cresson	watercress	2017
EPI	Epinard	winter_spinach	2017
EPI	Epinard	spring_spinach	2017
FEV	Fève	broad_bean	2017
FRA	Fraise	strawberry	2017
HAR	Haricot / Flageolet	dried_bean	2017
HAR	Haricot / Flageolet	green_bean	2017
HAR	Haricot / Flageolet	flageolet_bean	2017
HBL	Houblon	hop	2017
LBF	Laitue / Batavia / Feuille de chêne	lettuce	2017
LBF	Laitue / Batavia / Feuille de chêne	batavia	2017
LBF	Laitue / Batavia / Feuille de chêne	oakleaf	2017
MAC	Mâche	cornsalad	2017
MLO	Melon	melon	2017
NVT	Navet	early_turnip	2017
NVT	Navet	winter_turnip	2017
OIG	Oignon / Echalotte	onion	2017
OIG	Oignon / Echalotte	shallot	2017
PAN	Panais	parsnip	2017
PAS	Pastèque	watermelon	2017
PPO	Petits pois	pea	2017
PPO	Petits pois	dried_pea	2017
POR	Poireau	leek	2017
PVP	Poivron / Piment	pepper	2017
PVP	Poivron / Piment	chili	2017
PTC	Pomme de terre de consommation	potato	2017
PTF	Pomme de terre féculière	potato	2017
POT	Potiron / Potimarron	sugar_pumpkin	2017
POT	Potiron / Potimarron	red_kuri	2017
RDI	Radis	radish	2017
ROQ	Roquette	rocket	2017
RUT	Rutabaga	rutabaga	2017
SFI	Salsifis	salsify	2017
TAB	Tabac	tobacco	2017
TOM	Tomate	tomato	2017
TOT	Tomate pour transformation	tomato	2017
TOP	Topinambour	jerusalem_artichoke	2017
FLA	Autre légume ou fruit annuel	annual_vegetable	2017
FLA	Autre légume ou fruit annuel	purslane	2017
FLA	Autre légume ou fruit annuel	annual_fruit	2017
FLP	Autre légume ou fruit pérenne	perennial_vegetable	2017
FLP	Autre légume ou fruit pérenne	asparagus	2017
FLP	Autre légume ou fruit pérenne	rhubarb	2017
FLP	Autre légume ou fruit pérenne	orchard	2017
AGR	Agrume	citrus	2017
AGR	Agrume	clementine	2017
AGR	Agrume	grapefruit	2017
AGR	Agrume	lemon	2017
AGR	Agrume	mandarin	2017
AGR	Agrume	orange	2017
CAB	Caroube	carob	2017
CBT	Cerise bigarreau pour transformation	cherry	2017
CTG	Châtaigne	chesnut	2017
NOS	Noisette	hazelnut	2017
NOX	Noix	walnut	2017
OLI	Oliveraie	olive	2017
PVT	Pêche Pavie pour transformation	peach	2017
PEP	Pépinière	nursery	2017
PFR	Petit fruit rouge	bilberry	2017
PFR	Petit fruit rouge	blackberry	2017
PFR	Petit fruit rouge	blackcurrant	2017
PFR	Petit fruit rouge	cranberry	2017
PFR	Petit fruit rouge	mulberry	2017
PFR	Petit fruit rouge	raspberry	2017
PFR	Petit fruit rouge	redcurrant	2017
PIS	Pistache	pistachio	2017
PWT	Poire Williams pour transformation	pear	2017
PRU	Prune d’Ente pour transformation	plum	2017
VRG	Verger (fruits non transformés)	orchard	2017
VRG	Verger (fruits non transformés)	apple	2017
VRG	Verger (fruits non transformés)	apricot	2017
VRG	Verger (fruits non transformés)	cherry	2017
VRG	Verger (fruits non transformés)	fig	2017
VRG	Verger (fruits non transformés)	kiwi	2017
VRG	Verger (fruits non transformés)	nectarine	2017
VRG	Verger (fruits non transformés)	peach	2017
VRG	Verger (fruits non transformés)	pear	2017
VRG	Verger (fruits non transformés)	persimmon	2017
VRG	Verger (fruits non transformés)	plum	2017
VRG	Verger (fruits non transformés)	quince	2017
VRC	Vigne : raisins de cuve	vine	2017
VRT	Vigne : raisins de table	vine	2017
RVI	Restructuration du vignoble	vine	2017
ANE	Aneth	dill	2017
ANG	Angélique	angelica	2017
ANI	Anis	anise	2017
BAR	Bardane	burdock	2017
BAS	Basilic	basil	2017
BLT	Bleuet	cornflower	2017
BUR	Bugle rampant	bugle	2017
CMM	Camomille	chamomile	2017
CAV	Carvi	caraway	2017
CRF	Cerfeuil	chervil	2017
CHR	Chardon Marie	marian_thistle	2017
CIB	Ciboulette	chive	2017
CRD	Coriandre	coriander	2017
CUM	Cumin	cumin	2017
EST	Estragon	tarragon	2017
FNO	Fenouil	fennel	2017
GAI	Gaillet	galium	2017
LAV	Lavande / Lavandin	lavender	2017
LAV	Lavande / Lavandin	lavandin	2017
MRG	Marguerite	oxeye_daisy	2017
MRJ	Marjolaine / Origan	marjoram	2017
MRJ	Marjolaine / Origan	oregano	2017
MAV	Mauve	mallow	2017
MLI	Mélisse	lemon_balm	2017
MTH	Menthe	mint	2017
MLP	Millepertuis	st_johns_wort	2017
OSE	Oseille	sorrel	2017
ORT	Ortie	nettle	2017
PAQ	Pâquerette	common_daisy	2017
PSE	Pensée	pansy	2017
PSL	Persil	parsley	2017
PSY	Plantain psyllium	blond_psyllium	2017
PMV	Primevère	primrose	2017
PSN	Psyllium noir de Provence	black_psyllium	2017
ROM	Romarin	rosemary	2017
SRI	Sariette	savory	2017
SGE	Sauge	sage	2017
THY	Thym	thyme	2017
VAL	Valériane	valerian	2017
VER	Véronique	speedwell	2017
PPA	Autres plantes ornementales et PPAM annuelles	annual_ornamental_plant_and_mapp	2017
PPP	Autres plantes ornementales et PPAM pérennes	perrenial_ornamental_plant_and_mapp	2017
MPA	Autre mélange de plantes fixant l’azote	leguminous_mix	2017
MCT	Miscanthus	miscanthus	2017
CSS	Culture sous serre hors sol	crop_production	2017
TCR	Taillis à courte rotation	eucalyptus	2017
TRU	Truffière (chênaie de plants mycorhizés)	wood	2017
SBO	Surface boisée sur une ancienne terre agricole	wood	2017
SNE	Surface agricole temporairement non exploitée	fallow	2017
MRS	Marais salant	crop_production	2017
BFP	Bande admissible le long d’une forêt avec production	border	2017
BFS	Bande admissible le long d’une forêt sans production	border	2017
BTA	Bande tampon	border	2017
BOR	Bordure de champ	border	2017
BOR	Bordure de champ	cherry_laurel	2017
CID	Cultures conduites en interrangs : 2 cultures représentant chacune plus de 25%	interrow	2017
CIT	Cultures conduites en interrangs : 3 cultures représentant chacune plus de 25%	interrow	2017
ANA	Ananas	pineapple	2017
BCA	Banane créole (fruit et légume) - autre	banana	2017
BCF	Banane créole (fruit et légume) - fermage	banana	2017
BCI	Banane créole (fruit et légume) - indivision	banana	2017
BCP	Banane créole (fruit et légume) - propriété ou faire valoir direct	banana	2017
BCR	Banane créole (fruit et légume) - réforme foncière	banana	2017
BEA	Banane export - autre	banana	2017
BEF	Banane export - fermage	banana	2017
BEI	Banane export - indivision	banana	2017
BEP	Banane export - propriété ou faire valoir direct	banana	2017
BER	Banane export - réforme foncière	banana	2017
CAC	Café / Cacao	coffee	2017
CAC	Café / Cacao	cocoa	2017
CSA	Canne à sucre - autre	sugar_cane	2017
CSF	Canne à sucre - fermage	sugar_cane	2017
CSI	Canne à sucre - indivision	sugar_cane	2017
CSP	Canne à sucre - propriété ou faire valoir direct	sugar_cane	2017
CSR	Canne à sucre - réforme foncière	sugar_cane	2017
CUA	Culture sous abattis	crop_production	2017
CUR	Curcuma	turmeric	2017
GER	Géranium	geranium	2017
HPC	Horticulture ornementale de plein champ	annual_ornamental_plant_and_mapp	2017
HSA	Horticulture ornementale sous abri	annual_ornamental_plant_and_mapp	2017
LSA	Légume sous abri	annual_vegetable	2017
PPF	Plante à parfum (autre que géranium et vétiver)	annual_ornamental_plant_and_mapp	2017
PAR	Plante aromatique (autre que vanille)	annual_ornamental_plant_and_mapp	2017
PMD	Plante médicinale	annual_ornamental_plant_and_mapp	2017
TBT	Tubercule tropical	annual_vegetable	2017
TBT	Tubercule tropical	cassava	2017
TBT	Tubercule tropical	sweet_patato	2017
TBT	Tubercule tropical	yam	2017
VNL	Vanille	vanilla	2017
VNB	Vanille sous bois	vanilla	2017
VNV	Vanille verte	vanilla	2017
VGD	Verger (DOM)	orchard	2017
VGD	Verger (DOM)	giant_granadilla	2017
VGD	Verger (DOM)	guava	2017
VGD	Verger (DOM)	longan	2017
VET	Vétiver	vetiver	2017
YLA	Ylang-ylang	ylang_ylang	2017
ACA	Autre culture non précisée dans la liste (admissible)	crop_production	2017
ACA	Autre culture non précisée dans la liste (admissible)	cotton	2017
AVH	Avoine d’hiver	winter_oat	2018
AVP	Avoine de printemps	spring_oat	2018
BDH	Blé dur d’hiver	winter_hard_wheat	2018
BDP	Blé dur de printemps	spring_hard_wheat	2018
BTH	Blé tendre d’hiver	winter_common_wheat	2018
BTP	Blé tendre de printemps	spring_common_wheat	2018
EPE	Épeautre	spelt	2018
MID	Maïs doux	sweet_corn	2018
MIE	Maïs ensilage	silage_corn	2018
MIS	Maïs	grain_corn	2018
MLT	Millet	millet	2018
MOH	Moha	foxtail_millet	2018
ORH	Orge d'hiver	winter_barley	2018
ORP	Orge de printemps	spring_barley	2018
RIZ	Riz	rice	2018
SRS	Sarrasin	buckwheat	2018
SGH	Seigle d’hiver	winter_rye	2018
SGP	Seigle de printemps	spring_rye	2018
SOG	Sorgho	sorghum	2018
TTH	Triticale d’hiver	winter_triticale	2018
TTP	Triticale de printemps	spring_triticale	2018
CHA	Autre céréale d’hiver de genre Avena	winter_avena_cereal	2018
CHH	Autre céréale d’hiver de genre Hordeum	winter_hordeum_cereal	2018
CHS	Autre céréale d’hiver de genre Secale	winter_secale_cereal	2018
CHT	Autre céréale d’hiver de genre Triticum	winter_triticum_cereal	2018
CPA	Autre céréale de printemps de genre Avena	spring_avena_cereal	2018
CPH	Autre céréale de printemps de genre Hordeum	spring_hordeum_cereal	2018
CPS	Autre céréale de printemps de genre Secale	spring_secale_cereal	2018
CPT	Autre céréale de printemps de genre Triticum	spring_triticum_cereal	2018
CPZ	Autre céréale de printemps de genre Zea	spring_zea_cereal	2018
CGH	Autre céréale de genre Phalaris	phalaris_cereal	2018
CGP	Autre céréale de genre Panicum	panicum_cereal	2018
CGO	Autre céréale de genre Sorghum	sorghum_cereal	2018
CGS	Autre céréale de genre Setaria	setaria_cereal	2018
CGF	Autre céréale de genre Fagopyrum	fagopoyrum_cereal	2018
CAG	Autre céréale ou pseudo céréale d’un autre genre	cereal	2018
CAG	Autre céréale ou pseudo céréale d’un autre genre	quinoa	2018
MCR	Mélange de céréales ou pseudo céréales pures ou mélange avec des protéagineux non prépondérants	cereal_mix	2018
MCR	Mélange de céréales ou pseudo céréales pures ou mélange avec des protéagineux non prépondérants	fodder_species_mix	2018
CML	Cameline	camelina	2018
CZH	Colza d’hiver	winter_rape	2018
CZP	Colza de printemps	spring_rape	2018
LIH	Lin non textile d’hiver	winter_flax	2018
LIP	Lin non textile de printemps	spring_flax	2018
MOT	Moutarde	mustard	2018
NVE	Navette d’été	summer_field_mustard	2018
NVH	Navette d’hiver	winter_field_mustard	2018
NYG	Nyger	nyger	2018
OEI	Œillette (Pavot)	opium_poppy	2018
SOJ	Soja	soy	2018
TRN	Tournesol	sunflower	2018
OHN	Autre oléagineux d’hiver d’espèce Brassica napus	winter_brassica_napus_oleaginous	2018
OHR	Autre oléagineux d’hiver d’espèce Brassica rapa	winter_brassica_rapa_oleaginous	2018
OPN	Autre oléagineux de printemps d’espèce Brassica napus	spring_brassica_napus_oleaginous	2018
OPR	Autre oléagineux de printemps d’espèce Brassica rapa	spring_brassica_rapa_oleaginous	2018
OEH	Autre oléagineux d’espèce Helianthus	helianthus_oleaginous	2018
OAG	Autre oléagineux d’un autre genre	oleaginous	2018
OAG	Autre oléagineux d’un autre genre	castor_bean	2018
MOL	Mélange d’oléagineux	oleaginous_mix	2018
FVL	Féverole	winter_field_bean	2018
FVL	Féverole	spring_field_bean	2018
JOD	Jarosse déshydratée	dehydrated_tufted_vetch	2018
LDH	Lupin doux d’hiver	winter_sweet_lupin	2018
LDP	Lupin doux de printemps	spring_sweet_lupin	2018
LUD	Luzerne déshydratée	dehydrated_alfalfa	2018
MED	Mélilot déshydraté	dehydrated_melilot	2018
PHI	Pois d’hiver	winter_proteaginous_pea	2018
PPR	Pois de printemps	spring_proteaginous_pea	2018
SAD	Sainfoin déshydraté	dehydrated_sainfoin	2018
SED	Serradelle déshydratée	dehydrated_birds_foot	2018
TRD	Trèfle déshydraté	dehydrated_clover	2018
VED	Vesce déshydratée	dehydrated_common_vetch	2018
PAG	Autre protéagineux d’un autre genre	proteaginous	2018
MLD	Mélange de légumineuses déshydratées (entre elles)	leguminous_mix	2018
MPP	Mélange de protéagineux (pois et/ou lupin et/ou féverole)	proteaginous_mix	2018
MPC	Mélange de protéagineux prépondérants (pois et/ou lupin et/ou féverole) et de céréales	fodder_species_mix	2018
CHV	Chanvre	hemp	2018
LIF	Lin fibres	fiber_flax	2018
J5M	Jachère de 5 ans ou moins	fallow	2018
J6S	Jachère de 6 ans ou plus déclarée comme SIE	fallow	2018
J6P	Jachère de 6 ans ou plus	fallow	2018
JNO	Jachère noire	fallow	2018
ARA	Arachide	peanut	2018
CRN	Cornille	black_eyed_pea	2018
DOL	Dolique	catjang	2018
FNU	Fenugrec	fenugreek	2018
GES	Gesse	withe_pea	2018
LEC	Lentille cultivée (non fourragère)	fresh_lentil	2018
LEC	Lentille cultivée (non fourragère)	dried_lentil	2018
LO7	Lotier implanté pour la récolte 2017	birds_foot_trefoil	2018
LO8	Lotier implanté pour la récolte 2018	birds_foot_trefoil	2018
LOT	Autre lotier	birds_foot_trefoil	2018
MI7	Minette implanté pour la récolte 2017	black_medick	2018
MI8	Minette implanté pour la récolte 2018	black_medick	2018
MIN	Autre minette	black_medick	2018
PCH	Pois chiche	chickpea	2018
FF6	Féverole fourragère implantée pour la récolte 2016	winter_fodder_field_bean	2018
FF6	Féverole fourragère implantée pour la récolte 2016	spring_fodder_field_bean	2018
FF7	Féverole fourragère implantée pour la récolte 2017	winter_fodder_field_bean	2018
FF7	Féverole fourragère implantée pour la récolte 2017	spring_fodder_field_bean	2018
FF8	Féverole fourragère implantée pour la récolte 2018	winter_fodder_field_bean	2018
FF8	Féverole fourragère implantée pour la récolte 2018	spring_fodder_field_bean	2018
FFO	Autre féverole fourragère	winter_fodder_field_bean	2018
FFO	Autre féverole fourragère	spring_fodder_field_bean	2018
JO6	Jarosse implantée pour la récolte 2016	tufted_vetch	2018
JO7	Jarosse implantée pour la récolte 2017	tufted_vetch	2018
JO8	Jarosse implantée pour la récolte 2018	tufted_vetch	2018
JOS	Autre jarosse	tufted_vetch	2018
LH6	Lupin fourrager d’hiver implanté pour la récolte 2016	winter_fodder_lupin	2018
CES	Chicorée / Endive / Scarole	witloof	2018
LH7	Lupin fourrager d’hiver implanté pour la récolte 2017	winter_fodder_lupin	2018
LH8	Lupin fourrager d’hiver implanté pour la récolte 2018	winter_fodder_lupin	2018
LFH	Autre lupin fourrager d’hiver	winter_fodder_lupin	2018
LP6	Lupin fourrager de printemps implanté pour la récolte 2016	spring_fodder_lupin	2018
LP7	Lupin fourrager de printemps implanté pour la récolte 2017	spring_fodder_lupin	2018
LP8	Lupin fourrager de printemps implanté pour la récolte 2018	spring_fodder_lupin	2018
LFP	Autre lupin fourrager de printemps	spring_fodder_lupin	2018
LU6	Luzerne implantée pour la récolte 2016	alfalfa	2018
LU7	Luzerne implantée pour la récolte 2017	alfalfa	2018
LU8	Luzerne implantée pour la récolte 2018	alfalfa	2018
LUZ	Autre luzerne	alfalfa	2018
ME6	Mélilot implanté pour la récolte 2016	melilot	2018
ME7	Mélilot implanté pour la récolte 2017	melilot	2018
ME8	Mélilot implanté pour la récolte 2018	melilot	2018
MEL	Autre mélilot	melilot	2018
PH6	Pois fourrager d’hiver implanté pour la récolte 2016	winter_fodder_pea	2018
PH7	Pois fourrager d’hiver implanté pour la récolte 2017	winter_fodder_pea	2018
PH8	Pois fourrager d’hiver implanté pour la récolte 2018	winter_fodder_pea	2018
PFH	Autre pois fourrager d’hiver	winter_fodder_pea	2018
PP6	Pois fourrager de printemps implanté pour la récolte 2016	spring_fodder_pea	2018
PP7	Pois fourrager de printemps implanté pour la récolte 2017	spring_fodder_pea	2018
PP8	Pois fourrager de printemps implanté pour la récolte 2018	spring_fodder_pea	2018
PFP	Autre pois fourrager de printemps	spring_fodder_pea	2018
SA6	Sainfoin implanté pour la récolte 2016	sainfoin	2018
SA7	Sainfoin implanté pour la récolte 2017	sainfoin	2018
SA8	Sainfoin implanté pour la récolte 2018	sainfoin	2018
SAI	Autre sainfoin	sainfoin	2018
SE6	Serradelle implantée pour la récolte 2016	birds_foot	2018
SE7	Serradelle implantée pour la récolte 2017	birds_foot	2018
SE8	Serradelle implantée pour la récolte 2018	birds_foot	2018
SER	Autre serradelle	birds_foot	2018
TR6	Trèfle implanté pour la récolte 2016	clover	2018
TR7	Trèfle implanté pour la récolte 2017	clover	2018
TR8	Trèfle implanté pour la récolte 2018	clover	2018
TRE	Autre trèfle	clover	2018
VE6	Vesce implantée pour la récolte 2016	common_vetch	2018
VE7	Vesce implantée pour la récolte 2017	common_vetch	2018
VE8	Vesce implantée pour la récolte 2018	common_vetch	2018
VES	Autre vesce	common_vetch	2018
ML6	Mélange de légumineuses fourragères implantées pour la récolte 2016 (entre elles)	leguminous_mix	2018
ML7	Mélange de légumineuses fourragères implantées pour la récolte 2017 (entre elles)	leguminous_mix	2018
ML8	Mélange de légumineuses fourragères implantées pour la récolte 2018 (entre elles)	leguminous_mix	2018
MC6	Mélange de légumineuses fourragères prépondérantes implantées pour la récolte 2016 et de céréales	fodder_species_mix	2018
MC7	Mélange de légumineuses fourragères prépondérantes implantées pour la récolte 2017 et de céréales et/ou d’oléagineux	fodder_species_mix	2018
MC8	Mélange de légumineuses fourragères prépondérantes implantées pour la récolte 2018 et de céréales et/ou d’oléagineux	fodder_species_mix	2018
BVF	Betterave fourragère	fodder_beetroot	2018
CAF	Carotte fourragère	fodder_carrot	2018
CHF	Chou fourrager	fodder_cabbage	2018
LEF	Lentille fourragère	fodder_lentil	2018
NVF	Navet fourrager	fodder_turnip	2018
RDF	Radis fourrager	fodder_radish	2018
FSG	Autre plante fourragère sarclée d’un autre genre	fodder_specie	2018
FAG	Autre fourrage annuel d’un autre genre	fodder_specie	2018
CPL	Fourrage composé de céréales et/ou de protéagineux (en proportion < 50%) et/ou de légumineuses fourragères (en proportion < 50%)	fodder_species_mix	2018
BRH	Bourrache de 5 ans ou moins	borage	2018
BRO	Brôme de 5 ans ou moins	bromus	2018
CRA	Cresson alénois de 5 ans ou moins	cress	2018
DTY	Dactyle de 5 ans ou moins	cocksfoot	2018
FET	Fétuque de 5 ans ou moins	fescue	2018
FLO	Fléole de 5 ans ou moins	timothy	2018
PAT	Paturin commun de 5 ans ou moins	rough_bluegrass	2018
PCL	Phacélie de 5 ans ou moins	phacelia	2018
RGA	Ray-grass de 5 ans ou moins	ryegrass	2018
XFE	X-Festulolium de 5 ans ou moins	festulolium	2018
GFP	Autre graminée fourragère pure de 5 ans ou moins	meadow	2018
MLG	Mélange de légumineuses prépondérantes et de graminées fourragères de 5 ans ou moins	meadow	2018
PTR	Autre prairie temporaire de 5 ans ou moins	meadow	2018
PRL	Prairie en rotation longue (6 ans ou plus)	meadow	2018
PPH	Prairie permanente - herbe prédominante (ressources fourragères ligneuses absentes ou peu présentes)	meadow	2018
SPH	Surface pastorale - herbe prédominante et ressources fourragères ligneuses présentes	meadow	2018
SPL	Surface pastorale - ressources fourragères ligneuses prédominantes	meadow	2018
BOP	Bois pâturé (prairie herbacée sous couvet d'arbres)	meadow	2018
CAE	Châtaigneraie entretenue par des porcins ou des petits ruminants	chesnut	2018
CEE	Chênaie entretenue par des porcins ou des petits ruminants	oak	2018
ROS	Roselière	meadow	2018
AIL	Ail	garlic	2018
ART	Artichaut	artichoke	2018
AUB	Aubergine	eggplant	2018
AVO	Avocat	avocado	2018
BTN	Betterave non fourragère / Bette	beetroot	2018
BTN	Betterave non fourragère / Bette	chard	2018
CAR	Carotte	carrot	2018
CEL	Céleri	celery	2018
CEL	Céleri	celeriac	2018
CES	Chicorée / Endive / Scarole	root_chicory	2018
CES	Chicorée / Endive / Scarole	curly_endive	2018
CES	Chicorée / Endive / Scarole	escarole	2018
CHU	Chou	cabbage	2018
CHU	Chou	broccoli	2018
CHU	Chou	napa_cabbage	2018
CHU	Chou	brussels_sprout	2018
CHU	Chou	white_cabbage	2018
CHU	Chou	cauliflower	2018
CHU	Chou	kohlrabi	2018
CCN	Concombre / Cornichon	cucumber	2018
CCN	Concombre / Cornichon	pickle	2018
CMB	Courge musquée / Butternut	squash	2018
CMB	Courge musquée / Butternut	butternut_squash	2018
CCT	Courgette / Citrouille	zucchini	2018
CCT	Courgette / Citrouille	pumpkin	2018
CRS	Cresson	watercress	2018
EPI	Epinard	winter_spinach	2018
EPI	Epinard	spring_spinach	2018
FEV	Fève	broad_bean	2018
FRA	Fraise	strawberry	2018
HAR	Haricot / Flageolet	dried_bean	2018
HAR	Haricot / Flageolet	green_bean	2018
HAR	Haricot / Flageolet	flageolet_bean	2018
HBL	Houblon	hop	2018
LBF	Laitue / Batavia / Feuille de chêne	lettuce	2018
LBF	Laitue / Batavia / Feuille de chêne	batavia	2018
LBF	Laitue / Batavia / Feuille de chêne	oakleaf	2018
MAC	Mâche	cornsalad	2018
MLO	Melon	melon	2018
NVT	Navet	early_turnip	2018
NVT	Navet	winter_turnip	2018
OIG	Oignon / Echalotte	onion	2018
OIG	Oignon / Echalotte	shallot	2018
PAN	Panais	parsnip	2018
PAS	Pastèque	watermelon	2018
PPO	Pois (petits pois, pois cassés, pois gourmands)	pea	2018
PPO	Pois (petits pois, pois cassés, pois gourmands)	dried_pea	2018
POR	Poireau	leek	2018
PVP	Poivron / Piment	pepper	2018
PVP	Poivron / Piment	chili	2018
PTC	Pomme de terre de consommation	potato	2018
PTF	Pomme de terre féculière	potato	2018
POT	Potiron / Potimarron	sugar_pumpkin	2018
POT	Potiron / Potimarron	red_kuri	2018
RDI	Radis	radish	2018
ROQ	Roquette	rocket	2018
RUT	Rutabaga	rutabaga	2018
SFI	Salsifis	salsify	2018
TAB	Tabac	tobacco	2018
TOM	Tomate	tomato	2018
TOT	Tomate pour transformation	tomato	2018
TOP	Topinambour	jerusalem_artichoke	2018
FLA	Autre légume ou fruit annuel	annual_vegetable	2018
FLA	Autre légume ou fruit annuel	purslane	2018
FLA	Autre légume ou fruit annuel	annual_fruit	2018
FLP	Autre légume ou fruit pérenne	perennial_vegetable	2018
FLP	Autre légume ou fruit pérenne	asparagus	2018
FLP	Autre légume ou fruit pérenne	rhubarb	2018
FLP	Autre légume ou fruit pérenne	orchard	2018
AGR	Agrume	citrus	2018
AGR	Agrume	clementine	2018
AGR	Agrume	grapefruit	2018
AGR	Agrume	lemon	2018
AGR	Agrume	mandarin	2018
AGR	Agrume	orange	2018
CAB	Caroube	carob	2018
CBT	Cerise bigarreau pour transformation	cherry	2018
CTG	Châtaigne	chesnut	2018
NOS	Noisette	hazelnut	2018
NOX	Noix	walnut	2018
OLI	Oliveraie	olive	2018
PVT	Pêche Pavie pour transformation	peach	2018
PEP	Pépinière	nursery	2018
PFR	Petit fruit rouge	bilberry	2018
PFR	Petit fruit rouge	blackberry	2018
PFR	Petit fruit rouge	blackcurrant	2018
PFR	Petit fruit rouge	cranberry	2018
PFR	Petit fruit rouge	mulberry	2018
PFR	Petit fruit rouge	raspberry	2018
PFR	Petit fruit rouge	redcurrant	2018
PIS	Pistache	pistachio	2018
PWT	Poire Williams pour transformation	pear	2018
PRU	Prune d’Ente pour transformation	plum	2018
VRG	Autres vergers	orchard	2018
VRG	Autres vergers	apple	2018
VRG	Autres vergers	apricot	2018
VRG	Autres vergers	cherry	2018
VRG	Autres vergers	fig	2018
VRG	Autres vergers	kiwi	2018
VRG	Autres vergers	nectarine	2018
VRG	Autres vergers	peach	2018
VRG	Autres vergers	pear	2018
VRG	Autres vergers	persimmon	2018
VRG	Autres vergers	plum	2018
VRG	Autres vergers	quince	2018
VRC	Vigne : raisins de cuve en production	vine	2018
VRT	Vigne : raisins de table	vine	2018
VRN	Vigne : raisins de cuve non en production	vine	2018
RVI	Restructuration du vignoble	vine	2018
ANE	Aneth	dill	2018
ANG	Angélique	angelica	2018
ANI	Anis	anise	2018
BAR	Bardane	burdock	2018
BAS	Basilic	basil	2018
BLT	Bleuet	cornflower	2018
BUR	Bugle rampant	bugle	2018
CMM	Camomille	chamomile	2018
CAV	Carvi	caraway	2018
CRF	Cerfeuil	chervil	2018
CHR	Chardon Marie	marian_thistle	2018
CIB	Ciboulette	chive	2018
CRD	Coriandre	coriander	2018
CUM	Cumin	cumin	2018
EST	Estragon	tarragon	2018
FNO	Fenouil	fennel	2018
GAI	Gaillet	galium	2018
LAV	Lavande / Lavandin	lavender	2018
LAV	Lavande / Lavandin	lavandin	2018
MRG	Marguerite	oxeye_daisy	2018
MRJ	Marjolaine / Origan	marjoram	2018
MRJ	Marjolaine / Origan	oregano	2018
MAV	Mauve	mallow	2018
MLI	Mélisse	lemon_balm	2018
MTH	Menthe	mint	2018
MLP	Millepertuis	st_johns_wort	2018
OSE	Oseille	sorrel	2018
ORT	Ortie	nettle	2018
PAQ	Pâquerette	common_daisy	2018
PSE	Pensée	pansy	2018
PSL	Persil	parsley	2018
PSY	Plantain psyllium	blond_psyllium	2018
PMV	Primevère	primrose	2018
PSN	Psyllium noir de Provence	black_psyllium	2018
ROM	Romarin	rosemary	2018
SRI	Sariette	savory	2018
SGE	Sauge	sage	2018
THY	Thym	thyme	2018
VAL	Valériane	valerian	2018
VER	Véronique	speedwell	2018
PPA	Autres plantes ornementales et PPAM annuelles	annual_ornamental_plant_and_mapp	2018
PPP	Autres plantes ornementales et PPAM pérennes	perrenial_ornamental_plant_and_mapp	2018
MPA	Autre mélange de plantes fixant l’azote	leguminous_mix	2018
MCT	Miscanthus	miscanthus	2018
CSS	Culture sous serre hors sol	crop_production	2018
TCR	Taillis à courte rotation	eucalyptus	2018
TRU	Truffière (plants mycorhizés)	wood	2018
SBO	Surface boisée sur une ancienne terre agricole	wood	2018
SNE	Surface agricole temporairement non exploitée	fallow	2018
MRS	Marais salant	crop_production	2018
BFP	Bande admissible le long d’une forêt avec production	border	2018
BFS	Bande admissible le long d’une forêt sans production	border	2018
BTA	Bande tampon	border	2018
BOR	Bordure de champ	border	2018
BOR	Bordure de champ	cherry_laurel	2018
CID	Cultures conduites en interrangs : 2 cultures représentant chacune plus de 25%	interrow	2018
CIT	Cultures conduites en interrangs : 3 cultures représentant chacune plus de 25%	interrow	2018
ANA	Ananas	pineapple	2018
BCA	Banane créole (fruit et légume) - autre	banana	2018
BCF	Banane créole (fruit et légume) - fermage	banana	2018
BCI	Banane créole (fruit et légume) - indivision	banana	2018
BCP	Banane créole (fruit et légume) - propriété ou faire valoir direct	banana	2018
BCR	Banane créole (fruit et légume) - réforme foncière	banana	2018
BEA	Banane export - autre	banana	2018
BEF	Banane export - fermage	banana	2018
BEI	Banane export - indivision	banana	2018
BEP	Banane export - propriété ou faire valoir direct	banana	2018
BER	Banane export - réforme foncière	banana	2018
CAC	Café / Cacao	coffee	2018
CAC	Café / Cacao	cocoa	2018
CSA	Canne à sucre - autre	sugar_cane	2018
CSF	Canne à sucre - fermage	sugar_cane	2018
CSI	Canne à sucre - indivision	sugar_cane	2018
CSP	Canne à sucre - propriété ou faire valoir direct	sugar_cane	2018
CSR	Canne à sucre - réforme foncière	sugar_cane	2018
CUA	Culture sous abattis	crop_production	2018
CUR	Curcuma	turmeric	2018
GER	Géranium	geranium	2018
HPC	Horticulture ornementale de plein champ	annual_ornamental_plant_and_mapp	2018
HSA	Horticulture ornementale sous abri	annual_ornamental_plant_and_mapp	2018
LSA	Légume sous abri	annual_vegetable	2018
PPF	Plante à parfum (autre que géranium et vétiver)	annual_ornamental_plant_and_mapp	2018
PAR	Plante aromatique (autre que vanille)	annual_ornamental_plant_and_mapp	2018
PMD	Plante médicinale	annual_ornamental_plant_and_mapp	2018
TBT	Tubercule tropical	annual_vegetable	2018
TBT	Tubercule tropical	cassava	2018
TBT	Tubercule tropical	sweet_patato	2018
TBT	Tubercule tropical	yam	2018
VNL	Vanille	vanilla	2018
VNB	Vanille sous bois	vanilla	2018
VNV	Vanille verte	vanilla	2018
VGD	Verger (DOM)	orchard	2018
VGD	Verger (DOM)	giant_granadilla	2018
VGD	Verger (DOM)	guava	2018
VGD	Verger (DOM)	longan	2018
VET	Vétiver	vetiver	2018
YLA	Ylang-ylang	ylang_ylang	2018
ACA	Autre culture non précisée dans la liste (admissible)	crop_production	2018
ACA	Autre culture non précisée dans la liste (admissible)	cotton	2018
AVH	Avoine d’hiver	winter_oat	2019
AVP	Avoine de printemps	spring_oat	2019
BDH	Blé dur d’hiver	winter_hard_wheat	2019
BDP	Blé dur de printemps	spring_hard_wheat	2019
BTH	Blé tendre d’hiver	winter_common_wheat	2019
BTP	Blé tendre de printemps	spring_common_wheat	2019
EPE	Épeautre	spelt	2019
MID	Maïs doux	sweet_corn	2019
MIE	Maïs ensilage	silage_corn	2019
MIS	Maïs	grain_corn	2019
MLT	Millet	millet	2019
MOH	Moha	foxtail_millet	2019
ORH	Orge d'hiver	winter_barley	2019
ORP	Orge de printemps	spring_barley	2019
RIZ	Riz	rice	2019
SRS	Sarrasin	buckwheat	2019
SGH	Seigle d’hiver	winter_rye	2019
SGP	Seigle de printemps	spring_rye	2019
SOG	Sorgho	sorghum	2019
TTH	Triticale d’hiver	winter_triticale	2019
TTP	Triticale de printemps	spring_triticale	2019
CHA	Autre céréale d’hiver de genre Avena	winter_avena_cereal	2019
CHH	Autre céréale d’hiver de genre Hordeum	winter_hordeum_cereal	2019
CHS	Autre céréale d’hiver de genre Secale	winter_secale_cereal	2019
CHT	Autre céréale d’hiver de genre Triticum	winter_triticum_cereal	2019
CPA	Autre céréale de printemps de genre Avena	spring_avena_cereal	2019
CPH	Autre céréale de printemps de genre Hordeum	spring_hordeum_cereal	2019
CPS	Autre céréale de printemps de genre Secale	spring_secale_cereal	2019
CPT	Autre céréale de printemps de genre Triticum	spring_triticum_cereal	2019
CPZ	Autre céréale de printemps de genre Zea	spring_zea_cereal	2019
CGH	Autre céréale de genre Phalaris	phalaris_cereal	2019
CGP	Autre céréale de genre Panicum	panicum_cereal	2019
CGO	Autre céréale de genre Sorghum	sorghum_cereal	2019
CGS	Autre céréale de genre Setaria	setaria_cereal	2019
CGF	Autre céréale de genre Fagopyrum	fagopoyrum_cereal	2019
CAG	Autre céréale ou pseudo céréale d’un autre genre	cereal	2019
CAG	Autre céréale ou pseudo céréale d’un autre genre	quinoa	2019
MCR	Mélange de céréales ou pseudo céréales pures ou mélange avec des protéagineux non prépondérants	cereal_mix	2019
MCR	Mélange de céréales ou pseudo céréales pures ou mélange avec des protéagineux non prépondérants	fodder_species_mix	2019
CML	Cameline	camelina	2019
CZH	Colza d’hiver	winter_rape	2019
CZP	Colza de printemps	spring_rape	2019
LIH	Lin non textile d’hiver	winter_flax	2019
LIP	Lin non textile de printemps	spring_flax	2019
MOT	Moutarde	mustard	2019
NVE	Navette d’été	summer_field_mustard	2019
NVH	Navette d’hiver	winter_field_mustard	2019
NYG	Nyger	nyger	2019
OEI	Œillette (Pavot)	opium_poppy	2019
SOJ	Soja	soy	2019
TRN	Tournesol	sunflower	2019
OHN	Autre oléagineux d’hiver d’espèce Brassica napus	winter_brassica_napus_oleaginous	2019
OHR	Autre oléagineux d’hiver d’espèce Brassica rapa	winter_brassica_rapa_oleaginous	2019
OPN	Autre oléagineux de printemps d’espèce Brassica napus	spring_brassica_napus_oleaginous	2019
OPR	Autre oléagineux de printemps d’espèce Brassica rapa	spring_brassica_rapa_oleaginous	2019
OEH	Autre oléagineux d’espèce Helianthus	helianthus_oleaginous	2019
OAG	Autre oléagineux d’un autre genre	oleaginous	2019
OAG	Autre oléagineux d’un autre genre	castor_bean	2019
MOL	Mélange d’oléagineux	oleaginous_mix	2019
FVL	Féverole	winter_field_bean	2019
FVL	Féverole	spring_field_bean	2019
JOD	Jarosse déshydratée	dehydrated_tufted_vetch	2019
LDH	Lupin doux d’hiver	winter_sweet_lupin	2019
LDP	Lupin doux de printemps	spring_sweet_lupin	2019
LUD	Luzerne déshydratée	dehydrated_alfalfa	2019
MED	Mélilot déshydraté	dehydrated_melilot	2019
PHI	Pois d’hiver	winter_proteaginous_pea	2019
PPR	Pois de printemps	spring_proteaginous_pea	2019
SAD	Sainfoin déshydraté	dehydrated_sainfoin	2019
SED	Serradelle déshydratée	dehydrated_birds_foot	2019
TRD	Trèfle déshydraté	dehydrated_clover	2019
VED	Vesce déshydratée	dehydrated_common_vetch	2019
PAG	Autre protéagineux d’un autre genre	proteaginous	2019
MLD	Mélange de légumineuses déshydratées (entre elles)	leguminous_mix	2019
MPP	Mélange de protéagineux (pois et/ou lupin et/ou féverole)	proteaginous_mix	2019
MPC	Mélange de protéagineux prépondérants (pois et/ou lupin et/ou féverole) et de céréales	fodder_species_mix	2019
CHV	Chanvre	hemp	2019
LIF	Lin fibres	fiber_flax	2019
J5M	Jachère de 5 ans ou moins	fallow	2019
J6S	Jachère de 6 ans ou plus déclarée comme SIE	fallow	2019
J6P	Jachère de 6 ans ou plus	fallow	2019
JNO	Jachère noire	fallow	2019
ARA	Arachide	peanut	2019
CRN	Cornille	black_eyed_pea	2019
DOL	Dolique	catjang	2019
FNU	Fenugrec	fenugreek	2019
GES	Gesse	withe_pea	2019
LEC	Lentille cultivée (non fourragère)	fresh_lentil	2019
LEC	Lentille cultivée (non fourragère)	dried_lentil	2019
LOT	Lotier	birds_foot_trefoil	2019
MIN	Minette	black_medick	2019
PCH	Pois chiche	chickpea	2019
FFO	Féverole fourragère	winter_fodder_field_bean	2019
FFO	Féverole fourragère	spring_fodder_field_bean	2019
JOS	Jarosse	tufted_vetch	2019
LFH	Lupin fourrager d’hiver	winter_fodder_lupin	2019
LFP	Lupin fourrager de printemps	spring_fodder_lupin	2019
LUZ	Luzerne	alfalfa	2019
MEL	Mélilot	melilot	2019
PFH	Pois fourrager d’hiver	winter_fodder_pea	2019
PFP	Pois fourrager de printemps	spring_fodder_pea	2019
SAI	Sainfoin	sainfoin	2019
SER	Serradelle	birds_foot	2019
TRE	Trèfle	clover	2019
VES	Vesce	common_vetch	2019
MLF	Mélange de légumineuses fourragères (entre elles)	leguminous_mix	2019
MLC	Mélange de légumineuses fourragères prépondérantes et de céréales et/ou d’oléagineux	fodder_species_mix	2019
BVF	Betterave fourragère	fodder_beetroot	2019
CAF	Carotte fourragère	fodder_carrot	2019
CHF	Chou fourrager	fodder_cabbage	2019
LEF	Lentille fourragère	fodder_lentil	2019
NVF	Navet fourrager	fodder_turnip	2019
RDF	Radis fourrager	fodder_radish	2019
FSG	Autre plante fourragère sarclée d’un autre genre	fodder_specie	2019
FAG	Autre fourrage annuel d’un autre genre	fodder_specie	2019
CPL	Fourrage composé de céréales et/ou de protéagineux (en proportion < 50%) et/ou de légumineuses fourragères (en proportion < 50%)	fodder_species_mix	2019
BRH	Bourrache de 5 ans ou moins	borage	2019
BRO	Brôme de 5 ans ou moins	bromus	2019
CRA	Cresson alénois de 5 ans ou moins	cress	2019
DTY	Dactyle de 5 ans ou moins	cocksfoot	2019
FET	Fétuque de 5 ans ou moins	fescue	2019
FLO	Fléole de 5 ans ou moins	timothy	2019
PAT	Paturin commun de 5 ans ou moins	rough_bluegrass	2019
PCL	Phacélie de 5 ans ou moins	phacelia	2019
RGA	Ray-grass de 5 ans ou moins	ryegrass	2019
XFE	X-Festulolium de 5 ans ou moins	festulolium	2019
GFP	Autre graminée fourragère pure de 5 ans ou moins	meadow	2019
MLG	Mélange de légumineuses prépondérantes et de graminées fourragères de 5 ans ou moins	meadow	2019
PTR	Autre prairie temporaire de 5 ans ou moins	meadow	2019
PRL	Prairie en rotation longue (6 ans ou plus)	meadow	2019
PPH	Prairie permanente - herbe prédominante (ressources fourragères ligneuses absentes ou peu présentes)	meadow	2019
SPH	Surface pastorale - herbe prédominante et ressources fourragères ligneuses présentes	meadow	2019
SPL	Surface pastorale - ressources fourragères ligneuses prédominantes	meadow	2019
BOP	Bois pâturé (prairie herbacée sous couvet d'arbres)	meadow	2019
CAE	Châtaigneraie entretenue par des porcins ou des petits ruminants	chesnut	2019
CEE	Chênaie entretenue par des porcins ou des petits ruminants	oak	2019
ROS	Roselière	meadow	2019
AIL	Ail	garlic	2019
ART	Artichaut	artichoke	2019
AUB	Aubergine	eggplant	2019
AVO	Avocat	avocado	2019
BTN	Betterave non fourragère / Bette	beetroot	2019
BTN	Betterave non fourragère / Bette	chard	2019
CAR	Carotte	carrot	2019
CEL	Céleri	celery	2019
CEL	Céleri	celeriac	2019
CES	Chicorée / Endive / Scarole	root_chicory	2019
CES	Chicorée / Endive / Scarole	curly_endive	2019
CES	Chicorée / Endive / Scarole	witloof	2019
CES	Chicorée / Endive / Scarole	escarole	2019
CHU	Chou	cabbage	2019
CHU	Chou	broccoli	2019
CHU	Chou	napa_cabbage	2019
CHU	Chou	brussels_sprout	2019
CHU	Chou	white_cabbage	2019
CHU	Chou	cauliflower	2019
CHU	Chou	kohlrabi	2019
CCN	Concombre / Cornichon	cucumber	2019
CCN	Concombre / Cornichon	pickle	2019
CMB	Courge musquée / Butternut	squash	2019
CMB	Courge musquée / Butternut	butternut_squash	2019
CCT	Courgette / Citrouille	zucchini	2019
CCT	Courgette / Citrouille	pumpkin	2019
CRS	Cresson	watercress	2019
EPI	Epinard	winter_spinach	2019
EPI	Epinard	spring_spinach	2019
FEV	Fève	broad_bean	2019
FRA	Fraise	strawberry	2019
HAR	Haricot / Flageolet	dried_bean	2019
HAR	Haricot / Flageolet	green_bean	2019
HAR	Haricot / Flageolet	flageolet_bean	2019
HBL	Houblon	hop	2019
LBF	Laitue / Batavia / Feuille de chêne	lettuce	2019
LBF	Laitue / Batavia / Feuille de chêne	batavia	2019
LBF	Laitue / Batavia / Feuille de chêne	oakleaf	2019
MAC	Mâche	cornsalad	2019
MLO	Melon	melon	2019
NVT	Navet	early_turnip	2019
NVT	Navet	winter_turnip	2019
OIG	Oignon / Echalotte	onion	2019
OIG	Oignon / Echalotte	shallot	2019
PAN	Panais	parsnip	2019
PAS	Pastèque	watermelon	2019
PPO	Pois (petits pois, pois cassés, pois gourmands)	pea	2019
PPO	Pois (petits pois, pois cassés, pois gourmands)	dried_pea	2019
POR	Poireau	leek	2019
PVP	Poivron / Piment	pepper	2019
PVP	Poivron / Piment	chili	2019
PTC	Pomme de terre de consommation	potato	2019
PTF	Pomme de terre féculière	potato	2019
POT	Potiron / Potimarron	sugar_pumpkin	2019
POT	Potiron / Potimarron	red_kuri	2019
RDI	Radis	radish	2019
ROQ	Roquette	rocket	2019
RUT	Rutabaga	rutabaga	2019
SFI	Salsifis	salsify	2019
TAB	Tabac	tobacco	2019
TOM	Tomate	tomato	2019
TOT	Tomate pour transformation	tomato	2019
TOP	Topinambour	jerusalem_artichoke	2019
FLA	Autre légume ou fruit annuel	annual_vegetable	2019
FLA	Autre légume ou fruit annuel	purslane	2019
FLA	Autre légume ou fruit annuel	annual_fruit	2019
FLP	Autre légume ou fruit pérenne	perennial_vegetable	2019
FLP	Autre légume ou fruit pérenne	asparagus	2019
FLP	Autre légume ou fruit pérenne	rhubarb	2019
FLP	Autre légume ou fruit pérenne	orchard	2019
AGR	Agrume	citrus	2019
AGR	Agrume	clementine	2019
AGR	Agrume	grapefruit	2019
AGR	Agrume	lemon	2019
AGR	Agrume	mandarin	2019
AGR	Agrume	orange	2019
CAB	Caroube	carob	2019
CBT	Cerise bigarreau pour transformation	cherry	2019
CTG	Châtaigne	chesnut	2019
NOS	Noisette	hazelnut	2019
NOX	Noix	walnut	2019
OLI	Oliveraie	olive	2019
PVT	Pêche Pavie pour transformation	peach	2019
PEP	Pépinière	nursery	2019
PFR	Petit fruit rouge	bilberry	2019
PFR	Petit fruit rouge	blackberry	2019
PFR	Petit fruit rouge	blackcurrant	2019
PFR	Petit fruit rouge	cranberry	2019
PFR	Petit fruit rouge	mulberry	2019
PFR	Petit fruit rouge	raspberry	2019
PFR	Petit fruit rouge	redcurrant	2019
PIS	Pistache	pistachio	2019
PWT	Poire Williams pour transformation	pear	2019
PRU	Prune d’Ente pour transformation	plum	2019
VRG	Autres vergers	orchard	2019
VRG	Autres vergers	apple	2019
VRG	Autres vergers	apricot	2019
VRG	Autres vergers	cherry	2019
VRG	Autres vergers	fig	2019
VRG	Autres vergers	kiwi	2019
VRG	Autres vergers	nectarine	2019
VRG	Autres vergers	peach	2019
VRG	Autres vergers	pear	2019
VRG	Autres vergers	persimmon	2019
VRG	Autres vergers	plum	2019
VRG	Autres vergers	quince	2019
VRC	Vigne : raisins de cuve en production	vine	2019
VRT	Vigne : raisins de table	vine	2019
VRN	Vigne : raisins de cuve non en production	vine	2019
RVI	Restructuration du vignoble	vine	2019
ANE	Aneth	dill	2019
ANG	Angélique	angelica	2019
ANI	Anis	anise	2019
BAR	Bardane	burdock	2019
BAS	Basilic	basil	2019
BLT	Bleuet	cornflower	2019
BUR	Bugle rampant	bugle	2019
CMM	Camomille	chamomile	2019
CAV	Carvi	caraway	2019
CRF	Cerfeuil	chervil	2019
CHR	Chardon Marie	marian_thistle	2019
CIB	Ciboulette	chive	2019
CRD	Coriandre	coriander	2019
CUM	Cumin	cumin	2019
EST	Estragon	tarragon	2019
FNO	Fenouil	fennel	2019
GAI	Gaillet	galium	2019
LAV	Lavande / Lavandin	lavender	2019
LAV	Lavande / Lavandin	lavandin	2019
MRG	Marguerite	oxeye_daisy	2019
MRJ	Marjolaine / Origan	marjoram	2019
MRJ	Marjolaine / Origan	oregano	2019
MAV	Mauve	mallow	2019
MLI	Mélisse	lemon_balm	2019
MTH	Menthe	mint	2019
MLP	Millepertuis	st_johns_wort	2019
OSE	Oseille	sorrel	2019
ORT	Ortie	nettle	2019
PAQ	Pâquerette	common_daisy	2019
PSE	Pensée	pansy	2019
PSL	Persil	parsley	2019
PSY	Plantain psyllium	blond_psyllium	2019
PMV	Primevère	primrose	2019
PSN	Psyllium noir de Provence	black_psyllium	2019
ROM	Romarin	rosemary	2019
SRI	Sariette	savory	2019
SGE	Sauge	sage	2019
THY	Thym	thyme	2019
VAL	Valériane	valerian	2019
VER	Véronique	speedwell	2019
PPA	Autres plantes ornementales et PPAM annuelles	annual_ornamental_plant_and_mapp	2019
PPP	Autres plantes ornementales et PPAM pérennes	perrenial_ornamental_plant_and_mapp	2019
MPA	Autre mélange de plantes fixant l’azote	leguminous_mix	2019
MCT	Miscanthus	miscanthus	2019
CSS	Culture sous serre hors sol	crop_production	2019
TCR	Taillis à courte rotation	eucalyptus	2019
TRU	Truffière (plants mycorhizés)	wood	2019
SBO	Surface boisée sur une ancienne terre agricole	wood	2019
SNE	Surface agricole temporairement non exploitée	fallow	2019
MRS	Marais salant	crop_production	2019
BFP	Bande admissible le long d’une forêt avec production	border	2019
BFS	Bande admissible le long d’une forêt sans production	border	2019
BTA	Bande tampon	border	2019
BOR	Bordure de champ	border	2019
BOR	Bordure de champ	cherry_laurel	2019
CID	Cultures conduites en interrangs : 2 cultures représentant chacune plus de 25%	interrow	2019
CIT	Cultures conduites en interrangs : 3 cultures représentant chacune plus de 25%	interrow	2019
ANA	Ananas	pineapple	2019
BCA	Banane créole (fruit et légume) - autre	banana	2019
BCF	Banane créole (fruit et légume) - fermage	banana	2019
BCI	Banane créole (fruit et légume) - indivision	banana	2019
BCP	Banane créole (fruit et légume) - propriété ou faire valoir direct	banana	2019
BCR	Banane créole (fruit et légume) - réforme foncière	banana	2019
BEA	Banane export - autre	banana	2019
BEF	Banane export - fermage	banana	2019
BEI	Banane export - indivision	banana	2019
BEP	Banane export - propriété ou faire valoir direct	banana	2019
BER	Banane export - réforme foncière	banana	2019
CAC	Café / Cacao	coffee	2019
CAC	Café / Cacao	cocoa	2019
CSA	Canne à sucre - autre	sugar_cane	2019
CSF	Canne à sucre - fermage	sugar_cane	2019
CSI	Canne à sucre - indivision	sugar_cane	2019
CSP	Canne à sucre - propriété ou faire valoir direct	sugar_cane	2019
CSR	Canne à sucre - réforme foncière	sugar_cane	2019
CUA	Culture sous abattis	crop_production	2019
CUR	Curcuma	turmeric	2019
GER	Géranium	geranium	2019
HPC	Horticulture ornementale de plein champ	annual_ornamental_plant_and_mapp	2019
HSA	Horticulture ornementale sous abri	annual_ornamental_plant_and_mapp	2019
LSA	Légume sous abri	annual_vegetable	2019
PPF	Plante à parfum (autre que géranium et vétiver)	annual_ornamental_plant_and_mapp	2019
PAR	Plante aromatique (autre que vanille)	annual_ornamental_plant_and_mapp	2019
PMD	Plante médicinale	annual_ornamental_plant_and_mapp	2019
TBT	Tubercule tropical	annual_vegetable	2019
TBT	Tubercule tropical	cassava	2019
TBT	Tubercule tropical	sweet_patato	2019
TBT	Tubercule tropical	yam	2019
VNL	Vanille	vanilla	2019
VNB	Vanille sous bois	vanilla	2019
VNV	Vanille verte	vanilla	2019
VGD	Verger (DOM)	orchard	2019
VGD	Verger (DOM)	giant_granadilla	2019
VGD	Verger (DOM)	guava	2019
VGD	Verger (DOM)	longan	2019
VET	Vétiver	vetiver	2019
YLA	Ylang-ylang	ylang_ylang	2019
ACA	Autre culture non précisée dans la liste (admissible)	crop_production	2019
ACA	Autre culture non précisée dans la liste (admissible)	cotton	2019
AVH	Avoine d’hiver	winter_oat	2020
AVP	Avoine de printemps	spring_oat	2020
BDH	Blé dur d’hiver	winter_hard_wheat	2020
BDP	Blé dur de printemps	spring_hard_wheat	2020
BTH	Blé tendre d’hiver	winter_common_wheat	2020
BTP	Blé tendre de printemps	spring_common_wheat	2020
EPE	Épeautre	spelt	2020
MID	Maïs doux	sweet_corn	2020
MIE	Maïs ensilage	silage_corn	2020
MIS	Maïs	grain_corn	2020
MLT	Millet	millet	2020
MOH	Moha	foxtail_millet	2020
ORH	Orge d'hiver	winter_barley	2020
ORP	Orge de printemps	spring_barley	2020
RIZ	Riz	rice	2020
SRS	Sarrasin	buckwheat	2020
SGH	Seigle d’hiver	winter_rye	2020
SGP	Seigle de printemps	spring_rye	2020
SOG	Sorgho	sorghum	2020
TTH	Triticale d’hiver	winter_triticale	2020
TTP	Triticale de printemps	spring_triticale	2020
CHA	Autre céréale d’hiver de genre Avena	winter_avena_cereal	2020
CHH	Autre céréale d’hiver de genre Hordeum	winter_hordeum_cereal	2020
CHS	Autre céréale d’hiver de genre Secale	winter_secale_cereal	2020
CHT	Autre céréale d’hiver de genre Triticum	winter_triticum_cereal	2020
CPA	Autre céréale de printemps de genre Avena	spring_avena_cereal	2020
CPH	Autre céréale de printemps de genre Hordeum	spring_hordeum_cereal	2020
CPS	Autre céréale de printemps de genre Secale	spring_secale_cereal	2020
CPT	Autre céréale de printemps de genre Triticum	spring_triticum_cereal	2020
CPZ	Autre céréale de printemps de genre Zea	spring_zea_cereal	2020
CGH	Autre céréale de genre Phalaris	phalaris_cereal	2020
CGP	Autre céréale de genre Panicum	panicum_cereal	2020
CGO	Autre céréale de genre Sorghum	sorghum_cereal	2020
CGS	Autre céréale de genre Setaria	setaria_cereal	2020
CGF	Autre céréale de genre Fagopyrum	fagopoyrum_cereal	2020
CAG	Autre céréale ou pseudo-céréale d’un autre genre	cereal	2020
CAG	Autre céréale ou pseudo-céréale d’un autre genre	quinoa	2020
MCR	Mélange de céréales ou pseudo-céréales pures ou mélange avec des protéagineux non prépondérants	cereal_mix	2020
MCR	Mélange de céréales ou pseudo-céréales pures ou mélange avec des protéagineux non prépondérants	fodder_species_mix	2020
CML	Cameline	camelina	2020
CZH	Colza d’hiver	winter_rape	2020
CZP	Colza de printemps	spring_rape	2020
LIH	Lin non textile d’hiver	winter_flax	2020
LIP	Lin non textile de printemps	spring_flax	2020
MOT	Moutarde	mustard	2020
NVE	Navette d’été	summer_field_mustard	2020
NVH	Navette d’hiver	winter_field_mustard	2020
NYG	Nyger	nyger	2020
OEI	Œillette (Pavot)	opium_poppy	2020
SOJ	Soja	soy	2020
TRN	Tournesol	sunflower	2020
OHN	Autre oléagineux d’hiver d’espèce Brassica napus	winter_brassica_napus_oleaginous	2020
OHR	Autre oléagineux d’hiver d’espèce Brassica rapa	winter_brassica_rapa_oleaginous	2020
OPN	Autre oléagineux de printemps d’espèce Brassica napus	spring_brassica_napus_oleaginous	2020
OPR	Autre oléagineux de printemps d’espèce Brassica rapa	spring_brassica_rapa_oleaginous	2020
OEH	Autre oléagineux d’espèce Helianthus	helianthus_oleaginous	2020
OAG	Autre oléagineux d’un autre genre	oleaginous	2020
OAG	Autre oléagineux d’un autre genre	castor_bean	2020
MOL	Mélange d’oléagineux	oleaginous_mix	2020
FVL	Féverole	winter_field_bean	2020
FVL	Féverole	spring_field_bean	2020
JOD	Jarosse déshydratée	dehydrated_tufted_vetch	2020
LDH	Lupin doux d’hiver	winter_sweet_lupin	2020
LDP	Lupin doux de printemps	spring_sweet_lupin	2020
LUD	Luzerne déshydratée	dehydrated_alfalfa	2020
MED	Mélilot déshydraté	dehydrated_melilot	2020
PHI	Pois d’hiver	winter_proteaginous_pea	2020
PPR	Pois de printemps	spring_proteaginous_pea	2020
SAD	Sainfoin déshydraté	dehydrated_sainfoin	2020
SED	Serradelle déshydratée	dehydrated_birds_foot	2020
TRD	Trèfle déshydraté	dehydrated_clover	2020
VED	Vesce déshydratée	dehydrated_common_vetch	2020
PAG	Autre protéagineux d’un autre genre	proteaginous	2020
MLD	Mélange de légumineuses déshydratées (entre elles)	leguminous_mix	2020
MPP	Mélange de protéagineux (pois et/ou lupin et/ou féverole)	proteaginous_mix	2020
MPC	Mélange de protéagineux prépondérants (pois et/ou lupin et/ou féverole) et de céréales	fodder_species_mix	2020
CHV	Chanvre	hemp	2020
LIF	Lin fibres	fiber_flax	2020
J5M	Jachère de 5 ans ou moins	fallow	2020
J6S	Jachère de 6 ans ou plus déclarée comme SIE	fallow	2020
J6P	Jachère de 6 ans ou plus	fallow	2020
JNO	Jachère noire	fallow	2020
ARA	Arachide	peanut	2020
CRN	Cornille	black_eyed_pea	2020
DOL	Dolique	catjang	2020
FNU	Fenugrec	fenugreek	2020
GES	Gesse	withe_pea	2020
LEC	Lentille cultivée (non fourragère)	fresh_lentil	2020
LEC	Lentille cultivée (non fourragère)	dried_lentil	2020
LOT	Lotier	birds_foot_trefoil	2020
MIN	Minette	black_medick	2020
PCH	Pois chiche	chickpea	2020
MLS	Mélange de légumineuses non fourragères prépondérantes et de céréales et/ou oléagineux	crop_production	2020
FFO	Féverole fourragère	winter_fodder_field_bean	2020
FFO	Féverole fourragère	spring_fodder_field_bean	2020
JOS	Jarosse	tufted_vetch	2020
LFH	Lupin fourrager d’hiver	winter_fodder_lupin	2020
LFP	Lupin fourrager de printemps	spring_fodder_lupin	2020
LUZ	Luzerne	alfalfa	2020
MEL	Mélilot	melilot	2020
PFH	Pois fourrager d’hiver	winter_fodder_pea	2020
PFP	Pois fourrager de printemps	spring_fodder_pea	2020
SAI	Sainfoin	sainfoin	2020
SER	Serradelle	birds_foot	2020
TRE	Trèfle	clover	2020
VES	Vesce	common_vetch	2020
MLF	Mélange de légumineuses fourragères (entre elles)	leguminous_mix	2020
MLC	Mélange de légumineuses fourragères prépondérantes et de céréales et/ou d’oléagineux	fodder_species_mix	2020
BVF	Betterave fourragère	fodder_beetroot	2020
CAF	Carotte fourragère	fodder_carrot	2020
CHF	Chou fourrager	fodder_cabbage	2020
LEF	Lentille fourragère	fodder_lentil	2020
NVF	Navet fourrager	fodder_turnip	2020
RDF	Radis fourrager	fodder_radish	2020
FSG	Autre plante fourragère sarclée d’un autre genre	fodder_specie	2020
FAG	Autre fourrage annuel d’un autre genre	fodder_specie	2020
CPL	Fourrage composé de céréales et/ou de protéagineux (en proportion < 50%) et/ou de légumineuses fourragères (en proportion < 50%)	fodder_species_mix	2020
BRH	Bourrache de 5 ans ou moins	borage	2020
BRO	Brôme de 5 ans ou moins	bromus	2020
CRA	Cresson alénois de 5 ans ou moins	cress	2020
DTY	Dactyle de 5 ans ou moins	cocksfoot	2020
FET	Fétuque de 5 ans ou moins	fescue	2020
FLO	Fléole de 5 ans ou moins	timothy	2020
PAT	Paturin commun de 5 ans ou moins	rough_bluegrass	2020
PCL	Phacélie de 5 ans ou moins	phacelia	2020
RGA	Ray-grass de 5 ans ou moins	ryegrass	2020
XFE	X-Festulolium de 5 ans ou moins	festulolium	2020
GFP	Autre graminée fourragère pure de 5 ans ou moins	meadow	2020
MLG	Mélange de légumineuses prépondérantes et de graminées fourragères de 5 ans ou moins	meadow	2020
PTR	Autre prairie temporaire de 5 ans ou moins	meadow	2020
PRL	Prairie en rotation longue (6 ans ou plus)	meadow	2020
PPH	Prairie permanente - herbe prédominante (ressources fourragères ligneuses absentes ou peu présentes)	meadow	2020
SPH	Surface pastorale - herbe prédominante et ressources fourragères ligneuses présentes	meadow	2020
SPL	Surface pastorale - ressources fourragères ligneuses prédominantes	meadow	2020
BOP	Bois pâturé (prairie herbacée sous couvet d'arbres)	meadow	2020
CAE	Châtaigneraie entretenue par des porcins ou des petits ruminants	chesnut	2020
CEE	Chênaie entretenue par des porcins ou des petits ruminants	oak	2020
ROS	Roselière	meadow	2020
AIL	Ail	garlic	2020
ART	Artichaut	artichoke	2020
AUB	Aubergine	eggplant	2020
AVO	Avocat	avocado	2020
BTN	Betterave non fourragère / Bette	beetroot	2020
BTN	Betterave non fourragère / Bette	chard	2020
CAR	Carotte	carrot	2020
CEL	Céleri	celery	2020
CEL	Céleri	celeriac	2020
CES	Chicorée / Endive / Scarole	root_chicory	2020
CES	Chicorée / Endive / Scarole	curly_endive	2020
CES	Chicorée / Endive / Scarole	witloof	2020
CES	Chicorée / Endive / Scarole	escarole	2020
CHU	Chou	cabbage	2020
CHU	Chou	broccoli	2020
CHU	Chou	napa_cabbage	2020
CHU	Chou	brussels_sprout	2020
CHU	Chou	white_cabbage	2020
CHU	Chou	cauliflower	2020
CHU	Chou	kohlrabi	2020
CCN	Concombre / Cornichon	cucumber	2020
CCN	Concombre / Cornichon	pickle	2020
CMB	Courge musquée / Butternut	squash	2020
CMB	Courge musquée / Butternut	butternut_squash	2020
CCT	Courgette / Citrouille	zucchini	2020
CCT	Courgette / Citrouille	pumpkin	2020
CRS	Cresson	watercress	2020
EPI	Epinard	winter_spinach	2020
EPI	Epinard	spring_spinach	2020
FEV	Fève	broad_bean	2020
FRA	Fraise	strawberry	2020
HAR	Haricot / Flageolet	dried_bean	2020
HAR	Haricot / Flageolet	green_bean	2020
HAR	Haricot / Flageolet	flageolet_bean	2020
HBL	Houblon	hop	2020
LBF	Laitue / Batavia / Feuille de chêne	lettuce	2020
LBF	Laitue / Batavia / Feuille de chêne	batavia	2020
LBF	Laitue / Batavia / Feuille de chêne	oakleaf	2020
MAC	Mâche	cornsalad	2020
MLO	Melon	melon	2020
NVT	Navet	early_turnip	2020
NVT	Navet	winter_turnip	2020
OIG	Oignon / Echalotte	onion	2020
OIG	Oignon / Echalotte	shallot	2020
PAN	Panais	parsnip	2020
PAS	Pastèque	watermelon	2020
PPO	Pois (petits pois, pois cassés, pois gourmands)	pea	2020
PPO	Pois (petits pois, pois cassés, pois gourmands)	dried_pea	2020
POR	Poireau	leek	2020
PVP	Poivron / Piment	pepper	2020
PVP	Poivron / Piment	chili	2020
PTC	Pomme de terre de consommation	potato	2020
PTF	Pomme de terre féculière	potato	2020
POT	Potiron / Potimarron	sugar_pumpkin	2020
POT	Potiron / Potimarron	red_kuri	2020
RDI	Radis	radish	2020
ROQ	Roquette	rocket	2020
RUT	Rutabaga	rutabaga	2020
SFI	Salsifis	salsify	2020
TAB	Tabac	tobacco	2020
TOM	Tomate	tomato	2020
TOT	Tomate pour transformation	tomato	2020
TOP	Topinambour	jerusalem_artichoke	2020
FLA	Autre légume ou fruit annuel	annual_vegetable	2020
FLA	Autre légume ou fruit annuel	purslane	2020
FLA	Autre légume ou fruit annuel	annual_fruit	2020
FLP	Autre légume ou fruit pérenne	perennial_vegetable	2020
FLP	Autre légume ou fruit pérenne	asparagus	2020
FLP	Autre légume ou fruit pérenne	rhubarb	2020
FLP	Autre légume ou fruit pérenne	orchard	2020
AGR	Agrume	citrus	2020
AGR	Agrume	clementine	2020
AGR	Agrume	grapefruit	2020
AGR	Agrume	lemon	2020
AGR	Agrume	mandarin	2020
AGR	Agrume	orange	2020
CAB	Caroube	carob	2020
CBT	Cerise bigarreau pour transformation	cherry	2020
CTG	Châtaigne	chesnut	2020
NOS	Noisette	hazelnut	2020
NOX	Noix	walnut	2020
OLI	Oliveraie	olive	2020
PVT	Pêche Pavie pour transformation	peach	2020
PEP	Pépinière	nursery	2020
PFR	Petit fruit rouge	bilberry	2020
PFR	Petit fruit rouge	blackberry	2020
PFR	Petit fruit rouge	blackcurrant	2020
PFR	Petit fruit rouge	cranberry	2020
PFR	Petit fruit rouge	mulberry	2020
PFR	Petit fruit rouge	raspberry	2020
PFR	Petit fruit rouge	redcurrant	2020
PIS	Pistache	pistachio	2020
PWT	Poire Williams pour transformation	pear	2020
PRU	Prune d’Ente pour transformation	plum	2020
VRG	Autres vergers	orchard	2020
VRG	Autres vergers	apple	2020
VRG	Autres vergers	apricot	2020
VRG	Autres vergers	cherry	2020
VRG	Autres vergers	fig	2020
VRG	Autres vergers	kiwi	2020
VRG	Autres vergers	nectarine	2020
VRG	Autres vergers	peach	2020
VRG	Autres vergers	pear	2020
VRG	Autres vergers	persimmon	2020
VRG	Autres vergers	plum	2020
VRG	Autres vergers	quince	2020
VRC	Vigne : raisins de cuve en production	vine	2020
VRT	Vigne : raisins de table	vine	2020
VRN	Vigne : raisins de cuve non en production	vine	2020
RVI	Restructuration du vignoble	vine	2020
ANE	Aneth	dill	2020
ANG	Angélique	angelica	2020
ANI	Anis	anise	2020
BAR	Bardane	burdock	2020
BAS	Basilic	basil	2020
BLT	Bleuet	cornflower	2020
BUR	Bugle rampant	bugle	2020
CMM	Camomille	chamomile	2020
CAV	Carvi	caraway	2020
CRF	Cerfeuil	chervil	2020
CHR	Chardon Marie	marian_thistle	2020
CIB	Ciboulette	chive	2020
CRD	Coriandre	coriander	2020
CUM	Cumin	cumin	2020
EST	Estragon	tarragon	2020
FNO	Fenouil	fennel	2020
GAI	Gaillet	galium	2020
LAV	Lavande / Lavandin	lavender	2020
LAV	Lavande / Lavandin	lavandin	2020
MRG	Marguerite	oxeye_daisy	2020
MRJ	Marjolaine / Origan	marjoram	2020
MRJ	Marjolaine / Origan	oregano	2020
MAV	Mauve	mallow	2020
MLI	Mélisse	lemon_balm	2020
MTH	Menthe	mint	2020
MLP	Millepertuis	st_johns_wort	2020
OSE	Oseille	sorrel	2020
ORT	Ortie	nettle	2020
PAQ	Pâquerette	common_daisy	2020
PSE	Pensée	pansy	2020
PSL	Persil	parsley	2020
PSY	Plantain psyllium	blond_psyllium	2020
PMV	Primevère	primrose	2020
PSN	Psyllium noir de Provence	black_psyllium	2020
ROM	Romarin	rosemary	2020
SRI	Sariette	savory	2020
SGE	Sauge	sage	2020
THY	Thym	thyme	2020
VAL	Valériane	valerian	2020
VER	Véronique	speedwell	2020
PPA	Autres plantes ornementales et PPAM annuelles	annual_ornamental_plant_and_mapp	2020
PPP	Autres plantes ornementales et PPAM pérennes	perrenial_ornamental_plant_and_mapp	2020
MPA	Autre mélange de plantes fixant l’azote	leguminous_mix	2020
MCT	Miscanthus	miscanthus	2020
CSS	Culture sous serre hors sol	crop_production	2020
TCR	Taillis à courte rotation	eucalyptus	2020
TRU	Truffière (plants mycorhizés)	wood	2020
SBO	Surface boisée sur une ancienne terre agricole	wood	2020
SNE	Surface agricole temporairement non exploitée	fallow	2020
MRS	Marais salant	crop_production	2020
BFP	Bande admissible le long d’une forêt avec production	border	2020
BFS	Bande admissible le long d’une forêt sans production	border	2020
BTA	Bande tampon	border	2020
BOR	Bordure de champ	border	2020
BOR	Bordure de champ	cherry_laurel	2020
CID	Cultures conduites en interrangs : 2 cultures représentant chacune plus de 25%	interrow	2020
CIT	Cultures conduites en interrangs : 3 cultures représentant chacune plus de 25%	interrow	2020
ANA	Ananas	pineapple	2020
BCA	Banane créole (fruit et légume) - autre	banana	2020
BCF	Banane créole (fruit et légume) - fermage	banana	2020
BCI	Banane créole (fruit et légume) - indivision	banana	2020
BCP	Banane créole (fruit et légume) - propriété ou faire valoir direct	banana	2020
BCR	Banane créole (fruit et légume) - réforme foncière	banana	2020
BEA	Banane export - autre	banana	2020
BEF	Banane export - fermage	banana	2020
BEI	Banane export - indivision	banana	2020
BEP	Banane export - propriété ou faire valoir direct	banana	2020
BER	Banane export - réforme foncière	banana	2020
CAC	Café / Cacao	coffee	2020
CAC	Café / Cacao	cocoa	2020
CSA	Canne à sucre - autre	sugar_cane	2020
CSF	Canne à sucre - fermage	sugar_cane	2020
CSI	Canne à sucre - indivision	sugar_cane	2020
CSP	Canne à sucre - propriété ou faire valoir direct	sugar_cane	2020
CSR	Canne à sucre - réforme foncière	sugar_cane	2020
CUA	Culture sous abattis	crop_production	2020
CUR	Curcuma	turmeric	2020
GER	Géranium	geranium	2020
HPC	Horticulture ornementale de plein champ	annual_ornamental_plant_and_mapp	2020
HSA	Horticulture ornementale sous abri	annual_ornamental_plant_and_mapp	2020
LSA	Légume sous abri	annual_vegetable	2020
PPF	Plante à parfum (autre que géranium et vétiver)	annual_ornamental_plant_and_mapp	2020
PAR	Plante aromatique (autre que vanille)	annual_ornamental_plant_and_mapp	2020
PMD	Plante médicinale	annual_ornamental_plant_and_mapp	2020
TBT	Tubercule tropical	annual_vegetable	2020
TBT	Tubercule tropical	cassava	2020
TBT	Tubercule tropical	sweet_patato	2020
TBT	Tubercule tropical	yam	2020
VNL	Vanille	vanilla	2020
VNB	Vanille sous bois	vanilla	2020
VGD	Verger (DOM)	orchard	2020
VGD	Verger (DOM)	giant_granadilla	2020
VGD	Verger (DOM)	guava	2020
VGD	Verger (DOM)	longan	2020
VET	Vétiver	vetiver	2020
YLA	Ylang-ylang	ylang_ylang	2020
ACA	Autre culture non précisée dans la liste (admissible)	crop_production	2020
ACA	Autre culture non précisée dans la liste (admissible)	cotton	2020
\.


--
-- Data for Name: master_crop_production_start_states; Type: TABLE DATA; Schema: lexicon__5_0_0; Owner: lexicon
--

COPY lexicon__5_0_0.master_crop_production_start_states (production, year, key) FROM stdin;
apple	1	n_1
apple	2	n_2
apple	3	n_3
apricot	1	n_1
apricot	2	n_2
apricot	3	n_3
avocado	1	n_1
avocado	2	n_2
avocado	3	n_3
banana	1	n_1
banana	2	n_2
banana	3	n_3
bilberry	1	n_1
bilberry	2	n_2
bilberry	3	n_3
birds_foot_trefoil	1	n_1
birds_foot_trefoil	2	n_2
birds_foot_trefoil	3	n_3
black_elderberry	1	n_1
black_elderberry	2	n_2
black_elderberry	3	n_3
blackberry	1	n_1
blackberry	2	n_2
blackberry	3	n_3
blackcurrant	1	n_1
blackcurrant	2	n_2
blackcurrant	3	n_3
bromus	1	n_1
bromus	2	n_2
bromus	3	n_3
caraway	1	n_1
caraway	2	n_2
caraway	3	n_3
carob	1	n_1
carob	2	n_2
carob	3	n_3
cherry	1	n_1
cherry	2	n_2
cherry	3	n_3
cherry_laurel	1	n_1
cherry_laurel	2	n_2
cherry_laurel	3	n_3
chesnut	1	n_1
chesnut	2	n_2
chesnut	3	n_3
clementine	1	n_1
clementine	2	n_2
clementine	3	n_3
clover	1	n_1
clover	2	n_2
clover	3	n_3
cocksfoot	1	n_1
cocksfoot	2	n_2
cocksfoot	3	n_3
cocoa	1	n_1
cocoa	2	n_2
cocoa	3	n_3
coffee	1	n_1
coffee	2	n_2
coffee	3	n_3
cranberry	1	n_1
cranberry	2	n_2
cranberry	3	n_3
dehydrated_clover	1	n_1
dehydrated_clover	2	n_2
dehydrated_clover	3	n_3
eucalyptus	1	n_1
eucalyptus	2	n_2
eucalyptus	3	n_3
fallow	1	n_1
fallow	2	n_2
fallow	3	n_3
fescue	1	n_1
fescue	2	n_2
fescue	3	n_3
festulolium	1	n_1
festulolium	2	n_2
festulolium	3	n_3
fig	1	n_1
fig	2	n_2
fig	3	n_3
giant_granadilla	1	n_1
giant_granadilla	2	n_2
giant_granadilla	3	n_3
grapefruit	1	n_1
grapefruit	2	n_2
grapefruit	3	n_3
guava	1	n_1
guava	2	n_2
guava	3	n_3
hazelnut	1	n_1
hazelnut	2	n_2
hazelnut	3	n_3
kiwi	1	n_1
kiwi	2	n_2
kiwi	3	n_3
lavandin	1	n_1
lavandin	2	n_2
lavandin	3	n_3
lemon	1	n_1
lemon	2	n_2
lemon	3	n_3
longan	1	n_1
longan	2	n_2
longan	3	n_3
mandarin	1	n_1
mandarin	2	n_2
mandarin	3	n_3
meadow	1	n_1
meadow	2	n_2
meadow	3	n_3
mulberry	1	n_1
mulberry	2	n_2
mulberry	3	n_3
nectarine	1	n_1
nectarine	2	n_2
nectarine	3	n_3
oak	1	n_1
oak	2	n_2
oak	3	n_3
olive	1	n_1
olive	2	n_2
olive	3	n_3
orange	1	n_1
orange	2	n_2
orange	3	n_3
orchard	1	n_1
orchard	2	n_2
orchard	3	n_3
oregano	1	n_1
oregano	2	n_2
oregano	3	n_3
peach	1	n_1
peach	2	n_2
peach	3	n_3
pear	1	n_1
pear	2	n_2
pear	3	n_3
perennial_vegetable	1	n_1
perennial_vegetable	2	n_2
perennial_vegetable	3	n_3
perrenial_ornamental_plant_and_mapp	1	n_1
perrenial_ornamental_plant_and_mapp	2	n_2
perrenial_ornamental_plant_and_mapp	3	n_3
persimmon	1	n_1
persimmon	2	n_2
persimmon	3	n_3
phacelia	1	n_1
phacelia	2	n_2
phacelia	3	n_3
pineapple	1	n_1
pineapple	2	n_2
pineapple	3	n_3
pistachio	1	n_1
pistachio	2	n_2
pistachio	3	n_3
plum	1	n_1
plum	2	n_2
plum	3	n_3
quince	1	n_1
quince	2	n_2
quince	3	n_3
raspberry	1	n_1
raspberry	2	n_2
raspberry	3	n_3
redcurrant	1	n_1
redcurrant	2	n_2
redcurrant	3	n_3
rhubarb	1	n_1
rhubarb	2	n_2
rhubarb	3	n_3
rosemary	1	n_1
rosemary	2	n_2
rosemary	3	n_3
rough_bluegrass	1	n_1
rough_bluegrass	2	n_2
rough_bluegrass	3	n_3
thyme	1	n_1
thyme	2	n_2
thyme	3	n_3
timothy	1	n_1
timothy	2	n_2
timothy	3	n_3
valerian	1	n_1
valerian	2	n_2
valerian	3	n_3
vanilla	1	n_1
vanilla	2	n_2
vanilla	3	n_3
vine	3	n_3_4_leaf
vine	2	n_2_3_leaf
vine	4	n_4_5_leaf
walnut	1	n_1
walnut	2	n_2
walnut	3	n_3
ylang_ylang	1	n_1
ylang_ylang	2	n_2
ylang_ylang	3	n_3
\.


--
-- Data for Name: master_crop_production_tfi_codes; Type: TABLE DATA; Schema: lexicon__5_0_0; Owner: lexicon
--

COPY lexicon__5_0_0.master_crop_production_tfi_codes (tfi_code, tfi_label, production, campaign) FROM stdin;
1001	Abricotier	apricot	2020
1002	Ail	garlic	2020
1003	Airelle	\N	2020
1004	Amandier	\N	2020
1197	Amarantes	\N	2020
1005	Ananas	pineapple	2020
1006	Arachide	peanut	2020
1007	Arbres et arbustes	\N	2020
1008	Artichaut	artichoke	2020
1009	Asperge	asparagus	2020
1010	Aubergine	eggplant	2020
1203	Autres agrumes	\N	2020
1012	Autres anacardiacées	\N	2020
1013	Autres choux à inflorescence	\N	2020
1014	Autres choux feuillus	\N	2020
1015	Autres choux pommés	\N	2020
1016	Autres cucurbitacées à peau comestible	\N	2020
1017	Autres cucurbitacées à peau non comestible	\N	2020
1011	Autres oignons verts	\N	2020
1018	Autres salades	\N	2020
1019	Avocatier	avocado	2020
1020	Avoine	spring_oat	2020
1020	Avoine	winter_oat	2020
1021	Azerolier	\N	2020
1022	Bananier	banana	2020
1023	Barbadines	giant_granadilla	2020
1024	Barbe de capucin	\N	2020
1025	Betterave industrielle et fourragère	fodder_beetroot	2020
1026	Betterave potagère	beetroot	2020
1027	Blé	spring_common_wheat	2020
1027	Blé	spring_hard_wheat	2020
1027	Blé	winter_common_wheat	2020
1027	Blé	spring_hard_wheat	2020
1028	Bourrache	borage	2020
1029	Brocoli	broccoli	2020
1030	Bulbes ornementaux	\N	2020
1031	Cameline	camelina	2020
1032	Canne à sucre	sugar_cane	2020
1033	Carambole	\N	2020
1034	Cardon	\N	2020
1035	Carotte	carrot	2020
1035	Carotte	fodder_carrot	2020
1201	Carthame	\N	2020
1036	Cassissier	blackcurrant	2020
1038	Céleri-branche	celery	2020
1037	Céleri rave	celeriac	2020
1039	Cerisier	cherry	2020
1040	Champignons de couche	\N	2020
1046	Champignons sauvages	\N	2020
1041	Chanvre	hemp	2020
1042	Chataignier	chesnut	2020
1198	Chènevis	\N	2020
1043	Cherimole	\N	2020
1044	Chicorée frisée	curly_endive	2020
1045	Chicorée scarole	escarole	2020
1047	Chicorées production de racines	root_chicory	2020
1048	Chou-fleur	cauliflower	2020
1049	Choux chinois	napa_cabbage	2020
1050	Choux de bruxelles	brussels_sprout	2020
1051	Choux pommés	white_cabbage	2020
1053	Choux-raves	kohlrabi	2020
1052	Choux verts type non pommés	\N	2020
1054	Ciboule	chive	2020
1055	Citronnier	lemon	2020
1056	Clémentinier	clementine	2020
1057	Cognassier	quince	2020
1058	Colza	spring_rape	2020
1058	Colza	winter_rape	2020
1059	Concombre	cucumber	2020
1060	Cornichon	pickle	2020
1061	Corossol	\N	2020
1199	Courge à graines	\N	2020
1062	Courgette	zucchini	2020
1063	Cresson alenois	cress	2020
1064	Cresson de fontaine	watercress	2020
1065	Cultures florales et plantes vertes	\N	2020
1066	Cynhorodon	\N	2020
1067	Dachine	\N	2020
1068	Échalote	shallot	2020
1069	Endive	witloof	2020
1070	Épeautre	spelt	2020
1071	Epices	\N	2020
1072	Epinard	spring_spinach	2020
1072	Epinard	winter_spinach	2020
1073	Fenouil	fennel	2020
1074	Feuilles de bette	chard	2020
1077	Feverole	spring_field_bean	2020
1077	Feverole	spring_fodder_field_bean	2020
1077	Feverole	winter_field_bean	2020
1077	Feverole	winter_fodder_field_bean	2020
1076	Fève sèche	broad_bean	2020
1078	Figuier	fig	2020
1079	Fines Herbes	\N	2020
1081	Fraisier	strawberry	2020
1082	Framboisier	raspberry	2020
1084	Fruit de la passion	\N	2020
1083	Fruit de l'arbre à pain	\N	2020
1085	Goyavier	guava	2020
1086	Graminées fourragères	\N	2020
1087	Graminées ornementales	\N	2020
1088	Grenadilles	\N	2020
1089	Groseillier	redcurrant	2020
1090	Haricot sec	dried_bean	2020
1204	Haricots écossés frais	\N	2020
1091	Haricots et pois non écossés frais	\N	2020
1093	Houblon	hop	2020
1094	Igname	yam	2020
1095	Infusions séchées	\N	2020
1096	Jachères et cultures intermédiaires	fallow	2020
1097	Jachères faunistiques fleuries	fallow	2020
1098	Jujubier	\N	2020
1195	Kaki	persimmon	2020
1099	Kiwi	kiwi	2020
1100	Laitue	lettuce	2020
1101	Lentille fraîche	fresh_lentil	2020
1102	Lentille sèche	dried_lentil	2020
1104	Limettes	\N	2020
1105	Lin	fiber_flax	2020
1105	Lin	spring_flax	2020
1105	Lin	winter_flax	2020
1106	Litchi	\N	2020
1107	Longanis	longan	2020
1108	Lotier	birds_foot_trefoil	2020
1109	Lupin	spring_fodder_lupin	2020
1109	Lupin	spring_sweet_lupin	2020
1109	Lupin	winter_fodder_lupin	2020
1109	Lupin	winter_sweet_lupin	2020
1110	Luzerne	alfalfa	2020
1110	Luzerne	dehydrated_alfalfa	2020
1111	Mâche	cornsalad	2020
1112	Maïs	grain_corn	2020
1112	Maïs	silage_corn	2020
1113	Maïs doux	sweet_corn	2020
1114	Mandarinier	mandarin	2020
1115	Manguier	\N	2020
1116	Manioc	cassava	2020
1117	Melon	melon	2020
1118	Millet	millet	2020
1119	Mirabellier	\N	2020
1120	Miscanthus	miscanthus	2020
1121	Moha	foxtail_millet	2020
1122	Moutarde	mustard	2020
1123	Mûre morus sp	mulberry	2020
1125	Mûres des haies	\N	2020
1124	Mûres rubus sp	blackberry	2020
1126	Myrtillier	bilberry	2020
1127	Nashi	\N	2020
1128	Navet	early_turnip	2020
1128	Navet	fodder_turnip	2020
1128	Navet	winter_turnip	2020
1129	Navette	summer_field_mustard	2020
1129	Navette	winter_field_mustard	2020
1130	Nectarinier	nectarine	2020
1131	Néflier	\N	2020
1133	Noisetier	hazelnut	2020
1134	Noyer	walnut	2020
1135	Oignon	onion	2020
1136	Oignon de printemps	\N	2020
1137	Olivier	olive	2020
1200	Onagre	\N	2020
1138	Oranger	orange	2020
1139	Orge	spring_barley	2020
1139	Orge	winter_barley	2020
1140	Palmiers alimentaires	\N	2020
1141	Pamplemoussier	grapefruit	2020
1142	Panais	parsnip	2020
1143	Papayer	\N	2020
1144	Pastèque	watermelon	2020
1145	Patate douce	sweet_patato	2020
1146	Pavot	\N	2020
1147	Pêcher	peach	2020
1148	Persil à grosse racine et cerfeuil tubéreux	\N	2020
1149	Piment	chili	2020
1150	Pissenlit	\N	2020
1151	Plantes d'intérieur et balcons	\N	2020
1152	Poireau	leek	2020
1153	Poirier	pear	2020
1154	Pois chiche	chickpea	2020
1155	Pois écossés frais	\N	2020
1156	Pois fourrager	spring_fodder_pea	2020
1156	Pois fourrager	winter_fodder_pea	2020
1157	Pois protéagineux	spring_proteaginous_pea	2020
1157	Pois protéagineux	winter_proteaginous_pea	2020
1159	Pois sec	dried_pea	2020
1160	Poivron	pepper	2020
1161	Pomme de terre	potato	2020
1162	Pommette	\N	2020
1163	Pommier	apple	2020
1164	Potiron	sugar_pumpkin	2020
1165	Pourpier	purslane	2020
1205	PPAMC	\N	2020
1166	PPAM - non alimentaires	\N	2020
1167	Prairies	meadow	2020
1168	Prunier	plum	2020
1196	Quinoa	quinoa	2020
1169	Radis	fodder_radish	2020
1169	Radis	radish	2020
1170	Raifort	\N	2020
1171	Ramboutan	\N	2020
1172	Rhubarbe	rhubarb	2020
1202	Ricin	castor_bean	2020
1173	Riz	rice	2020
1174	Roquette	rocket	2020
1175	Rosier	\N	2020
1176	Rutabaga	rutabaga	2020
1177	Sainfoin	dehydrated_sainfoin	2020
1177	Sainfoin	sainfoin	2020
1178	Salsifis	salsify	2020
1179	Sarrasin	buckwheat	2020
1180	Scorsonère	\N	2020
1181	Seigle	spring_rye	2020
1181	Seigle	winter_rye	2020
1182	Sésame	\N	2020
1183	Soja	soy	2020
1184	Songe	\N	2020
1185	Sorgho	sorghum	2020
1186	Sureau noir	black_elderberry	2020
1187	Tabac	tobacco	2020
1188	Tomate	tomato	2020
1189	Topinambour et crosne	jerusalem_artichoke	2020
1190	Tournesol	sunflower	2020
1191	Trèfle	clover	2020
1191	Trèfle	dehydrated_clover	2020
1192	Triticale	spring_triticale	2020
1192	Triticale	winter_triticale	2020
1193	Vesce	common_vetch	2020
1193	Vesce	dehydrated_common_vetch	2020
1194	Vigne	vine	2020
\.


--
-- PostgreSQL database dump complete
--

