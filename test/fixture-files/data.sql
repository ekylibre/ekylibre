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

COPY lexicon.ephy_cropsets (id, name, label, crop_names, crop_labels, record_checksum) FROM stdin;
3	ephy_artichoke	{"fra": "Artichaut"}	{cynara_scolymus}	{"fra": "Artichaut, cardon"}	-457872021
1	ephy_citrus	{"fra": "Agrumes"}	{citrus,poncirus}	{"fra": "Oranger, citronnier, pamplemoussier, mandarinier, clémentinier, limettes et autres agrumes"}	-2113121812
2	ephy_trees_and_shrubs	{"fra": "Arbres et arbustes"}	{acer,alnus,cercis,fraxinus,hevea,koelreuteria,robinia,salix,sambucus,rosa,castanea,ceratonia,citrus,corylus,cydonia,ficus,fortunella,juglans,malus,morus,musa,olea,prunus,pyrus,ribes,vitellaria,annona,artocarpus,chrysophyllum,mangifera,persea,pouteria,cananga,theobroma,pistacia,actinidia,coffea,crataegus,ligustrum,anacardium,argania_spinosa,berberis,betula,carica,carpinus,cinnamomum,fagus,forsythia,gleditsia,gossypium,laburnum,manilkara_zapota,palaquium,philadelphus,poncirus,psidium,quercus,tieghemella,tilia,vasconcellea_pubescens,vitex,weigela}	{"fra": "Toutes espèces ligneuses de feuillus et résineux produites en pépinières ornementales et forestières, peupleraies, oseraies, palmeraies, plantations de sapins de Noël, vergers à graines, suberaies cultivées, truffières artificielles, boisement de terrains agricoles, taillis à courte et à très courte révolution"}	-2126857547
4	ephy_wheat	{"fra": "Blé"}	{triticum,triticosecale}	{"fra": "Blé, triticale, épeautre"}	1423631094
5	ephy_ornamental_bulbs	{"fra": "Bulbes ornementaux"}	{plant}	{"fra": "Toutes espèces de plantes ornementales à bulbes, à rhizomes ou à tubercules"}	1862210495
6	ephy_carrot	{"fra": "Carotte"}	{daucus,apium_graveolens_rapaceum,pastinaca_sativa,armoracia_rusticana,helianthus_tuberosus,stachys_affinis,petroselinum_crispum_tuberosum,chaerophyllum_bulbosum,tragopogon}	{"fra": "Carotte, céleri rave, panais, raifort, topinambour et crosne, persil à grosse racine et cerfeuil tubéreux, salsifis"}	681772233
7	ephy_blackcurrant	{"fra": "Cassissier"}	{ribes,vaccinium,sambucus_nigra,morus,vaccinium,rosa,crataegus_azarolus}	{"fra": "Cassissier, myrtillier, groseillier, sureau noir, mûre (Morus sp.), airelle, cynhorodon, azerolier"}	-152429739
8	ephy_celery_branch	{"fra": "Céleri branche"}	{apium_graveolens_dulce,foeniculum,rheum}	{"fra": "Céleri branche, fenouil, rhubarbe"}	1372537450
9	ephy_celery	{"fra": "Céleris"}	{apium_graveolens_dulce,apium_graveolens_rapaceum}	{"fra": "Céleri branche, céleri rave"}	-711638082
10	ephy_cereal	{"fra": "Céréales"}	{zea_mays,panicum_miliaceum,setaria_italica,sorghum,oryza,avena,triticum,hordeum,secale_cereale,fagopyrum}	{"fra": "Avoine, blé, orge, seigle, sarrasin, maïs, millet, moha, sorgho, riz"}	2112037670
11	ephy_straw_cereals	{"fra": "Céréales à pailles"}	{avena,triticum,hordeum,secale_cereale,fagopyrum}	{"fra": "Avoine, blé, orge, seigle, sarrasin"}	-2122812950
12	ephy_fungus	{"fra": "Champignons"}	{uncinula,fomitiporia,plasmopara,saccharomyces,botrytis}	{"fra": "Champignons de couche, champignons sauvages"}	-540544795
13	ephy_chicory_endives	{"fra": "Chicorées - production de chicons"}	{taraxacum,cichorium}	{"fra": "Endive, barbe de capucin, pissenlit"}	-1958247006
14	ephy_chicory_roots	{"fra": "Chicorées - production de racines"}	{cichorium}	{"fra": "Toutes racines de chicorées"}	-524544097
15	ephy_cabbages	{"fra": "Choux"}	{brassica_oleracea_gongylodes,brassica_oleracea_botrytis,brassica_oleracea_italica,brassica_oleracea_viridis,brassica_oleracea_acephala,brassica_oleracea_medullosa,brassica_rapa_pekinensis,brassica_oleracea_capitata,brassica_oleracea_gemmifera}	{"fra": "Choux à inflorescence, choux feuillus, choux pommés, choux-rave"}	-907554257
16	ephy_inflorescence_cabbages	{"fra": "Choux à inflorescence"}	{brassica_oleracea_botrytis,brassica_oleracea_italica}	{"fra": "Chou-fleur, brocoli et autres choux à inflorescence"}	840752772
17	ephy_leafy_cabbages	{"fra": "Choux feuillus"}	{brassica_oleracea_viridis,brassica_oleracea_acephala,brassica_oleracea_medullosa,brassica_rapa_pekinensis}	{"fra": "Choux verts (type non pommés), choux chinois et autres choux feuillus"}	-374394074
18	ephy_headed_cabbages	{"fra": "Choux pommés"}	{brassica_oleracea_capitata,brassica_oleracea_gemmifera}	{"fra": "Choux pommés, choux de Bruxelles et autres choux pommés"}	-415849264
19	ephy_cucumber	{"fra": "Concombre"}	{cucumis_sativus,cucurbita_pepo_pepo,cucumis_anguria}	{"fra": "Concombre, courgette, cornichon et autres cucurbitacées à peau comestible"}	-721813725
20	ephy_soursop	{"fra": "Corossol"}	{annona_cherimola}	{"fra": "Corossol, cherimole, fruit de l arbre à pain"}	2085429829
21	ephy_oilseed_crucifers	{"fra": "Crucifères oléagineuses"}	{brassica_napus,camelina_sativa,brassica_nigra,brassica_rapa_oleifera,cannabis,borago,linum}	{"fra": "Colza, cameline, moutarde, navette, chanvre, bourrache, sésame, lin oléagineux, lin fibre"}	55997914
22	ephy_floral_crops_and_green_plants	{"fra": "Cultures florales et plantes vertes"}	{rosa,hibiscus,viburnum,viola,centaurea_cyanus,passiflora,bellis,forsythia,geranium,humulus,lavandula,philadelphus,spiraea}	{"fra": "Toutes espèces de plantes florales et de plantes vertes : potées fleuries, plantes à massifs, vivaces, fleurs et feuillages coupés, jeunes plants et boutures, y compris les espèces de plantes géophytes à bulbes, rhizomes ou tubercules ornementaux (pendant leur phase végétative)"}	-2006482234
23	ephy_fruit_crops	{"fra": "Cultures fruitières"}	{castanea,ceratonia,citrus,corylus,cydonia,ficus,fortunella,juglans,malus,morus,musa,olea,prunus,pyrus,ribes,vitellaria,annona,artocarpus,chrysophyllum,mangifera,persea,pouteria,citrullus_colocynthis,citrullus_lanatus,cucumis_melo,fragaria,pistacia,actinidia,ananas,cucumis_metuliferus,hippophae,solanum_muricatum,vitis,carica,dimocarpus_longan,manilkara_zapota,poncirus,psidium,solanum_quitoense,vasconcellea_pubescens}	{"fra": "Toutes cultures fruitières et petits fruits (cassissier, myrtillier, groseillier, sureau noir, airelle, cynhorodon, azerolier, framboisier, mûre, mûre des haies)"}	-1309718315
24	ephy_vegetable_crops	{"fra": "Cultures légumières"}	{apium,arctium,asparagus,beta_vulgaris,brassica_oleracea,brassica_rapa,cucumis_sativus,cucurbita,cynara_scolymus,daucus_carota,dioscorea,manihot,ipomoea_batatas,foeniculum,lactuca,pastinaca_sativa,phaseolus_vulgaris,pisum_sativum,raphanus_sativus,solanum_lycopersicum,solanum_melongena,solanum_torvum,solanum_tuberosum,spinacia_oleracea,valerianella_locusta,solanum_torvum,crambe_maritima,lathyrus_sativus}	{"fra": "Toutes cultures légumières"}	179267868
25	ephy_ornamental_crops	{"fra": "Cultures ornementales"}	{acer,alnus,cercis,fraxinus,hevea,koelreuteria,robinia,salix,sambucus,rosa,castanea,ceratonia,citrus,corylus,cydonia,ficus,fortunella,juglans,malus,morus,musa,olea,prunus,pyrus,ribes,vitellaria,annona,artocarpus,chrysophyllum,mangifera,persea,pouteria,cananga,theobroma,pistacia,actinidia,coffea,crataegus,ligustrum,anacardium,argania_spinosa,berberis,betula,carica,carpinus,cinnamomum,fagus,forsythia,gleditsia,gossypium,laburnum,manilkara_zapota,palaquium,philadelphus,poncirus,psidium,quercus,tieghemella,tilia,vasconcellea_pubescens,vitex,weigela,hibiscus,viburnum,viola,centaurea_cyanus,passiflora,bellis,geranium,humulus,lavandula,spiraea,carum_carvi,anethum,anthriscus,artemisia,coriandrum,curcuma,ocimum,origanum,petroselinum,salvia,vanilla,brassica_nigra,allium_schoenoprasum,thymus,satureja,mentha,arctium,crocus_sativus,capsicum_baccatum,lepidium_sativum,malva_sylvestris,rumex,silybum,origanum,hypericum,nicotiana,valeriana}	{"fra": "Arbres et arbustes, rosier, cultures florales et plantes vertes, bulbes ornementaux"}	-1925156313
26	ephy_tropical_crops	{"fra": "Cultures tropicales"}	{annona,artocarpus,chrysophyllum,mangifera,persea,pouteria,theobroma,vanilla,citrullus_colocynthis,actinidia,ananas,dioscorea,manihot,ipomoea_batatas,coffea,cucumis_metuliferus,saccharum_officinarum,anacardium,carica,manilkara_zapota,psidium,tieghemella,vasconcellea_pubescens}	{"fra": "Toutes cultures tropicales"}	538501000
27	ephy_spinach	{"fra": "Epinard"}	{spinacia_oleracea,beta_vulgaris}	{"fra": "Epinard, feuilles de bette, pourpier, salicorne"}	760540767
28	ephy_herbs	{"fra": "Fines herbes"}	{carum_carvi,foeniculum,allium_schoenoprasum,rosa,cananga,anethum,anthriscus,artemisia,coriandrum,curcuma,ocimum,origanum,petroselinum,salvia,vanilla,brassica_nigra,thymus,satureja,mentha,crataegus,centaurea_cyanus,crataegus,lepidium_sativum,malva_sylvestris,silybum,hypericum,nicotiana,passiflora,lavandula,valeriana}	{"fra": "Plantes alliacées dont ciboulette. Plantes apiacées dont aneth, persil, cerfeuil, feuilles de fenouil, angélique, carvi. Plantes astéracées dont estragon, stevia. Plantes lamiacées dont basilic, thym, sauge, sarriette, origan, marjolaine, hysope, menthe. Autres plantes condimentaires, fines herbes consommées fraîches, fleurs comestibles et PPAM non alimentaires"}	-1561021659
29	ephy_forest	{"fra": "Forêt"}	{acer,alnus,fraxinus,hevea,koelreuteria,robinia,salix,sambucus,betula,carpinus,cinnamomum,fagus,gleditsia,quercus,tieghemella,tilia}	{"fra": "Espèces d arbres feuillus et résineux en peuplements"}	257911741
30	ephy_raspberry_brush	{"fra": "Framboisier"}	{rubus}	{"fra": "Framboisier, mûres (Rubus sp.), mûres des haies"}	439258896
31	ephy_passion_fruit	{"fra": "Fruit de la passion"}	{plant}	{"fra": "Fruit de la passion, grenadilles, barbadines"}	-1027517207
32	ephy_nut	{"fra": "Fruits à coque"}	{prunus_dulcis,juglans,castanea,corylus}	{"fra": "Amandier, noyer, châtaignier, noisetier"}	1707908418
33	ephy_stone_fruit	{"fra": "Fruits à noyau"}	{prunus}	{"fra": "Pêcher, abricotier, cerisier, prunier, nectarinier, mirabellier"}	880459823
34	ephy_grasses_turf	{"fra": "Gazons de graminées"}	{dactylis,lolium,festuca,poa}	{"fra": "Toutes espèces de graminées, comme dactyle, fétuque utilisées pour la création de gazons"}	-2015606993
35	ephy_protein_seeds	{"fra": "Graines protéagineuses"}	{pisum_sativum,vicia_faba,lupinus}	{"fra": "Pois protéagineux, pois fourrager, féveroles, lupin"}	-675748674
36	ephy_forage_grasses	{"fra": "Graminées fourragères"}	{dactylis,lolium,festuca,bromus,phleum,chloris_gayana,poa}	{"fra": "Toutes espèces de graminées comme ray-grass, fétuque, brome, fléole pour produire du fourrage destiné à l alimentation du bétail"}	-2054268783
37	ephy_shelled_beans	{"fra": "Haricots écossés (frais)"}	{vicia_faba,vigna_unguiculata}	{"fra": "Pois sabre, flageolet, fève, lima, niébé"}	195602603
38	ephy_unshelled_beans_and_peas	{"fra": "Haricots et pois non écossés (frais)"}	{phaseolus_vulgaris}	{"fra": "Haricot vert, haricot filet, haricot d Espagne, haricot à couper, dolique, fèves de soja, pois mange-tout"}	153767982
39	ephy_infusions	{"fra": "Infusions (séchées)"}	{rosa,cananga,hibiscus,thymus,salvia,anethum,ocimum,origanum,petroselinum,mentha,centaurea_cyanus,crataegus,malva_sylvestris,silybum,hypericum,nicotiana,passiflora,lavandula,tilia,valeriana}	{"fra": "Plantes ou parties de plantes à infusion séchées (fleurs, feuilles, racines) ainsi que les PPAM non alimentaires"}	883995916
40	ephy_lettuce	{"fra": "Laitue"}	{lactuca,cichorium_endivia_latifolium,cichorium_endivia_crispum,valerianella_locusta,eruca_vesicaria}	{"fra": "Laitue, chicorée - scarole, chicorée - frisée, mâche, roquette et autres salades"}	462999587
41	ephy_root_vegetables_and_tropical_tubers	{"fra": "Légumes racines et tubercules tropicaux"}	{dioscorea,manihot,ipomoea_batatas}	{"fra": "Igname, manioc, patate douce, songe, dachine"}	-1733659534
42	ephy_fodder_legumes	{"fra": "Légumineuses fourragères"}	{lotus_corniculatus,medicago,onobrychis,trifolium,vicia,melilotus}	{"fra": "Lotier, luzerne, sainfoin, trèfle, vesce"}	1672576334
43	ephy_legume_vegetables	{"fra": "Légumineuses potagères (sèches)"}	{cicer_arietinum,lens,chenopodium_quinoa}	{"fra": "Fève sèche, haricot sec, pois sec, pois chiche et lentille sèche"}	-758467177
44	ephy_lychee	{"fra": "Litchi"}	{dimocarpus_longan}	{"fra": "Litchi, ramboutan, longanis"}	1136554231
45	ephy_corn	{"fra": "Maïs"}	{zea_mays,panicum_miliaceum,miscanthus,panicum,sorghum}	{"fra": "Maïs, millet, moha, miscanthus, panic (dont Switchgrass), sorgho"}	-756673372
46	ephy_mango_tree	{"fra": "Manguier"}	{anacardiaceae}	{"fra": "Manguier et autres anacardiacées"}	-1734457043
47	ephy_melon	{"fra": "Melon"}	{cucumis_melo,citrullus,cucurbita,cucumis_metuliferus}	{"fra": "Melon, pastèque, potiron et autres cucurbitacées à peau non comestible"}	-285197453
48	ephy_turnip	{"fra": "Navet"}	{brassica_rapa_rapa,brassica_napus_rapifera,raphanus_sativus}	{"fra": "Navet, rutabaga, radis"}	-40279790
49	ephy_onion	{"fra": "Oignon"}	{allium_cepa,allium_sativum,allium_oleraceum,allium_scorodoprasum,allium_tricoccum,allium_triquetrum,allium_ursinum,allium_victorialis,allium_vineale,allium_ascalonicum,allium_triquetrum}	{"fra": "Oignon, ail, échalote et bulbes ornementaux"}	677623868
50	ephy_poppy	{"fra": "Pavot"}	{papaver,borago,cucurbita,ricinus,rosa,cananga,centaurea_cyanus,crataegus,malva_sylvestris,silybum,hypericum,nicotiana,passiflora,lavandula,valeriana}	{"fra": "Pavot, œillette, bourrache, chènevis, courges à graines, onagre, carthame, sésame, ricin ainsi que les PPAM non alimentaires"}	1316423413
51	ephy_peach_tree	{"fra": "Pêcher"}	{prunus_persica,prunus_armeniaca}	{"fra": "Pêcher, abricotier, nectarinier"}	-1875683210
52	ephy_small_fruits	{"fra": "Petits fruits"}	{ribes,vaccinium,sambucus_nigra,morus,vaccinium,rosa,crataegus_azarolus,rubus}	{"fra": "Cassissier, myrtillier, groseillier, sureau noir, airelle, cynhorodon, azerolier, framboisier, mûre, mûre des haies"}	-338460346
53	ephy_house_and_balcony_plants	{"fra": "Plantes d intérieur et balcons"}	{plant}	{"fra": "Plantes ou parties de plantes en place dans les habitations, locaux de travail ou tous lieux fermés publics ou privés, et sur balcons, vérandas et terrasses directement raccordés aux intérieurs"}	1885939472
54	ephy_leek	{"fra": "Poireau"}	{allium_porrum,allium_cepa,allium_ampeloprasum}	{"fra": "Poireau, oignon de printemps, ciboule et autres oignons verts"}	-309367489
55	ephy_pea_without_pods	{"fra": "Pois écossés (frais)"}	{pisum_sativum,lens}	{"fra": "Pois écossé frais et lentille fraîche"}	-1405127891
56	ephy_pepper	{"fra": "Poivron"}	{capsicum}	{"fra": "Poivron, piment"}	705523124
57	ephy_apple_tree	{"fra": "Pommier"}	{malus,pyrus,cydonia_oblonga}	{"fra": "Pommier, poirier, cognassier, néflier, nashi, pommette (Malus sylvestris)"}	-1664800223
58	ephy_seed_pamcp	{"fra": "Porte graine - PPAMC, florales et potagères"}	{plant}	{"fra": "Toute plante destinée à la production de semences de PPAMC, florales ou potagères"}	-1744899220
59	ephy_pamp	{"fra": "PPAM - non alimentaires"}	{rosa,cananga,centaurea_cyanus,crataegus,malva_sylvestris,silybum,hypericum,nicotiana,passiflora,lavandula,valeriana}	{"fra": "Plantes à parfum, aromatiques et médicinales, non alimentaires"}	667549493
60	ephy_pamcp	{"fra": "PPAMC"}	{carum_carvi,rosa,cananga,anethum,anthriscus,artemisia,coriandrum,curcuma,ocimum,origanum,petroselinum,salvia,vanilla,brassica_nigra,allium_schoenoprasum,thymus,satureja,mentha,arctium,centaurea_cyanus,crataegus,crocus_sativus,capsicum_baccatum,lepidium_sativum,malva_sylvestris,rumex,silybum,origanum,hypericum,nicotiana,passiflora,lavandula,tilia,valeriana}	{"fra": "Plantes à parfum, aromatiques, médicinales et condimentaires (alimentaires et non alimentaires), épices, fines herbes, infusions séchées, pavot"}	1580590449
61	ephy_plum_tree	{"fra": "Prunier"}	{prunus}	{"fra": "Prunier, jujubier"}	-230245663
62	ephy_rosebush	{"fra": "Rosier"}	{rosa}	{"fra": "Toutes espèces et cultivars du genre Rosa : rosiers miniatures en pot, rosiers pour fleurs coupées, rosiers de pépinières y compris les porte-greffes."}	1390906472
63	ephy_salsify	{"fra": "Salsifis"}	{tragopogon}	{"fra": "Salsifis, scorsonère"}	-1605803195
64	ephy_soy	{"fra": "Soja"}	{glycine_max,arachis}	{"fra": "Soja, arachide"}	-158384832
65	ephy_tomato	{"fra": "Tomate"}	{solanum_lycopersicum,solanum_melongena}	{"fra": "Tomate, aubergine"}	235234460
\.

