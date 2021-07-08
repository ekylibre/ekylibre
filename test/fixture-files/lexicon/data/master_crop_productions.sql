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

COPY lexicon__5_0_0.master_crop_productions (reference_name, specie, usage, started_on, stopped_on, agroedi_crop_code, season, life_duration, translation_id) FROM stdin;
    vine    vitis   fruit   2000-11-01      2001-10-31      ZMO     \N      70 years        crop_productions_vine 
\.
