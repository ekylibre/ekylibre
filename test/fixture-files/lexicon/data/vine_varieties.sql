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
-- Data for Name: registered_vine_varieties; Type: TABLE DATA; Schema: lexicon__5_0_0; Owner: lexicon
--

COPY lexicon__5_0_0.registered_vine_varieties (id, short_name, long_name, category, fr_validated, utilities, color, custom_code) FROM stdin;
c3e90f5e93f3c62564789065e8e3ff437da2e0a4	Rupestris Du Lot	Rupestris Du Lot	rootstock	t	\N	\N	9901
5accb3193afcab7ef3c496fffbfd04e0c25c2e7d	3309 Couderc	3309 Couderc	rootstock	t	\N	\N	9902
bf1aa1660e6105e82997a7bb8cd6ad1285eac676	41 B Mgt	41 B Millardet et de Grasset	rootstock	t	\N	\N	9903
5811988f34579648965a3e4a7afc58b184c0b070	161-49 Couderc	161-49 Couderc	rootstock	t	\N	\N	9904
a9fa719974d1732edcaef575981d9416de1f15a1	5 B B	Kober 5 B B.	rootstock	t	\N	\N	9905
c83cbd35a6855d57c803fa37a278ea7c2036d081	Riparia Gloire De Montpellier	Riparia Gloire de Montpellier	rootstock	t	\N	\N	9906
c71e1eb92afc184070e6039bfe133c3ef0c6486a	99 Richter	99 Richter	rootstock	t	\N	\N	9907
b3e209646b64671c78032cdd81f96e6a649e33ad	44-53 Malegue	44-53 Malegue	rootstock	t	\N	\N	9908
15eaf807afedbcebd06c60d05af874e59d13a6a0	110 Richter	110 Richter	rootstock	t	\N	\N	9909
f2dc520531f9d71cbdc5938b87c25cde355bc103	420 A Mgt	420 A Millardet et de Grasset	rootstock	t	\N	\N	9910
77b6ce2000a5c939391f840e4298bccbb0f4a717	101-14 Mgt	101-14 Millardet Et De Grasset	rootstock	t	\N	\N	9911
1233f4f4502d4f70b663ed425010cd3eb7efcec4	Vialla	Vialla	rootstock	t	\N	\N	9912
a4b8ec3b6290f07ee434196d2211b11c96a058d9	S O 4	Sélection Oppenheim 4	rootstock	t	\N	\N	9913
a3a9426fd0137dbc338ac007df0b54aad5512c8f	1616 Couderc	1616 Couderc	rootstock	t	\N	\N	9915
0a40f9ddd6f41fd9f2c1ee2b38c5b3a6c4461bf3	333 Em	333 Ecole de Montpellier	rootstock	t	\N	\N	9917
3dfcd462d665fff8bda497b661c111223b574c28	216-3 Castel	216-3 Castel	rootstock	t	\N	\N	9919
8c2a5478817ba99bd79e9f869351b4035703ca31	Teleki 8 B	Teleki 8 B	rootstock	t	\N	\N	9922
d43d49b1493d4fab99e29674ab22be48a30b4ef9	196-17 Castel	196-17 Castel	rootstock	t	\N	\N	9926
a5e0997616696601cd95d89bfb4a26ec3abd9615	34 Em	34 Ecole de Montpellier	rootstock	t	\N	\N	9927
510cce92238381c802b8b388018053660ac920b5	125 Aa	Kober 125 AA	rootstock	t	\N	\N	9928
a4c30b66c5b267f7c2db54c58b240ef8f17439bb	Nemadex Ab	Nemadex Alain Bouquet	rootstock	t	\N	\N	9929
d40497a9ede6d093fc6d74178abebf4faa1dadb8	4010 Castel	4010 Castel	rootstock	t	\N	\N	9930
6885b8f7356cb5e51bb7dc01765c4ee247fe9cca	Fercal	Fercal	rootstock	t	\N	\N	9932
ea3d55f0f8d43429ead4a0ad311c2e4f0340a052	Gravesac	Gravesac	rootstock	t	\N	\N	9934
760cc3c50980856d3fbd92fc28ecda32aa41ff61	Grezot 1	Grezot 1	rootstock	t	\N	\N	9945
840092fa2d9e5bc3cb784a2314519ae1bc85f95a	140 Ruggeri	140 Ruggeri	rootstock	t	\N	\N	9950
093109354558b1b1e73c6dcbbf9b02d591da746c	1103 Paulsen	1103 Paulsen	rootstock	t	\N	\N	9952
ebc37f88dd11f59db9b25e5145bc7d8d1b5c8e3a	1447 Paulsen	1447 Paulsen	rootstock	t	\N	\N	9953
cd07065888cdf1fe66fe27a1b9efc7bc634e02bd	Bc 2	Berlandieri-Colombard 2	rootstock	t	\N	\N	9954
91af4b7acc8b98b0ada3aafe171ad055fc590ccb	Teleki 5 C	Teleki 5 C	rootstock	t	\N	\N	9958
ab88051cb43e5ad729bd57d10e4ced1a16fc4c98	R S B 1	Resseguier Sélection Birolleau 1	rootstock	t	\N	\N	9982
2dd3b4d21ebf84be5907154942ead67d8b25400f	Olivette Noire N	\N	variety	t	{table}	black	\N
103c6f74baa6ecdd02a6b2eba91ce36ff0b4560e	Arrouya N	\N	variety	t	{wine}	black	\N
46f28a6f9ad2e23eca7b1d699fdda72988819383	Prunelard N	\N	variety	t	{wine}	black	\N
940047fba0e0715b06c65511d84cbb4bf69b7a67	Tempranillo N	\N	variety	t	{wine}	black	\N
fea7b7b056aee8ac62db359b1ce52da1c5a9df06	Corbeau N (= Douce Noire)	\N	variety	t	{wine}	black	\N
1547c472678f3a351b670fa05630d506431fa8c4	Mornen N	\N	variety	t	{wine}	black	\N
1c6e5d5c6c4b32c147b2278447231ff6d4fc4549	Pascal B	\N	variety	t	{wine}	white	\N
3341a5a4fc0c8ef16a2d87c48de0df63d4b3f636	Agiorgitiko N	\N	variety	t	{wine}	black	\N
e1bbb048ef7dd8402aeeb9774805ec90df1f7ffd	Muscat A Petits Grains Rouge Rg	\N	variety	t	{wine}	red	\N
057465ee1ee4d5855a142a6735fbd6701e4e8ede	Select B	\N	variety	t	{wine}	white	\N
10e32b39496957def9ad351fecbdc5a1be4277bc	Noual B	\N	variety	t	{wine}	white	\N
9fbfdcaace928a3f0bd47b0c22e1b48babdef5bc	Seyval B	\N	hybrid	t	{wine}	white	\N
2f6cc1b1268dc8c498ebd88bc357619a8d489218	Admirable De Courtiller B	\N	variety	t	{table}	white	\N
38099dc41d51e8f440771f8b952595971a0dd498	Precoce De Malingre B	\N	variety	t	{wine}	white	\N
fa4c625a71cac57ac8cafa8ff9708565ce98afab	Beclan N	\N	variety	t	{wine}	black	\N
1d36352b9d82c9b374b4f326900008496b177a57	Isa B	\N	variety	t	{table}	white	\N
0907ed1e7da7d8e43f55840268a99b9a22c77c47	Sciaccarello N	\N	variety	t	{wine}	black	\N
825182a24ead598ac01d358128f711b50f1166ab	Roussanne B	\N	variety	t	{wine}	white	\N
7634ecb9bf5f069acc09c39c28520c833374d2a7	Meunier N	\N	variety	t	{wine}	black	\N
d3da5cd5daa609e42bfcd1ca30c87108b8ab9987	Jurancon Blanc B	\N	variety	t	{wine}	white	\N
1a6f5889047f8b461f8a835fd1b679aa75da5650	Hibou Noir N	\N	variety	t	{wine}	black	\N
6e7cecfa6d35f5f81c25570823ac311cdfe70dee	Duras N	\N	variety	t	{wine}	black	\N
62418397964233b8b2faa0ca1b21142fb28fede4	Flame Seedless Rs	\N	variety	t	{table}	pink	\N
734335ae0a6a5b2feb3edaacd1750ac3c08c0e3a	Cot N	\N	variety	t	{wine}	black	\N
bf6114fdba73c05b82adb12333ac6589756c6ed6	Carla N	\N	variety	t	{table}	black	\N
a7e39df0fc21416e859247cb509bf1ed24ccce2f	Petite Sainte-Marie B	\N	variety	t	{wine}	white	\N
f953c8d3470086d2f02c1d1e4b970829d50d0a2a	Serna Inta Rs	\N	variety	t	{table}	pink	\N
8a79a29b7f89eacce6e75c69d170d87ba6f44244	Galibia = Galibert 14-5	\N	hybrid	t	{juice}	white	\N
ac771eb532dda3b6be3e001373c00afc348997db	Carignan Gris G	\N	variety	t	{wine}	grey	\N
1d57371178b00671e09f7383ebc236cfcb051424	Courbu Noir N	\N	variety	t	{wine}	black	\N
49a20719d244745feb8d00b74dbb40c0897f113e	Ganson N	\N	variety	t	{wine}	black	\N
3709be9f8a4714541b56893e69fb6bcb3aa94352	Ugni Blanc B	\N	variety	t	{wine}	white	\N
811adb474667e00c4fcca5c5139b5dea28d0feb7	Chardonnay B	\N	variety	t	{wine}	white	\N
898e0cbcdb478d9eab4e3851302acf89f54d894a	Olivette Blanche B	\N	variety	t	{table}	white	\N
5148eb80159d01c1a9802b5e056864b221f43a9a	Orbois B	\N	variety	t	{wine}	white	\N
106d194c949cf3686346b03205f09c1483d30f28	Dabouki B	\N	variety	t	{table}	white	\N
8a4fd883868cfe27c19be4c6d5d43df2ede4dd49	Rivairenc N (= Aspiran Noir)	\N	variety	t	{wine}	black	\N
ead79dcf5183c09aff230b9f0df4266dbc060e46	Len De L'El B	\N	variety	t	{wine}	white	\N
63821b658e85f67ef6b9b15792a0c302984a6b67	Arinarnoa N	\N	variety	t	{wine}	black	\N
c25b55caea8f381c4edaba7874dfb7960d28f591	Aligote B	\N	variety	t	{wine}	white	\N
c168dc058a6884cf5a73c60003d38f1560fc02bf	Portugais Bleu N	\N	variety	t	{wine}	black	\N
dee142d68ea0a72f411ed920c1626b4f06b9b2fc	Oberlin N	\N	hybrid	t	{wine}	black	\N
0f5fdc8b74998319077ba06a7d29b5cecf80dd7f	Aleatico N	\N	variety	t	{wine}	black	\N
85da98f7e3dacb3f018526c83f61e9bf8e9ca5ba	Arriloba B	\N	variety	t	{wine}	white	\N
bef6a277b2bdaf9e582fdd175329eb35ccae7487	Italia B	\N	variety	t	{table}	white	\N
6b520b215865812b207cea7f091fe94c8c7968e4	Molette B	\N	variety	t	{wine}	white	\N
4fd5d6c57e130be9ca968e94b984750cb28b1f0f	Aubun N	\N	variety	t	{wine}	black	\N
1831c6511d43ec1a0f5cabd45d925c4802ff8315	Negret De Banhars N	\N	variety	t	{wine}	black	\N
35c54e3c53fcf51b5bdf517041c6acb36df51592	Carcajolo N	\N	variety	t	{wine}	black	\N
0bd12135cc8f55a54903901a27c9259f95c2161b	Persan N	\N	variety	t	{wine}	black	\N
221924ae3b4185b753804bd00a5f930960084d52	Zinfandel N (= Primitivo)	\N	variety	t	{wine}	black	\N
14c1f4f08d6b0bd8cdcf1bd164cfcbac4a703083	Viognier B	\N	variety	t	{wine}	white	\N
abea217ab4861291ab0808aebdfaf21cbead7d65	Attiki N	\N	variety	t	{table}	black	\N
c6e56bde2a5a49713b5e20b7dfaaf9ef09492596	Semillon B	\N	variety	t	{wine}	white	\N
b442726c16a7a91f9e72c2a9f0abaa899b3a0a35	Grenache Blanc B	\N	variety	t	{wine}	white	\N
3189c696e53d64a7fade3775fa4a0700d516a5da	Lledoner Pelut N	\N	variety	t	{wine}	black	\N
1d74325c2a0a156553dadee9ff55520f716128c0	Cabernet Franc N	\N	variety	t	{wine}	black	\N
3477b771337579bf4cbef0787a446e1de37baf37	Roussette D'Ayze B	\N	variety	t	{wine}	white	\N
9743558e0d5db6803cf1b933b4f7ade67b355594	Chasan B	\N	variety	t	{wine}	white	\N
ea5f57ea611020f91f6f38c270601897cfcf28da	Portan N	\N	variety	t	{wine}	black	\N
c3541f3b90832f1cc7b46a0a532833e4105c7f9f	Amandin B	\N	variety	t	{table}	white	\N
5c473f456cdfba3d112b8df5696d0ccfb4b5dd2c	Ora B	\N	variety	t	{table}	white	\N
ed816f680f79fd7ae1bbf115fce210883e93cec1	Pinot Blanc B	\N	variety	t	{wine}	white	\N
34488f5caecaa556b78466246e8454b0993e25fc	Gibert N	\N	variety	t	{wine}	black	\N
62868e2c5430610df607fa4e22be25ffa1b889bb	Madina B	\N	variety	t	{table}	white	\N
fc2bd8ec2732553113ed825c81b4d675087e73d8	Colombaud B (= Bouteillan Blanc)	\N	variety	t	{wine}	white	\N
63b4c624fc0c9a35b8b4950883e378472a096f4a	Sugrasixteen N	\N	variety	t	{table}	black	\N
6a1c6bd2d88036e03922d77c31a5f1a291a323d1	Madeleine Royale B	\N	variety	t	{table}	white	\N
7009a27607d6b65a34da24323dbe610e0c1b730e	Petit Courbu B	\N	variety	t	{wine}	white	\N
9192fd256cffb93fabe3b47a108896fef59894c5	Biancu Gentile B	\N	variety	t	{wine}	white	\N
08b8b0b99d7522e85628b5d46e8ab2ce34024028	Aramon Blanc B	\N	variety	t	{wine}	white	\N
90d487114c497eb242b44a6dec0940d5a5b008a1	Cabestrel N (= 68-11)	\N	variety	t	{wine}	black	\N
72bdc61a9f654c422d3b6d4f6522ac9e986f6d8b	Raisaine B	\N	variety	t	{wine}	white	\N
abfb8fc2d564afe198409b111a69212c93edb310	Raffiat De Moncade B	\N	variety	t	{wine}	white	\N
b83d86635e26a845e1d9d24d456a13d6462aa9da	Bourboulenc B	\N	variety	t	{wine}	white	\N
e3c46164305fefda46cee7585fdae01130664ad1	Franc Noir De La Haute Saone N	\N	variety	t	{wine}	black	\N
3c72cd4fa9a09eec3bf42623985e214b36324b4f	Rivairenc B (= Aspiran Blanc)	\N	variety	t	{wine}	white	\N
20c8807a8c78626a7d98a423b40c9906c2e1907a	Iloa = Seyve-Villard 12-413	\N	hybrid	t	{juice}	white	\N
6c3cf65c3b66b560eb72080daea6c5b67f8735cd	Aladin N	\N	variety	t	{table}	black	\N
76be9aaacab3bf9f351986b6a5021a5f9bba689d	Sultanine B (=Thomson Seedless)	\N	variety	t	{table}	white	\N
c45c2b878ff71e20b55d273a6a1bcff093e6fe54	Noir Fleurien N	\N	variety	t	{wine}	black	\N
3425f0927065ee19f7f49d6cb026760b544c82b5	Gouget N	\N	variety	t	{wine}	black	\N
9486bb196efceb75a749bc2f1374cb0e15eccdc6	Liliorila B	\N	variety	t	{wine}	white	\N
e1e3b0fa903047675c358393fd49b26ee339ef27	Mauzac B	\N	variety	t	{wine}	white	\N
4fe3b9e3469ebd52f3855fceb8d0fa47053b876e	Beaugaray N	\N	variety	t	{wine}	black	\N
683d707686974f7b24e1ed0dbf57cac0f4076c5a	Colombard B	\N	variety	t	{wine}	white	\N
91b08755f4ba8370791c3ece52e60055801e5f74	Durif N	\N	variety	t	{wine}	black	\N
0bff3417ba775453fad0f600da7ac419948aefb2	Cabernet-Sauvignon N	\N	variety	t	{wine}	black	\N
0a4a6c5cea2f12fa39ce26bfbfe701a2e13ece03	Alicante Henri Bouschet N	\N	variety	t	{wine}	black	\N
de3c09daf2faf584c7683771bc2fcdd987878f20	Mouyssagues N	\N	variety	t	{wine}	black	\N
6ca598e7ba56fa86d3926c65ddd3936bbe7a1476	Varousset N	\N	hybrid	t	{wine}	black	\N
8fa0d97d2259c07a4c9e737fa54e1d58f4934ad9	Grand Noir De La Calmette N	\N	variety	t	{wine}	black	\N
d7b61b2b79aaf15ce25d9ea517a3c937c5355f65	Onchette N	\N	variety	t	{wine}	black	\N
e895846f380cdfbd4fd330ac52f21387f2602f9c	Madeleine Celine B	\N	variety	t	{table}	white	\N
58a744cd7c0ffca31792933311b4fd38191ba8cc	Peloursin	\N	variety	t	{wine}	black	\N
b8597b9f72e0eb9d06b55a773148ebb0aa03a9cc	Baco Blanc B	\N	hybrid	t	{wine}	white	\N
2c1c9500efe6b33ef90d5947f259bef65e622c7d	Marsanne B	\N	variety	t	{wine}	white	\N
e6aea84bb0ac71d2702949b7fb9c20c9e04ea1a5	Chouchillon B	\N	variety	t	{wine}	white	\N
1f052e365967e629c1f327f309021be059579368	Aubin Vert B	\N	variety	t	{wine}	white	\N
d817a55940e4e284677f1a64431e102a5d126ebd	Brun Argente N	\N	variety	t	{wine}	black	\N
9c9c04ff142d756aa2c23bd245a5035ea8e2ee09	Muscat D'Alexandrie B	\N	variety	t	{wine,table}	white	\N
f824d22c8cdba2b076141e5f45090d09b171966d	Trousseau N	\N	variety	t	{wine}	black	\N
8430354d01f1a81a123453175de3b9ee3f4dbc79	Sylvaner B	\N	variety	t	{wine}	white	\N
871d6c2a6213e09e78dd052127e76cb594ea7941	Muscat De Hambourg N	\N	variety	t	{wine,table}	black	\N
b10829883afc35fee21373757334c40cd699625f	Grolleau Gris G	\N	variety	t	{wine}	grey	\N
5da3464b3ecb316a36b11aba34e94caf44d52db8	Assyrtiko B	\N	variety	t	{wine}	white	\N
04760757497cb707e6b90ca19a1bffe0a0878edc	Jurancon Noir N	\N	variety	t	{wine}	black	\N
6b2bec0354c982821d64581d88fc8dbacde758c0	Centennial Seedless B	\N	variety	t	{table}	white	\N
486b388be2ed453895e108f934e9b76383b7b6e4	Dattier De Beyrouth B	\N	variety	t	{table}	white	\N
9d8b8e9f9ef8aa0914fca1ca26f6f4fed2ecd2ca	Jaoumet B	\N	variety	t	{table}	white	\N
e21985dea2f40fa3099ede06e9c62af3cce49f0e	Lilla B	\N	hybrid	t	{certified}	white	\N
6e5886afcc9cc2693fd4436455fea83077824813	Abouriou N	\N	variety	t	{wine}	black	\N
f19c6c2c8141ba080afbae934ed70d74cdbc1eb7	Gringet B	\N	variety	t	{wine}	white	\N
7b21b1ccb2081ab23aa2ccec2c417832083113ac	Petit Verdot N	\N	variety	t	{wine}	black	\N
f15eb282d84d3baaecec81318bb6f973cee6faef	Saint-Macaire N	\N	variety	t	{wine}	black	\N
4d0ec9d668a5d71adc8a680a62f4977b4c8cddee	Perlette B	\N	variety	t	{table}	white	\N
ed56cb9e20486c46d82ddbd7849b71881e7b1a78	Delhro N	\N	variety	t	{table}	black	\N
f21da74441de23cb215c17b166fdb0a426cb59d7	Piquepoul Blanc B	\N	variety	t	{wine}	white	\N
020308070bfd977428be3fc8cbbf05e6a5901659	Saperavi N	\N	variety	t	{wine}	black	\N
9faf6fd74cada16e690c73b6945b57998218531f	Couderc Noir N	\N	hybrid	t	{wine}	black	\N
0297fc022679c070bc64825adfb9f60aa3cc189f	Gascon N	\N	variety	t	{wine}	black	\N
76f2ac6ba05b799ff719ce6161cee7fb120ea008	Bouysselet B	\N	variety	t	{wine}	white	\N
2acf05ef1e46e19d2a28b14b6848416d650c064d	Florental N	\N	hybrid	t	{wine}	black	\N
9d13375a656ebe699a8ac9550996bfaf4d84af3c	Canner Seedless B	\N	variety	t	{table}	white	\N
d919be20962ac7c448bfaccfdf8b3bc767dd33bc	Italia Rubi Rg	\N	variety	t	{table}	red	\N
e5516c073c1b56092d2e5f0e105556860223f03f	Verdesse B	\N	variety	t	{wine}	white	\N
af7ec63f5a7acaf2f0ec0562f88a04e7b3a5cdc8	Courbu B	\N	variety	t	{wine}	white	\N
3b72a647593495980a95dc797a005dc31c9b08a3	Merlot N	\N	variety	t	{wine}	black	\N
481a8bdca5c800a300de4bf268f0e9a78ea57bed	Madeleine Angevine B	\N	variety	t	{table}	white	\N
de0c49658b83b95279ac9c41266bc497eb939ae4	Muscardin N	\N	variety	t	{wine}	black	\N
66baca3e2bb7ba6de49c89425380e418789e87ad	Syrah N	\N	variety	t	{wine}	black	\N
a051ecb80e50e5bf3ba0c23ea04f77828ea691d8	Poulsard N	\N	variety	t	{wine}	black	\N
d7b079fbe016e37f4a5acdba05dc0541fc9004d8	Trousseau Gris G (= Chauché Gris)	\N	variety	t	{wine}	grey	\N
f2e2b29fc384f4e9a7329a90b43514a6af9e8b21	Carubis N	\N	hybrid	t	{juice}	black	\N
017dfaf3f77d487f1da1acee8a7b782f5742458c	Muscadelle B	\N	variety	t	{wine}	white	\N
6b27bac0ccf136d217d6eafdd4b1189cee3d03d3	Ekigaina N	\N	variety	t	{wine}	black	\N
389bec0a35943bdc8a9a9e18901241b092ad13bd	Terret Noir N	\N	variety	t	{wine}	black	\N
c62028c6eba8f728ac874061ca5208493f49926d	Chenanson N	\N	variety	t	{wine}	black	\N
507b2c45176363664714b5f6d2b54a2ebb0b5778	Sauvignon B	\N	variety	t	{wine}	white	\N
5d9bb8dd9fc32f5e76d85258c0998a0518a321e5	Cinsaut N	\N	variety	t	{wine}	black	\N
a13f6b9afa2e8dbe54ede3898d6abfa50fa5d7d1	Carcajolo Blanc B	\N	variety	t	{wine}	white	\N
b5a112df3093727c2d1148a3bf2392bd985f14b0	Silara N	\N	hybrid	t	{juice}	black	\N
7341479b19104b443b57d7c3941487d84b3cf9a0	Phoenix B	\N	hybrid	t	{certified}	white	\N
952fca1ec884a15cebe84c74e28ca6a4077fb168	Prima N	\N	variety	t	{table}	black	\N
3b6e1c172b67f3250a0cfdeee74608f988e7c4ad	Romorantin B	\N	variety	t	{wine}	white	\N
52212f0b557314eab679f2a8f181ccd5ef829110	Manseng Noir N	\N	variety	t	{wine}	black	\N
0e8bf2fb7f751251f8df9511f6c9cacb37dbf9c6	Merlot Blanc B	\N	variety	t	{wine}	white	\N
269638626fd28e53c15ea1206127dad5cee3dd5e	Aledo B	\N	variety	t	{table}	white	\N
8ee2466f4e2108556c163e8dd8278fea6df45b27	Bia Blanc B	\N	variety	t	{wine}	white	\N
b924a5eee6bc063c63f6b0acd9453ba129fce0cd	Fer N	\N	variety	t	{wine}	black	\N
704e56d23f463347fe5178fc8fc15683ddce2ce6	Katharina Rs	\N	hybrid	t	{certified}	pink	\N
c8d38f4786c1314388801d3e4288f2d3a7ffa5ae	Autumn Royal N	\N	variety	t	{table}	black	\N
637baf8459f47b3fbfd2531325b99a5509741ffa	Grolleau N	\N	variety	t	{wine}	black	\N
dcd68db9f68c9d38dc050023e86d82c738257d1a	Barbera N	\N	variety	t	{wine}	black	\N
58345919d4a388310c7ce505dd084f14b0a13349	Mondeuse N	\N	variety	t	{wine}	black	\N
93ab717f05635877b5dc7060019f81c71704a164	Knipperle B	\N	variety	t	{wine}	white	\N
a635eacc296e13b7d6797c2852ed7dc17aff0f9a	Savagnin Blanc B	\N	variety	t	{wine}	white	\N
92c865cdf5c9a9377369314de5539320d5da1f7f	Picardan B (= Araignan Blanc)	\N	variety	t	{wine}	white	\N
29ea5bbecfdb966d302ee06aa2dfbd977fdb9f78	Rubilande Rs	\N	hybrid	t	{wine}	pink	\N
bd7c149d8047cc9ff5b489f840f424de02068e3d	Madeleine Salomon B	\N	variety	t	{table}	white	\N
137305dc2fff561f9126c32f307c2ed0f1f34bb6	Bouquettraube B	\N	variety	t	{wine}	white	\N
923e82ae0424ba567d75d915ec56a4d005c40821	Mavrud N	\N	variety	t	{wine}	black	\N
77a1ba860a21211edaa2fb886781203774a3b295	Codivarta B	\N	variety	t	{wine}	white	\N
7f63eb8007f754770263bfff6381b73941041d4d	Merille N	\N	variety	t	{wine}	black	\N
a38700c18b854afb694628bf77ef857f82b3ba3d	Mayorquin B = Faranah	\N	variety	t	{wine}	white	\N
30c5f63e06590487a0c4b16d56260dd39f228936	Muresconu N	\N	variety	t	{wine}	black	\N
04fee48003effee006649f94ad92011640c29e00	Datal B	\N	variety	t	{table}	white	\N
360cdb3b2c193bc28e47f9e0930f44b52c780f5d	Mourvaison N	\N	variety	t	{wine}	black	\N
3c3691c24aae566d034a59f9679dd81d70442415	Altesse B	\N	variety	t	{wine}	white	\N
0991919c3f486309ce9c3ccdf9846bc5131e09d8	Goron	\N	variety	t	{wine}	black	\N
23294d3f9b23d804dd5fa3c201d190ab9b98d877	Calitor N	\N	variety	t	{wine}	black	\N
36975dd07c232b7bb49b4b0f3196bae1f7ffee6d	Madeleine De Clermont B	\N	variety	t	{table}	white	\N
8b348d6e27b94242c7244711fd8f1afdb2099b9a	Lauzet B	\N	variety	t	{wine}	white	\N
27aad3e861ad957a782a9abe087c6603814bc9de	Evita Blanche B	\N	hybrid	t	{table}	white	\N
91e04057ec1e12d420b18b078baa047bbd69c1d0	Victoria B	\N	variety	t	{table}	white	\N
e87e551bd2fcb2eeb37f1d4fc2b4273983e951ae	Riesling B	\N	variety	t	{wine}	white	\N
5f84d115bdaf347c766070b1fcc0711cec36e73a	Dureza N	\N	variety	t	{wine}	black	\N
d2135f0ee9321fb4eae18f1cd219a919af4fbecc	Perle De Csaba B	\N	variety	t	{table}	white	\N
b0a8c359da702544331fd98281df078bffffd545	Macabeu B	\N	variety	t	{wine}	white	\N
775ba644f75ccd86ee980220e19f64c5222fa4b7	Abondant B	\N	variety	t	{wine}	white	\N
0b834a830fd0aac97669bcbb6bb7731115c9b6c4	Arbane B	\N	variety	t	{wine}	white	\N
97b8ac28633f396bffce99d35ef681df80598f46	Marechal Foch N	\N	hybrid	t	{wine}	black	\N
5a0c37ffe90cee7522c076c57d3160012c7c613f	Floreal B	\N	hybrid	t	{wine}	white	\N
45a4e72cb74f881950e28ebb11be0537dc93a24d	Verdejo Blanco B	\N	variety	t	{wine}	white	\N
c1b0f55d71204558d489c5f04f3a626690023b66	Muscat Cendre B	\N	variety	t	{wine}	white	\N
ffdbec6f305c572a2a9a2ec3c6f8ac25e8fc4f10	Servanin N	\N	variety	t	{wine}	black	\N
ecadcf6792d019655408365534d4bb79cc832b0c	Mollard N	\N	variety	t	{wine}	black	\N
ef35233fd0229a6c18c3efd978430ef9713fa50f	Milgranet N	\N	variety	t	{wine}	black	\N
5bbf78ae98de635af3cc74929b7bafeb0dc8d47d	Parellada B	\N	variety	t	{wine}	white	\N
110aaedac36120186524203e48495b0ea09ecc05	Clairette Rose Rs	\N	variety	t	{wine,table}	pink	\N
7948eb55194df2e847ab19796e060f4911ce732a	Precoce Bousquet B	\N	variety	t	{wine}	white	\N
2e2e8e95861127f2d700fd90bebd2ffa42f15dee	Madeleine Angevine Oberlin B	\N	variety	t	{table}	white	\N
789d26810ea68aea4faded21907c7c9b26675a75	Valerien B	\N	hybrid	t	{wine}	white	\N
f4e44b0dda0cdde5b05616ea482d1197db1f3182	Grenache N	\N	variety	t	{wine}	black	\N
c56389e3669845c3cb80e0132a3ab2f27699b094	Garonnet N	\N	hybrid	t	{wine}	black	\N
0f36350eb1511ea8b189db74c39ca4117233c25b	Etraire De La Dui N	\N	variety	t	{wine}	black	\N
3973feeb41997313afd3e6382604bf4b06c22332	Ignea Rs	\N	variety	t	{table}	pink	\N
66f67031de45c1ee3afe72468863cadf8ef4ead1	Folignan B	\N	variety	t	{wine}	white	\N
699229db899c6a82ba268af3ac24ba1c5e814b13	Goldriesling B	\N	variety	t	{wine}	white	\N
b57a67bb8d034db9bd8cf64e66c0a8caead9e1c1	Claverie B	\N	variety	t	{wine}	white	\N
234e8f14fd35721c2d327ac780c7162eb38a3793	Touriga Nacional N	\N	variety	t	{wine}	black	\N
26b5389721376d45b6eb7f6af2968259519cdf31	Gros Vert B	\N	variety	t	{wine,table}	white	\N
f099b32b9bbb9ebde9600bd774c271c49c7cd9ac	Vidoc N	\N	hybrid	t	{wine}	black	\N
af1e756092a103b99c335fd0e10de40f3a1e90f6	Brachet N	\N	variety	t	{wine}	black	\N
8217b27616e65b0eaf01de73be6f4714f6cbc57e	Pardotte N	\N	variety	t	{wine}	black	\N
805cb64c13f79aeae84531c8fbb5b55dec7a1fd2	Leon Millot N	\N	hybrid	t	{wine}	black	\N
74ebb3d786fc85fe7751aaea230fc9abef3c23ba	Terret Gris G	\N	variety	t	{wine}	grey	\N
5190c8154ab732d776404c4e1b6f6bd8207a7bb5	Alphonse Lavallee N	\N	variety	t	{wine,table}	black	\N
70de0ea6922f6f3b5a4df7b7206db5908ae26037	Cardinal Rg	\N	variety	t	{wine,table}	red	\N
57cec83dcdae370160062a550a1db5d3e74e7447	Belair N	\N	variety	t	{table}	black	\N
ffbc4cbe2675f3be65436f7c4adc78001bfe8f84	Melon B	\N	variety	t	{wine}	white	\N
4dc1460689b9b794b24b28c405993a067ee1d19e	Egiodola N	\N	variety	t	{wine}	black	\N
861f31fb16acb786f6fae7f65508ee6d405e0053	Sophie B	\N	hybrid	t	{certified}	white	\N
1f80505a5e05c6e813f8965032b757f1162f7a44	Gewurztraminer Rs	\N	variety	t	{wine}	pink	\N
4c85a41d248c5a62ed920bb64034548b6c49d316	Grassen N	\N	variety	t	{wine}	black	\N
8a10c1c4390edba95f0756813c322f4a1109fe8d	Xarello B	\N	variety	t	{wine}	white	\N
ae42b93a9f8dfb8157e1d8ed7f23cb8274a64022	Chambourcin N (=Joannes Seyve 26205)	\N	hybrid	t	{wine}	black	\N
8afe91b7d0b885cc307201c71a79d27f2da43c98	Tinta Barroca N	\N	variety	t	{wine}	black	\N
195fcf0b44cb697ab6de24a993401eb049886aa7	Pineau D'Aunis N	\N	variety	t	{wine}	black	\N
1e7d53128fc48543f4b64133fd5c45c65d4d64dd	Aubin B	\N	variety	t	{wine}	white	\N
d6e65737f2bcf02e2b8d7bae3ba276523c7ec5c9	Alvina N	\N	variety	t	{table}	black	\N
b97e3938f972b07d9b406480fff87347e87e8801	Artaban N	\N	hybrid	t	{wine}	black	\N
a0089c18741a71c73eacf4fce1dab3c7eac1a3f5	Dolcetto N	\N	variety	t	{wine}	black	\N
7e74dd4e26a88b584117cda8fecfd0737612c1e8	Gramon N	\N	variety	t	{wine}	black	\N
08e2d7c049be3b245f9110129d796ea56df013cf	Caladoc N	\N	variety	t	{wine}	black	\N
ed4e806d7c7a1e571948350ba63279f8b073e307	Philipp N	\N	hybrid	t	{certified}	black	\N
dbb382eefe14b9d6a84a44afa2b0b24aab2be0d9	Lival N	\N	variety	t	{wine,table}	black	\N
6681e53813bde8ba76d84b4df59607e4a5beec19	Monbadon B	\N	variety	t	{wine}	white	\N
e066ef2ff21b47fb667c67b1aedfbea06a29ee80	Monerac N	\N	variety	t	{wine}	black	\N
5d1b0590471221fd33cac887f981ec93efe6fbd1	Gamay De Bouze N	\N	variety	t	{wine}	black	\N
303cfefa6a0b1cb9c9b396e1b94b3b5a61d2fb4b	Grenache Gris G	\N	variety	t	{wine}	grey	\N
4deb33cf3a99aad7b4cb88941d95271e593210b4	Xinomavro N	\N	variety	t	{wine}	black	\N
c5b8b15b04902d22ab5723e4cc88ffb26569e0c9	Picarlat N	\N	variety	t	{wine}	black	\N
d36b6470943a94a86dc4c9baade400bbabfb54aa	Carignan N	\N	variety	t	{wine}	black	\N
71d2c4143610adb856b576b688411316983af4bb	Valdiguie N	\N	variety	t	{wine}	black	\N
eccb2a18c611f3082f72783bb81764fc77b4510c	Arrufiac B	\N	variety	t	{wine}	white	\N
de6367ba7087f1e913af5d24b3a4cc1ada07d9f4	Carmenere N	\N	variety	t	{wine}	black	\N
f3e7907327c741f3169c3e0685fe2da9c23457f1	Sacy B	\N	variety	t	{wine}	white	\N
6db92fb8941ce5ad664feb21083cb670b8163b8a	Saint-Côme B	\N	variety	t	{wine}	white	\N
84919e0e9b1a9caf4bf6ac2e45bdc9fce9b0a891	Chenin B	\N	variety	t	{wine}	white	\N
736c619ab965a5b616dcba329e12f2d554c763c3	Tressot N	\N	variety	t	{wine}	black	\N
2e43914616c07afae84880cb729c4b61874d3ca9	Chasselas Cioutat B	\N	variety	t	{table}	white	\N
90a400d4c1798c9a4c7b5d2020581b0b72153b83	Plant De Brunel N	\N	variety	t	{wine}	black	\N
3dedf8ca7e4e8332f4803387c8ea5b2a3b0bf1f2	Chasselas Rose Rs	\N	variety	t	{wine,table}	pink	\N
8fba4fb7b9008c3e36973a5ffb196c4619611a88	Danlas B	\N	variety	t	{wine,table}	white	\N
85910c07ae9244eec91c6a8afc5271087e425fd1	Gamay N	\N	variety	t	{wine}	black	\N
99e93edc26c43cdf2a8387e0d123ce1bfac64e0b	Elbling B	\N	variety	t	{wine}	white	\N
12aca93aa31161ac10895aaa80228ee51656bd4a	Sereneze N	\N	variety	t	{wine}	black	\N
145bb70d076315b05a468a8ab4baa8aa5a2c851a	Verdelho B (= Verdelho De Madère)	\N	variety	t	{wine}	white	\N
93ea894e915211e37e0d3858d4750edb6e682a0f	Sauvignon Gris G	\N	variety	t	{wine}	grey	\N
c428b284687f9f32019c9a543683bd6ae41ce288	Muller-Thurgau B	\N	variety	t	{wine}	white	\N
252060dfb1df8aa199a0fbad2d7e4cc507323809	Mondeuse Grise G	\N	variety	t	{wine}	grey	\N
23708297fb6d7c388da263efd7f5c79b537e99fa	Colobel N	\N	hybrid	t	{wine}	black	\N
639db445512d8c75275ca759c8a7c72c2c9e96ac	Ferradou N (= 83.81)	\N	variety	t	{wine}	black	\N
4c9615b4800e3bf6935b2819337519a145c9e6bb	Alvarinho B	\N	variety	t	{wine}	white	\N
c93f620150b672b6b443b0b489ae6f4d8339c7f2	Pagadebiti B	\N	variety	t	{wine}	white	\N
15a3574a50e046de0cf5457506efeec2b1abeeff	Moschofilero Rs	\N	variety	t	{wine}	pink	\N
070d82b4a2bdd2ccb4eac170b6c6c143d03e7214	Folle Blanche B	\N	variety	t	{wine}	white	\N
79bff813c51d5aa671cdb42343ed5521895fa6dd	Camaralet De Lasseube B	\N	variety	t	{wine}	white	\N
30bf9559d437c1a2e86e07e64951a680e7fae1fe	Gamay De Chaudenay N	\N	variety	t	{wine}	black	\N
a83a0a40450303c95c4c90ac0e490903940d8f96	Meslier Saint Francois B	\N	variety	t	{wine}	white	\N
2d7be04950b6e21faa836665e0d36a37379b0226	Pinotage N	\N	variety	t	{wine}	black	\N
70130a0681405ec5406acafdac28573de78e9d9e	Genouillet N	\N	variety	t	{wine}	black	\N
ca00c220d7303ae8371cc7f3a0d013c51c1cab30	Clairette B	\N	variety	t	{wine,table}	white	\N
cff6e9e1a99d4def7a51be3a62320bba73353c17	Piquepoul Gris G	\N	variety	t	{wine}	grey	\N
25c700ca269c10364cd85d82244e7eace4d8bff9	Brun Fourca N	\N	variety	t	{wine}	black	\N
1d79824400ef4ba3d09056309530817e20f8667d	Rayon D'Or B	\N	hybrid	t	{wine}	white	\N
9e7e6a563815f5fee4fdcdc34932f65a34c70a37	Velteliner Rouge Precoce Rs	\N	variety	t	{wine}	pink	\N
1dd9ebd3c73f98a4562c0d24314a43a9546af054	Perlaut B	\N	variety	t	{table}	white	\N
8daac4c9e04a36f6e13acfc227e9516d6bdeb4a5	Graisse B	\N	variety	t	{wine}	white	\N
b9759a3c6e7cc4e86ed193dee52d7dc17830e1b0	Granita N	\N	variety	t	{wine}	black	\N
655ec22d3b5984b5bd5f9a7fd495340c0a2ef7d1	Villard Blanc B	\N	hybrid	t	{wine}	white	\N
5d9aa1aff1a72e5feaf8683db7d4358e599cd301	Baroque B	\N	variety	t	{wine}	white	\N
73aad3bf4278b931ed3cb355862c607f4b9d8905	Mauzac Rose Rs	\N	variety	t	{wine}	pink	\N
17ddd0548b1cc270e10acf8619ff9084db652a59	Mondeuse Blanche B	\N	variety	t	{wine}	white	\N
71f9ea260cb539067f8fb83b15399cb3bec89dce	Gaminot N	\N	variety	t	{wine}	black	\N
74e68c5e998fc06e9d02599a22bb85b8b1b65e7b	Muscat A Petits Grains Blancs B	\N	variety	t	{wine}	white	\N
e1d2edaed47ea010ecac0dacf685e1031513f8ee	Robin Noir N	\N	variety	t	{wine}	black	\N
a94d48f07f744112840a09d7ebe92f4c6cad51e0	Kadarka N (= Gamza)	\N	variety	t	{wine}	black	\N
c0e7623cd03834c88a9dc46522a6bb795d6b3735	Clarin B	\N	variety	t	{wine}	white	\N
5eee53d34cafa636300269a3daa4195862f36bad	Nielluccio N	\N	variety	t	{wine}	black	\N
9d4156ee09a641baf1353c0995edb7ce27378fa8	Riminese B	\N	variety	t	{wine}	white	\N
eb90e0050f2bd81754efd015659bd0f2f925f8ca	Teoulier N	\N	variety	t	{wine}	black	\N
dfb1ab6e933bd5c65cdd74488baa35bb1333b72d	Cesar N	\N	variety	t	{wine}	black	\N
4bf080cb68b5646d4b2cc7f68bc13dfa23ae4b40	Furmint Blanc B	\N	variety	t	{wine}	white	\N
d7d73450e4d4a0185bd21723eaae09cf36dbd236	Segalin N	\N	variety	t	{wine}	black	\N
69e02e280c7903e99ea9efb4bc02471b6d8927ba	Muscat A Petits Grains Rose Rs	\N	variety	t	{wine}	pink	\N
167b12f33f3f4c349751023e4d50b1ddf7ab8be4	Pinot Gris G	\N	variety	t	{wine}	grey	\N
ca6376a2e37773c607baefdba5bc387006a3aa25	Plant Droit N	\N	variety	t	{wine}	black	\N
0af296817c4dcf9ea6c7beee6f8a537cbe7db443	Sugraeighteen B	\N	variety	t	{table}	white	\N
8a4223155a162f720206b8c2e1a35f8ece027f7d	Rivairenc Gris G (= Aspiran Gris)	\N	variety	t	{wine}	grey	\N
a32d53fd49e6de9a486ebb43f9e192667f9ea68b	Roublot B	\N	variety	t	{wine}	white	\N
2d11219c7de85e4d4bbadea7431c00064988866c	Ribol N	\N	variety	t	{wine,table}	black	\N
8755d405fb153d5f5e7b89a379b8e60265b24f10	Red Globe Rg	\N	variety	t	{table}	red	\N
84bea59cbff6c59bd0965aa99c0a7a5d2a15b358	Aramon Gris G	\N	variety	t	{wine}	grey	\N
0652e46a7438202b136d7f846aef6806fa002b04	Blanc Dame B	\N	variety	t	{wine}	white	\N
0a59da3c0f0bee79db4b9a898489e0aa8d214e92	Counoise N	\N	variety	t	{wine}	black	\N
83b30d8a8274609d67d466216ac78b6f5f6e4465	Seinoir N	\N	hybrid	t	{wine}	black	\N
19672b7b220a1090d66843c16c38ebb1670177ce	Aranel B	\N	variety	t	{wine}	white	\N
c26e711e82b97a2b5611aaf8a8bfa32efdeb1e48	Montils B	\N	variety	t	{wine}	white	\N
b56cdc94e0344947b6eddd35390a395479a4d6c0	Caralicante N	\N	variety	t	{juice}	black	\N
c7afa2ac7b67c55c3ed8e90d331be52cdd317338	Tardif N	\N	variety	t	{wine}	black	\N
53874d10f100e057760b294d35e18b49fc6e9e21	Tannat N	\N	variety	t	{wine}	black	\N
130a4b157e69dec7b893b20e6c8e5e4732fd9fba	Pinot Noir N	\N	variety	t	{wine}	black	\N
a1788670ba570e66218c2bb41c8646f86f5fe841	Jacquere B	\N	variety	t	{wine}	white	\N
d286d6e9ca5c3804794da63b7fb4345d2e1ecf45	Mourvedre N	\N	variety	t	{wine}	black	\N
bc1237d55812e03503cb9333c51af3c7409ef6a5	Terret Blanc B	\N	variety	t	{wine}	white	\N
0455558540ec6d37a115d310db3ca400c2e74e67	Servant B	\N	variety	t	{wine,table}	white	\N
0c91a75c98737c1320bd29ac8f8ac353cb06105d	Sulima B	\N	variety	t	{table}	white	\N
8ec295eb6f7149f2c57eb44c9458ac659d3251c1	Farelia = Seibel 10096	\N	hybrid	t	{juice}	black	\N
ec352bf7cfb7e219833c54d28dbe516cdc136959	Roditis Rs	\N	variety	t	{wine}	pink	\N
fdec15afc633bd35b8810bfc87834df091a4fc9a	Panse Precoce B	\N	variety	t	{table}	white	\N
b9c25a86cccc3374d891da534b3134f5c8bbe928	Couston N	\N	variety	t	{wine}	black	\N
aa65fa99aeda180fde4b3006eaa695be87c6250b	Morrastel N	\N	variety	t	{wine}	black	\N
7349355c19e76dd2fb2fc4e8e6db91e64dbc0cd3	Reine Des Vignes B	\N	variety	t	{table}	white	\N
740f5498abefcd856b138157c88fae1b85b56e85	Bequignol N	\N	variety	t	{wine}	black	\N
d78c70318824ed0a595bad327eba2f957f8f3fce	Feunate N	\N	variety	t	{wine}	black	\N
393662a2f55e72c132a56eb2277fb3f5172013be	Humagne Rouge Rg	\N	variety	t	{wine}	red	\N
25ff934dbc4d2e7a53f90304fed024b34dbdd91c	Semebat N	\N	variety	t	{wine}	black	\N
d025965c1c82e601751704096e35f8d5e9d9fdf7	Danuta B	\N	variety	t	{table}	white	\N
4bf1bb3bbaf40e15cd2e9f7bc5c88a55868a15b7	Nebbiolo N	\N	variety	t	{wine}	black	\N
f6312d2ec064f5f872ffa64e0cfac28a91ea0f72	Bachet N	\N	variety	t	{wine}	black	\N
8347f006ac2c142a1381bf163dea2176e4f4dbcb	Castets N	\N	variety	t	{wine}	black	\N
83666d44e3f0d2e6119f8bca9ba8ea04ad66c50c	Bouchales N	\N	variety	t	{wine}	black	\N
790ab66b010640bdfef755b4d6e9cf6a910603f5	Tourbat B	\N	variety	t	{wine}	white	\N
7c64cd28ecfaa8892bfd4c4f6e2ab101531f6dc9	Alval N	\N	variety	t	{table}	black	\N
41f685c6a46a41d54d9114f8380f48005f568afd	Carignan Blanc B	\N	variety	t	{wine}	white	\N
1ee2dde051b1329f27eea05213ada34836ca010b	Rose Du Var Rs	\N	variety	t	{wine}	pink	\N
4c17c2ae845f0126f0b9bf6afb54bf2d5c5ff816	Negrette N	\N	variety	t	{wine}	black	\N
3a3b0075f5cb6d88ebf49289f96d3d094b1bbe65	Valensi N	\N	variety	t	{table}	black	\N
a38d99935526c5e01b286eec1eaeeda53cc7f1b2	Calabrese N (= Nero D'Avola)	\N	variety	t	{wine}	black	\N
d02a0d812dc94d99352f092347e9011baefabd9f	Joubertin N	\N	variety	t	{wine}	black	\N
a2b810053eba5c252792a93b73e56032c131fec4	Ondenc B	\N	variety	t	{wine}	white	\N
6abd5bf52c8610f6691e5e27ee3e6cfed1befb1f	Fanny B	\N	hybrid	t	{certified}	white	\N
2086c80a9bc0d111511d49dfc571fed7af81a39e	Feteasca Neagra N	\N	variety	t	{wine}	black	\N
084c4c86a278250b3c7fba8ad095f60db9166531	Villard Noir N	\N	hybrid	t	{wine}	black	\N
eb0db4326ca4d9c40edbb0076b916f18ace60b51	Mecle N (= Mescle)	\N	variety	t	{wine}	black	\N
5c64d3aaa5147441b015d288820560b846760369	Lakemont B	\N	hybrid	t	{certified}	white	\N
d9d1d90a42b49530c552524202a2c75b998f0e07	Piquepoul Noir N	\N	variety	t	{wine}	black	\N
d878355cbe7e926bb5c82d879e19f758c7ab6c49	Chasselas Muscat B	\N	variety	t	{table}	white	\N
0771b819b2d3d911164576bcb639e08677a08a43	Gamaret Noir N	\N	variety	t	{wine}	black	\N
59d1761bb71a81bea394b975f631a8aa771a51fc	Oeillade N	\N	variety	t	{table}	black	\N
3edb2e2ea20f308be25467917a50ff4f23721bc5	Saint-Pierre Dore B	\N	variety	t	{wine}	white	\N
a6a2f0bd02f8ef25980745d5f75cfe29fdb77604	Mancin N	\N	variety	t	{wine}	black	\N
08186d1737933c32049f122470f20cfc8c37b2e6	Reze B	\N	variety	t	{wine}	white	\N
ba16e99329dfba9ef18b19cf4bada87d31c8c2e2	Verdanel B	\N	variety	t	{wine}	white	\N
509278d8a1d94083f83e6d2a713bf19dc93d53ff	Gros Manseng Blanc B	\N	variety	t	{wine}	white	\N
26c8837cd48f34d6b604652301e134aaad0ae4b0	Suffolk Red Rg	\N	variety	t	{table}	red	\N
6fdccf913f63462f3a6a262758dec981ccfca337	Suffolk Red Rg	\N	variety	t	{table}	red	\N
4688417e3a7e1dd100353fb93f46d941aada11b1	Aramon N	\N	variety	t	{wine}	black	\N
f16a6db937c5c1c70586f7ed5fa44231e0417204	Landal N	\N	hybrid	t	{wine}	black	\N
f474ff5caf2b2e9c2a41b4a4524e037306b28500	Bouillet N	\N	variety	t	{wine}	black	\N
d95bbebf08a0e7eb53c4ab6941c4a73d96d7baee	Marselan N	\N	variety	t	{wine}	black	\N
0503701b8baa5a9b75a19d2d1504a017428b3f78	Voltis B	\N	hybrid	t	{wine}	white	\N
65edfa51710e8fafb40b479626f5ad89eaf1d2dd	Ravat Blanc B	\N	hybrid	t	{wine}	white	\N
a247919bbfba801172390bac06ae8a846b3d3399	Fuella Nera N	\N	variety	t	{wine}	black	\N
647159f01a0f5b8d7a842c48e9458de9f4a64837	Listan B	\N	variety	t	{wine}	white	\N
1f90f37351e1808adafcc5ae5b4f170d54634151	Chasselas B	\N	variety	t	{wine,table}	white	\N
df7daaed1e5870b1a2700ccd85a15b67777766b5	Plantet N	\N	hybrid	t	{wine}	black	\N
4b042b9690d98a1ff4c3a2e7ad033cd5affb1ce8	Auxerrois B	\N	variety	t	{wine}	white	\N
9937de364749fd56a1f8ef6097f5ed28dba3bf79	Exalta B	\N	variety	t	{table}	white	\N
44e89915cdadd9b154ce21424e550a277cd52535	Barbaroux Rs	\N	variety	t	{wine}	pink	\N
72abd04988f80ebfd6958b8b93be748534a913f3	Tibouren N	\N	variety	t	{wine}	black	\N
240991e779aedf793996477980ee598c59dde999	Danam B	\N	variety	t	{table}	white	\N
def25da01d7c89efcb3f27be73750d4336210b44	Petit Meslier B	\N	variety	t	{wine}	white	\N
576675d449bcb6ba6e31245d95491759d56a4118	Vermentino B	\N	variety	t	{wine}	white	\N
3143789b93386592d42415f89489d6360dfe24fb	Gamay Freaux N	\N	variety	t	{wine}	black	\N
e60c354cb0c575384f3e3b917daf1b506e894ca5	Chardonnay Rose Rs	\N	variety	t	{wine}	pink	\N
d6aa91ed021472a5d257e316f8ed814b68e7c8b8	Savagnin Rose Rs	\N	variety	t	{wine}	pink	\N
5ddcdb63ea195f3adab84b0138b2a84d15f85bae	Petit Manseng B	\N	variety	t	{wine}	white	\N
c3eae641fb6b0c82875fcd15554afba6ca0e6c94	Crouchen B	\N	variety	t	{wine}	white	\N
ad592d7cb129ee6f43e9924f255b0df1ad1280a1	Flot Rouge N	\N	hybrid	t	{juice}	black	\N
ed4a106d13b3fdeb803c40a83a88fb8fa76bf01f	Muscat Ottonel B	\N	variety	t	{wine}	white	\N
3642a7de53da7f00e192e338d29c60e0b84e5027	Muscat Bleu N	\N	hybrid	t	{table}	black	\N
8acfd7b9a0d06c7b502e427f18cea0c98f5f10f6	Mireille B	\N	variety	t	{table}	white	\N
dadd12b5d95ff730a2db3a4d62c9b41a9e97beca	Perdin B	\N	variety	t	{table}	white	\N
ac6dc7ca57774d1b6d4cd6448b5e0414f9e941b1	Arvine B	\N	variety	t	{wine}	white	\N
1a27b86a028b0b5eadc581720cf309abefa1702f	Perdea B	\N	variety	t	{wine}	white	\N
574ac2d09c1a2be17a7e4663736b3451069832f7	Genovese B	\N	variety	t	{wine}	white	\N
25f05fe3145c111337b995e1aeec604554fc3e3b	Chatus N	\N	variety	t	{wine}	black	\N
c0c8bf41361172bfd7436e5ccb4b36c89ade1137	Candin B	\N	variety	t	{table}	white	\N
CUS_EKY_VARIETY_3309	Couderc	Couderc	rootstock	f	{wine}	\N	3309
CUS_EKY_VARIETY_9960	Riparia	Riparia	rootstock	f	{wine}	\N	9960
CUS_EKY_VARIETY_9985	Binova	Binova	rootstock	f	{wine}	\N	9985
CUS_EKY_VARIETY_9986	Borner	Borner	rootstock	f	{wine}	\N	9986
\.


--
-- PostgreSQL database dump complete
--