COPY lexicon.registered_phytosanitary_products (id, reference_name, name, other_name, nature, active_compounds, france_maaid, mix_category_code, in_field_reentry_delay, state, started_on, stopped_on, allowed_mentions, restricted_mentions, operator_protection_mentions, firm_name, product_type, record_checksum) FROM stdin;
7200298	7200298_extravon	EXTRAVON	AGRAL MAXX | AGRAM MAXX	Adjuv. Fongicide | Adjuv. Insecticide | Adjuv. Herbicide	Octylphenol octaglycol ether 250.0 g/L	7200298	1	24	RETIRE	1972-12-01	2019-04-27	\N	\N	• pendant le mélange/chargement \n- Gants en nitrile certifiés EN 374-3 ; \n- Combinaison de travail en polyester 65 %/coton 35 % avec un grammage de 230 g/m2 ou plus avec traitement déperlant ; \n- EPI partiel (blouse ou tablier à manches longues) de catégorie III et de type PB (3) à porter par dessus la combinaison précitée ; \n- Lunettes ou écran facial certifié norme EN 166 (CE, sigle 3); \n• pendant l'application - Pulvérisation vers le bas \nSi application avec tracteur avec cabine \n- Combinaison de travail en polyester 65 %/coton 35 % avec un grammage de 230 g/m2 ou plus avec traitement déperlant ; \n- Gants en nitrile certifiés EN 374-2 à usage unique, dans le cas d'une intervention sur le matériel pendant la phase de pulvérisation. Dans ce cas, les gants ne doivent être portés qu'à l'extérieur de la cabine et doivent être stockés après utilisation à l'extérieur de la cabine ; \nSi application avec tracteur sans cabine \n- Combinaison de travail en polyester 65 %/coton 35 % avec un grammage de 230 g/m2 ou plus avec traitement déperlant ; \n- Gants en nitrile certifiés EN 374-2 à usage unique, dans le cas d'une intervention sur le matériel pendant la phase de pulvérisation ; \n• pendant le nettoyage du matériel de pulvérisation \n- Gants en nitrile certifiés EN 374-3 ; \n- Combinaison de travail en polyester 65 %/coton 35 % avec un grammage de 230 g/m2 ou plus avec traitement déperlant ; \n- EPI partiel (blouse ou tablier à manches longues) de catégorie III et de type PB (3) à porter par dessus la combinaison précitée.\n- Lunettes ou écran facial certifié norme EN 166 (CE, sigle 3).	SYNGENTA FRANCE SAS	ADJUVANT	1207320650
2160478	2160478_slider	SLIDER	\N	Adjuvant	Ammonium sulphate 460.0 g/L	2160478	1	8	AUTORISE	2016-07-22	\N	\N	\N	Dans le cadre d'une application effectuée à l'aide d'un pulvérisateur à rampe\nPendant le mélange/chargement\n- Gants en nitrile certifiés EN 374-3 ;\n- Combinaison de travail en polyester 65 %/coton 35 % avec un grammage de 230 g/m² ou plus avec traitement déperlant ;\n- EPI partiel (blouse ou tablier à manches longues) de catégorie III et de type PB (3) à porter par-dessus la combinaison précitée ;\n- Lunettes ou écran facial certifié norme EN 166 (CE, sigle 3).\nPendant l'application - Pulvérisation vers le bas\nSi application avec tracteur avec cabine\n- Combinaison de travail en polyester 65 %/coton 35 % avec un grammage de 230 g/m² ou plus avec traitement déperlant ;\n- Gants en nitrile certifiés EN 374-2 à usage unique, dans le cas d'une intervention sur le matériel pendant la phase de pulvérisation. Dans ce cas, les gants ne doivent être portés qu'à l'extérieur de la cabine et doivent être stockés après utilisation à l'extérieur de la cabine.\nSi application avec tracteur sans cabine\n- Combinaison de travail en polyester 65 %/coton 35 % avec un grammage de 230 g/m² ou plus avec traitement déperlant ;\n- Gants en nitrile certifiés EN 374-2 à usage unique, dans le cas d'une intervention sur le matériel pendant la phase de pulvérisation ;\n- En cas d'exposition aux gouttelettes pulvérisées, porter un demi-masque filtrant à particules (EN 149) ou un demi-masque (EN 140) équipé d'un filtre à particules P3 (EN 143) ;\n- Lunettes ou écran facial certifié norme EN 166 (CE, sigle 3) ;\nPendant le nettoyage du matériel de pulvérisation\n- Gants en nitrile certifiés EN 374-3 ;\n- Combinaison de travail en polyester 65 %/coton 35 % avec un grammage de 230 g/m² ou plus avec traitement déperlant ;\n- EPI partiel (blouse ou tablier à manches longues) de catégorie III et de type PB (3) à porter par-dessus la combinaison précitée ;\n- Lunettes ou écran facial certifié norme EN 166 (CE, sigle 3) .	JOUFFRAY DRILLAUD	ADJUVANT	1628246832
2000235	2000235_silwet_l_77	SILWET L 77	PULVI-X	Adjuv. Fongicide | Adjuv. Herbicide	Heptamethyltrisiloxane modifie polyalkyleneoxide 60.38 g/L | Heptamethyltrisiloxane modifie polyalkyleneoxide 785.5 g/L	2000235	1	24	AUTORISE	2003-02-07	\N	\N	\N	Dans le cadre d'une application avec pulvérisateur à rampe :\n• pendant le mélange/chargement\n- Gants en nitrile certifiés EN 374-3 ;\n- Combinaison de travail en polyester 65 %/coton 35 % avec un grammage de 230 g/m² ou plus avec traitement déperlant ;\n- EPI partiel (blouse ou tablier à manches longues) de catégorie III et de type PB (3) à porter par-dessus la combinaison précitée ;\n• pendant l'application - Pulvérisation vers le bas\nSi application avec tracteur avec cabine\n- Combinaison de travail en polyester 65 %/coton 35 % avec un grammage de 230 g/m² ou plus avec traitement déperlant ;\n- Gants en nitrile certifiés EN 374-2 à usage unique, dans le cas d'une intervention sur le matériel pendant la phase de pulvérisation. Dans ce cas, les gants ne doivent être portés qu'à l'extérieur de la cabine et doivent être stockés après utilisation à l'extérieur de la cabine ;\nSi application avec tracteur sans cabine\n- Combinaison de travail en polyester 65 %/coton 35 % avec un grammage de 230 g/m² ou plus avec traitement déperlant ;\n- Gants en nitrile certifiés EN 374-2 à usage unique, dans le cas d'une intervention sur le matériel pendant la phase de pulvérisation ;\n• pendant le nettoyage du matériel de pulvérisation\n- Gants en nitrile certifiés EN 374-3 ;\n- Combinaison de travail en polyester 65 %/coton 35 % avec un grammage de 230 g/m² ou plus avec traitement déperlant ;\n- EPI partiel (blouse ou tablier à manches longues) de catégorie III et de type PB (3) à porter par-dessus la combinaison précitée ;	DE SANGOSSE	ADJUVANT	-1962963314
\.

COPY lexicon.registered_phytosanitary_usages (id, product_id, ephy_usage_phrase, crop, species, target_name, description, treatment, dose_quantity, dose_unit, dose_unit_name, dose_unit_factor, pre_harvest_delay, pre_harvest_delay_bbch, applications_count, applications_frequency, development_stage_min, development_stage_max, usage_conditions, untreated_buffer_aquatic, untreated_buffer_arthropod, untreated_buffer_plants, decision_date, state, record_checksum) FROM stdin;
20151012160519370333	7200298	Adjuvants*Bouil. Fongicide	{"fra": "Adjuvants"}	{plant}	{"fra": "Bouil. Fongicide"}	\N	\N	0.0500	centiliter_per_liter	L/hL	1	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	2017-10-27	Retrait	-1209918418
20151012160522378385	7200298	Adjuvants*Bouil. Herbicide	{"fra": "Adjuvants"}	{plant}	{"fra": "Bouil. Herbicide"}	\N	\N	0.0500	centiliter_per_liter	L/hL	1	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	2017-10-27	Retrait	1611657037
20151012160524727437	7200298	Adjuvants*Bouil. Insecticide	{"fra": "Adjuvants"}	{plant}	{"fra": "Bouil. Insecticide"}	\N	\N	0.0500	centiliter_per_liter	L/hL	1	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	2017-10-27	Retrait	720889187
20160712164039054134	2160478	Adjuvants*Bouil. Herbicide	{"fra": "Adjuvants"}	{plant}	{"fra": "Bouil. Herbicide"}	\N	\N	1.0000	centiliter_per_liter	L/hL	1	3	\N	\N	\N	\N	\N	- Non autorisé sur légumes "feuilles" et "tige" et uniquement avant apparition des parties consommables des végétaux traités.\n- Dose maximale d'application : 1L/hL dans un volume de bouillie de 100 à 400 L/ha.\n- Amélioration de la pénétration (humectant, correcteur d'eau)\n- Nombre d'application/stade d'application/délai avant récolte/zones non traitées : selon les préparations phytopharmaceutiques associées et dans les conditions d'emploi générales décrites pour la préparation adjuvante.	5	\N	\N	2016-07-22	Autorisé	1887571745
20151015175614214387	2000235	Adjuvants*Bouil. Fongicide	{"fra": "Adjuvants"}	{plant}	{"fra": "Bouil. Fongicide"}	\N	\N	0.1500	liter_per_hectare	L/ha	1	48	\N	1	\N	\N	\N	Uniquement sur blé, orge, avoine, sorgho, millet, maïs, betterave sucrière et colza.\nVolume maximal de bouillie : 200 L/ha.\nStades d'application / délai avant récolte / zones non traitées : selon les produits phytopharmaceutiques associés et dans les conditions d'emploi générales décrites pour l'adjuvant.	5	\N	\N	2014-02-27	Autorisé	-174537941
20151015175614270440	2000235	Adjuvants*Bouil. Herbicide	{"fra": "Adjuvants"}	{plant}	{"fra": "Bouil. Herbicide"}	\N	\N	0.1000	liter_per_hectare	L/ha	1	56	\N	2	\N	\N	\N	Uniquement sur seigle.\nVolume maximal de bouillie : 200 L/ha.\nStades d'application / délai avant récolte / zones non traitées : selon les produits phytopharmaceutiques associés et dans les conditions d'emploi générales décrites pour l'adjuvant.	5	\N	\N	2009-03-01	Autorisé	-111444982
20180730173523725925	2000235	Adjuvants*Bouil. Fongicide	{"fra": "Adjuvants"}	{plant}	{"fra": "Bouil. Fongicide"}	\N	\N	0.1500	liter_per_hectare	L/ha	1	56	\N	1	\N	\N	\N	Uniquement sur seigle.\nVolume maximal de bouillie : 200 L/ha.\nStades d'application / délai avant récolte / zones non traitées : selon les produits phytopharmaceutiques associés et dans les conditions d'emploi générales décrites pour l'adjuvant.	5	\N	\N	\N	Autorisé	-961565573
20180730175223584018	2000235	Adjuvants*Bouil. Herbicide	{"fra": "Adjuvants"}	{plant}	{"fra": "Bouil. Herbicide"}	\N	\N	0.1000	liter_per_hectare	L/ha	1	48	\N	2	\N	\N	\N	Uniquement sur blé, orge, avoine, sorgho, millet, maïs, betterave sucrière et colza.\nVolume maximal de bouillie : 200 L/ha.\nStades d'application / délai avant récolte / zones non traitées : selon les produits phytopharmaceutiques associés et dans les conditions d'emploi générales décrites pour l'adjuvant.	5	\N	\N	\N	Autorisé	736878373
\.

COPY lexicon.registered_phytosanitary_risks (product_id, risk_code, risk_phrase, record_checksum) FROM stdin;
7200298	H318	Provoque des lésions oculaires graves	-867535879
2160478	H411	Toxique pour les organismes aquatiques, entraîne des effets à long terme	-151460045
2000235	H319	Provoque une sévère irritation des yeux	161223406
2000235	H332	Nocif par inhalation	700150670
2000235	H411	Toxique pour les organismes aquatiques, entraîne des effets à long terme	-720684058
\.

COPY lexicon.variant_natures (id, reference_name, name, label_fra, nature, population_counting, indicators, abilities, variety, derivative_of) FROM stdin;
1	acidifier	{"fra": "Acidifiant"}	Acidifiant	article	decimal	{net_mass,net_volume}	{acidify(fermented_juice)}	matter	
2	agricultural_service	{"fra": "Prestation de service agricole"}	Prestation de service agricole	fee_and_service	decimal	{usage_duration,net_surface_area,net_mass,net_volume,members_count}	{}	service	
3	air_compressor	{"fra": "Compresseur"}	Compresseur	equipment	unitary	{motor_power,nominal_storable_net_volume}	{blow}	equipment	
11	bird_band	{"fra": "Groupe d'oiseaux"}	Groupe d'oiseaux	animal	integer	{reproductor,sex}	{move,consume(water),consume(plant),consume(preparation),produce(excrement),produce(egg)}	animal	aves
12	zone	{"fra": "Zone"}	Zone	zone	unitary	{net_surface_area,nominal_storable_net_mass,nominal_storable_net_volume,shape}	{store(matter)}	zone	
21	crop	{"fra": "Culture"}	Culture	crop	decimal	{certification,fresh_mass,plants_count,plants_interval,plant_life_state,plant_reproduction_state,shape,tiller_count,rows_interval}	{consume(water),consume(preparation),produce(grain),produce(straw),produce(flower),produce(fruit),produce(vegetable)}	plant	plant
27	fee_and_external_service	{"fra": "Frais et service extérieur"}	Frais et service extérieur	fee_and_service	decimal	{}	{}	service	
54	material	{"fra": "Matériel"}	Matériel	article	decimal	{diameter,height,length}	{}	matter	
64	organic_fertilizer	{"fra": "Engrais organique"}	Engrais organique	article	decimal	{net_mass,net_volume,mass_volume_density,nitrogen_concentration,phosphorus_concentration,potassium_concentration,sulfur_dioxide_concentration,magnesium_concentration,manganese_concentration,calcium_concentration,zinc_concentration,sodium_concentration,copper_concentration}	{fertilize}	matter	animal
69	plant_medicine	{"fra": "Produit phytosanitaire"}	Produit phytosanitaire	article	decimal	{net_mass,net_volume,approved_input_dose,untreated_zone_length,wait_before_entering_period,wait_before_harvest_period}	{care(plant)}	preparation	
79	seed	{"fra": "Semence"}	Semence	article	decimal	{thousand_grains_mass}	{grow}	matter	plant
106	water_spreader	{"fra": "Pulvérisateur d'eau"}	Pulvérisateur d'eau	equipment	unitary	{application_width,diameter,length,volume_flow,spans_count}	{spread(water)}	equipment	
111	worker	{"fra": "Travailleur"}	Travailleur	worker	unitary	{}	{drive(equipment),move,milk(mammalia),repair(equipment),administer_care(animal)}	worker	
\.

COPY lexicon.variant_categories (id, reference_name, name, label_fra, nature, fixed_asset_account, fixed_asset_allocation_account, fixed_asset_expenses_account, depreciation_percentage, purchase_account, sale_account, stock_account, stock_movement_account, purchasable, saleable, depreciable, storable, default_vat_rate, payment_frequency_value, payment_frequency_unit) FROM stdin;
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

COPY lexicon.variants (id, class_name, reference_name, name, label_fra, category, nature, sub_nature, default_unit, target_specie, specie, eu_product_code, indicators, variant_category_id, variant_nature_id) FROM stdin;
E27	equipment	hose_reel	{"fra": "Enrouleur"}	Enrouleur	equipment	water_spreader	\N	unity	\N	\N	\N	\N	26	106
A101	article	stake	{"fra": "Piquet"}	Piquet	material	material		unity				{}	53	54
A23	article	soft_wheat_herbicide	{"fra": "Herbicide pour blé tendre"}	Herbicide pour blé tendre	plant_medicine	plant_medicine	plant_medicine	liter	triticum_aestivum			{}	68	69
AFO58	article	horse_manure	{"fra": "Fumier de chevaux"}	Fumier de chevaux	fertilizer	organic_fertilizer	fertilizer	ton	\N	equus	\N	{"nitrogen_concentration": "0.82percent"}	33	64
S1	fee_and_service	additional_activity	{"fra": "Activité annexe"}	Activité annexe	additional_activity	fee_and_external_service	\N	unity	\N	\N	\N	\N	1	27
D1	worker	permanent	{"fra": "CDI"}	CDI	permanent_worker	worker	\N	hour	\N	\N	\N	\N	67	111
A4	article	soft_wheat_seed	{"fra": "Semence de blé tendre"}	Semence de blé tendre	seed_and_plant	seed	seed_and_plant	kilogram	triticum_aestivum	triticum_aestivum		{"thousand_grains_mass": "50.0gram"}	76	79
\.

--
-- PostgreSQL database dump complete
--

