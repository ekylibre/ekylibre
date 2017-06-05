--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.7
-- Dumped by pg_dump version 9.5.7

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: postgis; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA postgis;


SET search_path = public, pg_catalog;

--
-- Name: compute_outgoing_payment_list_cache(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION compute_outgoing_payment_list_cache() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
              DECLARE
                new_id INTEGER DEFAULT NULL;
                old_id INTEGER DEFAULT NULL;
              BEGIN
                IF TG_OP <> 'DELETE' THEN
                  new_id := NEW.list_id;
                END IF;

                IF TG_OP <> 'INSERT' THEN
                  old_id := OLD.list_id;
                END IF;

                UPDATE outgoing_payment_lists
                   SET cached_payment_count = payments.count,
                       cached_total_sum = payments.total
                  FROM (
                    SELECT outgoing_payments.list_id AS list_id,
                           SUM(outgoing_payments.amount) AS total,
                           COUNT(outgoing_payments.id) AS count
                      FROM outgoing_payments
                      GROUP BY outgoing_payments.list_id
                  ) AS payments
                  WHERE payments.list_id = id
                    AND ((new_id IS NOT NULL AND id = new_id)
                     OR  (old_id IS NOT NULL AND id = old_id));
                RETURN NEW;
              END
            $$;


--
-- Name: compute_partial_lettering(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION compute_partial_lettering() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE
      new_letter varchar DEFAULT NULL;
      old_letter varchar DEFAULT NULL;
      new_account_id integer DEFAULT NULL;
      old_account_id integer DEFAULT NULL;
    BEGIN
    IF TG_OP <> 'DELETE' THEN
      IF NEW.letter IS NOT NULL THEN
        new_letter := substring(NEW.letter from '[A-z]*');
      END IF;

    IF NEW.account_id IS NOT NULL THEN
      new_account_id := NEW.account_id;
    END IF;
  END IF;

  IF TG_OP <> 'INSERT' THEN
    IF OLD.letter IS NOT NULL THEN
      old_letter := substring(OLD.letter from '[A-z]*');
    END IF;

    IF OLD.account_id IS NOT NULL THEN
      old_account_id := OLD.account_id;
    END IF;
  END IF;

  UPDATE journal_entry_items
  SET letter = (CASE
                  WHEN modified_letter_groups.balance <> 0
                  THEN modified_letter_groups.letter || '*'
                  ELSE modified_letter_groups.letter
                END)
  FROM (SELECT new_letter AS letter,
               account_id AS account_id,
               SUM(debit) - SUM(credit) AS balance
            FROM journal_entry_items
            WHERE account_id = new_account_id
              AND letter SIMILAR TO (COALESCE(new_letter, '') || '\**')
              AND new_letter IS NOT NULL
              AND new_account_id IS NOT NULL
            GROUP BY account_id
        UNION ALL
        SELECT old_letter AS letter,
               account_id AS account_id,
               SUM(debit) - SUM(credit) AS balance
          FROM journal_entry_items
          WHERE account_id = old_account_id
            AND letter SIMILAR TO (COALESCE(old_letter, '') || '\**')
            AND old_letter IS NOT NULL
            AND old_account_id IS NOT NULL
          GROUP BY account_id) AS modified_letter_groups
  WHERE modified_letter_groups.account_id = journal_entry_items.account_id
  AND journal_entry_items.letter SIMILAR TO (modified_letter_groups.letter || '\**');

  RETURN NEW;
END;
$$;


--
-- Name: synchronize_jei_with_entry(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION synchronize_jei_with_entry() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  synced_entry_id integer DEFAULT NULL;
BEGIN
  IF TG_NARGS <> 0 THEN
    IF TG_ARGV[0] = 'jei' THEN
      synced_entry_id := NEW.entry_id;
    END IF;

    IF TG_ARGV[0] = 'entry' THEN
      synced_entry_id := NEW.id;
    END IF;
  END IF;

  UPDATE journal_entry_items AS jei
  SET state = entries.state,
      printed_on = entries.printed_on,
      journal_id = entries.journal_id,
      financial_year_id = entries.financial_year_id,
      entry_number = entries.number,
      real_currency = entries.real_currency,
      real_currency_rate = entries.real_currency_rate
  FROM journal_entries AS entries
  WHERE jei.entry_id = synced_entry_id
    AND entries.id = synced_entry_id
    AND synced_entry_id IS NOT NULL
    AND (jei.state <> entries.state
     OR jei.printed_on <> entries.printed_on
     OR jei.journal_id <> entries.journal_id
     OR jei.financial_year_id <> entries.financial_year_id
     OR jei.entry_number <> entries.number
     OR jei.real_currency <> entries.real_currency
     OR jei.real_currency_rate <> entries.real_currency_rate);
  RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: account_balances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE account_balances (
    id integer NOT NULL,
    account_id integer NOT NULL,
    financial_year_id integer NOT NULL,
    global_debit numeric(19,4) DEFAULT 0.0 NOT NULL,
    global_credit numeric(19,4) DEFAULT 0.0 NOT NULL,
    global_balance numeric(19,4) DEFAULT 0.0 NOT NULL,
    global_count integer DEFAULT 0 NOT NULL,
    local_debit numeric(19,4) DEFAULT 0.0 NOT NULL,
    local_credit numeric(19,4) DEFAULT 0.0 NOT NULL,
    local_balance numeric(19,4) DEFAULT 0.0 NOT NULL,
    local_count integer DEFAULT 0 NOT NULL,
    currency character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: account_balances_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE account_balances_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_balances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE account_balances_id_seq OWNED BY account_balances.id;


--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE accounts (
    id integer NOT NULL,
    number character varying NOT NULL,
    name character varying NOT NULL,
    label character varying NOT NULL,
    debtor boolean DEFAULT false NOT NULL,
    last_letter character varying,
    description text,
    reconcilable boolean DEFAULT false NOT NULL,
    usages text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb
);


--
-- Name: accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE accounts_id_seq OWNED BY accounts.id;


--
-- Name: activities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE activities (
    id integer NOT NULL,
    name character varying NOT NULL,
    description text,
    family character varying NOT NULL,
    nature character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    with_supports boolean NOT NULL,
    with_cultivation boolean NOT NULL,
    support_variety character varying,
    cultivation_variety character varying,
    size_indicator_name character varying,
    size_unit_name character varying,
    suspended boolean DEFAULT false NOT NULL,
    production_cycle character varying NOT NULL,
    production_campaign character varying,
    custom_fields jsonb,
    use_countings boolean DEFAULT false NOT NULL,
    use_gradings boolean DEFAULT false NOT NULL,
    measure_grading_items_count boolean DEFAULT false NOT NULL,
    measure_grading_net_mass boolean DEFAULT false NOT NULL,
    grading_net_mass_unit_name character varying,
    measure_grading_sizes boolean DEFAULT false NOT NULL,
    grading_sizes_indicator_name character varying,
    grading_sizes_unit_name character varying,
    production_system_name character varying,
    use_seasons boolean DEFAULT false,
    use_tactics boolean DEFAULT false
);


--
-- Name: activity_budgets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE activity_budgets (
    id integer NOT NULL,
    activity_id integer NOT NULL,
    campaign_id integer NOT NULL,
    currency character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: activity_productions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE activity_productions (
    id integer NOT NULL,
    support_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    usage character varying NOT NULL,
    size_value numeric(19,4) NOT NULL,
    size_indicator_name character varying NOT NULL,
    size_unit_name character varying,
    activity_id integer NOT NULL,
    cultivable_zone_id integer,
    irrigated boolean DEFAULT false NOT NULL,
    nitrate_fixing boolean DEFAULT false NOT NULL,
    support_shape postgis.geometry(MultiPolygon,4326),
    support_nature character varying,
    started_on date,
    stopped_on date,
    state character varying,
    rank_number integer NOT NULL,
    campaign_id integer,
    custom_fields jsonb,
    season_id integer,
    tactic_id integer
);


--
-- Name: campaigns; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE campaigns (
    id integer NOT NULL,
    name character varying NOT NULL,
    description text,
    harvest_year integer,
    closed boolean DEFAULT false NOT NULL,
    closed_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: activities_campaigns; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW activities_campaigns AS
 SELECT DISTINCT c.id AS campaign_id,
    a.id AS activity_id
   FROM (activities a
     LEFT JOIN campaigns c ON ((((a.id, c.id) IN ( SELECT ab.activity_id,
            ab.campaign_id
           FROM activity_budgets ab
          WHERE ((ab.campaign_id = c.id) AND (ab.activity_id = a.id)))) OR ((a.id, c.id) IN ( SELECT ap.activity_id,
            ap.campaign_id
           FROM activity_productions ap
          WHERE ((ap.campaign_id = c.id) AND (ap.activity_id = a.id)))))));


--
-- Name: activities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE activities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE activities_id_seq OWNED BY activities.id;


--
-- Name: intervention_parameters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE intervention_parameters (
    id integer NOT NULL,
    intervention_id integer NOT NULL,
    product_id integer,
    variant_id integer,
    quantity_population numeric(19,4),
    working_zone postgis.geometry(MultiPolygon,4326),
    reference_name character varying NOT NULL,
    "position" integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    event_participation_id integer,
    outcoming_product_id integer,
    type character varying,
    new_container_id integer,
    new_group_id integer,
    new_variant_id integer,
    quantity_handler character varying,
    quantity_value numeric(19,4),
    quantity_unit_name character varying,
    quantity_indicator_name character varying,
    group_id integer,
    new_name character varying,
    component_id integer,
    assembly_id integer,
    currency character varying,
    unit_pretax_stock_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    dead boolean DEFAULT false NOT NULL,
    identification_number character varying
);


--
-- Name: interventions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE interventions (
    id integer NOT NULL,
    issue_id integer,
    prescription_id integer,
    procedure_name character varying NOT NULL,
    state character varying NOT NULL,
    started_at timestamp without time zone NOT NULL,
    stopped_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    event_id integer,
    number character varying,
    description text,
    working_duration integer NOT NULL,
    whole_duration integer NOT NULL,
    actions character varying,
    custom_fields jsonb,
    nature character varying NOT NULL,
    request_intervention_id integer,
    trouble_encountered boolean DEFAULT false NOT NULL,
    trouble_description text,
    accounted_at timestamp without time zone,
    currency character varying,
    journal_entry_id integer,
    request_compliant boolean
);


--
-- Name: target_distributions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE target_distributions (
    id integer NOT NULL,
    target_id integer NOT NULL,
    activity_production_id integer NOT NULL,
    activity_id integer NOT NULL,
    started_at timestamp without time zone,
    stopped_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: activities_interventions; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW activities_interventions AS
 SELECT DISTINCT interventions.id AS intervention_id,
    activities.id AS activity_id
   FROM ((((activities
     JOIN activity_productions ON ((activity_productions.activity_id = activities.id)))
     JOIN target_distributions ON ((target_distributions.activity_production_id = activity_productions.id)))
     JOIN intervention_parameters ON ((target_distributions.target_id = intervention_parameters.product_id)))
     JOIN interventions ON ((intervention_parameters.intervention_id = interventions.id)))
  ORDER BY interventions.id;


--
-- Name: activity_budget_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE activity_budget_items (
    id integer NOT NULL,
    variant_id integer NOT NULL,
    direction character varying NOT NULL,
    amount numeric(19,4) DEFAULT 0.0,
    unit_amount numeric(19,4) DEFAULT 0.0,
    quantity numeric(19,4) DEFAULT 0.0,
    variant_indicator character varying,
    variant_unit character varying,
    computation_method character varying NOT NULL,
    currency character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    unit_population numeric(19,4),
    unit_currency character varying NOT NULL,
    activity_budget_id integer NOT NULL
);


--
-- Name: activity_budget_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE activity_budget_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_budget_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE activity_budget_items_id_seq OWNED BY activity_budget_items.id;


--
-- Name: activity_budgets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE activity_budgets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_budgets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE activity_budgets_id_seq OWNED BY activity_budgets.id;


--
-- Name: activity_distributions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE activity_distributions (
    id integer NOT NULL,
    activity_id integer NOT NULL,
    affectation_percentage numeric(19,4) NOT NULL,
    main_activity_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: activity_distributions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE activity_distributions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_distributions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE activity_distributions_id_seq OWNED BY activity_distributions.id;


--
-- Name: activity_inspection_calibration_natures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE activity_inspection_calibration_natures (
    id integer NOT NULL,
    scale_id integer NOT NULL,
    marketable boolean DEFAULT false NOT NULL,
    minimal_value numeric(19,4) NOT NULL,
    maximal_value numeric(19,4) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: activity_inspection_calibration_natures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE activity_inspection_calibration_natures_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_inspection_calibration_natures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE activity_inspection_calibration_natures_id_seq OWNED BY activity_inspection_calibration_natures.id;


--
-- Name: activity_inspection_calibration_scales; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE activity_inspection_calibration_scales (
    id integer NOT NULL,
    activity_id integer NOT NULL,
    size_indicator_name character varying NOT NULL,
    size_unit_name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: activity_inspection_calibration_scales_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE activity_inspection_calibration_scales_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_inspection_calibration_scales_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE activity_inspection_calibration_scales_id_seq OWNED BY activity_inspection_calibration_scales.id;


--
-- Name: activity_inspection_point_natures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE activity_inspection_point_natures (
    id integer NOT NULL,
    activity_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    name character varying NOT NULL,
    category character varying NOT NULL
);


--
-- Name: activity_inspection_point_natures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE activity_inspection_point_natures_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_inspection_point_natures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE activity_inspection_point_natures_id_seq OWNED BY activity_inspection_point_natures.id;


--
-- Name: activity_productions_campaigns; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW activity_productions_campaigns AS
 SELECT DISTINCT c.id AS campaign_id,
    ap.id AS activity_production_id
   FROM ((activity_productions ap
     JOIN activities a ON ((ap.activity_id = a.id)))
     LEFT JOIN campaigns c ON (((c.id = ap.campaign_id) OR ((c.id IS NOT NULL) AND ((a.production_cycle)::text = 'perennial'::text) AND ((((a.production_campaign)::text = 'at_cycle_start'::text) AND (((ap.stopped_on IS NULL) AND ((c.harvest_year)::double precision >= date_part('year'::text, ap.started_on))) OR ((ap.stopped_on IS NOT NULL) AND (date_part('year'::text, ap.started_on) <= (c.harvest_year)::double precision) AND ((c.harvest_year)::double precision < date_part('year'::text, ap.stopped_on))))) OR (((a.production_campaign)::text = 'at_cycle_end'::text) AND (((ap.stopped_on IS NULL) AND ((c.harvest_year)::double precision > date_part('year'::text, ap.started_on))) OR ((ap.stopped_on IS NOT NULL) AND (date_part('year'::text, ap.started_on) < (c.harvest_year)::double precision) AND ((c.harvest_year)::double precision <= date_part('year'::text, ap.stopped_on))))))))))
  ORDER BY c.id;


--
-- Name: activity_productions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE activity_productions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_productions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE activity_productions_id_seq OWNED BY activity_productions.id;


--
-- Name: activity_productions_interventions; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW activity_productions_interventions AS
 SELECT DISTINCT interventions.id AS intervention_id,
    target_distributions.activity_production_id
   FROM (((activities
     JOIN target_distributions ON ((target_distributions.activity_id = activities.id)))
     JOIN intervention_parameters ON ((target_distributions.target_id = intervention_parameters.product_id)))
     JOIN interventions ON ((intervention_parameters.intervention_id = interventions.id)))
  ORDER BY interventions.id;


--
-- Name: activity_seasons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE activity_seasons (
    id integer NOT NULL,
    activity_id integer NOT NULL,
    name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: activity_seasons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE activity_seasons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_seasons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE activity_seasons_id_seq OWNED BY activity_seasons.id;


--
-- Name: activity_tactics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE activity_tactics (
    id integer NOT NULL,
    activity_id integer NOT NULL,
    name character varying NOT NULL,
    planned_on date,
    mode_delta integer,
    mode character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: activity_tactics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE activity_tactics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_tactics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE activity_tactics_id_seq OWNED BY activity_tactics.id;


--
-- Name: affairs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE affairs (
    id integer NOT NULL,
    number character varying NOT NULL,
    closed boolean DEFAULT false NOT NULL,
    closed_at timestamp without time zone,
    third_id integer NOT NULL,
    currency character varying NOT NULL,
    debit numeric(19,4) DEFAULT 0.0 NOT NULL,
    credit numeric(19,4) DEFAULT 0.0 NOT NULL,
    accounted_at timestamp without time zone,
    journal_entry_id integer,
    deals_count integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    cash_session_id integer,
    responsible_id integer,
    dead_line_at timestamp without time zone,
    name character varying,
    description text,
    pretax_amount numeric(19,4) DEFAULT 0.0,
    origin character varying,
    type character varying,
    state character varying,
    probability_percentage numeric(19,4) DEFAULT 0.0,
    letter character varying
);


--
-- Name: affairs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE affairs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: affairs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE affairs_id_seq OWNED BY affairs.id;


--
-- Name: alert_phases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE alert_phases (
    id integer NOT NULL,
    alert_id integer NOT NULL,
    started_at timestamp without time zone NOT NULL,
    level integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: alert_phases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE alert_phases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: alert_phases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE alert_phases_id_seq OWNED BY alert_phases.id;


--
-- Name: alerts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE alerts (
    id integer NOT NULL,
    sensor_id integer,
    nature character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: alerts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE alerts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: alerts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE alerts_id_seq OWNED BY alerts.id;


--
-- Name: analyses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE analyses (
    id integer NOT NULL,
    number character varying NOT NULL,
    nature character varying NOT NULL,
    reference_number character varying,
    product_id integer,
    sampler_id integer,
    analyser_id integer,
    description text,
    geolocation postgis.geometry(Point,4326),
    sampled_at timestamp without time zone NOT NULL,
    analysed_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    host_id integer,
    sensor_id integer,
    sampling_temporal_mode character varying DEFAULT 'instant'::character varying NOT NULL,
    stopped_at timestamp without time zone,
    retrieval_status character varying DEFAULT 'ok'::character varying NOT NULL,
    retrieval_message character varying,
    custom_fields jsonb
);


--
-- Name: analyses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE analyses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: analyses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE analyses_id_seq OWNED BY analyses.id;


--
-- Name: analysis_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE analysis_items (
    id integer NOT NULL,
    analysis_id integer NOT NULL,
    indicator_name character varying NOT NULL,
    indicator_datatype character varying NOT NULL,
    absolute_measure_value_value numeric(19,4),
    absolute_measure_value_unit character varying,
    boolean_value boolean DEFAULT false NOT NULL,
    choice_value character varying,
    decimal_value numeric(19,4),
    multi_polygon_value postgis.geometry(MultiPolygon,4326),
    integer_value integer,
    measure_value_value numeric(19,4),
    measure_value_unit character varying,
    point_value postgis.geometry(Point,4326),
    string_value text,
    annotation text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    product_reading_id integer,
    geometry_value postgis.geometry(Geometry,4326)
);


--
-- Name: analysis_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE analysis_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: analysis_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE analysis_items_id_seq OWNED BY analysis_items.id;


--
-- Name: attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE attachments (
    id integer NOT NULL,
    resource_id integer NOT NULL,
    resource_type character varying NOT NULL,
    document_id integer NOT NULL,
    nature character varying,
    expired_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE attachments_id_seq OWNED BY attachments.id;


--
-- Name: bank_statement_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE bank_statement_items (
    id integer NOT NULL,
    bank_statement_id integer NOT NULL,
    name character varying NOT NULL,
    debit numeric(19,4) DEFAULT 0.0 NOT NULL,
    credit numeric(19,4) DEFAULT 0.0 NOT NULL,
    currency character varying NOT NULL,
    transfered_on date NOT NULL,
    initiated_on date,
    transaction_number character varying,
    letter character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    memo character varying
);


--
-- Name: bank_statement_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE bank_statement_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bank_statement_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE bank_statement_items_id_seq OWNED BY bank_statement_items.id;


--
-- Name: bank_statements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE bank_statements (
    id integer NOT NULL,
    cash_id integer NOT NULL,
    started_on date NOT NULL,
    stopped_on date NOT NULL,
    number character varying NOT NULL,
    debit numeric(19,4) DEFAULT 0.0 NOT NULL,
    credit numeric(19,4) DEFAULT 0.0 NOT NULL,
    currency character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb,
    initial_balance_debit numeric(19,4) DEFAULT 0.0 NOT NULL,
    initial_balance_credit numeric(19,4) DEFAULT 0.0 NOT NULL,
    journal_entry_id integer,
    accounted_at timestamp without time zone
);


--
-- Name: bank_statements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE bank_statements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bank_statements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE bank_statements_id_seq OWNED BY bank_statements.id;


--
-- Name: call_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE call_messages (
    id integer NOT NULL,
    status character varying,
    headers text,
    body text,
    type character varying,
    nature character varying NOT NULL,
    ip_address character varying,
    url character varying,
    format character varying,
    ssl character varying,
    verb character varying,
    request_id integer,
    call_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: call_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE call_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: call_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE call_messages_id_seq OWNED BY call_messages.id;


--
-- Name: calls; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE calls (
    id integer NOT NULL,
    state character varying,
    integration_name character varying,
    name character varying,
    arguments jsonb,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    source_id integer,
    source_type character varying
);


--
-- Name: calls_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE calls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: calls_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE calls_id_seq OWNED BY calls.id;


--
-- Name: campaigns_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE campaigns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: campaigns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE campaigns_id_seq OWNED BY campaigns.id;


--
-- Name: campaigns_interventions; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW campaigns_interventions AS
 SELECT DISTINCT campaigns.id AS campaign_id,
    interventions.id AS intervention_id
   FROM ((((interventions
     JOIN intervention_parameters ON ((intervention_parameters.intervention_id = interventions.id)))
     JOIN target_distributions ON ((target_distributions.target_id = intervention_parameters.product_id)))
     JOIN activity_productions ON ((target_distributions.activity_production_id = activity_productions.id)))
     JOIN campaigns ON ((activity_productions.campaign_id = campaigns.id)))
  ORDER BY campaigns.id;


--
-- Name: cap_islets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cap_islets (
    id integer NOT NULL,
    cap_statement_id integer NOT NULL,
    islet_number character varying NOT NULL,
    town_number character varying,
    shape postgis.geometry(MultiPolygon,4326) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: cap_islets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cap_islets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cap_islets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cap_islets_id_seq OWNED BY cap_islets.id;


--
-- Name: cap_land_parcels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cap_land_parcels (
    id integer NOT NULL,
    cap_islet_id integer NOT NULL,
    support_id integer,
    land_parcel_number character varying NOT NULL,
    main_crop_code character varying NOT NULL,
    main_crop_precision character varying,
    main_crop_seed_production boolean DEFAULT false NOT NULL,
    main_crop_commercialisation boolean DEFAULT false NOT NULL,
    shape postgis.geometry(MultiPolygon,4326) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: cap_land_parcels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cap_land_parcels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cap_land_parcels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cap_land_parcels_id_seq OWNED BY cap_land_parcels.id;


--
-- Name: cap_statements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cap_statements (
    id integer NOT NULL,
    campaign_id integer NOT NULL,
    declarant_id integer,
    pacage_number character varying,
    siret_number character varying,
    farm_name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: cap_statements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cap_statements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cap_statements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cap_statements_id_seq OWNED BY cap_statements.id;


--
-- Name: cash_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cash_sessions (
    id integer NOT NULL,
    cash_id integer NOT NULL,
    number character varying,
    started_at timestamp without time zone NOT NULL,
    stopped_at timestamp without time zone,
    currency character varying,
    noticed_start_amount numeric(19,4) DEFAULT 0.0,
    noticed_stop_amount numeric(19,4) DEFAULT 0.0,
    expected_stop_amount numeric(19,4) DEFAULT 0.0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: cash_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cash_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cash_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cash_sessions_id_seq OWNED BY cash_sessions.id;


--
-- Name: cash_transfers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cash_transfers (
    id integer NOT NULL,
    number character varying NOT NULL,
    description text,
    transfered_at timestamp without time zone NOT NULL,
    accounted_at timestamp without time zone,
    emission_amount numeric(19,4) NOT NULL,
    emission_currency character varying NOT NULL,
    emission_cash_id integer NOT NULL,
    emission_journal_entry_id integer,
    currency_rate numeric(19,10) NOT NULL,
    reception_amount numeric(19,4) NOT NULL,
    reception_currency character varying NOT NULL,
    reception_cash_id integer NOT NULL,
    reception_journal_entry_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb
);


--
-- Name: cash_transfers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cash_transfers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cash_transfers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cash_transfers_id_seq OWNED BY cash_transfers.id;


--
-- Name: cashes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cashes (
    id integer NOT NULL,
    name character varying NOT NULL,
    nature character varying DEFAULT 'bank_account'::character varying NOT NULL,
    journal_id integer NOT NULL,
    main_account_id integer NOT NULL,
    bank_code character varying,
    bank_agency_code character varying,
    bank_account_number character varying,
    bank_account_key character varying,
    bank_agency_address text,
    bank_name character varying,
    mode character varying DEFAULT 'iban'::character varying NOT NULL,
    bank_identifier_code character varying,
    iban character varying,
    spaced_iban character varying,
    currency character varying NOT NULL,
    country character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    container_id integer,
    last_number integer,
    owner_id integer,
    custom_fields jsonb,
    bank_account_holder_name character varying,
    suspend_until_reconciliation boolean DEFAULT false NOT NULL,
    suspense_account_id integer
);


--
-- Name: cashes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cashes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cashes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cashes_id_seq OWNED BY cashes.id;


--
-- Name: catalog_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE catalog_items (
    id integer NOT NULL,
    name character varying NOT NULL,
    variant_id integer NOT NULL,
    catalog_id integer NOT NULL,
    reference_tax_id integer,
    amount numeric(19,4) NOT NULL,
    all_taxes_included boolean DEFAULT false NOT NULL,
    currency character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    commercial_description text,
    commercial_name character varying
);


--
-- Name: catalog_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE catalog_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: catalog_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE catalog_items_id_seq OWNED BY catalog_items.id;


--
-- Name: catalogs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE catalogs (
    id integer NOT NULL,
    name character varying NOT NULL,
    usage character varying NOT NULL,
    code character varying NOT NULL,
    by_default boolean DEFAULT false NOT NULL,
    all_taxes_included boolean DEFAULT false NOT NULL,
    currency character varying NOT NULL,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: catalogs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE catalogs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: catalogs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE catalogs_id_seq OWNED BY catalogs.id;


--
-- Name: contract_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE contract_items (
    id integer NOT NULL,
    contract_id integer NOT NULL,
    variant_id integer NOT NULL,
    quantity numeric(19,4) DEFAULT 0.0 NOT NULL,
    unit_pretax_amount numeric(19,4) NOT NULL,
    pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: contract_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contract_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contract_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contract_items_id_seq OWNED BY contract_items.id;


--
-- Name: contracts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE contracts (
    id integer NOT NULL,
    number character varying,
    description character varying,
    state character varying,
    reference_number character varying,
    started_on date,
    stopped_on date,
    custom_fields jsonb,
    pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    currency character varying NOT NULL,
    responsible_id integer NOT NULL,
    supplier_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: contracts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contracts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contracts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contracts_id_seq OWNED BY contracts.id;


--
-- Name: crumbs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE crumbs (
    id integer NOT NULL,
    user_id integer,
    geolocation postgis.geometry(Point,4326) NOT NULL,
    read_at timestamp without time zone NOT NULL,
    accuracy numeric(19,4) NOT NULL,
    nature character varying NOT NULL,
    metadata text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    intervention_parameter_id integer,
    device_uid character varying NOT NULL,
    intervention_participation_id integer
);


--
-- Name: crumbs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE crumbs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crumbs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE crumbs_id_seq OWNED BY crumbs.id;


--
-- Name: cultivable_zones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cultivable_zones (
    id integer NOT NULL,
    name character varying NOT NULL,
    work_number character varying NOT NULL,
    shape postgis.geometry(MultiPolygon,4326) NOT NULL,
    description text,
    uuid uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb,
    production_system_name character varying,
    soil_nature character varying,
    owner_id integer,
    farmer_id integer
);


--
-- Name: cultivable_zones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cultivable_zones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cultivable_zones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cultivable_zones_id_seq OWNED BY cultivable_zones.id;


--
-- Name: custom_field_choices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE custom_field_choices (
    id integer NOT NULL,
    custom_field_id integer NOT NULL,
    name character varying NOT NULL,
    value character varying,
    "position" integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: custom_field_choices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE custom_field_choices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: custom_field_choices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE custom_field_choices_id_seq OWNED BY custom_field_choices.id;


--
-- Name: custom_fields; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE custom_fields (
    id integer NOT NULL,
    name character varying NOT NULL,
    nature character varying NOT NULL,
    column_name character varying NOT NULL,
    active boolean DEFAULT true NOT NULL,
    required boolean DEFAULT false NOT NULL,
    maximal_length integer,
    minimal_value numeric(19,4),
    maximal_value numeric(19,4),
    customized_type character varying NOT NULL,
    minimal_length integer,
    "position" integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: custom_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE custom_fields_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: custom_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE custom_fields_id_seq OWNED BY custom_fields.id;


--
-- Name: dashboards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE dashboards (
    id integer NOT NULL,
    owner_id integer NOT NULL,
    name character varying NOT NULL,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: dashboards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE dashboards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dashboards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE dashboards_id_seq OWNED BY dashboards.id;


--
-- Name: debt_transfers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE debt_transfers (
    id integer NOT NULL,
    affair_id integer NOT NULL,
    debt_transfer_affair_id integer NOT NULL,
    amount numeric(19,4) DEFAULT 0.0,
    number character varying,
    nature character varying NOT NULL,
    currency character varying NOT NULL,
    journal_entry_id integer,
    accounted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: debt_transfers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE debt_transfers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: debt_transfers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE debt_transfers_id_seq OWNED BY debt_transfers.id;


--
-- Name: deliveries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE deliveries (
    id integer NOT NULL,
    transporter_id integer,
    responsible_id integer,
    started_at timestamp without time zone,
    annotation text,
    number character varying,
    reference_number character varying,
    transporter_purchase_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    stopped_at timestamp without time zone,
    state character varying NOT NULL,
    driver_id integer,
    mode character varying,
    custom_fields jsonb
);


--
-- Name: deliveries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE deliveries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: deliveries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE deliveries_id_seq OWNED BY deliveries.id;


--
-- Name: delivery_tools; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE delivery_tools (
    id integer NOT NULL,
    delivery_id integer,
    tool_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: delivery_tools_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE delivery_tools_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delivery_tools_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE delivery_tools_id_seq OWNED BY delivery_tools.id;


--
-- Name: deposits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE deposits (
    id integer NOT NULL,
    number character varying NOT NULL,
    cash_id integer NOT NULL,
    mode_id integer NOT NULL,
    amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    payments_count integer DEFAULT 0 NOT NULL,
    description text,
    locked boolean DEFAULT false NOT NULL,
    responsible_id integer,
    accounted_at timestamp without time zone,
    journal_entry_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb
);


--
-- Name: deposits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE deposits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: deposits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE deposits_id_seq OWNED BY deposits.id;


--
-- Name: districts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE districts (
    id integer NOT NULL,
    name character varying NOT NULL,
    code character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: districts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE districts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: districts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE districts_id_seq OWNED BY districts.id;


--
-- Name: document_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE document_templates (
    id integer NOT NULL,
    name character varying NOT NULL,
    active boolean DEFAULT false NOT NULL,
    by_default boolean DEFAULT false NOT NULL,
    nature character varying NOT NULL,
    language character varying NOT NULL,
    archiving character varying NOT NULL,
    managed boolean DEFAULT false NOT NULL,
    formats character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: document_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE document_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: document_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE document_templates_id_seq OWNED BY document_templates.id;


--
-- Name: documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE documents (
    id integer NOT NULL,
    number character varying NOT NULL,
    name character varying NOT NULL,
    nature character varying,
    key character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    uploaded boolean DEFAULT false NOT NULL,
    template_id integer,
    file_file_name character varying,
    file_file_size integer,
    file_content_type character varying,
    file_updated_at timestamp without time zone,
    file_fingerprint character varying,
    file_pages_count integer,
    file_content_text text,
    custom_fields jsonb
);


--
-- Name: documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE documents_id_seq OWNED BY documents.id;


--
-- Name: entities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE entities (
    id integer NOT NULL,
    nature character varying NOT NULL,
    last_name character varying NOT NULL,
    first_name character varying,
    full_name character varying NOT NULL,
    number character varying,
    active boolean DEFAULT true NOT NULL,
    born_at timestamp without time zone,
    dead_at timestamp without time zone,
    client boolean DEFAULT false NOT NULL,
    client_account_id integer,
    supplier boolean DEFAULT false NOT NULL,
    supplier_account_id integer,
    transporter boolean DEFAULT false NOT NULL,
    prospect boolean DEFAULT false NOT NULL,
    vat_subjected boolean DEFAULT true NOT NULL,
    reminder_submissive boolean DEFAULT false NOT NULL,
    deliveries_conditions character varying,
    description text,
    language character varying NOT NULL,
    country character varying,
    currency character varying NOT NULL,
    authorized_payments_count integer,
    responsible_id integer,
    proposer_id integer,
    meeting_origin character varying,
    first_met_at timestamp without time zone,
    activity_code character varying,
    vat_number character varying,
    siret_number character varying,
    locked boolean DEFAULT false NOT NULL,
    of_company boolean DEFAULT false NOT NULL,
    picture_file_name character varying,
    picture_content_type character varying,
    picture_file_size integer,
    picture_updated_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    title character varying,
    custom_fields jsonb,
    employee boolean DEFAULT false NOT NULL,
    employee_account_id integer,
    codes jsonb,
    supplier_payment_delay character varying,
    bank_account_holder_name character varying,
    bank_identifier_code character varying,
    iban character varying,
    supplier_payment_mode_id integer,
    CONSTRAINT company_born_at_not_null CHECK (((of_company = false) OR ((of_company = true) AND (born_at IS NOT NULL))))
);


--
-- Name: incoming_payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE incoming_payments (
    id integer NOT NULL,
    paid_at timestamp without time zone,
    amount numeric(19,4) NOT NULL,
    mode_id integer NOT NULL,
    bank_name character varying,
    bank_check_number character varying,
    bank_account_number character varying,
    payer_id integer NOT NULL,
    to_bank_at timestamp without time zone NOT NULL,
    deposit_id integer,
    responsible_id integer,
    scheduled boolean DEFAULT false NOT NULL,
    received boolean DEFAULT true NOT NULL,
    number character varying,
    accounted_at timestamp without time zone,
    receipt text,
    journal_entry_id integer,
    commission_account_id integer,
    commission_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    currency character varying NOT NULL,
    downpayment boolean DEFAULT true NOT NULL,
    affair_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb,
    codes jsonb
);


--
-- Name: journal_entry_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE journal_entry_items (
    id integer NOT NULL,
    entry_id integer NOT NULL,
    journal_id integer NOT NULL,
    bank_statement_id integer,
    financial_year_id integer NOT NULL,
    state character varying NOT NULL,
    printed_on date NOT NULL,
    entry_number character varying NOT NULL,
    letter character varying,
    "position" integer,
    description text,
    account_id integer NOT NULL,
    name character varying NOT NULL,
    real_debit numeric(19,4) DEFAULT 0.0 NOT NULL,
    real_credit numeric(19,4) DEFAULT 0.0 NOT NULL,
    real_currency character varying NOT NULL,
    real_currency_rate numeric(19,10) DEFAULT 0.0 NOT NULL,
    debit numeric(19,4) DEFAULT 0.0 NOT NULL,
    credit numeric(19,4) DEFAULT 0.0 NOT NULL,
    balance numeric(19,4) DEFAULT 0.0 NOT NULL,
    currency character varying NOT NULL,
    absolute_debit numeric(19,4) DEFAULT 0.0 NOT NULL,
    absolute_credit numeric(19,4) DEFAULT 0.0 NOT NULL,
    absolute_currency character varying NOT NULL,
    cumulated_absolute_debit numeric(19,4) DEFAULT 0.0 NOT NULL,
    cumulated_absolute_credit numeric(19,4) DEFAULT 0.0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    real_balance numeric(19,4) DEFAULT 0.0 NOT NULL,
    bank_statement_letter character varying,
    activity_budget_id integer,
    team_id integer,
    tax_id integer,
    pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    real_pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    absolute_pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    tax_declaration_item_id integer,
    resource_id integer,
    resource_type character varying,
    resource_prism character varying,
    variant_id integer,
    tax_declaration_mode character varying
);


--
-- Name: outgoing_payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE outgoing_payments (
    id integer NOT NULL,
    accounted_at timestamp without time zone,
    amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    bank_check_number character varying,
    delivered boolean DEFAULT true NOT NULL,
    journal_entry_id integer,
    responsible_id integer NOT NULL,
    payee_id integer NOT NULL,
    mode_id integer NOT NULL,
    number character varying,
    paid_at timestamp without time zone,
    to_bank_at timestamp without time zone NOT NULL,
    cash_id integer NOT NULL,
    currency character varying NOT NULL,
    downpayment boolean DEFAULT true NOT NULL,
    affair_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb,
    list_id integer,
    "position" integer
);


--
-- Name: purchase_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE purchase_items (
    id integer NOT NULL,
    purchase_id integer NOT NULL,
    variant_id integer NOT NULL,
    quantity numeric(19,4) DEFAULT 1.0 NOT NULL,
    pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    tax_id integer NOT NULL,
    currency character varying NOT NULL,
    label text,
    annotation text,
    "position" integer,
    account_id integer NOT NULL,
    unit_pretax_amount numeric(19,4) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    unit_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    fixed boolean DEFAULT false NOT NULL,
    reduction_percentage numeric(19,4) DEFAULT 0.0 NOT NULL,
    activity_budget_id integer,
    team_id integer,
    depreciable_product_id integer,
    fixed_asset_id integer,
    preexisting_asset boolean
);


--
-- Name: purchases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE purchases (
    id integer NOT NULL,
    supplier_id integer NOT NULL,
    number character varying NOT NULL,
    pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    delivery_address_id integer,
    description text,
    planned_at timestamp without time zone,
    confirmed_at timestamp without time zone,
    invoiced_at timestamp without time zone,
    accounted_at timestamp without time zone,
    journal_entry_id integer,
    reference_number character varying,
    state character varying NOT NULL,
    responsible_id integer,
    currency character varying NOT NULL,
    nature_id integer NOT NULL,
    affair_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb,
    undelivered_invoice_journal_entry_id integer,
    quantity_gap_on_invoice_journal_entry_id integer,
    payment_delay character varying,
    payment_at timestamp without time zone,
    contract_id integer,
    tax_payability character varying NOT NULL
);


--
-- Name: sale_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sale_items (
    id integer NOT NULL,
    sale_id integer NOT NULL,
    variant_id integer NOT NULL,
    quantity numeric(19,4) DEFAULT 1.0 NOT NULL,
    pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    tax_id integer,
    currency character varying NOT NULL,
    label text,
    annotation text,
    "position" integer,
    account_id integer,
    unit_pretax_amount numeric(19,4),
    reduction_percentage numeric(19,4) DEFAULT 0.0 NOT NULL,
    credited_item_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    unit_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    credited_quantity numeric(19,4),
    activity_budget_id integer,
    team_id integer,
    codes jsonb,
    compute_from character varying NOT NULL
);


--
-- Name: sales; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sales (
    id integer NOT NULL,
    client_id integer NOT NULL,
    nature_id integer NOT NULL,
    number character varying NOT NULL,
    pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    state character varying NOT NULL,
    expired_at timestamp without time zone,
    has_downpayment boolean DEFAULT false NOT NULL,
    downpayment_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    address_id integer,
    invoice_address_id integer,
    delivery_address_id integer,
    subject character varying,
    function_title character varying,
    introduction text,
    conclusion text,
    description text,
    confirmed_at timestamp without time zone,
    responsible_id integer,
    letter_format boolean DEFAULT true NOT NULL,
    annotation text,
    transporter_id integer,
    accounted_at timestamp without time zone,
    journal_entry_id integer,
    reference_number character varying,
    invoiced_at timestamp without time zone,
    credit boolean DEFAULT false NOT NULL,
    payment_at timestamp without time zone,
    credited_sale_id integer,
    initial_number character varying,
    currency character varying NOT NULL,
    affair_id integer,
    expiration_delay character varying,
    payment_delay character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb,
    codes jsonb,
    undelivered_invoice_journal_entry_id integer,
    quantity_gap_on_invoice_journal_entry_id integer
);


--
-- Name: economic_situations; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW economic_situations AS
 SELECT entities.id,
    COALESCE(client_accounting.balance, (0)::numeric) AS client_accounting_balance,
    COALESCE(supplier_accounting.balance, (0)::numeric) AS supplier_accounting_balance,
    (COALESCE(client_accounting.balance, (0)::numeric) + COALESCE(supplier_accounting.balance, (0)::numeric)) AS accounting_balance,
    COALESCE(client_trade.balance, (0)::numeric) AS client_trade_balance,
    COALESCE(supplier_trade.balance, (0)::numeric) AS supplier_trade_balance,
    (COALESCE(client_trade.balance, (0)::numeric) + COALESCE(supplier_trade.balance, (0)::numeric)) AS trade_balance,
    entities.creator_id,
    entities.created_at,
    entities.updater_id,
    entities.updated_at,
    entities.lock_version
   FROM ((((entities
     LEFT JOIN ( SELECT entities_1.id AS entity_id,
            (- sum(client_items.balance)) AS balance
           FROM ((entities entities_1
             JOIN accounts clients ON ((entities_1.client_account_id = clients.id)))
             JOIN journal_entry_items client_items ON ((clients.id = client_items.account_id)))
          GROUP BY entities_1.id) client_accounting ON ((entities.id = client_accounting.entity_id)))
     LEFT JOIN ( SELECT entities_1.id AS entity_id,
            (- sum(supplier_items.balance)) AS balance
           FROM ((entities entities_1
             JOIN accounts suppliers ON ((entities_1.supplier_account_id = suppliers.id)))
             JOIN journal_entry_items supplier_items ON ((suppliers.id = supplier_items.account_id)))
          GROUP BY entities_1.id) supplier_accounting ON ((entities.id = supplier_accounting.entity_id)))
     LEFT JOIN ( SELECT client_tradings.entity_id,
            sum(client_tradings.amount) AS balance
           FROM ( SELECT entities_1.id AS entity_id,
                    (- sale_items.amount) AS amount
                   FROM ((entities entities_1
                     JOIN sales ON ((entities_1.id = sales.client_id)))
                     JOIN sale_items ON ((sales.id = sale_items.sale_id)))
                UNION ALL
                 SELECT entities_1.id AS entity_id,
                    incoming_payments.amount
                   FROM (entities entities_1
                     JOIN incoming_payments ON ((entities_1.id = incoming_payments.payer_id)))) client_tradings
          GROUP BY client_tradings.entity_id) client_trade ON ((entities.id = client_trade.entity_id)))
     LEFT JOIN ( SELECT supplier_tradings.entity_id,
            sum(supplier_tradings.amount) AS balance
           FROM ( SELECT entities_1.id AS entity_id,
                    purchase_items.amount
                   FROM ((entities entities_1
                     JOIN purchases ON ((entities_1.id = purchases.supplier_id)))
                     JOIN purchase_items ON ((purchases.id = purchase_items.purchase_id)))
                UNION ALL
                 SELECT entities_1.id AS entity_id,
                    (- outgoing_payments.amount) AS amount
                   FROM (entities entities_1
                     JOIN outgoing_payments ON ((entities_1.id = outgoing_payments.payee_id)))) supplier_tradings
          GROUP BY supplier_tradings.entity_id) supplier_trade ON ((entities.id = supplier_trade.entity_id)));


--
-- Name: entities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE entities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: entities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE entities_id_seq OWNED BY entities.id;


--
-- Name: entity_addresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE entity_addresses (
    id integer NOT NULL,
    entity_id integer NOT NULL,
    canal character varying NOT NULL,
    coordinate character varying NOT NULL,
    by_default boolean DEFAULT false NOT NULL,
    deleted_at timestamp without time zone,
    thread character varying,
    name character varying,
    mail_line_1 character varying,
    mail_line_2 character varying,
    mail_line_3 character varying,
    mail_line_4 character varying,
    mail_line_5 character varying,
    mail_line_6 character varying,
    mail_country character varying,
    mail_postal_zone_id integer,
    mail_geolocation postgis.geometry(Point,4326),
    mail_auto_update boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: entity_addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE entity_addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: entity_addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE entity_addresses_id_seq OWNED BY entity_addresses.id;


--
-- Name: entity_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE entity_links (
    id integer NOT NULL,
    nature character varying NOT NULL,
    entity_id integer NOT NULL,
    entity_role character varying NOT NULL,
    linked_id integer NOT NULL,
    linked_role character varying NOT NULL,
    started_at timestamp without time zone,
    stopped_at timestamp without time zone,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    post character varying,
    main boolean DEFAULT false NOT NULL
);


--
-- Name: entity_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE entity_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: entity_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE entity_links_id_seq OWNED BY entity_links.id;


--
-- Name: event_participations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE event_participations (
    id integer NOT NULL,
    event_id integer NOT NULL,
    participant_id integer NOT NULL,
    state character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: event_participations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE event_participations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: event_participations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE event_participations_id_seq OWNED BY event_participations.id;


--
-- Name: events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE events (
    id integer NOT NULL,
    name character varying NOT NULL,
    started_at timestamp without time zone NOT NULL,
    stopped_at timestamp without time zone,
    restricted boolean DEFAULT false NOT NULL,
    duration integer,
    place character varying,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    nature character varying NOT NULL,
    affair_id integer,
    custom_fields jsonb
);


--
-- Name: events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE events_id_seq OWNED BY events.id;


--
-- Name: financial_year_exchanges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE financial_year_exchanges (
    id integer NOT NULL,
    financial_year_id integer NOT NULL,
    started_on date NOT NULL,
    stopped_on date NOT NULL,
    closed_at timestamp without time zone,
    public_token character varying,
    public_token_expired_at timestamp without time zone,
    import_file_file_name character varying,
    import_file_content_type character varying,
    import_file_file_size integer,
    import_file_updated_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: financial_year_exchanges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE financial_year_exchanges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: financial_year_exchanges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE financial_year_exchanges_id_seq OWNED BY financial_year_exchanges.id;


--
-- Name: financial_years; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE financial_years (
    id integer NOT NULL,
    code character varying NOT NULL,
    closed boolean DEFAULT false NOT NULL,
    started_on date NOT NULL,
    stopped_on date NOT NULL,
    currency character varying NOT NULL,
    currency_precision integer,
    last_journal_entry_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb,
    tax_declaration_frequency character varying,
    tax_declaration_mode character varying NOT NULL,
    accountant_id integer
);


--
-- Name: financial_years_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE financial_years_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: financial_years_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE financial_years_id_seq OWNED BY financial_years.id;


--
-- Name: fixed_asset_depreciations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE fixed_asset_depreciations (
    id integer NOT NULL,
    fixed_asset_id integer NOT NULL,
    journal_entry_id integer,
    accountable boolean DEFAULT false NOT NULL,
    accounted_at timestamp without time zone,
    started_on date NOT NULL,
    stopped_on date NOT NULL,
    amount numeric(19,4) NOT NULL,
    "position" integer,
    locked boolean DEFAULT false NOT NULL,
    financial_year_id integer,
    depreciable_amount numeric(19,4),
    depreciated_amount numeric(19,4),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: fixed_asset_depreciations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE fixed_asset_depreciations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fixed_asset_depreciations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE fixed_asset_depreciations_id_seq OWNED BY fixed_asset_depreciations.id;


--
-- Name: fixed_assets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE fixed_assets (
    id integer NOT NULL,
    allocation_account_id integer NOT NULL,
    journal_id integer NOT NULL,
    name character varying NOT NULL,
    number character varying NOT NULL,
    description text,
    purchased_on date,
    purchase_id integer,
    purchase_item_id integer,
    ceded boolean,
    ceded_on date,
    sale_id integer,
    sale_item_id integer,
    purchase_amount numeric(19,4),
    started_on date NOT NULL,
    stopped_on date NOT NULL,
    depreciable_amount numeric(19,4) NOT NULL,
    depreciated_amount numeric(19,4) NOT NULL,
    depreciation_method character varying NOT NULL,
    currency character varying NOT NULL,
    current_amount numeric(19,4),
    expenses_account_id integer,
    depreciation_percentage numeric(19,4),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb,
    product_id integer,
    state character varying,
    depreciation_period character varying,
    accounted_at timestamp without time zone,
    journal_entry_id integer,
    asset_account_id integer,
    sold_on date,
    scrapped_on date,
    sold_journal_entry_id integer,
    scrapped_journal_entry_id integer
);


--
-- Name: fixed_assets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE fixed_assets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fixed_assets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE fixed_assets_id_seq OWNED BY fixed_assets.id;


--
-- Name: gap_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE gap_items (
    id integer NOT NULL,
    gap_id integer NOT NULL,
    pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    tax_id integer,
    currency character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: gap_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE gap_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gap_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE gap_items_id_seq OWNED BY gap_items.id;


--
-- Name: gaps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE gaps (
    id integer NOT NULL,
    number character varying NOT NULL,
    printed_at timestamp without time zone NOT NULL,
    direction character varying NOT NULL,
    affair_id integer,
    entity_id integer NOT NULL,
    pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    currency character varying NOT NULL,
    accounted_at timestamp without time zone,
    journal_entry_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    type character varying
);


--
-- Name: gaps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE gaps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gaps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE gaps_id_seq OWNED BY gaps.id;


--
-- Name: georeadings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE georeadings (
    id integer NOT NULL,
    name character varying NOT NULL,
    nature character varying NOT NULL,
    number character varying,
    description text,
    content postgis.geometry(Geometry,4326) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: georeadings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE georeadings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: georeadings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE georeadings_id_seq OWNED BY georeadings.id;


--
-- Name: guide_analyses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE guide_analyses (
    id integer NOT NULL,
    guide_id integer NOT NULL,
    execution_number integer NOT NULL,
    latest boolean DEFAULT false NOT NULL,
    started_at timestamp without time zone NOT NULL,
    stopped_at timestamp without time zone NOT NULL,
    acceptance_status character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: guide_analyses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE guide_analyses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: guide_analyses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE guide_analyses_id_seq OWNED BY guide_analyses.id;


--
-- Name: guide_analysis_points; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE guide_analysis_points (
    id integer NOT NULL,
    analysis_id integer NOT NULL,
    reference_name character varying NOT NULL,
    acceptance_status character varying NOT NULL,
    advice_reference_name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: guide_analysis_points_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE guide_analysis_points_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: guide_analysis_points_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE guide_analysis_points_id_seq OWNED BY guide_analysis_points.id;


--
-- Name: guides; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE guides (
    id integer NOT NULL,
    name character varying NOT NULL,
    nature character varying NOT NULL,
    active boolean DEFAULT false NOT NULL,
    external boolean DEFAULT false NOT NULL,
    frequency character varying NOT NULL,
    reference_name character varying,
    reference_source_file_name character varying,
    reference_source_content_type character varying,
    reference_source_file_size integer,
    reference_source_updated_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: guides_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE guides_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: guides_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE guides_id_seq OWNED BY guides.id;


--
-- Name: identifiers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE identifiers (
    id integer NOT NULL,
    net_service_id integer,
    nature character varying NOT NULL,
    value character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: identifiers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE identifiers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: identifiers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE identifiers_id_seq OWNED BY identifiers.id;


--
-- Name: imports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE imports (
    id integer NOT NULL,
    state character varying NOT NULL,
    nature character varying NOT NULL,
    archive_file_name character varying,
    archive_content_type character varying,
    archive_file_size integer,
    archive_updated_at timestamp without time zone,
    importer_id integer,
    imported_at timestamp without time zone,
    progression_percentage numeric(19,4),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: imports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE imports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: imports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE imports_id_seq OWNED BY imports.id;


--
-- Name: incoming_payment_modes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE incoming_payment_modes (
    id integer NOT NULL,
    name character varying NOT NULL,
    cash_id integer NOT NULL,
    active boolean DEFAULT false,
    "position" integer,
    with_accounting boolean DEFAULT false NOT NULL,
    with_commission boolean DEFAULT false NOT NULL,
    commission_percentage numeric(19,4) DEFAULT 0.0 NOT NULL,
    commission_base_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    commission_account_id integer,
    with_deposit boolean DEFAULT false NOT NULL,
    depositables_account_id integer,
    depositables_journal_id integer,
    detail_payments boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: incoming_payment_modes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE incoming_payment_modes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: incoming_payment_modes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE incoming_payment_modes_id_seq OWNED BY incoming_payment_modes.id;


--
-- Name: incoming_payments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE incoming_payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: incoming_payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE incoming_payments_id_seq OWNED BY incoming_payments.id;


--
-- Name: inspection_calibrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE inspection_calibrations (
    id integer NOT NULL,
    inspection_id integer NOT NULL,
    nature_id integer NOT NULL,
    items_count_value integer,
    net_mass_value numeric(19,4),
    minimal_size_value numeric(19,4),
    maximal_size_value numeric(19,4),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: inspection_calibrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE inspection_calibrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: inspection_calibrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE inspection_calibrations_id_seq OWNED BY inspection_calibrations.id;


--
-- Name: inspection_points; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE inspection_points (
    id integer NOT NULL,
    inspection_id integer NOT NULL,
    nature_id integer NOT NULL,
    items_count_value integer,
    net_mass_value numeric(19,4),
    minimal_size_value numeric(19,4),
    maximal_size_value numeric(19,4),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: inspection_points_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE inspection_points_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: inspection_points_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE inspection_points_id_seq OWNED BY inspection_points.id;


--
-- Name: inspections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE inspections (
    id integer NOT NULL,
    activity_id integer NOT NULL,
    product_id integer NOT NULL,
    number character varying NOT NULL,
    sampled_at timestamp without time zone NOT NULL,
    implanter_rows_number integer,
    implanter_working_width numeric(19,4),
    comment text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    implanter_application_width numeric(19,4),
    sampling_distance numeric(19,4),
    product_net_surface_area_value numeric(19,4),
    product_net_surface_area_unit character varying
);


--
-- Name: inspections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE inspections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: inspections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE inspections_id_seq OWNED BY inspections.id;


--
-- Name: integrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE integrations (
    id integer NOT NULL,
    nature character varying NOT NULL,
    initialization_vectors jsonb,
    ciphered_parameters jsonb,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: integrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE integrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE integrations_id_seq OWNED BY integrations.id;


--
-- Name: intervention_labellings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE intervention_labellings (
    id integer NOT NULL,
    intervention_id integer NOT NULL,
    label_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: intervention_labellings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE intervention_labellings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: intervention_labellings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE intervention_labellings_id_seq OWNED BY intervention_labellings.id;


--
-- Name: intervention_parameter_readings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE intervention_parameter_readings (
    id integer NOT NULL,
    indicator_name character varying NOT NULL,
    indicator_datatype character varying NOT NULL,
    absolute_measure_value_value numeric(19,4),
    absolute_measure_value_unit character varying,
    boolean_value boolean DEFAULT false NOT NULL,
    choice_value character varying,
    decimal_value numeric(19,4),
    multi_polygon_value postgis.geometry(MultiPolygon,4326),
    integer_value integer,
    measure_value_value numeric(19,4),
    measure_value_unit character varying,
    point_value postgis.geometry(Point,4326),
    string_value text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    parameter_id integer NOT NULL,
    geometry_value postgis.geometry(Geometry,4326)
);


--
-- Name: intervention_parameter_readings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE intervention_parameter_readings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: intervention_parameter_readings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE intervention_parameter_readings_id_seq OWNED BY intervention_parameter_readings.id;


--
-- Name: intervention_parameters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE intervention_parameters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: intervention_parameters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE intervention_parameters_id_seq OWNED BY intervention_parameters.id;


--
-- Name: intervention_participations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE intervention_participations (
    id integer NOT NULL,
    intervention_id integer,
    product_id integer,
    state character varying,
    request_compliant boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    procedure_name character varying
);


--
-- Name: intervention_participations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE intervention_participations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: intervention_participations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE intervention_participations_id_seq OWNED BY intervention_participations.id;


--
-- Name: intervention_working_periods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE intervention_working_periods (
    id integer NOT NULL,
    intervention_id integer,
    started_at timestamp without time zone NOT NULL,
    stopped_at timestamp without time zone NOT NULL,
    duration integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    intervention_participation_id integer,
    nature character varying
);


--
-- Name: intervention_working_periods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE intervention_working_periods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: intervention_working_periods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE intervention_working_periods_id_seq OWNED BY intervention_working_periods.id;


--
-- Name: interventions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE interventions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: interventions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE interventions_id_seq OWNED BY interventions.id;


--
-- Name: inventories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE inventories (
    id integer NOT NULL,
    number character varying NOT NULL,
    reflected_at timestamp without time zone,
    reflected boolean DEFAULT false NOT NULL,
    responsible_id integer,
    accounted_at timestamp without time zone,
    journal_entry_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    name character varying NOT NULL,
    achieved_at timestamp without time zone,
    custom_fields jsonb,
    financial_year_id integer,
    currency character varying
);


--
-- Name: inventories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE inventories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: inventories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE inventories_id_seq OWNED BY inventories.id;


--
-- Name: inventory_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE inventory_items (
    id integer NOT NULL,
    inventory_id integer NOT NULL,
    product_id integer NOT NULL,
    expected_population numeric(19,4) NOT NULL,
    actual_population numeric(19,4) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    product_movement_id integer,
    currency character varying,
    unit_pretax_stock_amount numeric(19,4) DEFAULT 0.0 NOT NULL
);


--
-- Name: inventory_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE inventory_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: inventory_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE inventory_items_id_seq OWNED BY inventory_items.id;


--
-- Name: issues; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE issues (
    id integer NOT NULL,
    target_id integer,
    target_type character varying,
    nature character varying NOT NULL,
    observed_at timestamp without time zone NOT NULL,
    priority integer,
    gravity integer,
    state character varying,
    name character varying NOT NULL,
    description text,
    picture_file_name character varying,
    picture_content_type character varying,
    picture_file_size integer,
    picture_updated_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    geolocation postgis.geometry(Point,4326),
    custom_fields jsonb,
    dead boolean DEFAULT false
);


--
-- Name: issues_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE issues_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: issues_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE issues_id_seq OWNED BY issues.id;


--
-- Name: journal_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE journal_entries (
    id integer NOT NULL,
    journal_id integer NOT NULL,
    financial_year_id integer,
    number character varying NOT NULL,
    resource_id integer,
    resource_type character varying,
    state character varying NOT NULL,
    printed_on date NOT NULL,
    real_debit numeric(19,4) DEFAULT 0.0 NOT NULL,
    real_credit numeric(19,4) DEFAULT 0.0 NOT NULL,
    real_currency character varying NOT NULL,
    real_currency_rate numeric(19,10) DEFAULT 0.0 NOT NULL,
    debit numeric(19,4) DEFAULT 0.0 NOT NULL,
    credit numeric(19,4) DEFAULT 0.0 NOT NULL,
    balance numeric(19,4) DEFAULT 0.0 NOT NULL,
    currency character varying NOT NULL,
    absolute_debit numeric(19,4) DEFAULT 0.0 NOT NULL,
    absolute_credit numeric(19,4) DEFAULT 0.0 NOT NULL,
    absolute_currency character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    real_balance numeric(19,4) DEFAULT 0.0 NOT NULL,
    resource_prism character varying,
    financial_year_exchange_id integer
);


--
-- Name: journal_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE journal_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: journal_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE journal_entries_id_seq OWNED BY journal_entries.id;


--
-- Name: journal_entry_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE journal_entry_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: journal_entry_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE journal_entry_items_id_seq OWNED BY journal_entry_items.id;


--
-- Name: journals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE journals (
    id integer NOT NULL,
    nature character varying NOT NULL,
    name character varying NOT NULL,
    code character varying NOT NULL,
    closed_on date NOT NULL,
    currency character varying NOT NULL,
    used_for_affairs boolean DEFAULT false NOT NULL,
    used_for_gaps boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb,
    used_for_permanent_stock_inventory boolean DEFAULT false NOT NULL,
    used_for_unbilled_payables boolean DEFAULT false NOT NULL,
    used_for_tax_declarations boolean DEFAULT false NOT NULL,
    accountant_id integer
);


--
-- Name: journals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE journals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: journals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE journals_id_seq OWNED BY journals.id;


--
-- Name: labels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE labels (
    id integer NOT NULL,
    name character varying NOT NULL,
    color character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: labels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE labels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: labels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE labels_id_seq OWNED BY labels.id;


--
-- Name: listing_node_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE listing_node_items (
    id integer NOT NULL,
    node_id integer NOT NULL,
    nature character varying NOT NULL,
    value text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: listing_node_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE listing_node_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: listing_node_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE listing_node_items_id_seq OWNED BY listing_node_items.id;


--
-- Name: listing_nodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE listing_nodes (
    id integer NOT NULL,
    name character varying NOT NULL,
    label character varying NOT NULL,
    nature character varying NOT NULL,
    "position" integer,
    exportable boolean DEFAULT true NOT NULL,
    parent_id integer,
    item_nature character varying,
    item_value text,
    item_listing_id integer,
    item_listing_node_id integer,
    listing_id integer NOT NULL,
    key character varying,
    sql_type character varying,
    condition_value character varying,
    condition_operator character varying,
    attribute_name character varying,
    lft integer,
    rgt integer,
    depth integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: listing_nodes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE listing_nodes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: listing_nodes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE listing_nodes_id_seq OWNED BY listing_nodes.id;


--
-- Name: listings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE listings (
    id integer NOT NULL,
    name character varying NOT NULL,
    root_model character varying NOT NULL,
    query text,
    description text,
    story text,
    conditions text,
    mail text,
    source text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: listings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE listings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: listings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE listings_id_seq OWNED BY listings.id;


--
-- Name: loan_repayments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE loan_repayments (
    id integer NOT NULL,
    loan_id integer NOT NULL,
    "position" integer NOT NULL,
    amount numeric(19,4) NOT NULL,
    base_amount numeric(19,4) NOT NULL,
    interest_amount numeric(19,4) NOT NULL,
    insurance_amount numeric(19,4) NOT NULL,
    remaining_amount numeric(19,4) NOT NULL,
    due_on date NOT NULL,
    journal_entry_id integer,
    accounted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    accountable boolean DEFAULT false NOT NULL,
    locked boolean DEFAULT false NOT NULL
);


--
-- Name: loan_repayments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE loan_repayments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: loan_repayments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE loan_repayments_id_seq OWNED BY loan_repayments.id;


--
-- Name: loans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE loans (
    id integer NOT NULL,
    lender_id integer NOT NULL,
    name character varying NOT NULL,
    cash_id integer NOT NULL,
    currency character varying NOT NULL,
    amount numeric(19,4) NOT NULL,
    interest_percentage numeric(19,4) NOT NULL,
    insurance_percentage numeric(19,4) NOT NULL,
    started_on date NOT NULL,
    repayment_duration integer NOT NULL,
    repayment_period character varying NOT NULL,
    repayment_method character varying NOT NULL,
    shift_duration integer DEFAULT 0 NOT NULL,
    shift_method character varying,
    journal_entry_id integer,
    accounted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb,
    insurance_repayment_method character varying,
    state character varying,
    ongoing_at timestamp without time zone,
    repaid_at timestamp without time zone,
    loan_account_id integer,
    interest_account_id integer,
    insurance_account_id integer,
    use_bank_guarantee boolean,
    bank_guarantee_account_id integer,
    bank_guarantee_amount integer,
    accountable_repayments_started_on date,
    initial_releasing_amount boolean DEFAULT false NOT NULL
);


--
-- Name: loans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE loans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: loans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE loans_id_seq OWNED BY loans.id;


--
-- Name: manure_management_plan_zones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE manure_management_plan_zones (
    id integer NOT NULL,
    plan_id integer NOT NULL,
    activity_production_id integer NOT NULL,
    computation_method character varying NOT NULL,
    administrative_area character varying,
    cultivation_variety character varying,
    soil_nature character varying,
    expected_yield numeric(19,4),
    nitrogen_need numeric(19,4),
    absorbed_nitrogen_at_opening numeric(19,4),
    mineral_nitrogen_at_opening numeric(19,4),
    humus_mineralization numeric(19,4),
    meadow_humus_mineralization numeric(19,4),
    previous_cultivation_residue_mineralization numeric(19,4),
    intermediate_cultivation_residue_mineralization numeric(19,4),
    irrigation_water_nitrogen numeric(19,4),
    organic_fertilizer_mineral_fraction numeric(19,4),
    nitrogen_at_closing numeric(19,4),
    soil_production numeric(19,4),
    nitrogen_input numeric(19,4),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    maximum_nitrogen_input numeric(19,4)
);


--
-- Name: manure_management_plan_zones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE manure_management_plan_zones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: manure_management_plan_zones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE manure_management_plan_zones_id_seq OWNED BY manure_management_plan_zones.id;


--
-- Name: manure_management_plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE manure_management_plans (
    id integer NOT NULL,
    name character varying NOT NULL,
    campaign_id integer NOT NULL,
    recommender_id integer NOT NULL,
    opened_at timestamp without time zone NOT NULL,
    default_computation_method character varying NOT NULL,
    locked boolean DEFAULT false NOT NULL,
    selected boolean DEFAULT false NOT NULL,
    annotation text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: manure_management_plans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE manure_management_plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: manure_management_plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE manure_management_plans_id_seq OWNED BY manure_management_plans.id;


--
-- Name: map_layers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE map_layers (
    id integer NOT NULL,
    name character varying NOT NULL,
    url character varying NOT NULL,
    reference_name character varying,
    attribution character varying,
    subdomains character varying,
    min_zoom integer,
    max_zoom integer,
    managed boolean DEFAULT false NOT NULL,
    tms boolean DEFAULT false NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    by_default boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    nature character varying,
    "position" integer,
    opacity integer
);


--
-- Name: map_layers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE map_layers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: map_layers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE map_layers_id_seq OWNED BY map_layers.id;


--
-- Name: net_services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE net_services (
    id integer NOT NULL,
    reference_name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: net_services_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE net_services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: net_services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE net_services_id_seq OWNED BY net_services.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE notifications (
    id integer NOT NULL,
    recipient_id integer NOT NULL,
    message character varying NOT NULL,
    level character varying NOT NULL,
    read_at timestamp without time zone,
    target_id integer,
    target_type character varying,
    target_url character varying,
    interpolations json,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE notifications_id_seq OWNED BY notifications.id;


--
-- Name: observations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE observations (
    id integer NOT NULL,
    subject_id integer NOT NULL,
    subject_type character varying NOT NULL,
    importance character varying NOT NULL,
    content text NOT NULL,
    observed_at timestamp without time zone NOT NULL,
    author_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: observations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE observations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: observations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE observations_id_seq OWNED BY observations.id;


--
-- Name: outgoing_payment_lists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE outgoing_payment_lists (
    id integer NOT NULL,
    number character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    mode_id integer NOT NULL,
    cached_payment_count integer,
    cached_total_sum numeric
);


--
-- Name: outgoing_payment_lists_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE outgoing_payment_lists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: outgoing_payment_lists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE outgoing_payment_lists_id_seq OWNED BY outgoing_payment_lists.id;


--
-- Name: outgoing_payment_modes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE outgoing_payment_modes (
    id integer NOT NULL,
    name character varying NOT NULL,
    with_accounting boolean DEFAULT false NOT NULL,
    cash_id integer NOT NULL,
    "position" integer,
    active boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    sepa boolean DEFAULT false NOT NULL
);


--
-- Name: outgoing_payment_modes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE outgoing_payment_modes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: outgoing_payment_modes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE outgoing_payment_modes_id_seq OWNED BY outgoing_payment_modes.id;


--
-- Name: outgoing_payments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE outgoing_payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: outgoing_payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE outgoing_payments_id_seq OWNED BY outgoing_payments.id;


--
-- Name: parcel_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE parcel_items (
    id integer NOT NULL,
    parcel_id integer NOT NULL,
    sale_item_id integer,
    purchase_item_id integer,
    source_product_id integer,
    product_id integer,
    analysis_id integer,
    variant_id integer,
    parted boolean DEFAULT false NOT NULL,
    population numeric(19,4),
    shape postgis.geometry(MultiPolygon,4326),
    product_enjoyment_id integer,
    product_ownership_id integer,
    product_localization_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    product_movement_id integer,
    source_product_movement_id integer,
    product_identification_number character varying,
    product_name character varying,
    currency character varying,
    unit_pretax_stock_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    unit_pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL
);


--
-- Name: parcel_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE parcel_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: parcel_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE parcel_items_id_seq OWNED BY parcel_items.id;


--
-- Name: parcels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE parcels (
    id integer NOT NULL,
    number character varying NOT NULL,
    nature character varying NOT NULL,
    reference_number character varying,
    recipient_id integer,
    sender_id integer,
    address_id integer,
    storage_id integer,
    delivery_id integer,
    sale_id integer,
    purchase_id integer,
    transporter_id integer,
    remain_owner boolean DEFAULT false NOT NULL,
    delivery_mode character varying,
    state character varying NOT NULL,
    planned_at timestamp without time zone NOT NULL,
    ordered_at timestamp without time zone,
    in_preparation_at timestamp without time zone,
    prepared_at timestamp without time zone,
    given_at timestamp without time zone,
    "position" integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb,
    with_delivery boolean DEFAULT false NOT NULL,
    separated_stock boolean,
    accounted_at timestamp without time zone,
    currency character varying,
    journal_entry_id integer,
    undelivered_invoice_journal_entry_id integer,
    contract_id integer,
    pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    responsible_id integer
);


--
-- Name: parcels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE parcels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: parcels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE parcels_id_seq OWNED BY parcels.id;


--
-- Name: plant_counting_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE plant_counting_items (
    id integer NOT NULL,
    plant_counting_id integer NOT NULL,
    value integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: plant_counting_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE plant_counting_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plant_counting_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE plant_counting_items_id_seq OWNED BY plant_counting_items.id;


--
-- Name: plant_countings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE plant_countings (
    id integer NOT NULL,
    plant_id integer NOT NULL,
    plant_density_abacus_id integer NOT NULL,
    plant_density_abacus_item_id integer NOT NULL,
    average_value numeric(19,4),
    read_at timestamp without time zone,
    comment text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    number character varying,
    nature character varying,
    working_width_value numeric(19,4),
    rows_count_value integer
);


--
-- Name: plant_countings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE plant_countings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plant_countings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE plant_countings_id_seq OWNED BY plant_countings.id;


--
-- Name: plant_density_abaci; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE plant_density_abaci (
    id integer NOT NULL,
    name character varying NOT NULL,
    germination_percentage numeric(19,4),
    seeding_density_unit character varying NOT NULL,
    sampling_length_unit character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    activity_id integer NOT NULL
);


--
-- Name: plant_density_abaci_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE plant_density_abaci_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plant_density_abaci_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE plant_density_abaci_id_seq OWNED BY plant_density_abaci.id;


--
-- Name: plant_density_abacus_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE plant_density_abacus_items (
    id integer NOT NULL,
    plant_density_abacus_id integer NOT NULL,
    seeding_density_value numeric(19,4) NOT NULL,
    plants_count integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: plant_density_abacus_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE plant_density_abacus_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plant_density_abacus_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE plant_density_abacus_items_id_seq OWNED BY plant_density_abacus_items.id;


--
-- Name: postal_zones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE postal_zones (
    id integer NOT NULL,
    postal_code character varying NOT NULL,
    name character varying NOT NULL,
    country character varying NOT NULL,
    district_id integer,
    city character varying,
    city_name character varying,
    code character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: postal_zones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE postal_zones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: postal_zones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE postal_zones_id_seq OWNED BY postal_zones.id;


--
-- Name: preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE preferences (
    id integer NOT NULL,
    name character varying NOT NULL,
    nature character varying NOT NULL,
    string_value text,
    boolean_value boolean,
    integer_value integer,
    decimal_value numeric(19,4),
    record_value_id integer,
    record_value_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: preferences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE preferences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE preferences_id_seq OWNED BY preferences.id;


--
-- Name: prescriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE prescriptions (
    id integer NOT NULL,
    prescriptor_id integer NOT NULL,
    reference_number character varying,
    delivered_at timestamp without time zone,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb
);


--
-- Name: prescriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE prescriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: prescriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE prescriptions_id_seq OWNED BY prescriptions.id;


--
-- Name: product_enjoyments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE product_enjoyments (
    id integer NOT NULL,
    originator_id integer,
    originator_type character varying,
    product_id integer NOT NULL,
    nature character varying NOT NULL,
    enjoyer_id integer,
    started_at timestamp without time zone,
    stopped_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    intervention_id integer
);


--
-- Name: product_enjoyments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE product_enjoyments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_enjoyments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE product_enjoyments_id_seq OWNED BY product_enjoyments.id;


--
-- Name: product_labellings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE product_labellings (
    id integer NOT NULL,
    product_id integer NOT NULL,
    label_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: product_labellings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE product_labellings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_labellings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE product_labellings_id_seq OWNED BY product_labellings.id;


--
-- Name: product_linkages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE product_linkages (
    id integer NOT NULL,
    originator_id integer,
    originator_type character varying,
    carrier_id integer NOT NULL,
    point character varying NOT NULL,
    nature character varying NOT NULL,
    carried_id integer NOT NULL,
    started_at timestamp without time zone,
    stopped_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    intervention_id integer
);


--
-- Name: product_linkages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE product_linkages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_linkages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE product_linkages_id_seq OWNED BY product_linkages.id;


--
-- Name: product_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE product_links (
    id integer NOT NULL,
    originator_id integer,
    originator_type character varying,
    product_id integer NOT NULL,
    nature character varying NOT NULL,
    linked_id integer NOT NULL,
    started_at timestamp without time zone,
    stopped_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    intervention_id integer
);


--
-- Name: product_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE product_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE product_links_id_seq OWNED BY product_links.id;


--
-- Name: product_localizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE product_localizations (
    id integer NOT NULL,
    originator_id integer,
    originator_type character varying,
    product_id integer NOT NULL,
    nature character varying NOT NULL,
    container_id integer,
    started_at timestamp without time zone,
    stopped_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    intervention_id integer
);


--
-- Name: product_localizations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE product_localizations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_localizations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE product_localizations_id_seq OWNED BY product_localizations.id;


--
-- Name: product_memberships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE product_memberships (
    id integer NOT NULL,
    originator_id integer,
    originator_type character varying,
    member_id integer NOT NULL,
    nature character varying NOT NULL,
    group_id integer NOT NULL,
    started_at timestamp without time zone NOT NULL,
    stopped_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    intervention_id integer
);


--
-- Name: product_memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE product_memberships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE product_memberships_id_seq OWNED BY product_memberships.id;


--
-- Name: product_movements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE product_movements (
    id integer NOT NULL,
    product_id integer NOT NULL,
    intervention_id integer,
    originator_id integer,
    originator_type character varying,
    delta numeric(19,4) NOT NULL,
    population numeric(19,4) NOT NULL,
    started_at timestamp without time zone NOT NULL,
    stopped_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    description character varying
);


--
-- Name: product_movements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE product_movements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_movements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE product_movements_id_seq OWNED BY product_movements.id;


--
-- Name: product_nature_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE product_nature_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    number character varying NOT NULL,
    description text,
    reference_name character varying,
    pictogram character varying,
    active boolean DEFAULT false NOT NULL,
    depreciable boolean DEFAULT false NOT NULL,
    saleable boolean DEFAULT false NOT NULL,
    purchasable boolean DEFAULT false NOT NULL,
    storable boolean DEFAULT false NOT NULL,
    reductible boolean DEFAULT false NOT NULL,
    subscribing boolean DEFAULT false NOT NULL,
    charge_account_id integer,
    product_account_id integer,
    fixed_asset_account_id integer,
    stock_account_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    fixed_asset_allocation_account_id integer,
    fixed_asset_expenses_account_id integer,
    fixed_asset_depreciation_percentage numeric(19,4) DEFAULT 0.0,
    fixed_asset_depreciation_method character varying,
    custom_fields jsonb,
    stock_movement_account_id integer
);


--
-- Name: product_nature_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE product_nature_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_nature_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE product_nature_categories_id_seq OWNED BY product_nature_categories.id;


--
-- Name: product_nature_category_taxations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE product_nature_category_taxations (
    id integer NOT NULL,
    product_nature_category_id integer NOT NULL,
    tax_id integer NOT NULL,
    usage character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: product_nature_category_taxations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE product_nature_category_taxations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_nature_category_taxations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE product_nature_category_taxations_id_seq OWNED BY product_nature_category_taxations.id;


--
-- Name: product_nature_variant_components; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE product_nature_variant_components (
    id integer NOT NULL,
    product_nature_variant_id integer NOT NULL,
    part_product_nature_variant_id integer,
    parent_id integer,
    deleted_at timestamp without time zone,
    name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: product_nature_variant_components_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE product_nature_variant_components_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_nature_variant_components_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE product_nature_variant_components_id_seq OWNED BY product_nature_variant_components.id;


--
-- Name: product_nature_variant_readings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE product_nature_variant_readings (
    id integer NOT NULL,
    variant_id integer NOT NULL,
    indicator_name character varying NOT NULL,
    indicator_datatype character varying NOT NULL,
    absolute_measure_value_value numeric(19,4),
    absolute_measure_value_unit character varying,
    boolean_value boolean DEFAULT false NOT NULL,
    choice_value character varying,
    decimal_value numeric(19,4),
    multi_polygon_value postgis.geometry(MultiPolygon,4326),
    integer_value integer,
    measure_value_value numeric(19,4),
    measure_value_unit character varying,
    point_value postgis.geometry(Point,4326),
    string_value text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    geometry_value postgis.geometry(Geometry,4326)
);


--
-- Name: product_nature_variant_readings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE product_nature_variant_readings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_nature_variant_readings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE product_nature_variant_readings_id_seq OWNED BY product_nature_variant_readings.id;


--
-- Name: product_nature_variants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE product_nature_variants (
    id integer NOT NULL,
    category_id integer NOT NULL,
    nature_id integer NOT NULL,
    name character varying,
    work_number character varying,
    variety character varying NOT NULL,
    derivative_of character varying,
    reference_name character varying,
    unit_name character varying NOT NULL,
    active boolean DEFAULT false NOT NULL,
    picture_file_name character varying,
    picture_content_type character varying,
    picture_file_size integer,
    picture_updated_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb,
    gtin character varying,
    number character varying NOT NULL,
    stock_account_id integer,
    stock_movement_account_id integer,
    france_maaid character varying
);


--
-- Name: product_nature_variants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE product_nature_variants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_nature_variants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE product_nature_variants_id_seq OWNED BY product_nature_variants.id;


--
-- Name: product_natures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE product_natures (
    id integer NOT NULL,
    category_id integer NOT NULL,
    name character varying NOT NULL,
    number character varying NOT NULL,
    variety character varying NOT NULL,
    derivative_of character varying,
    reference_name character varying,
    active boolean DEFAULT false NOT NULL,
    evolvable boolean DEFAULT false NOT NULL,
    population_counting character varying NOT NULL,
    abilities_list text,
    variable_indicators_list text,
    frozen_indicators_list text,
    linkage_points_list text,
    derivatives_list text,
    picture_file_name character varying,
    picture_content_type character varying,
    picture_file_size integer,
    picture_updated_at timestamp without time zone,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb,
    subscribing boolean DEFAULT false NOT NULL,
    subscription_nature_id integer,
    subscription_years_count integer DEFAULT 0 NOT NULL,
    subscription_months_count integer DEFAULT 0 NOT NULL,
    subscription_days_count integer DEFAULT 0 NOT NULL
);


--
-- Name: product_natures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE product_natures_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_natures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE product_natures_id_seq OWNED BY product_natures.id;


--
-- Name: product_ownerships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE product_ownerships (
    id integer NOT NULL,
    originator_id integer,
    originator_type character varying,
    product_id integer NOT NULL,
    nature character varying NOT NULL,
    owner_id integer,
    started_at timestamp without time zone,
    stopped_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    intervention_id integer
);


--
-- Name: product_ownerships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE product_ownerships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_ownerships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE product_ownerships_id_seq OWNED BY product_ownerships.id;


--
-- Name: product_phases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE product_phases (
    id integer NOT NULL,
    originator_id integer,
    originator_type character varying,
    product_id integer NOT NULL,
    variant_id integer NOT NULL,
    nature_id integer NOT NULL,
    category_id integer NOT NULL,
    started_at timestamp without time zone,
    stopped_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    intervention_id integer
);


--
-- Name: product_phases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE product_phases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_phases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE product_phases_id_seq OWNED BY product_phases.id;


--
-- Name: product_populations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE product_populations (
    product_id integer,
    started_at timestamp without time zone,
    value numeric,
    creator_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    updater_id integer,
    id integer,
    lock_version integer
);

ALTER TABLE ONLY product_populations REPLICA IDENTITY NOTHING;


--
-- Name: product_readings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE product_readings (
    id integer NOT NULL,
    originator_id integer,
    originator_type character varying,
    product_id integer NOT NULL,
    read_at timestamp without time zone NOT NULL,
    indicator_name character varying NOT NULL,
    indicator_datatype character varying NOT NULL,
    absolute_measure_value_value numeric(19,4),
    absolute_measure_value_unit character varying,
    boolean_value boolean DEFAULT false NOT NULL,
    choice_value character varying,
    decimal_value numeric(19,4),
    multi_polygon_value postgis.geometry(MultiPolygon,4326),
    integer_value integer,
    measure_value_value numeric(19,4),
    measure_value_unit character varying,
    point_value postgis.geometry(Point,4326),
    string_value text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    geometry_value postgis.geometry(Geometry,4326)
);


--
-- Name: product_readings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE product_readings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_readings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE product_readings_id_seq OWNED BY product_readings.id;


--
-- Name: products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE products (
    id integer NOT NULL,
    type character varying,
    name character varying NOT NULL,
    number character varying NOT NULL,
    variant_id integer NOT NULL,
    nature_id integer NOT NULL,
    category_id integer NOT NULL,
    initial_born_at timestamp without time zone,
    initial_dead_at timestamp without time zone,
    initial_container_id integer,
    initial_owner_id integer,
    initial_enjoyer_id integer,
    initial_population numeric(19,4) DEFAULT 0.0,
    initial_shape postgis.geometry(MultiPolygon,4326),
    initial_father_id integer,
    initial_mother_id integer,
    variety character varying NOT NULL,
    derivative_of character varying,
    tracking_id integer,
    fixed_asset_id integer,
    born_at timestamp without time zone,
    dead_at timestamp without time zone,
    description text,
    picture_file_name character varying,
    picture_content_type character varying,
    picture_file_size integer,
    picture_updated_at timestamp without time zone,
    identification_number character varying,
    work_number character varying,
    address_id integer,
    parent_id integer,
    default_storage_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    person_id integer,
    initial_geolocation postgis.geometry(Point,4326),
    uuid uuid,
    initial_movement_id integer,
    custom_fields jsonb,
    team_id integer,
    member_variant_id integer,
    birth_date_completeness character varying,
    birth_farm_number character varying,
    country character varying,
    filiation_status character varying,
    first_calving_on timestamp without time zone,
    mother_country character varying,
    mother_variety character varying,
    mother_identification_number character varying,
    father_country character varying,
    father_variety character varying,
    father_identification_number character varying,
    origin_country character varying,
    origin_identification_number character varying,
    end_of_life_reason character varying,
    originator_id integer
);


--
-- Name: products_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE products_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE products_id_seq OWNED BY products.id;


--
-- Name: purchase_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE purchase_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: purchase_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE purchase_items_id_seq OWNED BY purchase_items.id;


--
-- Name: purchase_natures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE purchase_natures (
    id integer NOT NULL,
    active boolean DEFAULT true NOT NULL,
    name character varying,
    description text,
    currency character varying NOT NULL,
    with_accounting boolean DEFAULT false NOT NULL,
    journal_id integer,
    by_default boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    nature character varying NOT NULL
);


--
-- Name: purchase_natures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE purchase_natures_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: purchase_natures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE purchase_natures_id_seq OWNED BY purchase_natures.id;


--
-- Name: purchases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE purchases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: purchases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE purchases_id_seq OWNED BY purchases.id;


--
-- Name: regularizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE regularizations (
    id integer NOT NULL,
    affair_id integer NOT NULL,
    journal_entry_id integer NOT NULL,
    currency character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: regularizations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE regularizations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: regularizations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE regularizations_id_seq OWNED BY regularizations.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE roles (
    id integer NOT NULL,
    name character varying NOT NULL,
    rights text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    reference_name character varying
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE roles_id_seq OWNED BY roles.id;


--
-- Name: sale_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sale_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sale_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sale_items_id_seq OWNED BY sale_items.id;


--
-- Name: sale_natures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sale_natures (
    id integer NOT NULL,
    name character varying NOT NULL,
    active boolean DEFAULT true NOT NULL,
    by_default boolean DEFAULT false NOT NULL,
    downpayment boolean DEFAULT false NOT NULL,
    downpayment_minimum numeric(19,4) DEFAULT 0.0,
    downpayment_percentage numeric(19,4) DEFAULT 0.0,
    payment_mode_id integer,
    catalog_id integer NOT NULL,
    payment_mode_complement text,
    currency character varying NOT NULL,
    sales_conditions text,
    expiration_delay character varying NOT NULL,
    payment_delay character varying NOT NULL,
    with_accounting boolean DEFAULT false NOT NULL,
    journal_id integer,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: sale_natures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sale_natures_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sale_natures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sale_natures_id_seq OWNED BY sale_natures.id;


--
-- Name: sales_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sales_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sales_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sales_id_seq OWNED BY sales.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: sensors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sensors (
    id integer NOT NULL,
    vendor_euid character varying,
    model_euid character varying,
    name character varying NOT NULL,
    retrieval_mode character varying NOT NULL,
    access_parameters json,
    product_id integer,
    embedded boolean DEFAULT false NOT NULL,
    host_id integer,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    token character varying,
    custom_fields jsonb,
    euid character varying,
    partner_url character varying,
    battery_level numeric(19,4),
    last_transmission_at timestamp without time zone
);


--
-- Name: sensors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sensors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sensors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sensors_id_seq OWNED BY sensors.id;


--
-- Name: sequences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sequences (
    id integer NOT NULL,
    name character varying NOT NULL,
    number_format character varying NOT NULL,
    period character varying DEFAULT 'number'::character varying NOT NULL,
    last_year integer,
    last_month integer,
    last_cweek integer,
    last_number integer,
    number_increment integer DEFAULT 1 NOT NULL,
    number_start integer DEFAULT 1 NOT NULL,
    usage character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: sequences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sequences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sequences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sequences_id_seq OWNED BY sequences.id;


--
-- Name: subscription_natures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE subscription_natures (
    id integer NOT NULL,
    name character varying NOT NULL,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: subscription_natures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE subscription_natures_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subscription_natures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE subscription_natures_id_seq OWNED BY subscription_natures.id;


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE subscriptions (
    id integer NOT NULL,
    started_on date NOT NULL,
    stopped_on date NOT NULL,
    address_id integer,
    quantity integer NOT NULL,
    suspended boolean DEFAULT false NOT NULL,
    nature_id integer NOT NULL,
    subscriber_id integer NOT NULL,
    description text,
    number character varying,
    sale_item_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb,
    parent_id integer,
    swim_lane_uuid uuid NOT NULL
);


--
-- Name: subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE subscriptions_id_seq OWNED BY subscriptions.id;


--
-- Name: supervision_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE supervision_items (
    id integer NOT NULL,
    supervision_id integer NOT NULL,
    sensor_id integer NOT NULL,
    color character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: supervision_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE supervision_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: supervision_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE supervision_items_id_seq OWNED BY supervision_items.id;


--
-- Name: supervisions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE supervisions (
    id integer NOT NULL,
    name character varying NOT NULL,
    time_window integer,
    view_parameters json,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb
);


--
-- Name: supervisions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE supervisions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: supervisions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE supervisions_id_seq OWNED BY supervisions.id;


--
-- Name: synchronization_operations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE synchronization_operations (
    id integer NOT NULL,
    operation_name character varying NOT NULL,
    state character varying NOT NULL,
    finished_at timestamp without time zone,
    notification_id integer,
    request jsonb,
    response jsonb,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    originator_id integer,
    originator_type character varying
);


--
-- Name: synchronization_operations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE synchronization_operations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: synchronization_operations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE synchronization_operations_id_seq OWNED BY synchronization_operations.id;


--
-- Name: target_distributions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE target_distributions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: target_distributions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE target_distributions_id_seq OWNED BY target_distributions.id;


--
-- Name: tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tasks (
    id integer NOT NULL,
    name character varying NOT NULL,
    state character varying NOT NULL,
    nature character varying NOT NULL,
    entity_id integer NOT NULL,
    executor_id integer,
    sale_opportunity_id integer,
    description text,
    due_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    custom_fields jsonb
);


--
-- Name: tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tasks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tasks_id_seq OWNED BY tasks.id;


--
-- Name: tax_declaration_item_parts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tax_declaration_item_parts (
    id integer NOT NULL,
    tax_declaration_item_id integer NOT NULL,
    journal_entry_item_id integer NOT NULL,
    account_id integer NOT NULL,
    tax_amount numeric(19,4) NOT NULL,
    pretax_amount numeric(19,4) NOT NULL,
    total_tax_amount numeric(19,4) NOT NULL,
    total_pretax_amount numeric(19,4) NOT NULL,
    direction character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: tax_declaration_item_parts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tax_declaration_item_parts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tax_declaration_item_parts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tax_declaration_item_parts_id_seq OWNED BY tax_declaration_item_parts.id;


--
-- Name: tax_declaration_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tax_declaration_items (
    id integer NOT NULL,
    tax_declaration_id integer NOT NULL,
    tax_id integer NOT NULL,
    currency character varying NOT NULL,
    collected_tax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    deductible_tax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    deductible_pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    collected_pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    fixed_asset_deductible_pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    fixed_asset_deductible_tax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    balance_pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    balance_tax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    intracommunity_payable_tax_amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    intracommunity_payable_pretax_amount numeric(19,4) DEFAULT 0.0 NOT NULL
);


--
-- Name: tax_declaration_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tax_declaration_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tax_declaration_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tax_declaration_items_id_seq OWNED BY tax_declaration_items.id;


--
-- Name: tax_declarations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tax_declarations (
    id integer NOT NULL,
    financial_year_id integer NOT NULL,
    journal_entry_id integer,
    accounted_at timestamp without time zone,
    responsible_id integer,
    mode character varying NOT NULL,
    description text,
    started_on date NOT NULL,
    stopped_on date NOT NULL,
    currency character varying NOT NULL,
    number character varying,
    reference_number character varying,
    state character varying,
    invoiced_on date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: tax_declarations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tax_declarations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tax_declarations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tax_declarations_id_seq OWNED BY tax_declarations.id;


--
-- Name: taxes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE taxes (
    id integer NOT NULL,
    name character varying NOT NULL,
    amount numeric(19,4) DEFAULT 0.0 NOT NULL,
    description text,
    collect_account_id integer,
    deduction_account_id integer,
    reference_name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    active boolean DEFAULT false NOT NULL,
    nature character varying NOT NULL,
    country character varying NOT NULL,
    fixed_asset_deduction_account_id integer,
    fixed_asset_collect_account_id integer,
    intracommunity boolean DEFAULT false NOT NULL,
    intracommunity_payable_account_id integer
);


--
-- Name: taxes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE taxes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: taxes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE taxes_id_seq OWNED BY taxes.id;


--
-- Name: teams; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE teams (
    id integer NOT NULL,
    name character varying NOT NULL,
    description text,
    parent_id integer,
    lft integer,
    rgt integer,
    depth integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: teams_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE teams_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: teams_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE teams_id_seq OWNED BY teams.id;


--
-- Name: tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tokens (
    id integer NOT NULL,
    name character varying NOT NULL,
    value character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tokens_id_seq OWNED BY tokens.id;


--
-- Name: trackings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE trackings (
    id integer NOT NULL,
    name character varying NOT NULL,
    serial character varying,
    active boolean DEFAULT true NOT NULL,
    description text,
    product_id integer,
    producer_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    usage_limit_on date,
    usage_limit_nature character varying
);


--
-- Name: trackings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE trackings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trackings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE trackings_id_seq OWNED BY trackings.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE users (
    id integer NOT NULL,
    first_name character varying NOT NULL,
    last_name character varying NOT NULL,
    locked boolean DEFAULT false NOT NULL,
    email character varying NOT NULL,
    person_id integer,
    role_id integer,
    maximal_grantable_reduction_percentage numeric(19,4) DEFAULT 5.0 NOT NULL,
    administrator boolean DEFAULT false NOT NULL,
    rights text,
    description text,
    commercial boolean DEFAULT false NOT NULL,
    team_id integer,
    employed boolean DEFAULT false NOT NULL,
    employment character varying,
    language character varying NOT NULL,
    last_sign_in_at timestamp without time zone,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0,
    current_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying,
    last_sign_in_ip character varying,
    confirmation_token character varying,
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    unconfirmed_email character varying,
    failed_attempts integer DEFAULT 0,
    unlock_token character varying,
    locked_at timestamp without time zone,
    authentication_token character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    creator_id integer,
    updater_id integer,
    lock_version integer DEFAULT 0 NOT NULL,
    invitation_token character varying,
    invitation_created_at timestamp without time zone,
    invitation_sent_at timestamp without time zone,
    invitation_accepted_at timestamp without time zone,
    invitation_limit integer,
    invited_by_id integer,
    invitations_count integer DEFAULT 0,
    signup_at timestamp without time zone,
    provider character varying,
    uid character varying
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE versions (
    id integer NOT NULL,
    event character varying NOT NULL,
    item_id integer,
    item_type character varying,
    item_object text,
    item_changes text,
    created_at timestamp without time zone NOT NULL,
    creator_id integer,
    creator_name character varying
);


--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE versions_id_seq OWNED BY versions.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_balances ALTER COLUMN id SET DEFAULT nextval('account_balances_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY accounts ALTER COLUMN id SET DEFAULT nextval('accounts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY activities ALTER COLUMN id SET DEFAULT nextval('activities_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_budget_items ALTER COLUMN id SET DEFAULT nextval('activity_budget_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_budgets ALTER COLUMN id SET DEFAULT nextval('activity_budgets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_distributions ALTER COLUMN id SET DEFAULT nextval('activity_distributions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_inspection_calibration_natures ALTER COLUMN id SET DEFAULT nextval('activity_inspection_calibration_natures_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_inspection_calibration_scales ALTER COLUMN id SET DEFAULT nextval('activity_inspection_calibration_scales_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_inspection_point_natures ALTER COLUMN id SET DEFAULT nextval('activity_inspection_point_natures_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_productions ALTER COLUMN id SET DEFAULT nextval('activity_productions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_seasons ALTER COLUMN id SET DEFAULT nextval('activity_seasons_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_tactics ALTER COLUMN id SET DEFAULT nextval('activity_tactics_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY affairs ALTER COLUMN id SET DEFAULT nextval('affairs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY alert_phases ALTER COLUMN id SET DEFAULT nextval('alert_phases_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY alerts ALTER COLUMN id SET DEFAULT nextval('alerts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY analyses ALTER COLUMN id SET DEFAULT nextval('analyses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY analysis_items ALTER COLUMN id SET DEFAULT nextval('analysis_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY attachments ALTER COLUMN id SET DEFAULT nextval('attachments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY bank_statement_items ALTER COLUMN id SET DEFAULT nextval('bank_statement_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY bank_statements ALTER COLUMN id SET DEFAULT nextval('bank_statements_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY call_messages ALTER COLUMN id SET DEFAULT nextval('call_messages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY calls ALTER COLUMN id SET DEFAULT nextval('calls_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY campaigns ALTER COLUMN id SET DEFAULT nextval('campaigns_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cap_islets ALTER COLUMN id SET DEFAULT nextval('cap_islets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cap_land_parcels ALTER COLUMN id SET DEFAULT nextval('cap_land_parcels_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cap_statements ALTER COLUMN id SET DEFAULT nextval('cap_statements_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cash_sessions ALTER COLUMN id SET DEFAULT nextval('cash_sessions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cash_transfers ALTER COLUMN id SET DEFAULT nextval('cash_transfers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cashes ALTER COLUMN id SET DEFAULT nextval('cashes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY catalog_items ALTER COLUMN id SET DEFAULT nextval('catalog_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY catalogs ALTER COLUMN id SET DEFAULT nextval('catalogs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY contract_items ALTER COLUMN id SET DEFAULT nextval('contract_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY contracts ALTER COLUMN id SET DEFAULT nextval('contracts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY crumbs ALTER COLUMN id SET DEFAULT nextval('crumbs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cultivable_zones ALTER COLUMN id SET DEFAULT nextval('cultivable_zones_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_field_choices ALTER COLUMN id SET DEFAULT nextval('custom_field_choices_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_fields ALTER COLUMN id SET DEFAULT nextval('custom_fields_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY dashboards ALTER COLUMN id SET DEFAULT nextval('dashboards_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY debt_transfers ALTER COLUMN id SET DEFAULT nextval('debt_transfers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY deliveries ALTER COLUMN id SET DEFAULT nextval('deliveries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY delivery_tools ALTER COLUMN id SET DEFAULT nextval('delivery_tools_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY deposits ALTER COLUMN id SET DEFAULT nextval('deposits_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY districts ALTER COLUMN id SET DEFAULT nextval('districts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY document_templates ALTER COLUMN id SET DEFAULT nextval('document_templates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY documents ALTER COLUMN id SET DEFAULT nextval('documents_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY entities ALTER COLUMN id SET DEFAULT nextval('entities_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY entity_addresses ALTER COLUMN id SET DEFAULT nextval('entity_addresses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY entity_links ALTER COLUMN id SET DEFAULT nextval('entity_links_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY event_participations ALTER COLUMN id SET DEFAULT nextval('event_participations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY events ALTER COLUMN id SET DEFAULT nextval('events_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY financial_year_exchanges ALTER COLUMN id SET DEFAULT nextval('financial_year_exchanges_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY financial_years ALTER COLUMN id SET DEFAULT nextval('financial_years_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY fixed_asset_depreciations ALTER COLUMN id SET DEFAULT nextval('fixed_asset_depreciations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY fixed_assets ALTER COLUMN id SET DEFAULT nextval('fixed_assets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY gap_items ALTER COLUMN id SET DEFAULT nextval('gap_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY gaps ALTER COLUMN id SET DEFAULT nextval('gaps_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY georeadings ALTER COLUMN id SET DEFAULT nextval('georeadings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY guide_analyses ALTER COLUMN id SET DEFAULT nextval('guide_analyses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY guide_analysis_points ALTER COLUMN id SET DEFAULT nextval('guide_analysis_points_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY guides ALTER COLUMN id SET DEFAULT nextval('guides_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY identifiers ALTER COLUMN id SET DEFAULT nextval('identifiers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY imports ALTER COLUMN id SET DEFAULT nextval('imports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY incoming_payment_modes ALTER COLUMN id SET DEFAULT nextval('incoming_payment_modes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY incoming_payments ALTER COLUMN id SET DEFAULT nextval('incoming_payments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY inspection_calibrations ALTER COLUMN id SET DEFAULT nextval('inspection_calibrations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY inspection_points ALTER COLUMN id SET DEFAULT nextval('inspection_points_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY inspections ALTER COLUMN id SET DEFAULT nextval('inspections_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY integrations ALTER COLUMN id SET DEFAULT nextval('integrations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY intervention_labellings ALTER COLUMN id SET DEFAULT nextval('intervention_labellings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY intervention_parameter_readings ALTER COLUMN id SET DEFAULT nextval('intervention_parameter_readings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY intervention_parameters ALTER COLUMN id SET DEFAULT nextval('intervention_parameters_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY intervention_participations ALTER COLUMN id SET DEFAULT nextval('intervention_participations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY intervention_working_periods ALTER COLUMN id SET DEFAULT nextval('intervention_working_periods_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY interventions ALTER COLUMN id SET DEFAULT nextval('interventions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY inventories ALTER COLUMN id SET DEFAULT nextval('inventories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY inventory_items ALTER COLUMN id SET DEFAULT nextval('inventory_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY issues ALTER COLUMN id SET DEFAULT nextval('issues_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY journal_entries ALTER COLUMN id SET DEFAULT nextval('journal_entries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY journal_entry_items ALTER COLUMN id SET DEFAULT nextval('journal_entry_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY journals ALTER COLUMN id SET DEFAULT nextval('journals_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY labels ALTER COLUMN id SET DEFAULT nextval('labels_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY listing_node_items ALTER COLUMN id SET DEFAULT nextval('listing_node_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY listing_nodes ALTER COLUMN id SET DEFAULT nextval('listing_nodes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY listings ALTER COLUMN id SET DEFAULT nextval('listings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY loan_repayments ALTER COLUMN id SET DEFAULT nextval('loan_repayments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY loans ALTER COLUMN id SET DEFAULT nextval('loans_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY manure_management_plan_zones ALTER COLUMN id SET DEFAULT nextval('manure_management_plan_zones_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY manure_management_plans ALTER COLUMN id SET DEFAULT nextval('manure_management_plans_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY map_layers ALTER COLUMN id SET DEFAULT nextval('map_layers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY net_services ALTER COLUMN id SET DEFAULT nextval('net_services_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY notifications ALTER COLUMN id SET DEFAULT nextval('notifications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY observations ALTER COLUMN id SET DEFAULT nextval('observations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY outgoing_payment_lists ALTER COLUMN id SET DEFAULT nextval('outgoing_payment_lists_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY outgoing_payment_modes ALTER COLUMN id SET DEFAULT nextval('outgoing_payment_modes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY outgoing_payments ALTER COLUMN id SET DEFAULT nextval('outgoing_payments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY parcel_items ALTER COLUMN id SET DEFAULT nextval('parcel_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY parcels ALTER COLUMN id SET DEFAULT nextval('parcels_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY plant_counting_items ALTER COLUMN id SET DEFAULT nextval('plant_counting_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY plant_countings ALTER COLUMN id SET DEFAULT nextval('plant_countings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY plant_density_abaci ALTER COLUMN id SET DEFAULT nextval('plant_density_abaci_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY plant_density_abacus_items ALTER COLUMN id SET DEFAULT nextval('plant_density_abacus_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY postal_zones ALTER COLUMN id SET DEFAULT nextval('postal_zones_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY preferences ALTER COLUMN id SET DEFAULT nextval('preferences_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY prescriptions ALTER COLUMN id SET DEFAULT nextval('prescriptions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_enjoyments ALTER COLUMN id SET DEFAULT nextval('product_enjoyments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_labellings ALTER COLUMN id SET DEFAULT nextval('product_labellings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_linkages ALTER COLUMN id SET DEFAULT nextval('product_linkages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_links ALTER COLUMN id SET DEFAULT nextval('product_links_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_localizations ALTER COLUMN id SET DEFAULT nextval('product_localizations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_memberships ALTER COLUMN id SET DEFAULT nextval('product_memberships_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_movements ALTER COLUMN id SET DEFAULT nextval('product_movements_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_categories ALTER COLUMN id SET DEFAULT nextval('product_nature_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_category_taxations ALTER COLUMN id SET DEFAULT nextval('product_nature_category_taxations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_variant_components ALTER COLUMN id SET DEFAULT nextval('product_nature_variant_components_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_variant_readings ALTER COLUMN id SET DEFAULT nextval('product_nature_variant_readings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_variants ALTER COLUMN id SET DEFAULT nextval('product_nature_variants_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_natures ALTER COLUMN id SET DEFAULT nextval('product_natures_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_ownerships ALTER COLUMN id SET DEFAULT nextval('product_ownerships_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_phases ALTER COLUMN id SET DEFAULT nextval('product_phases_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_readings ALTER COLUMN id SET DEFAULT nextval('product_readings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY products ALTER COLUMN id SET DEFAULT nextval('products_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY purchase_items ALTER COLUMN id SET DEFAULT nextval('purchase_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY purchase_natures ALTER COLUMN id SET DEFAULT nextval('purchase_natures_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY purchases ALTER COLUMN id SET DEFAULT nextval('purchases_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY regularizations ALTER COLUMN id SET DEFAULT nextval('regularizations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY roles ALTER COLUMN id SET DEFAULT nextval('roles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sale_items ALTER COLUMN id SET DEFAULT nextval('sale_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sale_natures ALTER COLUMN id SET DEFAULT nextval('sale_natures_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sales ALTER COLUMN id SET DEFAULT nextval('sales_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sensors ALTER COLUMN id SET DEFAULT nextval('sensors_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sequences ALTER COLUMN id SET DEFAULT nextval('sequences_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY subscription_natures ALTER COLUMN id SET DEFAULT nextval('subscription_natures_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY subscriptions ALTER COLUMN id SET DEFAULT nextval('subscriptions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY supervision_items ALTER COLUMN id SET DEFAULT nextval('supervision_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY supervisions ALTER COLUMN id SET DEFAULT nextval('supervisions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY synchronization_operations ALTER COLUMN id SET DEFAULT nextval('synchronization_operations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY target_distributions ALTER COLUMN id SET DEFAULT nextval('target_distributions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tasks ALTER COLUMN id SET DEFAULT nextval('tasks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tax_declaration_item_parts ALTER COLUMN id SET DEFAULT nextval('tax_declaration_item_parts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tax_declaration_items ALTER COLUMN id SET DEFAULT nextval('tax_declaration_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tax_declarations ALTER COLUMN id SET DEFAULT nextval('tax_declarations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY taxes ALTER COLUMN id SET DEFAULT nextval('taxes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY teams ALTER COLUMN id SET DEFAULT nextval('teams_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tokens ALTER COLUMN id SET DEFAULT nextval('tokens_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY trackings ALTER COLUMN id SET DEFAULT nextval('trackings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY versions ALTER COLUMN id SET DEFAULT nextval('versions_id_seq'::regclass);


--
-- Name: account_balances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_balances
    ADD CONSTRAINT account_balances_pkey PRIMARY KEY (id);


--
-- Name: accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activities
    ADD CONSTRAINT activities_pkey PRIMARY KEY (id);


--
-- Name: activity_budget_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_budget_items
    ADD CONSTRAINT activity_budget_items_pkey PRIMARY KEY (id);


--
-- Name: activity_budgets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_budgets
    ADD CONSTRAINT activity_budgets_pkey PRIMARY KEY (id);


--
-- Name: activity_distributions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_distributions
    ADD CONSTRAINT activity_distributions_pkey PRIMARY KEY (id);


--
-- Name: activity_inspection_calibration_natures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_inspection_calibration_natures
    ADD CONSTRAINT activity_inspection_calibration_natures_pkey PRIMARY KEY (id);


--
-- Name: activity_inspection_calibration_scales_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_inspection_calibration_scales
    ADD CONSTRAINT activity_inspection_calibration_scales_pkey PRIMARY KEY (id);


--
-- Name: activity_inspection_point_natures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_inspection_point_natures
    ADD CONSTRAINT activity_inspection_point_natures_pkey PRIMARY KEY (id);


--
-- Name: activity_productions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_productions
    ADD CONSTRAINT activity_productions_pkey PRIMARY KEY (id);


--
-- Name: activity_seasons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_seasons
    ADD CONSTRAINT activity_seasons_pkey PRIMARY KEY (id);


--
-- Name: activity_tactics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_tactics
    ADD CONSTRAINT activity_tactics_pkey PRIMARY KEY (id);


--
-- Name: affairs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY affairs
    ADD CONSTRAINT affairs_pkey PRIMARY KEY (id);


--
-- Name: alert_phases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY alert_phases
    ADD CONSTRAINT alert_phases_pkey PRIMARY KEY (id);


--
-- Name: alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY alerts
    ADD CONSTRAINT alerts_pkey PRIMARY KEY (id);


--
-- Name: analyses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY analyses
    ADD CONSTRAINT analyses_pkey PRIMARY KEY (id);


--
-- Name: analysis_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY analysis_items
    ADD CONSTRAINT analysis_items_pkey PRIMARY KEY (id);


--
-- Name: attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY attachments
    ADD CONSTRAINT attachments_pkey PRIMARY KEY (id);


--
-- Name: bank_statement_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bank_statement_items
    ADD CONSTRAINT bank_statement_items_pkey PRIMARY KEY (id);


--
-- Name: bank_statements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bank_statements
    ADD CONSTRAINT bank_statements_pkey PRIMARY KEY (id);


--
-- Name: call_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY call_messages
    ADD CONSTRAINT call_messages_pkey PRIMARY KEY (id);


--
-- Name: calls_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY calls
    ADD CONSTRAINT calls_pkey PRIMARY KEY (id);


--
-- Name: campaigns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY campaigns
    ADD CONSTRAINT campaigns_pkey PRIMARY KEY (id);


--
-- Name: cap_islets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cap_islets
    ADD CONSTRAINT cap_islets_pkey PRIMARY KEY (id);


--
-- Name: cap_land_parcels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cap_land_parcels
    ADD CONSTRAINT cap_land_parcels_pkey PRIMARY KEY (id);


--
-- Name: cap_statements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cap_statements
    ADD CONSTRAINT cap_statements_pkey PRIMARY KEY (id);


--
-- Name: cash_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cash_sessions
    ADD CONSTRAINT cash_sessions_pkey PRIMARY KEY (id);


--
-- Name: cash_transfers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cash_transfers
    ADD CONSTRAINT cash_transfers_pkey PRIMARY KEY (id);


--
-- Name: cashes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cashes
    ADD CONSTRAINT cashes_pkey PRIMARY KEY (id);


--
-- Name: catalog_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY catalog_items
    ADD CONSTRAINT catalog_items_pkey PRIMARY KEY (id);


--
-- Name: catalogs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY catalogs
    ADD CONSTRAINT catalogs_pkey PRIMARY KEY (id);


--
-- Name: contract_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contract_items
    ADD CONSTRAINT contract_items_pkey PRIMARY KEY (id);


--
-- Name: contracts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contracts
    ADD CONSTRAINT contracts_pkey PRIMARY KEY (id);


--
-- Name: crumbs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY crumbs
    ADD CONSTRAINT crumbs_pkey PRIMARY KEY (id);


--
-- Name: cultivable_zones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cultivable_zones
    ADD CONSTRAINT cultivable_zones_pkey PRIMARY KEY (id);


--
-- Name: custom_field_choices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_field_choices
    ADD CONSTRAINT custom_field_choices_pkey PRIMARY KEY (id);


--
-- Name: custom_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_fields
    ADD CONSTRAINT custom_fields_pkey PRIMARY KEY (id);


--
-- Name: dashboards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY dashboards
    ADD CONSTRAINT dashboards_pkey PRIMARY KEY (id);


--
-- Name: debt_transfers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY debt_transfers
    ADD CONSTRAINT debt_transfers_pkey PRIMARY KEY (id);


--
-- Name: deliveries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deliveries
    ADD CONSTRAINT deliveries_pkey PRIMARY KEY (id);


--
-- Name: delivery_tools_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY delivery_tools
    ADD CONSTRAINT delivery_tools_pkey PRIMARY KEY (id);


--
-- Name: deposits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deposits
    ADD CONSTRAINT deposits_pkey PRIMARY KEY (id);


--
-- Name: districts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY districts
    ADD CONSTRAINT districts_pkey PRIMARY KEY (id);


--
-- Name: document_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY document_templates
    ADD CONSTRAINT document_templates_pkey PRIMARY KEY (id);


--
-- Name: documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY documents
    ADD CONSTRAINT documents_pkey PRIMARY KEY (id);


--
-- Name: entities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY entities
    ADD CONSTRAINT entities_pkey PRIMARY KEY (id);


--
-- Name: entity_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY entity_addresses
    ADD CONSTRAINT entity_addresses_pkey PRIMARY KEY (id);


--
-- Name: entity_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY entity_links
    ADD CONSTRAINT entity_links_pkey PRIMARY KEY (id);


--
-- Name: event_participations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY event_participations
    ADD CONSTRAINT event_participations_pkey PRIMARY KEY (id);


--
-- Name: events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: financial_year_exchanges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY financial_year_exchanges
    ADD CONSTRAINT financial_year_exchanges_pkey PRIMARY KEY (id);


--
-- Name: financial_years_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY financial_years
    ADD CONSTRAINT financial_years_pkey PRIMARY KEY (id);


--
-- Name: fixed_asset_depreciations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY fixed_asset_depreciations
    ADD CONSTRAINT fixed_asset_depreciations_pkey PRIMARY KEY (id);


--
-- Name: fixed_assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY fixed_assets
    ADD CONSTRAINT fixed_assets_pkey PRIMARY KEY (id);


--
-- Name: gap_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gap_items
    ADD CONSTRAINT gap_items_pkey PRIMARY KEY (id);


--
-- Name: gaps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gaps
    ADD CONSTRAINT gaps_pkey PRIMARY KEY (id);


--
-- Name: georeadings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY georeadings
    ADD CONSTRAINT georeadings_pkey PRIMARY KEY (id);


--
-- Name: guide_analyses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY guide_analyses
    ADD CONSTRAINT guide_analyses_pkey PRIMARY KEY (id);


--
-- Name: guide_analysis_points_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY guide_analysis_points
    ADD CONSTRAINT guide_analysis_points_pkey PRIMARY KEY (id);


--
-- Name: guides_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY guides
    ADD CONSTRAINT guides_pkey PRIMARY KEY (id);


--
-- Name: identifiers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY identifiers
    ADD CONSTRAINT identifiers_pkey PRIMARY KEY (id);


--
-- Name: imports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY imports
    ADD CONSTRAINT imports_pkey PRIMARY KEY (id);


--
-- Name: incoming_payment_modes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY incoming_payment_modes
    ADD CONSTRAINT incoming_payment_modes_pkey PRIMARY KEY (id);


--
-- Name: incoming_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY incoming_payments
    ADD CONSTRAINT incoming_payments_pkey PRIMARY KEY (id);


--
-- Name: inspection_calibrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inspection_calibrations
    ADD CONSTRAINT inspection_calibrations_pkey PRIMARY KEY (id);


--
-- Name: inspection_points_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inspection_points
    ADD CONSTRAINT inspection_points_pkey PRIMARY KEY (id);


--
-- Name: inspections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inspections
    ADD CONSTRAINT inspections_pkey PRIMARY KEY (id);


--
-- Name: integrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY integrations
    ADD CONSTRAINT integrations_pkey PRIMARY KEY (id);


--
-- Name: intervention_labellings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY intervention_labellings
    ADD CONSTRAINT intervention_labellings_pkey PRIMARY KEY (id);


--
-- Name: intervention_parameter_readings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY intervention_parameter_readings
    ADD CONSTRAINT intervention_parameter_readings_pkey PRIMARY KEY (id);


--
-- Name: intervention_parameters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY intervention_parameters
    ADD CONSTRAINT intervention_parameters_pkey PRIMARY KEY (id);


--
-- Name: intervention_participations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY intervention_participations
    ADD CONSTRAINT intervention_participations_pkey PRIMARY KEY (id);


--
-- Name: intervention_working_periods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY intervention_working_periods
    ADD CONSTRAINT intervention_working_periods_pkey PRIMARY KEY (id);


--
-- Name: interventions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY interventions
    ADD CONSTRAINT interventions_pkey PRIMARY KEY (id);


--
-- Name: inventories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inventories
    ADD CONSTRAINT inventories_pkey PRIMARY KEY (id);


--
-- Name: inventory_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inventory_items
    ADD CONSTRAINT inventory_items_pkey PRIMARY KEY (id);


--
-- Name: issues_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY issues
    ADD CONSTRAINT issues_pkey PRIMARY KEY (id);


--
-- Name: journal_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY journal_entries
    ADD CONSTRAINT journal_entries_pkey PRIMARY KEY (id);


--
-- Name: journal_entry_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY journal_entry_items
    ADD CONSTRAINT journal_entry_items_pkey PRIMARY KEY (id);


--
-- Name: journals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY journals
    ADD CONSTRAINT journals_pkey PRIMARY KEY (id);


--
-- Name: labels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY labels
    ADD CONSTRAINT labels_pkey PRIMARY KEY (id);


--
-- Name: listing_node_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY listing_node_items
    ADD CONSTRAINT listing_node_items_pkey PRIMARY KEY (id);


--
-- Name: listing_nodes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY listing_nodes
    ADD CONSTRAINT listing_nodes_pkey PRIMARY KEY (id);


--
-- Name: listings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY listings
    ADD CONSTRAINT listings_pkey PRIMARY KEY (id);


--
-- Name: loan_repayments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY loan_repayments
    ADD CONSTRAINT loan_repayments_pkey PRIMARY KEY (id);


--
-- Name: loans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY loans
    ADD CONSTRAINT loans_pkey PRIMARY KEY (id);


--
-- Name: manure_management_plan_zones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY manure_management_plan_zones
    ADD CONSTRAINT manure_management_plan_zones_pkey PRIMARY KEY (id);


--
-- Name: manure_management_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY manure_management_plans
    ADD CONSTRAINT manure_management_plans_pkey PRIMARY KEY (id);


--
-- Name: map_layers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY map_layers
    ADD CONSTRAINT map_layers_pkey PRIMARY KEY (id);


--
-- Name: net_services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY net_services
    ADD CONSTRAINT net_services_pkey PRIMARY KEY (id);


--
-- Name: notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: observations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY observations
    ADD CONSTRAINT observations_pkey PRIMARY KEY (id);


--
-- Name: outgoing_payment_lists_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY outgoing_payment_lists
    ADD CONSTRAINT outgoing_payment_lists_pkey PRIMARY KEY (id);


--
-- Name: outgoing_payment_modes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY outgoing_payment_modes
    ADD CONSTRAINT outgoing_payment_modes_pkey PRIMARY KEY (id);


--
-- Name: outgoing_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY outgoing_payments
    ADD CONSTRAINT outgoing_payments_pkey PRIMARY KEY (id);


--
-- Name: parcel_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY parcel_items
    ADD CONSTRAINT parcel_items_pkey PRIMARY KEY (id);


--
-- Name: parcels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY parcels
    ADD CONSTRAINT parcels_pkey PRIMARY KEY (id);


--
-- Name: plant_counting_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY plant_counting_items
    ADD CONSTRAINT plant_counting_items_pkey PRIMARY KEY (id);


--
-- Name: plant_countings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY plant_countings
    ADD CONSTRAINT plant_countings_pkey PRIMARY KEY (id);


--
-- Name: plant_density_abaci_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY plant_density_abaci
    ADD CONSTRAINT plant_density_abaci_pkey PRIMARY KEY (id);


--
-- Name: plant_density_abacus_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY plant_density_abacus_items
    ADD CONSTRAINT plant_density_abacus_items_pkey PRIMARY KEY (id);


--
-- Name: postal_zones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY postal_zones
    ADD CONSTRAINT postal_zones_pkey PRIMARY KEY (id);


--
-- Name: preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY preferences
    ADD CONSTRAINT preferences_pkey PRIMARY KEY (id);


--
-- Name: prescriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY prescriptions
    ADD CONSTRAINT prescriptions_pkey PRIMARY KEY (id);


--
-- Name: product_enjoyments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_enjoyments
    ADD CONSTRAINT product_enjoyments_pkey PRIMARY KEY (id);


--
-- Name: product_labellings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_labellings
    ADD CONSTRAINT product_labellings_pkey PRIMARY KEY (id);


--
-- Name: product_linkages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_linkages
    ADD CONSTRAINT product_linkages_pkey PRIMARY KEY (id);


--
-- Name: product_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_links
    ADD CONSTRAINT product_links_pkey PRIMARY KEY (id);


--
-- Name: product_localizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_localizations
    ADD CONSTRAINT product_localizations_pkey PRIMARY KEY (id);


--
-- Name: product_memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_memberships
    ADD CONSTRAINT product_memberships_pkey PRIMARY KEY (id);


--
-- Name: product_movements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_movements
    ADD CONSTRAINT product_movements_pkey PRIMARY KEY (id);


--
-- Name: product_nature_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_categories
    ADD CONSTRAINT product_nature_categories_pkey PRIMARY KEY (id);


--
-- Name: product_nature_category_taxations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_category_taxations
    ADD CONSTRAINT product_nature_category_taxations_pkey PRIMARY KEY (id);


--
-- Name: product_nature_variant_components_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_variant_components
    ADD CONSTRAINT product_nature_variant_components_pkey PRIMARY KEY (id);


--
-- Name: product_nature_variant_readings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_variant_readings
    ADD CONSTRAINT product_nature_variant_readings_pkey PRIMARY KEY (id);


--
-- Name: product_nature_variants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_variants
    ADD CONSTRAINT product_nature_variants_pkey PRIMARY KEY (id);


--
-- Name: product_natures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_natures
    ADD CONSTRAINT product_natures_pkey PRIMARY KEY (id);


--
-- Name: product_ownerships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_ownerships
    ADD CONSTRAINT product_ownerships_pkey PRIMARY KEY (id);


--
-- Name: product_phases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_phases
    ADD CONSTRAINT product_phases_pkey PRIMARY KEY (id);


--
-- Name: product_readings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_readings
    ADD CONSTRAINT product_readings_pkey PRIMARY KEY (id);


--
-- Name: products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: purchase_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY purchase_items
    ADD CONSTRAINT purchase_items_pkey PRIMARY KEY (id);


--
-- Name: purchase_natures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY purchase_natures
    ADD CONSTRAINT purchase_natures_pkey PRIMARY KEY (id);


--
-- Name: purchases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY purchases
    ADD CONSTRAINT purchases_pkey PRIMARY KEY (id);


--
-- Name: regularizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY regularizations
    ADD CONSTRAINT regularizations_pkey PRIMARY KEY (id);


--
-- Name: roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: sale_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sale_items
    ADD CONSTRAINT sale_items_pkey PRIMARY KEY (id);


--
-- Name: sale_natures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sale_natures
    ADD CONSTRAINT sale_natures_pkey PRIMARY KEY (id);


--
-- Name: sales_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sales
    ADD CONSTRAINT sales_pkey PRIMARY KEY (id);


--
-- Name: sensors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sensors
    ADD CONSTRAINT sensors_pkey PRIMARY KEY (id);


--
-- Name: sequences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sequences
    ADD CONSTRAINT sequences_pkey PRIMARY KEY (id);


--
-- Name: subscription_natures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY subscription_natures
    ADD CONSTRAINT subscription_natures_pkey PRIMARY KEY (id);


--
-- Name: subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: supervision_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY supervision_items
    ADD CONSTRAINT supervision_items_pkey PRIMARY KEY (id);


--
-- Name: supervisions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY supervisions
    ADD CONSTRAINT supervisions_pkey PRIMARY KEY (id);


--
-- Name: synchronization_operations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY synchronization_operations
    ADD CONSTRAINT synchronization_operations_pkey PRIMARY KEY (id);


--
-- Name: target_distributions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY target_distributions
    ADD CONSTRAINT target_distributions_pkey PRIMARY KEY (id);


--
-- Name: tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (id);


--
-- Name: tax_declaration_item_parts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tax_declaration_item_parts
    ADD CONSTRAINT tax_declaration_item_parts_pkey PRIMARY KEY (id);


--
-- Name: tax_declaration_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tax_declaration_items
    ADD CONSTRAINT tax_declaration_items_pkey PRIMARY KEY (id);


--
-- Name: tax_declarations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tax_declarations
    ADD CONSTRAINT tax_declarations_pkey PRIMARY KEY (id);


--
-- Name: taxes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY taxes
    ADD CONSTRAINT taxes_pkey PRIMARY KEY (id);


--
-- Name: teams_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (id);


--
-- Name: tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tokens
    ADD CONSTRAINT tokens_pkey PRIMARY KEY (id);


--
-- Name: trackings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY trackings
    ADD CONSTRAINT trackings_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: index_account_balances_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_balances_on_account_id ON account_balances USING btree (account_id);


--
-- Name: index_account_balances_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_balances_on_created_at ON account_balances USING btree (created_at);


--
-- Name: index_account_balances_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_balances_on_creator_id ON account_balances USING btree (creator_id);


--
-- Name: index_account_balances_on_financial_year_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_balances_on_financial_year_id ON account_balances USING btree (financial_year_id);


--
-- Name: index_account_balances_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_balances_on_updated_at ON account_balances USING btree (updated_at);


--
-- Name: index_account_balances_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_balances_on_updater_id ON account_balances USING btree (updater_id);


--
-- Name: index_accounts_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_created_at ON accounts USING btree (created_at);


--
-- Name: index_accounts_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_creator_id ON accounts USING btree (creator_id);


--
-- Name: index_accounts_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_updated_at ON accounts USING btree (updated_at);


--
-- Name: index_accounts_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_updater_id ON accounts USING btree (updater_id);


--
-- Name: index_activities_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_created_at ON activities USING btree (created_at);


--
-- Name: index_activities_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_creator_id ON activities USING btree (creator_id);


--
-- Name: index_activities_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_name ON activities USING btree (name);


--
-- Name: index_activities_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_updated_at ON activities USING btree (updated_at);


--
-- Name: index_activities_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_updater_id ON activities USING btree (updater_id);


--
-- Name: index_activity_budget_items_on_activity_budget_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_budget_items_on_activity_budget_id ON activity_budget_items USING btree (activity_budget_id);


--
-- Name: index_activity_budget_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_budget_items_on_created_at ON activity_budget_items USING btree (created_at);


--
-- Name: index_activity_budget_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_budget_items_on_creator_id ON activity_budget_items USING btree (creator_id);


--
-- Name: index_activity_budget_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_budget_items_on_updated_at ON activity_budget_items USING btree (updated_at);


--
-- Name: index_activity_budget_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_budget_items_on_updater_id ON activity_budget_items USING btree (updater_id);


--
-- Name: index_activity_budget_items_on_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_budget_items_on_variant_id ON activity_budget_items USING btree (variant_id);


--
-- Name: index_activity_budgets_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_budgets_on_activity_id ON activity_budgets USING btree (activity_id);


--
-- Name: index_activity_budgets_on_activity_id_and_campaign_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_activity_budgets_on_activity_id_and_campaign_id ON activity_budgets USING btree (activity_id, campaign_id);


--
-- Name: index_activity_budgets_on_campaign_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_budgets_on_campaign_id ON activity_budgets USING btree (campaign_id);


--
-- Name: index_activity_budgets_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_budgets_on_created_at ON activity_budgets USING btree (created_at);


--
-- Name: index_activity_budgets_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_budgets_on_creator_id ON activity_budgets USING btree (creator_id);


--
-- Name: index_activity_budgets_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_budgets_on_updated_at ON activity_budgets USING btree (updated_at);


--
-- Name: index_activity_budgets_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_budgets_on_updater_id ON activity_budgets USING btree (updater_id);


--
-- Name: index_activity_distributions_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_distributions_on_activity_id ON activity_distributions USING btree (activity_id);


--
-- Name: index_activity_distributions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_distributions_on_created_at ON activity_distributions USING btree (created_at);


--
-- Name: index_activity_distributions_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_distributions_on_creator_id ON activity_distributions USING btree (creator_id);


--
-- Name: index_activity_distributions_on_main_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_distributions_on_main_activity_id ON activity_distributions USING btree (main_activity_id);


--
-- Name: index_activity_distributions_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_distributions_on_updated_at ON activity_distributions USING btree (updated_at);


--
-- Name: index_activity_distributions_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_distributions_on_updater_id ON activity_distributions USING btree (updater_id);


--
-- Name: index_activity_inspection_calibration_natures_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_inspection_calibration_natures_on_created_at ON activity_inspection_calibration_natures USING btree (created_at);


--
-- Name: index_activity_inspection_calibration_natures_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_inspection_calibration_natures_on_creator_id ON activity_inspection_calibration_natures USING btree (creator_id);


--
-- Name: index_activity_inspection_calibration_natures_on_scale_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_inspection_calibration_natures_on_scale_id ON activity_inspection_calibration_natures USING btree (scale_id);


--
-- Name: index_activity_inspection_calibration_natures_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_inspection_calibration_natures_on_updated_at ON activity_inspection_calibration_natures USING btree (updated_at);


--
-- Name: index_activity_inspection_calibration_natures_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_inspection_calibration_natures_on_updater_id ON activity_inspection_calibration_natures USING btree (updater_id);


--
-- Name: index_activity_inspection_calibration_scales_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_inspection_calibration_scales_on_activity_id ON activity_inspection_calibration_scales USING btree (activity_id);


--
-- Name: index_activity_inspection_calibration_scales_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_inspection_calibration_scales_on_created_at ON activity_inspection_calibration_scales USING btree (created_at);


--
-- Name: index_activity_inspection_calibration_scales_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_inspection_calibration_scales_on_creator_id ON activity_inspection_calibration_scales USING btree (creator_id);


--
-- Name: index_activity_inspection_calibration_scales_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_inspection_calibration_scales_on_updated_at ON activity_inspection_calibration_scales USING btree (updated_at);


--
-- Name: index_activity_inspection_calibration_scales_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_inspection_calibration_scales_on_updater_id ON activity_inspection_calibration_scales USING btree (updater_id);


--
-- Name: index_activity_inspection_point_natures_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_inspection_point_natures_on_activity_id ON activity_inspection_point_natures USING btree (activity_id);


--
-- Name: index_activity_inspection_point_natures_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_inspection_point_natures_on_created_at ON activity_inspection_point_natures USING btree (created_at);


--
-- Name: index_activity_inspection_point_natures_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_inspection_point_natures_on_creator_id ON activity_inspection_point_natures USING btree (creator_id);


--
-- Name: index_activity_inspection_point_natures_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_inspection_point_natures_on_updated_at ON activity_inspection_point_natures USING btree (updated_at);


--
-- Name: index_activity_inspection_point_natures_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_inspection_point_natures_on_updater_id ON activity_inspection_point_natures USING btree (updater_id);


--
-- Name: index_activity_productions_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_productions_on_activity_id ON activity_productions USING btree (activity_id);


--
-- Name: index_activity_productions_on_campaign_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_productions_on_campaign_id ON activity_productions USING btree (campaign_id);


--
-- Name: index_activity_productions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_productions_on_created_at ON activity_productions USING btree (created_at);


--
-- Name: index_activity_productions_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_productions_on_creator_id ON activity_productions USING btree (creator_id);


--
-- Name: index_activity_productions_on_cultivable_zone_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_productions_on_cultivable_zone_id ON activity_productions USING btree (cultivable_zone_id);


--
-- Name: index_activity_productions_on_season_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_productions_on_season_id ON activity_productions USING btree (season_id);


--
-- Name: index_activity_productions_on_support_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_productions_on_support_id ON activity_productions USING btree (support_id);


--
-- Name: index_activity_productions_on_tactic_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_productions_on_tactic_id ON activity_productions USING btree (tactic_id);


--
-- Name: index_activity_productions_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_productions_on_updated_at ON activity_productions USING btree (updated_at);


--
-- Name: index_activity_productions_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_productions_on_updater_id ON activity_productions USING btree (updater_id);


--
-- Name: index_activity_seasons_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_seasons_on_activity_id ON activity_seasons USING btree (activity_id);


--
-- Name: index_activity_seasons_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_seasons_on_created_at ON activity_seasons USING btree (created_at);


--
-- Name: index_activity_seasons_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_seasons_on_creator_id ON activity_seasons USING btree (creator_id);


--
-- Name: index_activity_seasons_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_seasons_on_updated_at ON activity_seasons USING btree (updated_at);


--
-- Name: index_activity_seasons_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_seasons_on_updater_id ON activity_seasons USING btree (updater_id);


--
-- Name: index_activity_tactics_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_tactics_on_activity_id ON activity_tactics USING btree (activity_id);


--
-- Name: index_activity_tactics_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_tactics_on_created_at ON activity_tactics USING btree (created_at);


--
-- Name: index_activity_tactics_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_tactics_on_creator_id ON activity_tactics USING btree (creator_id);


--
-- Name: index_activity_tactics_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_tactics_on_updated_at ON activity_tactics USING btree (updated_at);


--
-- Name: index_activity_tactics_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_tactics_on_updater_id ON activity_tactics USING btree (updater_id);


--
-- Name: index_affairs_on_cash_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_affairs_on_cash_session_id ON affairs USING btree (cash_session_id);


--
-- Name: index_affairs_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_affairs_on_created_at ON affairs USING btree (created_at);


--
-- Name: index_affairs_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_affairs_on_creator_id ON affairs USING btree (creator_id);


--
-- Name: index_affairs_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_affairs_on_journal_entry_id ON affairs USING btree (journal_entry_id);


--
-- Name: index_affairs_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_affairs_on_name ON affairs USING btree (name);


--
-- Name: index_affairs_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_affairs_on_number ON affairs USING btree (number);


--
-- Name: index_affairs_on_responsible_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_affairs_on_responsible_id ON affairs USING btree (responsible_id);


--
-- Name: index_affairs_on_third_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_affairs_on_third_id ON affairs USING btree (third_id);


--
-- Name: index_affairs_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_affairs_on_updated_at ON affairs USING btree (updated_at);


--
-- Name: index_affairs_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_affairs_on_updater_id ON affairs USING btree (updater_id);


--
-- Name: index_alert_phases_on_alert_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alert_phases_on_alert_id ON alert_phases USING btree (alert_id);


--
-- Name: index_alert_phases_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alert_phases_on_created_at ON alert_phases USING btree (created_at);


--
-- Name: index_alert_phases_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alert_phases_on_creator_id ON alert_phases USING btree (creator_id);


--
-- Name: index_alert_phases_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alert_phases_on_updated_at ON alert_phases USING btree (updated_at);


--
-- Name: index_alert_phases_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alert_phases_on_updater_id ON alert_phases USING btree (updater_id);


--
-- Name: index_alerts_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alerts_on_created_at ON alerts USING btree (created_at);


--
-- Name: index_alerts_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alerts_on_creator_id ON alerts USING btree (creator_id);


--
-- Name: index_alerts_on_sensor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alerts_on_sensor_id ON alerts USING btree (sensor_id);


--
-- Name: index_alerts_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alerts_on_updated_at ON alerts USING btree (updated_at);


--
-- Name: index_alerts_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alerts_on_updater_id ON alerts USING btree (updater_id);


--
-- Name: index_analyses_on_analyser_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analyses_on_analyser_id ON analyses USING btree (analyser_id);


--
-- Name: index_analyses_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analyses_on_created_at ON analyses USING btree (created_at);


--
-- Name: index_analyses_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analyses_on_creator_id ON analyses USING btree (creator_id);


--
-- Name: index_analyses_on_host_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analyses_on_host_id ON analyses USING btree (host_id);


--
-- Name: index_analyses_on_nature; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analyses_on_nature ON analyses USING btree (nature);


--
-- Name: index_analyses_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analyses_on_number ON analyses USING btree (number);


--
-- Name: index_analyses_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analyses_on_product_id ON analyses USING btree (product_id);


--
-- Name: index_analyses_on_reference_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analyses_on_reference_number ON analyses USING btree (reference_number);


--
-- Name: index_analyses_on_sampler_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analyses_on_sampler_id ON analyses USING btree (sampler_id);


--
-- Name: index_analyses_on_sensor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analyses_on_sensor_id ON analyses USING btree (sensor_id);


--
-- Name: index_analyses_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analyses_on_updated_at ON analyses USING btree (updated_at);


--
-- Name: index_analyses_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analyses_on_updater_id ON analyses USING btree (updater_id);


--
-- Name: index_analysis_items_on_analysis_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analysis_items_on_analysis_id ON analysis_items USING btree (analysis_id);


--
-- Name: index_analysis_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analysis_items_on_created_at ON analysis_items USING btree (created_at);


--
-- Name: index_analysis_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analysis_items_on_creator_id ON analysis_items USING btree (creator_id);


--
-- Name: index_analysis_items_on_indicator_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analysis_items_on_indicator_name ON analysis_items USING btree (indicator_name);


--
-- Name: index_analysis_items_on_product_reading_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analysis_items_on_product_reading_id ON analysis_items USING btree (product_reading_id);


--
-- Name: index_analysis_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analysis_items_on_updated_at ON analysis_items USING btree (updated_at);


--
-- Name: index_analysis_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_analysis_items_on_updater_id ON analysis_items USING btree (updater_id);


--
-- Name: index_attachments_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_created_at ON attachments USING btree (created_at);


--
-- Name: index_attachments_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_creator_id ON attachments USING btree (creator_id);


--
-- Name: index_attachments_on_document_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_document_id ON attachments USING btree (document_id);


--
-- Name: index_attachments_on_resource_type_and_resource_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_resource_type_and_resource_id ON attachments USING btree (resource_type, resource_id);


--
-- Name: index_attachments_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_updated_at ON attachments USING btree (updated_at);


--
-- Name: index_attachments_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_updater_id ON attachments USING btree (updater_id);


--
-- Name: index_bank_statement_items_on_bank_statement_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bank_statement_items_on_bank_statement_id ON bank_statement_items USING btree (bank_statement_id);


--
-- Name: index_bank_statement_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bank_statement_items_on_created_at ON bank_statement_items USING btree (created_at);


--
-- Name: index_bank_statement_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bank_statement_items_on_creator_id ON bank_statement_items USING btree (creator_id);


--
-- Name: index_bank_statement_items_on_letter; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bank_statement_items_on_letter ON bank_statement_items USING btree (letter);


--
-- Name: index_bank_statement_items_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bank_statement_items_on_name ON bank_statement_items USING btree (name);


--
-- Name: index_bank_statement_items_on_transaction_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bank_statement_items_on_transaction_number ON bank_statement_items USING btree (transaction_number);


--
-- Name: index_bank_statement_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bank_statement_items_on_updated_at ON bank_statement_items USING btree (updated_at);


--
-- Name: index_bank_statement_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bank_statement_items_on_updater_id ON bank_statement_items USING btree (updater_id);


--
-- Name: index_bank_statements_on_cash_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bank_statements_on_cash_id ON bank_statements USING btree (cash_id);


--
-- Name: index_bank_statements_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bank_statements_on_created_at ON bank_statements USING btree (created_at);


--
-- Name: index_bank_statements_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bank_statements_on_creator_id ON bank_statements USING btree (creator_id);


--
-- Name: index_bank_statements_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bank_statements_on_journal_entry_id ON bank_statements USING btree (journal_entry_id);


--
-- Name: index_bank_statements_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bank_statements_on_updated_at ON bank_statements USING btree (updated_at);


--
-- Name: index_bank_statements_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bank_statements_on_updater_id ON bank_statements USING btree (updater_id);


--
-- Name: index_call_messages_on_call_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_call_messages_on_call_id ON call_messages USING btree (call_id);


--
-- Name: index_call_messages_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_call_messages_on_created_at ON call_messages USING btree (created_at);


--
-- Name: index_call_messages_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_call_messages_on_creator_id ON call_messages USING btree (creator_id);


--
-- Name: index_call_messages_on_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_call_messages_on_request_id ON call_messages USING btree (request_id);


--
-- Name: index_call_messages_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_call_messages_on_updated_at ON call_messages USING btree (updated_at);


--
-- Name: index_call_messages_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_call_messages_on_updater_id ON call_messages USING btree (updater_id);


--
-- Name: index_calls_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_calls_on_created_at ON calls USING btree (created_at);


--
-- Name: index_calls_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_calls_on_creator_id ON calls USING btree (creator_id);


--
-- Name: index_calls_on_source_type_and_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_calls_on_source_type_and_source_id ON calls USING btree (source_type, source_id);


--
-- Name: index_calls_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_calls_on_updated_at ON calls USING btree (updated_at);


--
-- Name: index_calls_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_calls_on_updater_id ON calls USING btree (updater_id);


--
-- Name: index_campaigns_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_campaigns_on_created_at ON campaigns USING btree (created_at);


--
-- Name: index_campaigns_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_campaigns_on_creator_id ON campaigns USING btree (creator_id);


--
-- Name: index_campaigns_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_campaigns_on_updated_at ON campaigns USING btree (updated_at);


--
-- Name: index_campaigns_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_campaigns_on_updater_id ON campaigns USING btree (updater_id);


--
-- Name: index_cap_islets_on_cap_statement_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_islets_on_cap_statement_id ON cap_islets USING btree (cap_statement_id);


--
-- Name: index_cap_islets_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_islets_on_created_at ON cap_islets USING btree (created_at);


--
-- Name: index_cap_islets_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_islets_on_creator_id ON cap_islets USING btree (creator_id);


--
-- Name: index_cap_islets_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_islets_on_updated_at ON cap_islets USING btree (updated_at);


--
-- Name: index_cap_islets_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_islets_on_updater_id ON cap_islets USING btree (updater_id);


--
-- Name: index_cap_land_parcels_on_cap_islet_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_land_parcels_on_cap_islet_id ON cap_land_parcels USING btree (cap_islet_id);


--
-- Name: index_cap_land_parcels_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_land_parcels_on_created_at ON cap_land_parcels USING btree (created_at);


--
-- Name: index_cap_land_parcels_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_land_parcels_on_creator_id ON cap_land_parcels USING btree (creator_id);


--
-- Name: index_cap_land_parcels_on_support_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_land_parcels_on_support_id ON cap_land_parcels USING btree (support_id);


--
-- Name: index_cap_land_parcels_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_land_parcels_on_updated_at ON cap_land_parcels USING btree (updated_at);


--
-- Name: index_cap_land_parcels_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_land_parcels_on_updater_id ON cap_land_parcels USING btree (updater_id);


--
-- Name: index_cap_statements_on_campaign_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_statements_on_campaign_id ON cap_statements USING btree (campaign_id);


--
-- Name: index_cap_statements_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_statements_on_created_at ON cap_statements USING btree (created_at);


--
-- Name: index_cap_statements_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_statements_on_creator_id ON cap_statements USING btree (creator_id);


--
-- Name: index_cap_statements_on_declarant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_statements_on_declarant_id ON cap_statements USING btree (declarant_id);


--
-- Name: index_cap_statements_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_statements_on_updated_at ON cap_statements USING btree (updated_at);


--
-- Name: index_cap_statements_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cap_statements_on_updater_id ON cap_statements USING btree (updater_id);


--
-- Name: index_cash_sessions_on_cash_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cash_sessions_on_cash_id ON cash_sessions USING btree (cash_id);


--
-- Name: index_cash_sessions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cash_sessions_on_created_at ON cash_sessions USING btree (created_at);


--
-- Name: index_cash_sessions_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cash_sessions_on_creator_id ON cash_sessions USING btree (creator_id);


--
-- Name: index_cash_sessions_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cash_sessions_on_number ON cash_sessions USING btree (number);


--
-- Name: index_cash_sessions_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cash_sessions_on_updated_at ON cash_sessions USING btree (updated_at);


--
-- Name: index_cash_sessions_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cash_sessions_on_updater_id ON cash_sessions USING btree (updater_id);


--
-- Name: index_cash_transfers_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cash_transfers_on_created_at ON cash_transfers USING btree (created_at);


--
-- Name: index_cash_transfers_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cash_transfers_on_creator_id ON cash_transfers USING btree (creator_id);


--
-- Name: index_cash_transfers_on_emission_cash_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cash_transfers_on_emission_cash_id ON cash_transfers USING btree (emission_cash_id);


--
-- Name: index_cash_transfers_on_emission_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cash_transfers_on_emission_journal_entry_id ON cash_transfers USING btree (emission_journal_entry_id);


--
-- Name: index_cash_transfers_on_reception_cash_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cash_transfers_on_reception_cash_id ON cash_transfers USING btree (reception_cash_id);


--
-- Name: index_cash_transfers_on_reception_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cash_transfers_on_reception_journal_entry_id ON cash_transfers USING btree (reception_journal_entry_id);


--
-- Name: index_cash_transfers_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cash_transfers_on_updated_at ON cash_transfers USING btree (updated_at);


--
-- Name: index_cash_transfers_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cash_transfers_on_updater_id ON cash_transfers USING btree (updater_id);


--
-- Name: index_cashes_on_container_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cashes_on_container_id ON cashes USING btree (container_id);


--
-- Name: index_cashes_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cashes_on_created_at ON cashes USING btree (created_at);


--
-- Name: index_cashes_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cashes_on_creator_id ON cashes USING btree (creator_id);


--
-- Name: index_cashes_on_journal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cashes_on_journal_id ON cashes USING btree (journal_id);


--
-- Name: index_cashes_on_main_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cashes_on_main_account_id ON cashes USING btree (main_account_id);


--
-- Name: index_cashes_on_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cashes_on_owner_id ON cashes USING btree (owner_id);


--
-- Name: index_cashes_on_suspense_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cashes_on_suspense_account_id ON cashes USING btree (suspense_account_id);


--
-- Name: index_cashes_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cashes_on_updated_at ON cashes USING btree (updated_at);


--
-- Name: index_cashes_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cashes_on_updater_id ON cashes USING btree (updater_id);


--
-- Name: index_catalog_items_on_catalog_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_catalog_items_on_catalog_id ON catalog_items USING btree (catalog_id);


--
-- Name: index_catalog_items_on_catalog_id_and_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_catalog_items_on_catalog_id_and_variant_id ON catalog_items USING btree (catalog_id, variant_id);


--
-- Name: index_catalog_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_catalog_items_on_created_at ON catalog_items USING btree (created_at);


--
-- Name: index_catalog_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_catalog_items_on_creator_id ON catalog_items USING btree (creator_id);


--
-- Name: index_catalog_items_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_catalog_items_on_name ON catalog_items USING btree (name);


--
-- Name: index_catalog_items_on_reference_tax_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_catalog_items_on_reference_tax_id ON catalog_items USING btree (reference_tax_id);


--
-- Name: index_catalog_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_catalog_items_on_updated_at ON catalog_items USING btree (updated_at);


--
-- Name: index_catalog_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_catalog_items_on_updater_id ON catalog_items USING btree (updater_id);


--
-- Name: index_catalog_items_on_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_catalog_items_on_variant_id ON catalog_items USING btree (variant_id);


--
-- Name: index_catalogs_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_catalogs_on_created_at ON catalogs USING btree (created_at);


--
-- Name: index_catalogs_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_catalogs_on_creator_id ON catalogs USING btree (creator_id);


--
-- Name: index_catalogs_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_catalogs_on_updated_at ON catalogs USING btree (updated_at);


--
-- Name: index_catalogs_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_catalogs_on_updater_id ON catalogs USING btree (updater_id);


--
-- Name: index_contract_items_on_contract_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contract_items_on_contract_id ON contract_items USING btree (contract_id);


--
-- Name: index_contract_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contract_items_on_created_at ON contract_items USING btree (created_at);


--
-- Name: index_contract_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contract_items_on_creator_id ON contract_items USING btree (creator_id);


--
-- Name: index_contract_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contract_items_on_updated_at ON contract_items USING btree (updated_at);


--
-- Name: index_contract_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contract_items_on_updater_id ON contract_items USING btree (updater_id);


--
-- Name: index_contract_items_on_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contract_items_on_variant_id ON contract_items USING btree (variant_id);


--
-- Name: index_contracts_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contracts_on_created_at ON contracts USING btree (created_at);


--
-- Name: index_contracts_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contracts_on_creator_id ON contracts USING btree (creator_id);


--
-- Name: index_contracts_on_responsible_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contracts_on_responsible_id ON contracts USING btree (responsible_id);


--
-- Name: index_contracts_on_supplier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contracts_on_supplier_id ON contracts USING btree (supplier_id);


--
-- Name: index_contracts_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contracts_on_updated_at ON contracts USING btree (updated_at);


--
-- Name: index_contracts_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contracts_on_updater_id ON contracts USING btree (updater_id);


--
-- Name: index_crumbs_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crumbs_on_created_at ON crumbs USING btree (created_at);


--
-- Name: index_crumbs_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crumbs_on_creator_id ON crumbs USING btree (creator_id);


--
-- Name: index_crumbs_on_intervention_parameter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crumbs_on_intervention_parameter_id ON crumbs USING btree (intervention_parameter_id);


--
-- Name: index_crumbs_on_intervention_participation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crumbs_on_intervention_participation_id ON crumbs USING btree (intervention_participation_id);


--
-- Name: index_crumbs_on_nature; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crumbs_on_nature ON crumbs USING btree (nature);


--
-- Name: index_crumbs_on_read_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crumbs_on_read_at ON crumbs USING btree (read_at);


--
-- Name: index_crumbs_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crumbs_on_updated_at ON crumbs USING btree (updated_at);


--
-- Name: index_crumbs_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crumbs_on_updater_id ON crumbs USING btree (updater_id);


--
-- Name: index_crumbs_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crumbs_on_user_id ON crumbs USING btree (user_id);


--
-- Name: index_cultivable_zones_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cultivable_zones_on_created_at ON cultivable_zones USING btree (created_at);


--
-- Name: index_cultivable_zones_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cultivable_zones_on_creator_id ON cultivable_zones USING btree (creator_id);


--
-- Name: index_cultivable_zones_on_farmer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cultivable_zones_on_farmer_id ON cultivable_zones USING btree (farmer_id);


--
-- Name: index_cultivable_zones_on_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cultivable_zones_on_owner_id ON cultivable_zones USING btree (owner_id);


--
-- Name: index_cultivable_zones_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cultivable_zones_on_updated_at ON cultivable_zones USING btree (updated_at);


--
-- Name: index_cultivable_zones_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cultivable_zones_on_updater_id ON cultivable_zones USING btree (updater_id);


--
-- Name: index_custom_field_choices_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_field_choices_on_created_at ON custom_field_choices USING btree (created_at);


--
-- Name: index_custom_field_choices_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_field_choices_on_creator_id ON custom_field_choices USING btree (creator_id);


--
-- Name: index_custom_field_choices_on_custom_field_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_field_choices_on_custom_field_id ON custom_field_choices USING btree (custom_field_id);


--
-- Name: index_custom_field_choices_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_field_choices_on_updated_at ON custom_field_choices USING btree (updated_at);


--
-- Name: index_custom_field_choices_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_field_choices_on_updater_id ON custom_field_choices USING btree (updater_id);


--
-- Name: index_custom_fields_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_fields_on_created_at ON custom_fields USING btree (created_at);


--
-- Name: index_custom_fields_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_fields_on_creator_id ON custom_fields USING btree (creator_id);


--
-- Name: index_custom_fields_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_fields_on_updated_at ON custom_fields USING btree (updated_at);


--
-- Name: index_custom_fields_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_fields_on_updater_id ON custom_fields USING btree (updater_id);


--
-- Name: index_dashboards_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dashboards_on_created_at ON dashboards USING btree (created_at);


--
-- Name: index_dashboards_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dashboards_on_creator_id ON dashboards USING btree (creator_id);


--
-- Name: index_dashboards_on_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dashboards_on_owner_id ON dashboards USING btree (owner_id);


--
-- Name: index_dashboards_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dashboards_on_updated_at ON dashboards USING btree (updated_at);


--
-- Name: index_dashboards_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dashboards_on_updater_id ON dashboards USING btree (updater_id);


--
-- Name: index_debt_transfers_on_affair_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_debt_transfers_on_affair_id ON debt_transfers USING btree (affair_id);


--
-- Name: index_debt_transfers_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_debt_transfers_on_created_at ON debt_transfers USING btree (created_at);


--
-- Name: index_debt_transfers_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_debt_transfers_on_creator_id ON debt_transfers USING btree (creator_id);


--
-- Name: index_debt_transfers_on_debt_transfer_affair_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_debt_transfers_on_debt_transfer_affair_id ON debt_transfers USING btree (debt_transfer_affair_id);


--
-- Name: index_debt_transfers_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_debt_transfers_on_updated_at ON debt_transfers USING btree (updated_at);


--
-- Name: index_debt_transfers_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_debt_transfers_on_updater_id ON debt_transfers USING btree (updater_id);


--
-- Name: index_deliveries_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deliveries_on_created_at ON deliveries USING btree (created_at);


--
-- Name: index_deliveries_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deliveries_on_creator_id ON deliveries USING btree (creator_id);


--
-- Name: index_deliveries_on_driver_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deliveries_on_driver_id ON deliveries USING btree (driver_id);


--
-- Name: index_deliveries_on_responsible_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deliveries_on_responsible_id ON deliveries USING btree (responsible_id);


--
-- Name: index_deliveries_on_transporter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deliveries_on_transporter_id ON deliveries USING btree (transporter_id);


--
-- Name: index_deliveries_on_transporter_purchase_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deliveries_on_transporter_purchase_id ON deliveries USING btree (transporter_purchase_id);


--
-- Name: index_deliveries_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deliveries_on_updated_at ON deliveries USING btree (updated_at);


--
-- Name: index_deliveries_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deliveries_on_updater_id ON deliveries USING btree (updater_id);


--
-- Name: index_delivery_tools_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delivery_tools_on_created_at ON delivery_tools USING btree (created_at);


--
-- Name: index_delivery_tools_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delivery_tools_on_creator_id ON delivery_tools USING btree (creator_id);


--
-- Name: index_delivery_tools_on_delivery_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delivery_tools_on_delivery_id ON delivery_tools USING btree (delivery_id);


--
-- Name: index_delivery_tools_on_tool_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delivery_tools_on_tool_id ON delivery_tools USING btree (tool_id);


--
-- Name: index_delivery_tools_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delivery_tools_on_updated_at ON delivery_tools USING btree (updated_at);


--
-- Name: index_delivery_tools_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delivery_tools_on_updater_id ON delivery_tools USING btree (updater_id);


--
-- Name: index_deposits_on_cash_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deposits_on_cash_id ON deposits USING btree (cash_id);


--
-- Name: index_deposits_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deposits_on_created_at ON deposits USING btree (created_at);


--
-- Name: index_deposits_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deposits_on_creator_id ON deposits USING btree (creator_id);


--
-- Name: index_deposits_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deposits_on_journal_entry_id ON deposits USING btree (journal_entry_id);


--
-- Name: index_deposits_on_mode_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deposits_on_mode_id ON deposits USING btree (mode_id);


--
-- Name: index_deposits_on_responsible_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deposits_on_responsible_id ON deposits USING btree (responsible_id);


--
-- Name: index_deposits_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deposits_on_updated_at ON deposits USING btree (updated_at);


--
-- Name: index_deposits_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deposits_on_updater_id ON deposits USING btree (updater_id);


--
-- Name: index_districts_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_districts_on_created_at ON districts USING btree (created_at);


--
-- Name: index_districts_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_districts_on_creator_id ON districts USING btree (creator_id);


--
-- Name: index_districts_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_districts_on_updated_at ON districts USING btree (updated_at);


--
-- Name: index_districts_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_districts_on_updater_id ON districts USING btree (updater_id);


--
-- Name: index_document_templates_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_document_templates_on_created_at ON document_templates USING btree (created_at);


--
-- Name: index_document_templates_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_document_templates_on_creator_id ON document_templates USING btree (creator_id);


--
-- Name: index_document_templates_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_document_templates_on_updated_at ON document_templates USING btree (updated_at);


--
-- Name: index_document_templates_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_document_templates_on_updater_id ON document_templates USING btree (updater_id);


--
-- Name: index_documents_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_documents_on_created_at ON documents USING btree (created_at);


--
-- Name: index_documents_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_documents_on_creator_id ON documents USING btree (creator_id);


--
-- Name: index_documents_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_documents_on_name ON documents USING btree (name);


--
-- Name: index_documents_on_nature; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_documents_on_nature ON documents USING btree (nature);


--
-- Name: index_documents_on_nature_and_key; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_documents_on_nature_and_key ON documents USING btree (nature, key);


--
-- Name: index_documents_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_documents_on_number ON documents USING btree (number);


--
-- Name: index_documents_on_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_documents_on_template_id ON documents USING btree (template_id);


--
-- Name: index_documents_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_documents_on_updated_at ON documents USING btree (updated_at);


--
-- Name: index_documents_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_documents_on_updater_id ON documents USING btree (updater_id);


--
-- Name: index_entities_on_client_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entities_on_client_account_id ON entities USING btree (client_account_id);


--
-- Name: index_entities_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entities_on_created_at ON entities USING btree (created_at);


--
-- Name: index_entities_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entities_on_creator_id ON entities USING btree (creator_id);


--
-- Name: index_entities_on_employee_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entities_on_employee_account_id ON entities USING btree (employee_account_id);


--
-- Name: index_entities_on_full_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entities_on_full_name ON entities USING btree (full_name);


--
-- Name: index_entities_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entities_on_number ON entities USING btree (number);


--
-- Name: index_entities_on_of_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entities_on_of_company ON entities USING btree (of_company);


--
-- Name: index_entities_on_proposer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entities_on_proposer_id ON entities USING btree (proposer_id);


--
-- Name: index_entities_on_responsible_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entities_on_responsible_id ON entities USING btree (responsible_id);


--
-- Name: index_entities_on_supplier_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entities_on_supplier_account_id ON entities USING btree (supplier_account_id);


--
-- Name: index_entities_on_supplier_payment_mode_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entities_on_supplier_payment_mode_id ON entities USING btree (supplier_payment_mode_id);


--
-- Name: index_entities_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entities_on_updated_at ON entities USING btree (updated_at);


--
-- Name: index_entities_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entities_on_updater_id ON entities USING btree (updater_id);


--
-- Name: index_entity_addresses_on_by_default; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_addresses_on_by_default ON entity_addresses USING btree (by_default);


--
-- Name: index_entity_addresses_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_addresses_on_created_at ON entity_addresses USING btree (created_at);


--
-- Name: index_entity_addresses_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_addresses_on_creator_id ON entity_addresses USING btree (creator_id);


--
-- Name: index_entity_addresses_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_addresses_on_deleted_at ON entity_addresses USING btree (deleted_at);


--
-- Name: index_entity_addresses_on_entity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_addresses_on_entity_id ON entity_addresses USING btree (entity_id);


--
-- Name: index_entity_addresses_on_mail_postal_zone_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_addresses_on_mail_postal_zone_id ON entity_addresses USING btree (mail_postal_zone_id);


--
-- Name: index_entity_addresses_on_thread; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_addresses_on_thread ON entity_addresses USING btree (thread);


--
-- Name: index_entity_addresses_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_addresses_on_updated_at ON entity_addresses USING btree (updated_at);


--
-- Name: index_entity_addresses_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_addresses_on_updater_id ON entity_addresses USING btree (updater_id);


--
-- Name: index_entity_links_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_links_on_created_at ON entity_links USING btree (created_at);


--
-- Name: index_entity_links_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_links_on_creator_id ON entity_links USING btree (creator_id);


--
-- Name: index_entity_links_on_entity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_links_on_entity_id ON entity_links USING btree (entity_id);


--
-- Name: index_entity_links_on_entity_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_links_on_entity_role ON entity_links USING btree (entity_role);


--
-- Name: index_entity_links_on_linked_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_links_on_linked_id ON entity_links USING btree (linked_id);


--
-- Name: index_entity_links_on_linked_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_links_on_linked_role ON entity_links USING btree (linked_role);


--
-- Name: index_entity_links_on_nature; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_links_on_nature ON entity_links USING btree (nature);


--
-- Name: index_entity_links_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_links_on_updated_at ON entity_links USING btree (updated_at);


--
-- Name: index_entity_links_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entity_links_on_updater_id ON entity_links USING btree (updater_id);


--
-- Name: index_event_participations_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_event_participations_on_created_at ON event_participations USING btree (created_at);


--
-- Name: index_event_participations_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_event_participations_on_creator_id ON event_participations USING btree (creator_id);


--
-- Name: index_event_participations_on_event_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_event_participations_on_event_id ON event_participations USING btree (event_id);


--
-- Name: index_event_participations_on_participant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_event_participations_on_participant_id ON event_participations USING btree (participant_id);


--
-- Name: index_event_participations_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_event_participations_on_updated_at ON event_participations USING btree (updated_at);


--
-- Name: index_event_participations_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_event_participations_on_updater_id ON event_participations USING btree (updater_id);


--
-- Name: index_events_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_created_at ON events USING btree (created_at);


--
-- Name: index_events_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_creator_id ON events USING btree (creator_id);


--
-- Name: index_events_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_updated_at ON events USING btree (updated_at);


--
-- Name: index_events_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_updater_id ON events USING btree (updater_id);


--
-- Name: index_financial_year_exchanges_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_financial_year_exchanges_on_created_at ON financial_year_exchanges USING btree (created_at);


--
-- Name: index_financial_year_exchanges_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_financial_year_exchanges_on_creator_id ON financial_year_exchanges USING btree (creator_id);


--
-- Name: index_financial_year_exchanges_on_financial_year_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_financial_year_exchanges_on_financial_year_id ON financial_year_exchanges USING btree (financial_year_id);


--
-- Name: index_financial_year_exchanges_on_public_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_financial_year_exchanges_on_public_token ON financial_year_exchanges USING btree (public_token);


--
-- Name: index_financial_year_exchanges_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_financial_year_exchanges_on_updated_at ON financial_year_exchanges USING btree (updated_at);


--
-- Name: index_financial_year_exchanges_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_financial_year_exchanges_on_updater_id ON financial_year_exchanges USING btree (updater_id);


--
-- Name: index_financial_years_on_accountant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_financial_years_on_accountant_id ON financial_years USING btree (accountant_id);


--
-- Name: index_financial_years_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_financial_years_on_created_at ON financial_years USING btree (created_at);


--
-- Name: index_financial_years_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_financial_years_on_creator_id ON financial_years USING btree (creator_id);


--
-- Name: index_financial_years_on_last_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_financial_years_on_last_journal_entry_id ON financial_years USING btree (last_journal_entry_id);


--
-- Name: index_financial_years_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_financial_years_on_updated_at ON financial_years USING btree (updated_at);


--
-- Name: index_financial_years_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_financial_years_on_updater_id ON financial_years USING btree (updater_id);


--
-- Name: index_fixed_asset_depreciations_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_asset_depreciations_on_created_at ON fixed_asset_depreciations USING btree (created_at);


--
-- Name: index_fixed_asset_depreciations_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_asset_depreciations_on_creator_id ON fixed_asset_depreciations USING btree (creator_id);


--
-- Name: index_fixed_asset_depreciations_on_financial_year_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_asset_depreciations_on_financial_year_id ON fixed_asset_depreciations USING btree (financial_year_id);


--
-- Name: index_fixed_asset_depreciations_on_fixed_asset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_asset_depreciations_on_fixed_asset_id ON fixed_asset_depreciations USING btree (fixed_asset_id);


--
-- Name: index_fixed_asset_depreciations_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_asset_depreciations_on_journal_entry_id ON fixed_asset_depreciations USING btree (journal_entry_id);


--
-- Name: index_fixed_asset_depreciations_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_asset_depreciations_on_updated_at ON fixed_asset_depreciations USING btree (updated_at);


--
-- Name: index_fixed_asset_depreciations_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_asset_depreciations_on_updater_id ON fixed_asset_depreciations USING btree (updater_id);


--
-- Name: index_fixed_assets_on_allocation_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_allocation_account_id ON fixed_assets USING btree (allocation_account_id);


--
-- Name: index_fixed_assets_on_asset_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_asset_account_id ON fixed_assets USING btree (asset_account_id);


--
-- Name: index_fixed_assets_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_created_at ON fixed_assets USING btree (created_at);


--
-- Name: index_fixed_assets_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_creator_id ON fixed_assets USING btree (creator_id);


--
-- Name: index_fixed_assets_on_expenses_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_expenses_account_id ON fixed_assets USING btree (expenses_account_id);


--
-- Name: index_fixed_assets_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_journal_entry_id ON fixed_assets USING btree (journal_entry_id);


--
-- Name: index_fixed_assets_on_journal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_journal_id ON fixed_assets USING btree (journal_id);


--
-- Name: index_fixed_assets_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_product_id ON fixed_assets USING btree (product_id);


--
-- Name: index_fixed_assets_on_purchase_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_purchase_id ON fixed_assets USING btree (purchase_id);


--
-- Name: index_fixed_assets_on_purchase_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_purchase_item_id ON fixed_assets USING btree (purchase_item_id);


--
-- Name: index_fixed_assets_on_sale_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_sale_id ON fixed_assets USING btree (sale_id);


--
-- Name: index_fixed_assets_on_sale_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_sale_item_id ON fixed_assets USING btree (sale_item_id);


--
-- Name: index_fixed_assets_on_scrapped_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_scrapped_journal_entry_id ON fixed_assets USING btree (scrapped_journal_entry_id);


--
-- Name: index_fixed_assets_on_sold_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_sold_journal_entry_id ON fixed_assets USING btree (sold_journal_entry_id);


--
-- Name: index_fixed_assets_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_updated_at ON fixed_assets USING btree (updated_at);


--
-- Name: index_fixed_assets_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fixed_assets_on_updater_id ON fixed_assets USING btree (updater_id);


--
-- Name: index_gap_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gap_items_on_created_at ON gap_items USING btree (created_at);


--
-- Name: index_gap_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gap_items_on_creator_id ON gap_items USING btree (creator_id);


--
-- Name: index_gap_items_on_gap_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gap_items_on_gap_id ON gap_items USING btree (gap_id);


--
-- Name: index_gap_items_on_tax_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gap_items_on_tax_id ON gap_items USING btree (tax_id);


--
-- Name: index_gap_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gap_items_on_updated_at ON gap_items USING btree (updated_at);


--
-- Name: index_gap_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gap_items_on_updater_id ON gap_items USING btree (updater_id);


--
-- Name: index_gaps_on_affair_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gaps_on_affair_id ON gaps USING btree (affair_id);


--
-- Name: index_gaps_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gaps_on_created_at ON gaps USING btree (created_at);


--
-- Name: index_gaps_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gaps_on_creator_id ON gaps USING btree (creator_id);


--
-- Name: index_gaps_on_direction; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gaps_on_direction ON gaps USING btree (direction);


--
-- Name: index_gaps_on_entity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gaps_on_entity_id ON gaps USING btree (entity_id);


--
-- Name: index_gaps_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gaps_on_journal_entry_id ON gaps USING btree (journal_entry_id);


--
-- Name: index_gaps_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gaps_on_number ON gaps USING btree (number);


--
-- Name: index_gaps_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gaps_on_updated_at ON gaps USING btree (updated_at);


--
-- Name: index_gaps_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gaps_on_updater_id ON gaps USING btree (updater_id);


--
-- Name: index_georeadings_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_georeadings_on_created_at ON georeadings USING btree (created_at);


--
-- Name: index_georeadings_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_georeadings_on_creator_id ON georeadings USING btree (creator_id);


--
-- Name: index_georeadings_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_georeadings_on_name ON georeadings USING btree (name);


--
-- Name: index_georeadings_on_nature; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_georeadings_on_nature ON georeadings USING btree (nature);


--
-- Name: index_georeadings_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_georeadings_on_number ON georeadings USING btree (number);


--
-- Name: index_georeadings_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_georeadings_on_updated_at ON georeadings USING btree (updated_at);


--
-- Name: index_georeadings_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_georeadings_on_updater_id ON georeadings USING btree (updater_id);


--
-- Name: index_guide_analyses_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_guide_analyses_on_created_at ON guide_analyses USING btree (created_at);


--
-- Name: index_guide_analyses_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_guide_analyses_on_creator_id ON guide_analyses USING btree (creator_id);


--
-- Name: index_guide_analyses_on_guide_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_guide_analyses_on_guide_id ON guide_analyses USING btree (guide_id);


--
-- Name: index_guide_analyses_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_guide_analyses_on_updated_at ON guide_analyses USING btree (updated_at);


--
-- Name: index_guide_analyses_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_guide_analyses_on_updater_id ON guide_analyses USING btree (updater_id);


--
-- Name: index_guide_analysis_points_on_analysis_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_guide_analysis_points_on_analysis_id ON guide_analysis_points USING btree (analysis_id);


--
-- Name: index_guide_analysis_points_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_guide_analysis_points_on_created_at ON guide_analysis_points USING btree (created_at);


--
-- Name: index_guide_analysis_points_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_guide_analysis_points_on_creator_id ON guide_analysis_points USING btree (creator_id);


--
-- Name: index_guide_analysis_points_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_guide_analysis_points_on_updated_at ON guide_analysis_points USING btree (updated_at);


--
-- Name: index_guide_analysis_points_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_guide_analysis_points_on_updater_id ON guide_analysis_points USING btree (updater_id);


--
-- Name: index_guides_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_guides_on_created_at ON guides USING btree (created_at);


--
-- Name: index_guides_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_guides_on_creator_id ON guides USING btree (creator_id);


--
-- Name: index_guides_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_guides_on_updated_at ON guides USING btree (updated_at);


--
-- Name: index_guides_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_guides_on_updater_id ON guides USING btree (updater_id);


--
-- Name: index_identifiers_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_identifiers_on_created_at ON identifiers USING btree (created_at);


--
-- Name: index_identifiers_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_identifiers_on_creator_id ON identifiers USING btree (creator_id);


--
-- Name: index_identifiers_on_nature; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_identifiers_on_nature ON identifiers USING btree (nature);


--
-- Name: index_identifiers_on_net_service_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_identifiers_on_net_service_id ON identifiers USING btree (net_service_id);


--
-- Name: index_identifiers_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_identifiers_on_updated_at ON identifiers USING btree (updated_at);


--
-- Name: index_identifiers_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_identifiers_on_updater_id ON identifiers USING btree (updater_id);


--
-- Name: index_imports_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_imports_on_created_at ON imports USING btree (created_at);


--
-- Name: index_imports_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_imports_on_creator_id ON imports USING btree (creator_id);


--
-- Name: index_imports_on_imported_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_imports_on_imported_at ON imports USING btree (imported_at);


--
-- Name: index_imports_on_importer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_imports_on_importer_id ON imports USING btree (importer_id);


--
-- Name: index_imports_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_imports_on_updated_at ON imports USING btree (updated_at);


--
-- Name: index_imports_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_imports_on_updater_id ON imports USING btree (updater_id);


--
-- Name: index_incoming_payment_modes_on_cash_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payment_modes_on_cash_id ON incoming_payment_modes USING btree (cash_id);


--
-- Name: index_incoming_payment_modes_on_commission_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payment_modes_on_commission_account_id ON incoming_payment_modes USING btree (commission_account_id);


--
-- Name: index_incoming_payment_modes_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payment_modes_on_created_at ON incoming_payment_modes USING btree (created_at);


--
-- Name: index_incoming_payment_modes_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payment_modes_on_creator_id ON incoming_payment_modes USING btree (creator_id);


--
-- Name: index_incoming_payment_modes_on_depositables_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payment_modes_on_depositables_account_id ON incoming_payment_modes USING btree (depositables_account_id);


--
-- Name: index_incoming_payment_modes_on_depositables_journal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payment_modes_on_depositables_journal_id ON incoming_payment_modes USING btree (depositables_journal_id);


--
-- Name: index_incoming_payment_modes_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payment_modes_on_updated_at ON incoming_payment_modes USING btree (updated_at);


--
-- Name: index_incoming_payment_modes_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payment_modes_on_updater_id ON incoming_payment_modes USING btree (updater_id);


--
-- Name: index_incoming_payments_on_accounted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payments_on_accounted_at ON incoming_payments USING btree (accounted_at);


--
-- Name: index_incoming_payments_on_affair_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payments_on_affair_id ON incoming_payments USING btree (affair_id);


--
-- Name: index_incoming_payments_on_commission_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payments_on_commission_account_id ON incoming_payments USING btree (commission_account_id);


--
-- Name: index_incoming_payments_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payments_on_created_at ON incoming_payments USING btree (created_at);


--
-- Name: index_incoming_payments_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payments_on_creator_id ON incoming_payments USING btree (creator_id);


--
-- Name: index_incoming_payments_on_deposit_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payments_on_deposit_id ON incoming_payments USING btree (deposit_id);


--
-- Name: index_incoming_payments_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payments_on_journal_entry_id ON incoming_payments USING btree (journal_entry_id);


--
-- Name: index_incoming_payments_on_mode_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payments_on_mode_id ON incoming_payments USING btree (mode_id);


--
-- Name: index_incoming_payments_on_payer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payments_on_payer_id ON incoming_payments USING btree (payer_id);


--
-- Name: index_incoming_payments_on_responsible_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payments_on_responsible_id ON incoming_payments USING btree (responsible_id);


--
-- Name: index_incoming_payments_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payments_on_updated_at ON incoming_payments USING btree (updated_at);


--
-- Name: index_incoming_payments_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incoming_payments_on_updater_id ON incoming_payments USING btree (updater_id);


--
-- Name: index_inspection_calibrations_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspection_calibrations_on_created_at ON inspection_calibrations USING btree (created_at);


--
-- Name: index_inspection_calibrations_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspection_calibrations_on_creator_id ON inspection_calibrations USING btree (creator_id);


--
-- Name: index_inspection_calibrations_on_inspection_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspection_calibrations_on_inspection_id ON inspection_calibrations USING btree (inspection_id);


--
-- Name: index_inspection_calibrations_on_nature_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspection_calibrations_on_nature_id ON inspection_calibrations USING btree (nature_id);


--
-- Name: index_inspection_calibrations_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspection_calibrations_on_updated_at ON inspection_calibrations USING btree (updated_at);


--
-- Name: index_inspection_calibrations_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspection_calibrations_on_updater_id ON inspection_calibrations USING btree (updater_id);


--
-- Name: index_inspection_points_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspection_points_on_created_at ON inspection_points USING btree (created_at);


--
-- Name: index_inspection_points_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspection_points_on_creator_id ON inspection_points USING btree (creator_id);


--
-- Name: index_inspection_points_on_inspection_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspection_points_on_inspection_id ON inspection_points USING btree (inspection_id);


--
-- Name: index_inspection_points_on_nature_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspection_points_on_nature_id ON inspection_points USING btree (nature_id);


--
-- Name: index_inspection_points_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspection_points_on_updated_at ON inspection_points USING btree (updated_at);


--
-- Name: index_inspection_points_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspection_points_on_updater_id ON inspection_points USING btree (updater_id);


--
-- Name: index_inspections_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspections_on_activity_id ON inspections USING btree (activity_id);


--
-- Name: index_inspections_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspections_on_created_at ON inspections USING btree (created_at);


--
-- Name: index_inspections_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspections_on_creator_id ON inspections USING btree (creator_id);


--
-- Name: index_inspections_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspections_on_product_id ON inspections USING btree (product_id);


--
-- Name: index_inspections_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspections_on_updated_at ON inspections USING btree (updated_at);


--
-- Name: index_inspections_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inspections_on_updater_id ON inspections USING btree (updater_id);


--
-- Name: index_integrations_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_integrations_on_created_at ON integrations USING btree (created_at);


--
-- Name: index_integrations_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_integrations_on_creator_id ON integrations USING btree (creator_id);


--
-- Name: index_integrations_on_nature; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_integrations_on_nature ON integrations USING btree (nature);


--
-- Name: index_integrations_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_integrations_on_updated_at ON integrations USING btree (updated_at);


--
-- Name: index_integrations_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_integrations_on_updater_id ON integrations USING btree (updater_id);


--
-- Name: index_intervention_labellings_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_labellings_on_created_at ON intervention_labellings USING btree (created_at);


--
-- Name: index_intervention_labellings_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_labellings_on_creator_id ON intervention_labellings USING btree (creator_id);


--
-- Name: index_intervention_labellings_on_intervention_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_labellings_on_intervention_id ON intervention_labellings USING btree (intervention_id);


--
-- Name: index_intervention_labellings_on_intervention_id_and_label_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_intervention_labellings_on_intervention_id_and_label_id ON intervention_labellings USING btree (intervention_id, label_id);


--
-- Name: index_intervention_labellings_on_label_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_labellings_on_label_id ON intervention_labellings USING btree (label_id);


--
-- Name: index_intervention_labellings_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_labellings_on_updated_at ON intervention_labellings USING btree (updated_at);


--
-- Name: index_intervention_labellings_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_labellings_on_updater_id ON intervention_labellings USING btree (updater_id);


--
-- Name: index_intervention_parameter_readings_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameter_readings_on_created_at ON intervention_parameter_readings USING btree (created_at);


--
-- Name: index_intervention_parameter_readings_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameter_readings_on_creator_id ON intervention_parameter_readings USING btree (creator_id);


--
-- Name: index_intervention_parameter_readings_on_indicator_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameter_readings_on_indicator_name ON intervention_parameter_readings USING btree (indicator_name);


--
-- Name: index_intervention_parameter_readings_on_parameter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameter_readings_on_parameter_id ON intervention_parameter_readings USING btree (parameter_id);


--
-- Name: index_intervention_parameter_readings_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameter_readings_on_updated_at ON intervention_parameter_readings USING btree (updated_at);


--
-- Name: index_intervention_parameter_readings_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameter_readings_on_updater_id ON intervention_parameter_readings USING btree (updater_id);


--
-- Name: index_intervention_parameters_on_assembly_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_assembly_id ON intervention_parameters USING btree (assembly_id);


--
-- Name: index_intervention_parameters_on_component_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_component_id ON intervention_parameters USING btree (component_id);


--
-- Name: index_intervention_parameters_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_created_at ON intervention_parameters USING btree (created_at);


--
-- Name: index_intervention_parameters_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_creator_id ON intervention_parameters USING btree (creator_id);


--
-- Name: index_intervention_parameters_on_event_participation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_event_participation_id ON intervention_parameters USING btree (event_participation_id);


--
-- Name: index_intervention_parameters_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_group_id ON intervention_parameters USING btree (group_id);


--
-- Name: index_intervention_parameters_on_intervention_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_intervention_id ON intervention_parameters USING btree (intervention_id);


--
-- Name: index_intervention_parameters_on_new_container_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_new_container_id ON intervention_parameters USING btree (new_container_id);


--
-- Name: index_intervention_parameters_on_new_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_new_group_id ON intervention_parameters USING btree (new_group_id);


--
-- Name: index_intervention_parameters_on_new_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_new_variant_id ON intervention_parameters USING btree (new_variant_id);


--
-- Name: index_intervention_parameters_on_outcoming_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_outcoming_product_id ON intervention_parameters USING btree (outcoming_product_id);


--
-- Name: index_intervention_parameters_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_product_id ON intervention_parameters USING btree (product_id);


--
-- Name: index_intervention_parameters_on_reference_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_reference_name ON intervention_parameters USING btree (reference_name);


--
-- Name: index_intervention_parameters_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_type ON intervention_parameters USING btree (type);


--
-- Name: index_intervention_parameters_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_updated_at ON intervention_parameters USING btree (updated_at);


--
-- Name: index_intervention_parameters_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_updater_id ON intervention_parameters USING btree (updater_id);


--
-- Name: index_intervention_parameters_on_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_parameters_on_variant_id ON intervention_parameters USING btree (variant_id);


--
-- Name: index_intervention_participations_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_participations_on_created_at ON intervention_participations USING btree (created_at);


--
-- Name: index_intervention_participations_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_participations_on_creator_id ON intervention_participations USING btree (creator_id);


--
-- Name: index_intervention_participations_on_intervention_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_participations_on_intervention_id ON intervention_participations USING btree (intervention_id);


--
-- Name: index_intervention_participations_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_participations_on_product_id ON intervention_participations USING btree (product_id);


--
-- Name: index_intervention_participations_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_participations_on_updated_at ON intervention_participations USING btree (updated_at);


--
-- Name: index_intervention_participations_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_participations_on_updater_id ON intervention_participations USING btree (updater_id);


--
-- Name: index_intervention_working_periods_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_working_periods_on_created_at ON intervention_working_periods USING btree (created_at);


--
-- Name: index_intervention_working_periods_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_working_periods_on_creator_id ON intervention_working_periods USING btree (creator_id);


--
-- Name: index_intervention_working_periods_on_intervention_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_working_periods_on_intervention_id ON intervention_working_periods USING btree (intervention_id);


--
-- Name: index_intervention_working_periods_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_working_periods_on_updated_at ON intervention_working_periods USING btree (updated_at);


--
-- Name: index_intervention_working_periods_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_intervention_working_periods_on_updater_id ON intervention_working_periods USING btree (updater_id);


--
-- Name: index_interventions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_interventions_on_created_at ON interventions USING btree (created_at);


--
-- Name: index_interventions_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_interventions_on_creator_id ON interventions USING btree (creator_id);


--
-- Name: index_interventions_on_event_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_interventions_on_event_id ON interventions USING btree (event_id);


--
-- Name: index_interventions_on_issue_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_interventions_on_issue_id ON interventions USING btree (issue_id);


--
-- Name: index_interventions_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_interventions_on_journal_entry_id ON interventions USING btree (journal_entry_id);


--
-- Name: index_interventions_on_nature; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_interventions_on_nature ON interventions USING btree (nature);


--
-- Name: index_interventions_on_prescription_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_interventions_on_prescription_id ON interventions USING btree (prescription_id);


--
-- Name: index_interventions_on_procedure_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_interventions_on_procedure_name ON interventions USING btree (procedure_name);


--
-- Name: index_interventions_on_request_intervention_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_interventions_on_request_intervention_id ON interventions USING btree (request_intervention_id);


--
-- Name: index_interventions_on_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_interventions_on_started_at ON interventions USING btree (started_at);


--
-- Name: index_interventions_on_stopped_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_interventions_on_stopped_at ON interventions USING btree (stopped_at);


--
-- Name: index_interventions_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_interventions_on_updated_at ON interventions USING btree (updated_at);


--
-- Name: index_interventions_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_interventions_on_updater_id ON interventions USING btree (updater_id);


--
-- Name: index_inventories_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventories_on_created_at ON inventories USING btree (created_at);


--
-- Name: index_inventories_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventories_on_creator_id ON inventories USING btree (creator_id);


--
-- Name: index_inventories_on_financial_year_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventories_on_financial_year_id ON inventories USING btree (financial_year_id);


--
-- Name: index_inventories_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventories_on_journal_entry_id ON inventories USING btree (journal_entry_id);


--
-- Name: index_inventories_on_responsible_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventories_on_responsible_id ON inventories USING btree (responsible_id);


--
-- Name: index_inventories_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventories_on_updated_at ON inventories USING btree (updated_at);


--
-- Name: index_inventories_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventories_on_updater_id ON inventories USING btree (updater_id);


--
-- Name: index_inventory_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventory_items_on_created_at ON inventory_items USING btree (created_at);


--
-- Name: index_inventory_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventory_items_on_creator_id ON inventory_items USING btree (creator_id);


--
-- Name: index_inventory_items_on_inventory_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventory_items_on_inventory_id ON inventory_items USING btree (inventory_id);


--
-- Name: index_inventory_items_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventory_items_on_product_id ON inventory_items USING btree (product_id);


--
-- Name: index_inventory_items_on_product_movement_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventory_items_on_product_movement_id ON inventory_items USING btree (product_movement_id);


--
-- Name: index_inventory_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventory_items_on_updated_at ON inventory_items USING btree (updated_at);


--
-- Name: index_inventory_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventory_items_on_updater_id ON inventory_items USING btree (updater_id);


--
-- Name: index_issues_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_created_at ON issues USING btree (created_at);


--
-- Name: index_issues_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_creator_id ON issues USING btree (creator_id);


--
-- Name: index_issues_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_name ON issues USING btree (name);


--
-- Name: index_issues_on_nature; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_nature ON issues USING btree (nature);


--
-- Name: index_issues_on_target_type_and_target_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_target_type_and_target_id ON issues USING btree (target_type, target_id);


--
-- Name: index_issues_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_updated_at ON issues USING btree (updated_at);


--
-- Name: index_issues_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_updater_id ON issues USING btree (updater_id);


--
-- Name: index_journal_entries_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entries_on_created_at ON journal_entries USING btree (created_at);


--
-- Name: index_journal_entries_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entries_on_creator_id ON journal_entries USING btree (creator_id);


--
-- Name: index_journal_entries_on_financial_year_exchange_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entries_on_financial_year_exchange_id ON journal_entries USING btree (financial_year_exchange_id);


--
-- Name: index_journal_entries_on_financial_year_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entries_on_financial_year_id ON journal_entries USING btree (financial_year_id);


--
-- Name: index_journal_entries_on_journal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entries_on_journal_id ON journal_entries USING btree (journal_id);


--
-- Name: index_journal_entries_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entries_on_number ON journal_entries USING btree (number);


--
-- Name: index_journal_entries_on_resource_type_and_resource_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entries_on_resource_type_and_resource_id ON journal_entries USING btree (resource_type, resource_id);


--
-- Name: index_journal_entries_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entries_on_updated_at ON journal_entries USING btree (updated_at);


--
-- Name: index_journal_entries_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entries_on_updater_id ON journal_entries USING btree (updater_id);


--
-- Name: index_journal_entry_items_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_account_id ON journal_entry_items USING btree (account_id);


--
-- Name: index_journal_entry_items_on_activity_budget_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_activity_budget_id ON journal_entry_items USING btree (activity_budget_id);


--
-- Name: index_journal_entry_items_on_bank_statement_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_bank_statement_id ON journal_entry_items USING btree (bank_statement_id);


--
-- Name: index_journal_entry_items_on_bank_statement_letter; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_bank_statement_letter ON journal_entry_items USING btree (bank_statement_letter);


--
-- Name: index_journal_entry_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_created_at ON journal_entry_items USING btree (created_at);


--
-- Name: index_journal_entry_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_creator_id ON journal_entry_items USING btree (creator_id);


--
-- Name: index_journal_entry_items_on_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_entry_id ON journal_entry_items USING btree (entry_id);


--
-- Name: index_journal_entry_items_on_financial_year_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_financial_year_id ON journal_entry_items USING btree (financial_year_id);


--
-- Name: index_journal_entry_items_on_journal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_journal_id ON journal_entry_items USING btree (journal_id);


--
-- Name: index_journal_entry_items_on_letter; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_letter ON journal_entry_items USING btree (letter);


--
-- Name: index_journal_entry_items_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_name ON journal_entry_items USING btree (name);


--
-- Name: index_journal_entry_items_on_resource_type_and_resource_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_resource_type_and_resource_id ON journal_entry_items USING btree (resource_type, resource_id);


--
-- Name: index_journal_entry_items_on_tax_declaration_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_tax_declaration_item_id ON journal_entry_items USING btree (tax_declaration_item_id);


--
-- Name: index_journal_entry_items_on_tax_declaration_mode; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_tax_declaration_mode ON journal_entry_items USING btree (tax_declaration_mode);


--
-- Name: index_journal_entry_items_on_tax_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_tax_id ON journal_entry_items USING btree (tax_id);


--
-- Name: index_journal_entry_items_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_team_id ON journal_entry_items USING btree (team_id);


--
-- Name: index_journal_entry_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_updated_at ON journal_entry_items USING btree (updated_at);


--
-- Name: index_journal_entry_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_updater_id ON journal_entry_items USING btree (updater_id);


--
-- Name: index_journal_entry_items_on_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journal_entry_items_on_variant_id ON journal_entry_items USING btree (variant_id);


--
-- Name: index_journals_on_accountant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journals_on_accountant_id ON journals USING btree (accountant_id);


--
-- Name: index_journals_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journals_on_created_at ON journals USING btree (created_at);


--
-- Name: index_journals_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journals_on_creator_id ON journals USING btree (creator_id);


--
-- Name: index_journals_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journals_on_updated_at ON journals USING btree (updated_at);


--
-- Name: index_journals_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journals_on_updater_id ON journals USING btree (updater_id);


--
-- Name: index_labels_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_labels_on_created_at ON labels USING btree (created_at);


--
-- Name: index_labels_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_labels_on_creator_id ON labels USING btree (creator_id);


--
-- Name: index_labels_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_labels_on_name ON labels USING btree (name);


--
-- Name: index_labels_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_labels_on_updated_at ON labels USING btree (updated_at);


--
-- Name: index_labels_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_labels_on_updater_id ON labels USING btree (updater_id);


--
-- Name: index_listing_node_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listing_node_items_on_created_at ON listing_node_items USING btree (created_at);


--
-- Name: index_listing_node_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listing_node_items_on_creator_id ON listing_node_items USING btree (creator_id);


--
-- Name: index_listing_node_items_on_node_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listing_node_items_on_node_id ON listing_node_items USING btree (node_id);


--
-- Name: index_listing_node_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listing_node_items_on_updated_at ON listing_node_items USING btree (updated_at);


--
-- Name: index_listing_node_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listing_node_items_on_updater_id ON listing_node_items USING btree (updater_id);


--
-- Name: index_listing_nodes_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listing_nodes_on_created_at ON listing_nodes USING btree (created_at);


--
-- Name: index_listing_nodes_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listing_nodes_on_creator_id ON listing_nodes USING btree (creator_id);


--
-- Name: index_listing_nodes_on_exportable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listing_nodes_on_exportable ON listing_nodes USING btree (exportable);


--
-- Name: index_listing_nodes_on_item_listing_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listing_nodes_on_item_listing_id ON listing_nodes USING btree (item_listing_id);


--
-- Name: index_listing_nodes_on_item_listing_node_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listing_nodes_on_item_listing_node_id ON listing_nodes USING btree (item_listing_node_id);


--
-- Name: index_listing_nodes_on_listing_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listing_nodes_on_listing_id ON listing_nodes USING btree (listing_id);


--
-- Name: index_listing_nodes_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listing_nodes_on_name ON listing_nodes USING btree (name);


--
-- Name: index_listing_nodes_on_nature; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listing_nodes_on_nature ON listing_nodes USING btree (nature);


--
-- Name: index_listing_nodes_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listing_nodes_on_parent_id ON listing_nodes USING btree (parent_id);


--
-- Name: index_listing_nodes_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listing_nodes_on_updated_at ON listing_nodes USING btree (updated_at);


--
-- Name: index_listing_nodes_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listing_nodes_on_updater_id ON listing_nodes USING btree (updater_id);


--
-- Name: index_listings_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listings_on_created_at ON listings USING btree (created_at);


--
-- Name: index_listings_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listings_on_creator_id ON listings USING btree (creator_id);


--
-- Name: index_listings_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listings_on_name ON listings USING btree (name);


--
-- Name: index_listings_on_root_model; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listings_on_root_model ON listings USING btree (root_model);


--
-- Name: index_listings_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listings_on_updated_at ON listings USING btree (updated_at);


--
-- Name: index_listings_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_listings_on_updater_id ON listings USING btree (updater_id);


--
-- Name: index_loan_repayments_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_repayments_on_created_at ON loan_repayments USING btree (created_at);


--
-- Name: index_loan_repayments_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_repayments_on_creator_id ON loan_repayments USING btree (creator_id);


--
-- Name: index_loan_repayments_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_repayments_on_journal_entry_id ON loan_repayments USING btree (journal_entry_id);


--
-- Name: index_loan_repayments_on_loan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_repayments_on_loan_id ON loan_repayments USING btree (loan_id);


--
-- Name: index_loan_repayments_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_repayments_on_updated_at ON loan_repayments USING btree (updated_at);


--
-- Name: index_loan_repayments_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loan_repayments_on_updater_id ON loan_repayments USING btree (updater_id);


--
-- Name: index_loans_on_cash_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loans_on_cash_id ON loans USING btree (cash_id);


--
-- Name: index_loans_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loans_on_created_at ON loans USING btree (created_at);


--
-- Name: index_loans_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loans_on_creator_id ON loans USING btree (creator_id);


--
-- Name: index_loans_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loans_on_journal_entry_id ON loans USING btree (journal_entry_id);


--
-- Name: index_loans_on_lender_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loans_on_lender_id ON loans USING btree (lender_id);


--
-- Name: index_loans_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loans_on_updated_at ON loans USING btree (updated_at);


--
-- Name: index_loans_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loans_on_updater_id ON loans USING btree (updater_id);


--
-- Name: index_manure_management_plan_zones_on_activity_production_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_manure_management_plan_zones_on_activity_production_id ON manure_management_plan_zones USING btree (activity_production_id);


--
-- Name: index_manure_management_plan_zones_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_manure_management_plan_zones_on_created_at ON manure_management_plan_zones USING btree (created_at);


--
-- Name: index_manure_management_plan_zones_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_manure_management_plan_zones_on_creator_id ON manure_management_plan_zones USING btree (creator_id);


--
-- Name: index_manure_management_plan_zones_on_plan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_manure_management_plan_zones_on_plan_id ON manure_management_plan_zones USING btree (plan_id);


--
-- Name: index_manure_management_plan_zones_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_manure_management_plan_zones_on_updated_at ON manure_management_plan_zones USING btree (updated_at);


--
-- Name: index_manure_management_plan_zones_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_manure_management_plan_zones_on_updater_id ON manure_management_plan_zones USING btree (updater_id);


--
-- Name: index_manure_management_plans_on_campaign_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_manure_management_plans_on_campaign_id ON manure_management_plans USING btree (campaign_id);


--
-- Name: index_manure_management_plans_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_manure_management_plans_on_created_at ON manure_management_plans USING btree (created_at);


--
-- Name: index_manure_management_plans_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_manure_management_plans_on_creator_id ON manure_management_plans USING btree (creator_id);


--
-- Name: index_manure_management_plans_on_recommender_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_manure_management_plans_on_recommender_id ON manure_management_plans USING btree (recommender_id);


--
-- Name: index_manure_management_plans_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_manure_management_plans_on_updated_at ON manure_management_plans USING btree (updated_at);


--
-- Name: index_manure_management_plans_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_manure_management_plans_on_updater_id ON manure_management_plans USING btree (updater_id);


--
-- Name: index_map_layers_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_map_layers_on_created_at ON map_layers USING btree (created_at);


--
-- Name: index_map_layers_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_map_layers_on_creator_id ON map_layers USING btree (creator_id);


--
-- Name: index_map_layers_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_map_layers_on_name ON map_layers USING btree (name);


--
-- Name: index_map_layers_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_map_layers_on_updated_at ON map_layers USING btree (updated_at);


--
-- Name: index_map_layers_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_map_layers_on_updater_id ON map_layers USING btree (updater_id);


--
-- Name: index_net_services_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_net_services_on_created_at ON net_services USING btree (created_at);


--
-- Name: index_net_services_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_net_services_on_creator_id ON net_services USING btree (creator_id);


--
-- Name: index_net_services_on_reference_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_net_services_on_reference_name ON net_services USING btree (reference_name);


--
-- Name: index_net_services_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_net_services_on_updated_at ON net_services USING btree (updated_at);


--
-- Name: index_net_services_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_net_services_on_updater_id ON net_services USING btree (updater_id);


--
-- Name: index_notifications_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_created_at ON notifications USING btree (created_at);


--
-- Name: index_notifications_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_creator_id ON notifications USING btree (creator_id);


--
-- Name: index_notifications_on_level; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_level ON notifications USING btree (level);


--
-- Name: index_notifications_on_read_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_read_at ON notifications USING btree (read_at);


--
-- Name: index_notifications_on_recipient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_recipient_id ON notifications USING btree (recipient_id);


--
-- Name: index_notifications_on_target_type_and_target_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_target_type_and_target_id ON notifications USING btree (target_type, target_id);


--
-- Name: index_notifications_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_updated_at ON notifications USING btree (updated_at);


--
-- Name: index_notifications_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_updater_id ON notifications USING btree (updater_id);


--
-- Name: index_observations_on_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_observations_on_author_id ON observations USING btree (author_id);


--
-- Name: index_observations_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_observations_on_created_at ON observations USING btree (created_at);


--
-- Name: index_observations_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_observations_on_creator_id ON observations USING btree (creator_id);


--
-- Name: index_observations_on_subject_type_and_subject_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_observations_on_subject_type_and_subject_id ON observations USING btree (subject_type, subject_id);


--
-- Name: index_observations_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_observations_on_updated_at ON observations USING btree (updated_at);


--
-- Name: index_observations_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_observations_on_updater_id ON observations USING btree (updater_id);


--
-- Name: index_outgoing_payment_lists_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payment_lists_on_creator_id ON outgoing_payment_lists USING btree (creator_id);


--
-- Name: index_outgoing_payment_lists_on_mode_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payment_lists_on_mode_id ON outgoing_payment_lists USING btree (mode_id);


--
-- Name: index_outgoing_payment_lists_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payment_lists_on_updater_id ON outgoing_payment_lists USING btree (updater_id);


--
-- Name: index_outgoing_payment_modes_on_cash_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payment_modes_on_cash_id ON outgoing_payment_modes USING btree (cash_id);


--
-- Name: index_outgoing_payment_modes_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payment_modes_on_created_at ON outgoing_payment_modes USING btree (created_at);


--
-- Name: index_outgoing_payment_modes_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payment_modes_on_creator_id ON outgoing_payment_modes USING btree (creator_id);


--
-- Name: index_outgoing_payment_modes_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payment_modes_on_updated_at ON outgoing_payment_modes USING btree (updated_at);


--
-- Name: index_outgoing_payment_modes_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payment_modes_on_updater_id ON outgoing_payment_modes USING btree (updater_id);


--
-- Name: index_outgoing_payments_on_affair_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payments_on_affair_id ON outgoing_payments USING btree (affair_id);


--
-- Name: index_outgoing_payments_on_cash_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payments_on_cash_id ON outgoing_payments USING btree (cash_id);


--
-- Name: index_outgoing_payments_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payments_on_created_at ON outgoing_payments USING btree (created_at);


--
-- Name: index_outgoing_payments_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payments_on_creator_id ON outgoing_payments USING btree (creator_id);


--
-- Name: index_outgoing_payments_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payments_on_journal_entry_id ON outgoing_payments USING btree (journal_entry_id);


--
-- Name: index_outgoing_payments_on_mode_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payments_on_mode_id ON outgoing_payments USING btree (mode_id);


--
-- Name: index_outgoing_payments_on_payee_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payments_on_payee_id ON outgoing_payments USING btree (payee_id);


--
-- Name: index_outgoing_payments_on_responsible_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payments_on_responsible_id ON outgoing_payments USING btree (responsible_id);


--
-- Name: index_outgoing_payments_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payments_on_updated_at ON outgoing_payments USING btree (updated_at);


--
-- Name: index_outgoing_payments_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outgoing_payments_on_updater_id ON outgoing_payments USING btree (updater_id);


--
-- Name: index_parcel_items_on_analysis_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_analysis_id ON parcel_items USING btree (analysis_id);


--
-- Name: index_parcel_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_created_at ON parcel_items USING btree (created_at);


--
-- Name: index_parcel_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_creator_id ON parcel_items USING btree (creator_id);


--
-- Name: index_parcel_items_on_parcel_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_parcel_id ON parcel_items USING btree (parcel_id);


--
-- Name: index_parcel_items_on_product_enjoyment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_product_enjoyment_id ON parcel_items USING btree (product_enjoyment_id);


--
-- Name: index_parcel_items_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_product_id ON parcel_items USING btree (product_id);


--
-- Name: index_parcel_items_on_product_localization_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_product_localization_id ON parcel_items USING btree (product_localization_id);


--
-- Name: index_parcel_items_on_product_movement_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_product_movement_id ON parcel_items USING btree (product_movement_id);


--
-- Name: index_parcel_items_on_product_ownership_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_product_ownership_id ON parcel_items USING btree (product_ownership_id);


--
-- Name: index_parcel_items_on_purchase_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_purchase_item_id ON parcel_items USING btree (purchase_item_id);


--
-- Name: index_parcel_items_on_sale_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_sale_item_id ON parcel_items USING btree (sale_item_id);


--
-- Name: index_parcel_items_on_source_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_source_product_id ON parcel_items USING btree (source_product_id);


--
-- Name: index_parcel_items_on_source_product_movement_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_source_product_movement_id ON parcel_items USING btree (source_product_movement_id);


--
-- Name: index_parcel_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_updated_at ON parcel_items USING btree (updated_at);


--
-- Name: index_parcel_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_updater_id ON parcel_items USING btree (updater_id);


--
-- Name: index_parcel_items_on_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcel_items_on_variant_id ON parcel_items USING btree (variant_id);


--
-- Name: index_parcels_on_address_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_address_id ON parcels USING btree (address_id);


--
-- Name: index_parcels_on_contract_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_contract_id ON parcels USING btree (contract_id);


--
-- Name: index_parcels_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_created_at ON parcels USING btree (created_at);


--
-- Name: index_parcels_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_creator_id ON parcels USING btree (creator_id);


--
-- Name: index_parcels_on_delivery_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_delivery_id ON parcels USING btree (delivery_id);


--
-- Name: index_parcels_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_journal_entry_id ON parcels USING btree (journal_entry_id);


--
-- Name: index_parcels_on_nature; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_nature ON parcels USING btree (nature);


--
-- Name: index_parcels_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_parcels_on_number ON parcels USING btree (number);


--
-- Name: index_parcels_on_purchase_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_purchase_id ON parcels USING btree (purchase_id);


--
-- Name: index_parcels_on_recipient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_recipient_id ON parcels USING btree (recipient_id);


--
-- Name: index_parcels_on_responsible_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_responsible_id ON parcels USING btree (responsible_id);


--
-- Name: index_parcels_on_sale_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_sale_id ON parcels USING btree (sale_id);


--
-- Name: index_parcels_on_sender_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_sender_id ON parcels USING btree (sender_id);


--
-- Name: index_parcels_on_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_state ON parcels USING btree (state);


--
-- Name: index_parcels_on_storage_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_storage_id ON parcels USING btree (storage_id);


--
-- Name: index_parcels_on_transporter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_transporter_id ON parcels USING btree (transporter_id);


--
-- Name: index_parcels_on_undelivered_invoice_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_undelivered_invoice_journal_entry_id ON parcels USING btree (undelivered_invoice_journal_entry_id);


--
-- Name: index_parcels_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_updated_at ON parcels USING btree (updated_at);


--
-- Name: index_parcels_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parcels_on_updater_id ON parcels USING btree (updater_id);


--
-- Name: index_plant_counting_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_counting_items_on_created_at ON plant_counting_items USING btree (created_at);


--
-- Name: index_plant_counting_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_counting_items_on_creator_id ON plant_counting_items USING btree (creator_id);


--
-- Name: index_plant_counting_items_on_plant_counting_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_counting_items_on_plant_counting_id ON plant_counting_items USING btree (plant_counting_id);


--
-- Name: index_plant_counting_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_counting_items_on_updated_at ON plant_counting_items USING btree (updated_at);


--
-- Name: index_plant_counting_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_counting_items_on_updater_id ON plant_counting_items USING btree (updater_id);


--
-- Name: index_plant_countings_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_countings_on_created_at ON plant_countings USING btree (created_at);


--
-- Name: index_plant_countings_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_countings_on_creator_id ON plant_countings USING btree (creator_id);


--
-- Name: index_plant_countings_on_plant_density_abacus_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_countings_on_plant_density_abacus_id ON plant_countings USING btree (plant_density_abacus_id);


--
-- Name: index_plant_countings_on_plant_density_abacus_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_countings_on_plant_density_abacus_item_id ON plant_countings USING btree (plant_density_abacus_item_id);


--
-- Name: index_plant_countings_on_plant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_countings_on_plant_id ON plant_countings USING btree (plant_id);


--
-- Name: index_plant_countings_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_countings_on_updated_at ON plant_countings USING btree (updated_at);


--
-- Name: index_plant_countings_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_countings_on_updater_id ON plant_countings USING btree (updater_id);


--
-- Name: index_plant_density_abaci_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_density_abaci_on_created_at ON plant_density_abaci USING btree (created_at);


--
-- Name: index_plant_density_abaci_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_density_abaci_on_creator_id ON plant_density_abaci USING btree (creator_id);


--
-- Name: index_plant_density_abaci_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_plant_density_abaci_on_name ON plant_density_abaci USING btree (name);


--
-- Name: index_plant_density_abaci_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_density_abaci_on_updated_at ON plant_density_abaci USING btree (updated_at);


--
-- Name: index_plant_density_abaci_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_density_abaci_on_updater_id ON plant_density_abaci USING btree (updater_id);


--
-- Name: index_plant_density_abacus_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_density_abacus_items_on_created_at ON plant_density_abacus_items USING btree (created_at);


--
-- Name: index_plant_density_abacus_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_density_abacus_items_on_creator_id ON plant_density_abacus_items USING btree (creator_id);


--
-- Name: index_plant_density_abacus_items_on_plant_density_abacus_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_density_abacus_items_on_plant_density_abacus_id ON plant_density_abacus_items USING btree (plant_density_abacus_id);


--
-- Name: index_plant_density_abacus_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_density_abacus_items_on_updated_at ON plant_density_abacus_items USING btree (updated_at);


--
-- Name: index_plant_density_abacus_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plant_density_abacus_items_on_updater_id ON plant_density_abacus_items USING btree (updater_id);


--
-- Name: index_pnc_on_financial_asset_allocation_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pnc_on_financial_asset_allocation_account_id ON product_nature_categories USING btree (fixed_asset_allocation_account_id);


--
-- Name: index_pnc_on_financial_asset_expenses_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pnc_on_financial_asset_expenses_account_id ON product_nature_categories USING btree (fixed_asset_expenses_account_id);


--
-- Name: index_postal_zones_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_postal_zones_on_created_at ON postal_zones USING btree (created_at);


--
-- Name: index_postal_zones_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_postal_zones_on_creator_id ON postal_zones USING btree (creator_id);


--
-- Name: index_postal_zones_on_district_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_postal_zones_on_district_id ON postal_zones USING btree (district_id);


--
-- Name: index_postal_zones_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_postal_zones_on_updated_at ON postal_zones USING btree (updated_at);


--
-- Name: index_postal_zones_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_postal_zones_on_updater_id ON postal_zones USING btree (updater_id);


--
-- Name: index_preferences_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_preferences_on_created_at ON preferences USING btree (created_at);


--
-- Name: index_preferences_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_preferences_on_creator_id ON preferences USING btree (creator_id);


--
-- Name: index_preferences_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_preferences_on_name ON preferences USING btree (name);


--
-- Name: index_preferences_on_record_value_type_and_record_value_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_preferences_on_record_value_type_and_record_value_id ON preferences USING btree (record_value_type, record_value_id);


--
-- Name: index_preferences_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_preferences_on_updated_at ON preferences USING btree (updated_at);


--
-- Name: index_preferences_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_preferences_on_updater_id ON preferences USING btree (updater_id);


--
-- Name: index_preferences_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_preferences_on_user_id ON preferences USING btree (user_id);


--
-- Name: index_preferences_on_user_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_preferences_on_user_id_and_name ON preferences USING btree (user_id, name);


--
-- Name: index_prescriptions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_prescriptions_on_created_at ON prescriptions USING btree (created_at);


--
-- Name: index_prescriptions_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_prescriptions_on_creator_id ON prescriptions USING btree (creator_id);


--
-- Name: index_prescriptions_on_delivered_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_prescriptions_on_delivered_at ON prescriptions USING btree (delivered_at);


--
-- Name: index_prescriptions_on_prescriptor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_prescriptions_on_prescriptor_id ON prescriptions USING btree (prescriptor_id);


--
-- Name: index_prescriptions_on_reference_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_prescriptions_on_reference_number ON prescriptions USING btree (reference_number);


--
-- Name: index_prescriptions_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_prescriptions_on_updated_at ON prescriptions USING btree (updated_at);


--
-- Name: index_prescriptions_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_prescriptions_on_updater_id ON prescriptions USING btree (updater_id);


--
-- Name: index_product_enjoyments_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_enjoyments_on_created_at ON product_enjoyments USING btree (created_at);


--
-- Name: index_product_enjoyments_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_enjoyments_on_creator_id ON product_enjoyments USING btree (creator_id);


--
-- Name: index_product_enjoyments_on_enjoyer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_enjoyments_on_enjoyer_id ON product_enjoyments USING btree (enjoyer_id);


--
-- Name: index_product_enjoyments_on_intervention_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_enjoyments_on_intervention_id ON product_enjoyments USING btree (intervention_id);


--
-- Name: index_product_enjoyments_on_originator_type_and_originator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_enjoyments_on_originator_type_and_originator_id ON product_enjoyments USING btree (originator_type, originator_id);


--
-- Name: index_product_enjoyments_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_enjoyments_on_product_id ON product_enjoyments USING btree (product_id);


--
-- Name: index_product_enjoyments_on_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_enjoyments_on_started_at ON product_enjoyments USING btree (started_at);


--
-- Name: index_product_enjoyments_on_stopped_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_enjoyments_on_stopped_at ON product_enjoyments USING btree (stopped_at);


--
-- Name: index_product_enjoyments_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_enjoyments_on_updated_at ON product_enjoyments USING btree (updated_at);


--
-- Name: index_product_enjoyments_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_enjoyments_on_updater_id ON product_enjoyments USING btree (updater_id);


--
-- Name: index_product_labellings_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_labellings_on_created_at ON product_labellings USING btree (created_at);


--
-- Name: index_product_labellings_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_labellings_on_creator_id ON product_labellings USING btree (creator_id);


--
-- Name: index_product_labellings_on_label_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_labellings_on_label_id ON product_labellings USING btree (label_id);


--
-- Name: index_product_labellings_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_labellings_on_product_id ON product_labellings USING btree (product_id);


--
-- Name: index_product_labellings_on_product_id_and_label_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_product_labellings_on_product_id_and_label_id ON product_labellings USING btree (product_id, label_id);


--
-- Name: index_product_labellings_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_labellings_on_updated_at ON product_labellings USING btree (updated_at);


--
-- Name: index_product_labellings_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_labellings_on_updater_id ON product_labellings USING btree (updater_id);


--
-- Name: index_product_linkages_on_carried_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_linkages_on_carried_id ON product_linkages USING btree (carried_id);


--
-- Name: index_product_linkages_on_carrier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_linkages_on_carrier_id ON product_linkages USING btree (carrier_id);


--
-- Name: index_product_linkages_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_linkages_on_created_at ON product_linkages USING btree (created_at);


--
-- Name: index_product_linkages_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_linkages_on_creator_id ON product_linkages USING btree (creator_id);


--
-- Name: index_product_linkages_on_intervention_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_linkages_on_intervention_id ON product_linkages USING btree (intervention_id);


--
-- Name: index_product_linkages_on_originator_type_and_originator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_linkages_on_originator_type_and_originator_id ON product_linkages USING btree (originator_type, originator_id);


--
-- Name: index_product_linkages_on_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_linkages_on_started_at ON product_linkages USING btree (started_at);


--
-- Name: index_product_linkages_on_stopped_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_linkages_on_stopped_at ON product_linkages USING btree (stopped_at);


--
-- Name: index_product_linkages_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_linkages_on_updated_at ON product_linkages USING btree (updated_at);


--
-- Name: index_product_linkages_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_linkages_on_updater_id ON product_linkages USING btree (updater_id);


--
-- Name: index_product_links_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_links_on_created_at ON product_links USING btree (created_at);


--
-- Name: index_product_links_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_links_on_creator_id ON product_links USING btree (creator_id);


--
-- Name: index_product_links_on_intervention_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_links_on_intervention_id ON product_links USING btree (intervention_id);


--
-- Name: index_product_links_on_linked_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_links_on_linked_id ON product_links USING btree (linked_id);


--
-- Name: index_product_links_on_originator_type_and_originator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_links_on_originator_type_and_originator_id ON product_links USING btree (originator_type, originator_id);


--
-- Name: index_product_links_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_links_on_product_id ON product_links USING btree (product_id);


--
-- Name: index_product_links_on_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_links_on_started_at ON product_links USING btree (started_at);


--
-- Name: index_product_links_on_stopped_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_links_on_stopped_at ON product_links USING btree (stopped_at);


--
-- Name: index_product_links_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_links_on_updated_at ON product_links USING btree (updated_at);


--
-- Name: index_product_links_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_links_on_updater_id ON product_links USING btree (updater_id);


--
-- Name: index_product_localizations_on_container_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_localizations_on_container_id ON product_localizations USING btree (container_id);


--
-- Name: index_product_localizations_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_localizations_on_created_at ON product_localizations USING btree (created_at);


--
-- Name: index_product_localizations_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_localizations_on_creator_id ON product_localizations USING btree (creator_id);


--
-- Name: index_product_localizations_on_intervention_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_localizations_on_intervention_id ON product_localizations USING btree (intervention_id);


--
-- Name: index_product_localizations_on_originator; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_localizations_on_originator ON product_localizations USING btree (originator_id, originator_type);


--
-- Name: index_product_localizations_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_localizations_on_product_id ON product_localizations USING btree (product_id);


--
-- Name: index_product_localizations_on_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_localizations_on_started_at ON product_localizations USING btree (started_at);


--
-- Name: index_product_localizations_on_stopped_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_localizations_on_stopped_at ON product_localizations USING btree (stopped_at);


--
-- Name: index_product_localizations_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_localizations_on_updated_at ON product_localizations USING btree (updated_at);


--
-- Name: index_product_localizations_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_localizations_on_updater_id ON product_localizations USING btree (updater_id);


--
-- Name: index_product_memberships_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_memberships_on_created_at ON product_memberships USING btree (created_at);


--
-- Name: index_product_memberships_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_memberships_on_creator_id ON product_memberships USING btree (creator_id);


--
-- Name: index_product_memberships_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_memberships_on_group_id ON product_memberships USING btree (group_id);


--
-- Name: index_product_memberships_on_intervention_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_memberships_on_intervention_id ON product_memberships USING btree (intervention_id);


--
-- Name: index_product_memberships_on_member_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_memberships_on_member_id ON product_memberships USING btree (member_id);


--
-- Name: index_product_memberships_on_originator_type_and_originator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_memberships_on_originator_type_and_originator_id ON product_memberships USING btree (originator_type, originator_id);


--
-- Name: index_product_memberships_on_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_memberships_on_started_at ON product_memberships USING btree (started_at);


--
-- Name: index_product_memberships_on_stopped_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_memberships_on_stopped_at ON product_memberships USING btree (stopped_at);


--
-- Name: index_product_memberships_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_memberships_on_updated_at ON product_memberships USING btree (updated_at);


--
-- Name: index_product_memberships_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_memberships_on_updater_id ON product_memberships USING btree (updater_id);


--
-- Name: index_product_movements_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_movements_on_created_at ON product_movements USING btree (created_at);


--
-- Name: index_product_movements_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_movements_on_creator_id ON product_movements USING btree (creator_id);


--
-- Name: index_product_movements_on_intervention_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_movements_on_intervention_id ON product_movements USING btree (intervention_id);


--
-- Name: index_product_movements_on_originator_type_and_originator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_movements_on_originator_type_and_originator_id ON product_movements USING btree (originator_type, originator_id);


--
-- Name: index_product_movements_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_movements_on_product_id ON product_movements USING btree (product_id);


--
-- Name: index_product_movements_on_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_movements_on_started_at ON product_movements USING btree (started_at);


--
-- Name: index_product_movements_on_stopped_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_movements_on_stopped_at ON product_movements USING btree (stopped_at);


--
-- Name: index_product_movements_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_movements_on_updated_at ON product_movements USING btree (updated_at);


--
-- Name: index_product_movements_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_movements_on_updater_id ON product_movements USING btree (updater_id);


--
-- Name: index_product_nature_categories_on_charge_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_categories_on_charge_account_id ON product_nature_categories USING btree (charge_account_id);


--
-- Name: index_product_nature_categories_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_categories_on_created_at ON product_nature_categories USING btree (created_at);


--
-- Name: index_product_nature_categories_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_categories_on_creator_id ON product_nature_categories USING btree (creator_id);


--
-- Name: index_product_nature_categories_on_fixed_asset_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_categories_on_fixed_asset_account_id ON product_nature_categories USING btree (fixed_asset_account_id);


--
-- Name: index_product_nature_categories_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_categories_on_name ON product_nature_categories USING btree (name);


--
-- Name: index_product_nature_categories_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_product_nature_categories_on_number ON product_nature_categories USING btree (number);


--
-- Name: index_product_nature_categories_on_product_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_categories_on_product_account_id ON product_nature_categories USING btree (product_account_id);


--
-- Name: index_product_nature_categories_on_stock_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_categories_on_stock_account_id ON product_nature_categories USING btree (stock_account_id);


--
-- Name: index_product_nature_categories_on_stock_movement_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_categories_on_stock_movement_account_id ON product_nature_categories USING btree (stock_movement_account_id);


--
-- Name: index_product_nature_categories_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_categories_on_updated_at ON product_nature_categories USING btree (updated_at);


--
-- Name: index_product_nature_categories_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_categories_on_updater_id ON product_nature_categories USING btree (updater_id);


--
-- Name: index_product_nature_category_taxations_on_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_category_taxations_on_category_id ON product_nature_category_taxations USING btree (product_nature_category_id);


--
-- Name: index_product_nature_category_taxations_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_category_taxations_on_created_at ON product_nature_category_taxations USING btree (created_at);


--
-- Name: index_product_nature_category_taxations_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_category_taxations_on_creator_id ON product_nature_category_taxations USING btree (creator_id);


--
-- Name: index_product_nature_category_taxations_on_tax_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_category_taxations_on_tax_id ON product_nature_category_taxations USING btree (tax_id);


--
-- Name: index_product_nature_category_taxations_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_category_taxations_on_updated_at ON product_nature_category_taxations USING btree (updated_at);


--
-- Name: index_product_nature_category_taxations_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_category_taxations_on_updater_id ON product_nature_category_taxations USING btree (updater_id);


--
-- Name: index_product_nature_category_taxations_on_usage; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_category_taxations_on_usage ON product_nature_category_taxations USING btree (usage);


--
-- Name: index_product_nature_variant_components_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variant_components_on_created_at ON product_nature_variant_components USING btree (created_at);


--
-- Name: index_product_nature_variant_components_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variant_components_on_creator_id ON product_nature_variant_components USING btree (creator_id);


--
-- Name: index_product_nature_variant_components_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variant_components_on_deleted_at ON product_nature_variant_components USING btree (deleted_at);


--
-- Name: index_product_nature_variant_components_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variant_components_on_parent_id ON product_nature_variant_components USING btree (parent_id);


--
-- Name: index_product_nature_variant_components_on_part_variant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variant_components_on_part_variant ON product_nature_variant_components USING btree (part_product_nature_variant_id);


--
-- Name: index_product_nature_variant_components_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variant_components_on_updated_at ON product_nature_variant_components USING btree (updated_at);


--
-- Name: index_product_nature_variant_components_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variant_components_on_updater_id ON product_nature_variant_components USING btree (updater_id);


--
-- Name: index_product_nature_variant_components_on_variant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variant_components_on_variant ON product_nature_variant_components USING btree (product_nature_variant_id);


--
-- Name: index_product_nature_variant_name_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_product_nature_variant_name_unique ON product_nature_variant_components USING btree (name, product_nature_variant_id);


--
-- Name: index_product_nature_variant_readings_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variant_readings_on_created_at ON product_nature_variant_readings USING btree (created_at);


--
-- Name: index_product_nature_variant_readings_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variant_readings_on_creator_id ON product_nature_variant_readings USING btree (creator_id);


--
-- Name: index_product_nature_variant_readings_on_indicator_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variant_readings_on_indicator_name ON product_nature_variant_readings USING btree (indicator_name);


--
-- Name: index_product_nature_variant_readings_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variant_readings_on_updated_at ON product_nature_variant_readings USING btree (updated_at);


--
-- Name: index_product_nature_variant_readings_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variant_readings_on_updater_id ON product_nature_variant_readings USING btree (updater_id);


--
-- Name: index_product_nature_variant_readings_on_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variant_readings_on_variant_id ON product_nature_variant_readings USING btree (variant_id);


--
-- Name: index_product_nature_variants_on_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variants_on_category_id ON product_nature_variants USING btree (category_id);


--
-- Name: index_product_nature_variants_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variants_on_created_at ON product_nature_variants USING btree (created_at);


--
-- Name: index_product_nature_variants_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variants_on_creator_id ON product_nature_variants USING btree (creator_id);


--
-- Name: index_product_nature_variants_on_nature_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variants_on_nature_id ON product_nature_variants USING btree (nature_id);


--
-- Name: index_product_nature_variants_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_product_nature_variants_on_number ON product_nature_variants USING btree (number);


--
-- Name: index_product_nature_variants_on_stock_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variants_on_stock_account_id ON product_nature_variants USING btree (stock_account_id);


--
-- Name: index_product_nature_variants_on_stock_movement_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variants_on_stock_movement_account_id ON product_nature_variants USING btree (stock_movement_account_id);


--
-- Name: index_product_nature_variants_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variants_on_updated_at ON product_nature_variants USING btree (updated_at);


--
-- Name: index_product_nature_variants_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_nature_variants_on_updater_id ON product_nature_variants USING btree (updater_id);


--
-- Name: index_product_natures_on_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_natures_on_category_id ON product_natures USING btree (category_id);


--
-- Name: index_product_natures_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_natures_on_created_at ON product_natures USING btree (created_at);


--
-- Name: index_product_natures_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_natures_on_creator_id ON product_natures USING btree (creator_id);


--
-- Name: index_product_natures_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_natures_on_name ON product_natures USING btree (name);


--
-- Name: index_product_natures_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_product_natures_on_number ON product_natures USING btree (number);


--
-- Name: index_product_natures_on_subscription_nature_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_natures_on_subscription_nature_id ON product_natures USING btree (subscription_nature_id);


--
-- Name: index_product_natures_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_natures_on_updated_at ON product_natures USING btree (updated_at);


--
-- Name: index_product_natures_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_natures_on_updater_id ON product_natures USING btree (updater_id);


--
-- Name: index_product_ownerships_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_ownerships_on_created_at ON product_ownerships USING btree (created_at);


--
-- Name: index_product_ownerships_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_ownerships_on_creator_id ON product_ownerships USING btree (creator_id);


--
-- Name: index_product_ownerships_on_intervention_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_ownerships_on_intervention_id ON product_ownerships USING btree (intervention_id);


--
-- Name: index_product_ownerships_on_originator_type_and_originator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_ownerships_on_originator_type_and_originator_id ON product_ownerships USING btree (originator_type, originator_id);


--
-- Name: index_product_ownerships_on_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_ownerships_on_owner_id ON product_ownerships USING btree (owner_id);


--
-- Name: index_product_ownerships_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_ownerships_on_product_id ON product_ownerships USING btree (product_id);


--
-- Name: index_product_ownerships_on_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_ownerships_on_started_at ON product_ownerships USING btree (started_at);


--
-- Name: index_product_ownerships_on_stopped_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_ownerships_on_stopped_at ON product_ownerships USING btree (stopped_at);


--
-- Name: index_product_ownerships_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_ownerships_on_updated_at ON product_ownerships USING btree (updated_at);


--
-- Name: index_product_ownerships_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_ownerships_on_updater_id ON product_ownerships USING btree (updater_id);


--
-- Name: index_product_phases_on_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_phases_on_category_id ON product_phases USING btree (category_id);


--
-- Name: index_product_phases_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_phases_on_created_at ON product_phases USING btree (created_at);


--
-- Name: index_product_phases_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_phases_on_creator_id ON product_phases USING btree (creator_id);


--
-- Name: index_product_phases_on_intervention_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_phases_on_intervention_id ON product_phases USING btree (intervention_id);


--
-- Name: index_product_phases_on_nature_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_phases_on_nature_id ON product_phases USING btree (nature_id);


--
-- Name: index_product_phases_on_originator_type_and_originator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_phases_on_originator_type_and_originator_id ON product_phases USING btree (originator_type, originator_id);


--
-- Name: index_product_phases_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_phases_on_product_id ON product_phases USING btree (product_id);


--
-- Name: index_product_phases_on_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_phases_on_started_at ON product_phases USING btree (started_at);


--
-- Name: index_product_phases_on_stopped_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_phases_on_stopped_at ON product_phases USING btree (stopped_at);


--
-- Name: index_product_phases_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_phases_on_updated_at ON product_phases USING btree (updated_at);


--
-- Name: index_product_phases_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_phases_on_updater_id ON product_phases USING btree (updater_id);


--
-- Name: index_product_phases_on_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_phases_on_variant_id ON product_phases USING btree (variant_id);


--
-- Name: index_product_readings_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_readings_on_created_at ON product_readings USING btree (created_at);


--
-- Name: index_product_readings_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_readings_on_creator_id ON product_readings USING btree (creator_id);


--
-- Name: index_product_readings_on_indicator_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_readings_on_indicator_name ON product_readings USING btree (indicator_name);


--
-- Name: index_product_readings_on_originator; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_readings_on_originator ON product_readings USING btree (originator_id, originator_type);


--
-- Name: index_product_readings_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_readings_on_product_id ON product_readings USING btree (product_id);


--
-- Name: index_product_readings_on_read_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_readings_on_read_at ON product_readings USING btree (read_at);


--
-- Name: index_product_readings_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_readings_on_updated_at ON product_readings USING btree (updated_at);


--
-- Name: index_product_readings_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_readings_on_updater_id ON product_readings USING btree (updater_id);


--
-- Name: index_products_on_address_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_address_id ON products USING btree (address_id);


--
-- Name: index_products_on_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_category_id ON products USING btree (category_id);


--
-- Name: index_products_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_created_at ON products USING btree (created_at);


--
-- Name: index_products_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_creator_id ON products USING btree (creator_id);


--
-- Name: index_products_on_default_storage_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_default_storage_id ON products USING btree (default_storage_id);


--
-- Name: index_products_on_fixed_asset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_fixed_asset_id ON products USING btree (fixed_asset_id);


--
-- Name: index_products_on_initial_container_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_initial_container_id ON products USING btree (initial_container_id);


--
-- Name: index_products_on_initial_enjoyer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_initial_enjoyer_id ON products USING btree (initial_enjoyer_id);


--
-- Name: index_products_on_initial_father_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_initial_father_id ON products USING btree (initial_father_id);


--
-- Name: index_products_on_initial_mother_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_initial_mother_id ON products USING btree (initial_mother_id);


--
-- Name: index_products_on_initial_movement_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_initial_movement_id ON products USING btree (initial_movement_id);


--
-- Name: index_products_on_initial_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_initial_owner_id ON products USING btree (initial_owner_id);


--
-- Name: index_products_on_member_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_member_variant_id ON products USING btree (member_variant_id);


--
-- Name: index_products_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_name ON products USING btree (name);


--
-- Name: index_products_on_nature_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_nature_id ON products USING btree (nature_id);


--
-- Name: index_products_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_products_on_number ON products USING btree (number);


--
-- Name: index_products_on_originator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_originator_id ON products USING btree (originator_id);


--
-- Name: index_products_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_parent_id ON products USING btree (parent_id);


--
-- Name: index_products_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_team_id ON products USING btree (team_id);


--
-- Name: index_products_on_tracking_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_tracking_id ON products USING btree (tracking_id);


--
-- Name: index_products_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_type ON products USING btree (type);


--
-- Name: index_products_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_updated_at ON products USING btree (updated_at);


--
-- Name: index_products_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_updater_id ON products USING btree (updater_id);


--
-- Name: index_products_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_uuid ON products USING btree (uuid);


--
-- Name: index_products_on_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_variant_id ON products USING btree (variant_id);


--
-- Name: index_products_on_variety; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_variety ON products USING btree (variety);


--
-- Name: index_purchase_items_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_items_on_account_id ON purchase_items USING btree (account_id);


--
-- Name: index_purchase_items_on_activity_budget_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_items_on_activity_budget_id ON purchase_items USING btree (activity_budget_id);


--
-- Name: index_purchase_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_items_on_created_at ON purchase_items USING btree (created_at);


--
-- Name: index_purchase_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_items_on_creator_id ON purchase_items USING btree (creator_id);


--
-- Name: index_purchase_items_on_depreciable_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_items_on_depreciable_product_id ON purchase_items USING btree (depreciable_product_id);


--
-- Name: index_purchase_items_on_fixed_asset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_items_on_fixed_asset_id ON purchase_items USING btree (fixed_asset_id);


--
-- Name: index_purchase_items_on_purchase_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_items_on_purchase_id ON purchase_items USING btree (purchase_id);


--
-- Name: index_purchase_items_on_tax_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_items_on_tax_id ON purchase_items USING btree (tax_id);


--
-- Name: index_purchase_items_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_items_on_team_id ON purchase_items USING btree (team_id);


--
-- Name: index_purchase_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_items_on_updated_at ON purchase_items USING btree (updated_at);


--
-- Name: index_purchase_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_items_on_updater_id ON purchase_items USING btree (updater_id);


--
-- Name: index_purchase_items_on_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_items_on_variant_id ON purchase_items USING btree (variant_id);


--
-- Name: index_purchase_natures_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_natures_on_created_at ON purchase_natures USING btree (created_at);


--
-- Name: index_purchase_natures_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_natures_on_creator_id ON purchase_natures USING btree (creator_id);


--
-- Name: index_purchase_natures_on_currency; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_natures_on_currency ON purchase_natures USING btree (currency);


--
-- Name: index_purchase_natures_on_journal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_natures_on_journal_id ON purchase_natures USING btree (journal_id);


--
-- Name: index_purchase_natures_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_natures_on_updated_at ON purchase_natures USING btree (updated_at);


--
-- Name: index_purchase_natures_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchase_natures_on_updater_id ON purchase_natures USING btree (updater_id);


--
-- Name: index_purchases_on_accounted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchases_on_accounted_at ON purchases USING btree (accounted_at);


--
-- Name: index_purchases_on_affair_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchases_on_affair_id ON purchases USING btree (affair_id);


--
-- Name: index_purchases_on_contract_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchases_on_contract_id ON purchases USING btree (contract_id);


--
-- Name: index_purchases_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchases_on_created_at ON purchases USING btree (created_at);


--
-- Name: index_purchases_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchases_on_creator_id ON purchases USING btree (creator_id);


--
-- Name: index_purchases_on_currency; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchases_on_currency ON purchases USING btree (currency);


--
-- Name: index_purchases_on_delivery_address_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchases_on_delivery_address_id ON purchases USING btree (delivery_address_id);


--
-- Name: index_purchases_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchases_on_journal_entry_id ON purchases USING btree (journal_entry_id);


--
-- Name: index_purchases_on_nature_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchases_on_nature_id ON purchases USING btree (nature_id);


--
-- Name: index_purchases_on_quantity_gap_on_invoice_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchases_on_quantity_gap_on_invoice_journal_entry_id ON purchases USING btree (quantity_gap_on_invoice_journal_entry_id);


--
-- Name: index_purchases_on_responsible_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchases_on_responsible_id ON purchases USING btree (responsible_id);


--
-- Name: index_purchases_on_supplier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchases_on_supplier_id ON purchases USING btree (supplier_id);


--
-- Name: index_purchases_on_undelivered_invoice_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchases_on_undelivered_invoice_journal_entry_id ON purchases USING btree (undelivered_invoice_journal_entry_id);


--
-- Name: index_purchases_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchases_on_updated_at ON purchases USING btree (updated_at);


--
-- Name: index_purchases_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purchases_on_updater_id ON purchases USING btree (updater_id);


--
-- Name: index_regularizations_on_affair_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_regularizations_on_affair_id ON regularizations USING btree (affair_id);


--
-- Name: index_regularizations_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_regularizations_on_created_at ON regularizations USING btree (created_at);


--
-- Name: index_regularizations_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_regularizations_on_creator_id ON regularizations USING btree (creator_id);


--
-- Name: index_regularizations_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_regularizations_on_journal_entry_id ON regularizations USING btree (journal_entry_id);


--
-- Name: index_regularizations_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_regularizations_on_updated_at ON regularizations USING btree (updated_at);


--
-- Name: index_regularizations_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_regularizations_on_updater_id ON regularizations USING btree (updater_id);


--
-- Name: index_roles_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_created_at ON roles USING btree (created_at);


--
-- Name: index_roles_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_creator_id ON roles USING btree (creator_id);


--
-- Name: index_roles_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_updated_at ON roles USING btree (updated_at);


--
-- Name: index_roles_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_updater_id ON roles USING btree (updater_id);


--
-- Name: index_sale_items_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_items_on_account_id ON sale_items USING btree (account_id);


--
-- Name: index_sale_items_on_activity_budget_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_items_on_activity_budget_id ON sale_items USING btree (activity_budget_id);


--
-- Name: index_sale_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_items_on_created_at ON sale_items USING btree (created_at);


--
-- Name: index_sale_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_items_on_creator_id ON sale_items USING btree (creator_id);


--
-- Name: index_sale_items_on_credited_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_items_on_credited_item_id ON sale_items USING btree (credited_item_id);


--
-- Name: index_sale_items_on_sale_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_items_on_sale_id ON sale_items USING btree (sale_id);


--
-- Name: index_sale_items_on_tax_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_items_on_tax_id ON sale_items USING btree (tax_id);


--
-- Name: index_sale_items_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_items_on_team_id ON sale_items USING btree (team_id);


--
-- Name: index_sale_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_items_on_updated_at ON sale_items USING btree (updated_at);


--
-- Name: index_sale_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_items_on_updater_id ON sale_items USING btree (updater_id);


--
-- Name: index_sale_items_on_variant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_items_on_variant_id ON sale_items USING btree (variant_id);


--
-- Name: index_sale_natures_on_catalog_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_natures_on_catalog_id ON sale_natures USING btree (catalog_id);


--
-- Name: index_sale_natures_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_natures_on_created_at ON sale_natures USING btree (created_at);


--
-- Name: index_sale_natures_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_natures_on_creator_id ON sale_natures USING btree (creator_id);


--
-- Name: index_sale_natures_on_journal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_natures_on_journal_id ON sale_natures USING btree (journal_id);


--
-- Name: index_sale_natures_on_payment_mode_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_natures_on_payment_mode_id ON sale_natures USING btree (payment_mode_id);


--
-- Name: index_sale_natures_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_natures_on_updated_at ON sale_natures USING btree (updated_at);


--
-- Name: index_sale_natures_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_natures_on_updater_id ON sale_natures USING btree (updater_id);


--
-- Name: index_sales_on_accounted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_accounted_at ON sales USING btree (accounted_at);


--
-- Name: index_sales_on_address_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_address_id ON sales USING btree (address_id);


--
-- Name: index_sales_on_affair_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_affair_id ON sales USING btree (affair_id);


--
-- Name: index_sales_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_client_id ON sales USING btree (client_id);


--
-- Name: index_sales_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_created_at ON sales USING btree (created_at);


--
-- Name: index_sales_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_creator_id ON sales USING btree (creator_id);


--
-- Name: index_sales_on_credited_sale_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_credited_sale_id ON sales USING btree (credited_sale_id);


--
-- Name: index_sales_on_currency; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_currency ON sales USING btree (currency);


--
-- Name: index_sales_on_delivery_address_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_delivery_address_id ON sales USING btree (delivery_address_id);


--
-- Name: index_sales_on_invoice_address_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_invoice_address_id ON sales USING btree (invoice_address_id);


--
-- Name: index_sales_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_journal_entry_id ON sales USING btree (journal_entry_id);


--
-- Name: index_sales_on_nature_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_nature_id ON sales USING btree (nature_id);


--
-- Name: index_sales_on_quantity_gap_on_invoice_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_quantity_gap_on_invoice_journal_entry_id ON sales USING btree (quantity_gap_on_invoice_journal_entry_id);


--
-- Name: index_sales_on_responsible_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_responsible_id ON sales USING btree (responsible_id);


--
-- Name: index_sales_on_transporter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_transporter_id ON sales USING btree (transporter_id);


--
-- Name: index_sales_on_undelivered_invoice_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_undelivered_invoice_journal_entry_id ON sales USING btree (undelivered_invoice_journal_entry_id);


--
-- Name: index_sales_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_updated_at ON sales USING btree (updated_at);


--
-- Name: index_sales_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sales_on_updater_id ON sales USING btree (updater_id);


--
-- Name: index_sensors_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sensors_on_created_at ON sensors USING btree (created_at);


--
-- Name: index_sensors_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sensors_on_creator_id ON sensors USING btree (creator_id);


--
-- Name: index_sensors_on_host_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sensors_on_host_id ON sensors USING btree (host_id);


--
-- Name: index_sensors_on_model_euid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sensors_on_model_euid ON sensors USING btree (model_euid);


--
-- Name: index_sensors_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sensors_on_name ON sensors USING btree (name);


--
-- Name: index_sensors_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sensors_on_product_id ON sensors USING btree (product_id);


--
-- Name: index_sensors_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sensors_on_updated_at ON sensors USING btree (updated_at);


--
-- Name: index_sensors_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sensors_on_updater_id ON sensors USING btree (updater_id);


--
-- Name: index_sensors_on_vendor_euid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sensors_on_vendor_euid ON sensors USING btree (vendor_euid);


--
-- Name: index_sequences_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sequences_on_created_at ON sequences USING btree (created_at);


--
-- Name: index_sequences_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sequences_on_creator_id ON sequences USING btree (creator_id);


--
-- Name: index_sequences_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sequences_on_updated_at ON sequences USING btree (updated_at);


--
-- Name: index_sequences_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sequences_on_updater_id ON sequences USING btree (updater_id);


--
-- Name: index_subscription_natures_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscription_natures_on_created_at ON subscription_natures USING btree (created_at);


--
-- Name: index_subscription_natures_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscription_natures_on_creator_id ON subscription_natures USING btree (creator_id);


--
-- Name: index_subscription_natures_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscription_natures_on_updated_at ON subscription_natures USING btree (updated_at);


--
-- Name: index_subscription_natures_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscription_natures_on_updater_id ON subscription_natures USING btree (updater_id);


--
-- Name: index_subscriptions_on_address_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_address_id ON subscriptions USING btree (address_id);


--
-- Name: index_subscriptions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_created_at ON subscriptions USING btree (created_at);


--
-- Name: index_subscriptions_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_creator_id ON subscriptions USING btree (creator_id);


--
-- Name: index_subscriptions_on_nature_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_nature_id ON subscriptions USING btree (nature_id);


--
-- Name: index_subscriptions_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_parent_id ON subscriptions USING btree (parent_id);


--
-- Name: index_subscriptions_on_sale_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_sale_item_id ON subscriptions USING btree (sale_item_id);


--
-- Name: index_subscriptions_on_started_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_started_on ON subscriptions USING btree (started_on);


--
-- Name: index_subscriptions_on_stopped_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_stopped_on ON subscriptions USING btree (stopped_on);


--
-- Name: index_subscriptions_on_subscriber_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_subscriber_id ON subscriptions USING btree (subscriber_id);


--
-- Name: index_subscriptions_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_updated_at ON subscriptions USING btree (updated_at);


--
-- Name: index_subscriptions_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_updater_id ON subscriptions USING btree (updater_id);


--
-- Name: index_supervision_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_supervision_items_on_created_at ON supervision_items USING btree (created_at);


--
-- Name: index_supervision_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_supervision_items_on_creator_id ON supervision_items USING btree (creator_id);


--
-- Name: index_supervision_items_on_sensor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_supervision_items_on_sensor_id ON supervision_items USING btree (sensor_id);


--
-- Name: index_supervision_items_on_supervision_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_supervision_items_on_supervision_id ON supervision_items USING btree (supervision_id);


--
-- Name: index_supervision_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_supervision_items_on_updated_at ON supervision_items USING btree (updated_at);


--
-- Name: index_supervision_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_supervision_items_on_updater_id ON supervision_items USING btree (updater_id);


--
-- Name: index_supervisions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_supervisions_on_created_at ON supervisions USING btree (created_at);


--
-- Name: index_supervisions_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_supervisions_on_creator_id ON supervisions USING btree (creator_id);


--
-- Name: index_supervisions_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_supervisions_on_name ON supervisions USING btree (name);


--
-- Name: index_supervisions_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_supervisions_on_updated_at ON supervisions USING btree (updated_at);


--
-- Name: index_supervisions_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_supervisions_on_updater_id ON supervisions USING btree (updater_id);


--
-- Name: index_synchronization_operations_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_synchronization_operations_on_created_at ON synchronization_operations USING btree (created_at);


--
-- Name: index_synchronization_operations_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_synchronization_operations_on_creator_id ON synchronization_operations USING btree (creator_id);


--
-- Name: index_synchronization_operations_on_operation_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_synchronization_operations_on_operation_name ON synchronization_operations USING btree (operation_name);


--
-- Name: index_synchronization_operations_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_synchronization_operations_on_updated_at ON synchronization_operations USING btree (updated_at);


--
-- Name: index_synchronization_operations_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_synchronization_operations_on_updater_id ON synchronization_operations USING btree (updater_id);


--
-- Name: index_target_distributions_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_target_distributions_on_activity_id ON target_distributions USING btree (activity_id);


--
-- Name: index_target_distributions_on_activity_production_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_target_distributions_on_activity_production_id ON target_distributions USING btree (activity_production_id);


--
-- Name: index_target_distributions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_target_distributions_on_created_at ON target_distributions USING btree (created_at);


--
-- Name: index_target_distributions_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_target_distributions_on_creator_id ON target_distributions USING btree (creator_id);


--
-- Name: index_target_distributions_on_target_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_target_distributions_on_target_id ON target_distributions USING btree (target_id);


--
-- Name: index_target_distributions_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_target_distributions_on_updated_at ON target_distributions USING btree (updated_at);


--
-- Name: index_target_distributions_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_target_distributions_on_updater_id ON target_distributions USING btree (updater_id);


--
-- Name: index_tasks_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tasks_on_created_at ON tasks USING btree (created_at);


--
-- Name: index_tasks_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tasks_on_creator_id ON tasks USING btree (creator_id);


--
-- Name: index_tasks_on_entity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tasks_on_entity_id ON tasks USING btree (entity_id);


--
-- Name: index_tasks_on_executor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tasks_on_executor_id ON tasks USING btree (executor_id);


--
-- Name: index_tasks_on_sale_opportunity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tasks_on_sale_opportunity_id ON tasks USING btree (sale_opportunity_id);


--
-- Name: index_tasks_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tasks_on_updated_at ON tasks USING btree (updated_at);


--
-- Name: index_tasks_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tasks_on_updater_id ON tasks USING btree (updater_id);


--
-- Name: index_tax_declaration_item_parts_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declaration_item_parts_on_account_id ON tax_declaration_item_parts USING btree (account_id);


--
-- Name: index_tax_declaration_item_parts_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declaration_item_parts_on_created_at ON tax_declaration_item_parts USING btree (created_at);


--
-- Name: index_tax_declaration_item_parts_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declaration_item_parts_on_creator_id ON tax_declaration_item_parts USING btree (creator_id);


--
-- Name: index_tax_declaration_item_parts_on_direction; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declaration_item_parts_on_direction ON tax_declaration_item_parts USING btree (direction);


--
-- Name: index_tax_declaration_item_parts_on_journal_entry_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declaration_item_parts_on_journal_entry_item_id ON tax_declaration_item_parts USING btree (journal_entry_item_id);


--
-- Name: index_tax_declaration_item_parts_on_tax_declaration_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declaration_item_parts_on_tax_declaration_item_id ON tax_declaration_item_parts USING btree (tax_declaration_item_id);


--
-- Name: index_tax_declaration_item_parts_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declaration_item_parts_on_updated_at ON tax_declaration_item_parts USING btree (updated_at);


--
-- Name: index_tax_declaration_item_parts_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declaration_item_parts_on_updater_id ON tax_declaration_item_parts USING btree (updater_id);


--
-- Name: index_tax_declaration_items_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declaration_items_on_created_at ON tax_declaration_items USING btree (created_at);


--
-- Name: index_tax_declaration_items_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declaration_items_on_creator_id ON tax_declaration_items USING btree (creator_id);


--
-- Name: index_tax_declaration_items_on_tax_declaration_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declaration_items_on_tax_declaration_id ON tax_declaration_items USING btree (tax_declaration_id);


--
-- Name: index_tax_declaration_items_on_tax_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declaration_items_on_tax_id ON tax_declaration_items USING btree (tax_id);


--
-- Name: index_tax_declaration_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declaration_items_on_updated_at ON tax_declaration_items USING btree (updated_at);


--
-- Name: index_tax_declaration_items_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declaration_items_on_updater_id ON tax_declaration_items USING btree (updater_id);


--
-- Name: index_tax_declarations_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declarations_on_created_at ON tax_declarations USING btree (created_at);


--
-- Name: index_tax_declarations_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declarations_on_creator_id ON tax_declarations USING btree (creator_id);


--
-- Name: index_tax_declarations_on_financial_year_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declarations_on_financial_year_id ON tax_declarations USING btree (financial_year_id);


--
-- Name: index_tax_declarations_on_journal_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declarations_on_journal_entry_id ON tax_declarations USING btree (journal_entry_id);


--
-- Name: index_tax_declarations_on_responsible_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declarations_on_responsible_id ON tax_declarations USING btree (responsible_id);


--
-- Name: index_tax_declarations_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declarations_on_updated_at ON tax_declarations USING btree (updated_at);


--
-- Name: index_tax_declarations_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tax_declarations_on_updater_id ON tax_declarations USING btree (updater_id);


--
-- Name: index_taxes_on_collect_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taxes_on_collect_account_id ON taxes USING btree (collect_account_id);


--
-- Name: index_taxes_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taxes_on_created_at ON taxes USING btree (created_at);


--
-- Name: index_taxes_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taxes_on_creator_id ON taxes USING btree (creator_id);


--
-- Name: index_taxes_on_deduction_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taxes_on_deduction_account_id ON taxes USING btree (deduction_account_id);


--
-- Name: index_taxes_on_fixed_asset_collect_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taxes_on_fixed_asset_collect_account_id ON taxes USING btree (fixed_asset_collect_account_id);


--
-- Name: index_taxes_on_fixed_asset_deduction_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taxes_on_fixed_asset_deduction_account_id ON taxes USING btree (fixed_asset_deduction_account_id);


--
-- Name: index_taxes_on_intracommunity_payable_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taxes_on_intracommunity_payable_account_id ON taxes USING btree (intracommunity_payable_account_id);


--
-- Name: index_taxes_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taxes_on_updated_at ON taxes USING btree (updated_at);


--
-- Name: index_taxes_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taxes_on_updater_id ON taxes USING btree (updater_id);


--
-- Name: index_teams_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_on_created_at ON teams USING btree (created_at);


--
-- Name: index_teams_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_on_creator_id ON teams USING btree (creator_id);


--
-- Name: index_teams_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_on_parent_id ON teams USING btree (parent_id);


--
-- Name: index_teams_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_on_updated_at ON teams USING btree (updated_at);


--
-- Name: index_teams_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_on_updater_id ON teams USING btree (updater_id);


--
-- Name: index_tokens_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tokens_on_created_at ON tokens USING btree (created_at);


--
-- Name: index_tokens_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tokens_on_creator_id ON tokens USING btree (creator_id);


--
-- Name: index_tokens_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tokens_on_name ON tokens USING btree (name);


--
-- Name: index_tokens_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tokens_on_updated_at ON tokens USING btree (updated_at);


--
-- Name: index_tokens_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tokens_on_updater_id ON tokens USING btree (updater_id);


--
-- Name: index_trackings_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trackings_on_created_at ON trackings USING btree (created_at);


--
-- Name: index_trackings_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trackings_on_creator_id ON trackings USING btree (creator_id);


--
-- Name: index_trackings_on_producer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trackings_on_producer_id ON trackings USING btree (producer_id);


--
-- Name: index_trackings_on_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trackings_on_product_id ON trackings USING btree (product_id);


--
-- Name: index_trackings_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trackings_on_updated_at ON trackings USING btree (updated_at);


--
-- Name: index_trackings_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trackings_on_updater_id ON trackings USING btree (updater_id);


--
-- Name: index_users_on_authentication_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_authentication_token ON users USING btree (authentication_token);


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON users USING btree (confirmation_token);


--
-- Name: index_users_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_created_at ON users USING btree (created_at);


--
-- Name: index_users_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_creator_id ON users USING btree (creator_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_users_on_invitation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_invitation_token ON users USING btree (invitation_token);


--
-- Name: index_users_on_invitations_count; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_invitations_count ON users USING btree (invitations_count);


--
-- Name: index_users_on_invited_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_invited_by_id ON users USING btree (invited_by_id);


--
-- Name: index_users_on_person_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_person_id ON users USING btree (person_id);


--
-- Name: index_users_on_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_provider ON users USING btree (provider);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);


--
-- Name: index_users_on_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_role_id ON users USING btree (role_id);


--
-- Name: index_users_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_team_id ON users USING btree (team_id);


--
-- Name: index_users_on_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_uid ON users USING btree (uid);


--
-- Name: index_users_on_unlock_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_unlock_token ON users USING btree (unlock_token);


--
-- Name: index_users_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_updated_at ON users USING btree (updated_at);


--
-- Name: index_users_on_updater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_updater_id ON users USING btree (updater_id);


--
-- Name: index_versions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_created_at ON versions USING btree (created_at);


--
-- Name: index_versions_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_creator_id ON versions USING btree (creator_id);


--
-- Name: index_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_item_type_and_item_id ON versions USING btree (item_type, item_id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE RULE "_RETURN" AS
    ON SELECT TO product_populations DO INSTEAD  SELECT DISTINCT ON (movements.started_at, movements.product_id) movements.product_id,
    movements.started_at,
    sum(precedings.delta) AS value,
    max(movements.creator_id) AS creator_id,
    max(movements.created_at) AS created_at,
    max(movements.updated_at) AS updated_at,
    max(movements.updater_id) AS updater_id,
    min(movements.id) AS id,
    1 AS lock_version
   FROM (product_movements movements
     LEFT JOIN ( SELECT sum(product_movements.delta) AS delta,
            product_movements.product_id,
            product_movements.started_at
           FROM product_movements
          GROUP BY product_movements.product_id, product_movements.started_at) precedings ON (((movements.started_at >= precedings.started_at) AND (movements.product_id = precedings.product_id))))
  GROUP BY movements.id;


--
-- Name: delete_activities_campaigns; Type: RULE; Schema: public; Owner: -
--

CREATE RULE delete_activities_campaigns AS
    ON DELETE TO activities_campaigns DO INSTEAD NOTHING;


--
-- Name: delete_activities_interventions; Type: RULE; Schema: public; Owner: -
--

CREATE RULE delete_activities_interventions AS
    ON DELETE TO activities_interventions DO INSTEAD NOTHING;


--
-- Name: delete_activity_productions_campaigns; Type: RULE; Schema: public; Owner: -
--

CREATE RULE delete_activity_productions_campaigns AS
    ON DELETE TO activity_productions_campaigns DO INSTEAD NOTHING;


--
-- Name: delete_activity_productions_interventions; Type: RULE; Schema: public; Owner: -
--

CREATE RULE delete_activity_productions_interventions AS
    ON DELETE TO activity_productions_interventions DO INSTEAD NOTHING;


--
-- Name: delete_campaigns_interventions; Type: RULE; Schema: public; Owner: -
--

CREATE RULE delete_campaigns_interventions AS
    ON DELETE TO campaigns_interventions DO INSTEAD NOTHING;


--
-- Name: delete_product_populations; Type: RULE; Schema: public; Owner: -
--

CREATE RULE delete_product_populations AS
    ON DELETE TO product_populations DO INSTEAD NOTHING;


--
-- Name: compute_partial_lettering_status_insert_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER compute_partial_lettering_status_insert_delete AFTER INSERT OR DELETE ON journal_entry_items FOR EACH ROW EXECUTE PROCEDURE compute_partial_lettering();


--
-- Name: compute_partial_lettering_status_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER compute_partial_lettering_status_update AFTER UPDATE OF credit, debit, account_id, letter ON journal_entry_items FOR EACH ROW WHEN ((((COALESCE(old.letter, ''::character varying))::text <> (COALESCE(new.letter, ''::character varying))::text) OR (old.account_id <> new.account_id) OR (old.credit <> new.credit) OR (old.debit <> new.debit))) EXECUTE PROCEDURE compute_partial_lettering();


--
-- Name: outgoing_payment_list_cache; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER outgoing_payment_list_cache AFTER INSERT OR DELETE OR UPDATE OF list_id, amount ON outgoing_payments FOR EACH ROW EXECUTE PROCEDURE compute_outgoing_payment_list_cache();


--
-- Name: synchronize_jei_with_entry; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER synchronize_jei_with_entry AFTER INSERT OR UPDATE ON journal_entry_items FOR EACH ROW EXECUTE PROCEDURE synchronize_jei_with_entry('jei');


--
-- Name: synchronize_jeis_of_entry; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER synchronize_jeis_of_entry AFTER INSERT OR UPDATE ON journal_entries FOR EACH ROW EXECUTE PROCEDURE synchronize_jei_with_entry('entry');


--
-- Name: fk_rails_00f6e5b7b4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tasks
    ADD CONSTRAINT fk_rails_00f6e5b7b4 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_014abe90d4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cap_land_parcels
    ADD CONSTRAINT fk_rails_014abe90d4 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_0150e5fc85; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_categories
    ADD CONSTRAINT fk_rails_0150e5fc85 FOREIGN KEY (charge_account_id) REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_016126bbd5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY journal_entries
    ADD CONSTRAINT fk_rails_016126bbd5 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_016c5e233e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY document_templates
    ADD CONSTRAINT fk_rails_016c5e233e FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_017ab798be; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_distributions
    ADD CONSTRAINT fk_rails_017ab798be FOREIGN KEY (main_activity_id) REFERENCES activities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_01c09fc3cf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY outgoing_payment_modes
    ADD CONSTRAINT fk_rails_01c09fc3cf FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_02a06f182e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY prescriptions
    ADD CONSTRAINT fk_rails_02a06f182e FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_03176cbeef; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY purchase_items
    ADD CONSTRAINT fk_rails_03176cbeef FOREIGN KEY (team_id) REFERENCES teams(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_0337fef8bc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY products
    ADD CONSTRAINT fk_rails_0337fef8bc FOREIGN KEY (initial_container_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_03660d3acc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY manure_management_plan_zones
    ADD CONSTRAINT fk_rails_03660d3acc FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_03d706b853; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY parcels
    ADD CONSTRAINT fk_rails_03d706b853 FOREIGN KEY (address_id) REFERENCES entity_addresses(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_04fd2943ce; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cap_statements
    ADD CONSTRAINT fk_rails_04fd2943ce FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_054d4c650a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY teams
    ADD CONSTRAINT fk_rails_054d4c650a FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_05a0fe3602; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY dashboards
    ADD CONSTRAINT fk_rails_05a0fe3602 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_061293054f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY purchase_items
    ADD CONSTRAINT fk_rails_061293054f FOREIGN KEY (tax_id) REFERENCES taxes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_062a77958b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY loans
    ADD CONSTRAINT fk_rails_062a77958b FOREIGN KEY (insurance_account_id) REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_069e9acf9f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sale_items
    ADD CONSTRAINT fk_rails_069e9acf9f FOREIGN KEY (account_id) REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_069f9114d7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY parcels
    ADD CONSTRAINT fk_rails_069f9114d7 FOREIGN KEY (storage_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_07a90c7250; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_memberships
    ADD CONSTRAINT fk_rails_07a90c7250 FOREIGN KEY (group_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_07ab6c8b5b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY journal_entry_items
    ADD CONSTRAINT fk_rails_07ab6c8b5b FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_07b5213437; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gaps
    ADD CONSTRAINT fk_rails_07b5213437 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_0810aa229a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY interventions
    ADD CONSTRAINT fk_rails_0810aa229a FOREIGN KEY (issue_id) REFERENCES issues(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_088dda4f12; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bank_statements
    ADD CONSTRAINT fk_rails_088dda4f12 FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_095663aed2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY incoming_payments
    ADD CONSTRAINT fk_rails_095663aed2 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_0970270702; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_movements
    ADD CONSTRAINT fk_rails_0970270702 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_09d092bb77; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sequences
    ADD CONSTRAINT fk_rails_09d092bb77 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_0a71e763ae; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY preferences
    ADD CONSTRAINT fk_rails_0a71e763ae FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_0aa83e541e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contracts
    ADD CONSTRAINT fk_rails_0aa83e541e FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_0ce09753e6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY alert_phases
    ADD CONSTRAINT fk_rails_0ce09753e6 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_0d7dbac6ba; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY intervention_parameters
    ADD CONSTRAINT fk_rails_0d7dbac6ba FOREIGN KEY (intervention_id) REFERENCES interventions(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_0dccdbdfad; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_natures
    ADD CONSTRAINT fk_rails_0dccdbdfad FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_0e05d16f09; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sensors
    ADD CONSTRAINT fk_rails_0e05d16f09 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_0e164d8565; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY analyses
    ADD CONSTRAINT fk_rails_0e164d8565 FOREIGN KEY (sampler_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_0e263ab4e2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY outgoing_payments
    ADD CONSTRAINT fk_rails_0e263ab4e2 FOREIGN KEY (responsible_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_0e39758b4c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY intervention_parameters
    ADD CONSTRAINT fk_rails_0e39758b4c FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_0f9172c3c4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cash_transfers
    ADD CONSTRAINT fk_rails_0f9172c3c4 FOREIGN KEY (reception_journal_entry_id) REFERENCES journal_entries(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_0f9f697d40; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY issues
    ADD CONSTRAINT fk_rails_0f9f697d40 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_0fe90aeb1d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_variant_readings
    ADD CONSTRAINT fk_rails_0fe90aeb1d FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_104f78b99c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY plant_density_abaci
    ADD CONSTRAINT fk_rails_104f78b99c FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_10e09a9740; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contract_items
    ADD CONSTRAINT fk_rails_10e09a9740 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_1209c4e2b8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tax_declaration_item_parts
    ADD CONSTRAINT fk_rails_1209c4e2b8 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_12457329e7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_balances
    ADD CONSTRAINT fk_rails_12457329e7 FOREIGN KEY (financial_year_id) REFERENCES financial_years(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_12a7a5513a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_links
    ADD CONSTRAINT fk_rails_12a7a5513a FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_12b713bf34; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inventories
    ADD CONSTRAINT fk_rails_12b713bf34 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_134eaa866e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_localizations
    ADD CONSTRAINT fk_rails_134eaa866e FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_137689e04b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_budget_items
    ADD CONSTRAINT fk_rails_137689e04b FOREIGN KEY (variant_id) REFERENCES product_nature_variants(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_138ee77f1e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_budget_items
    ADD CONSTRAINT fk_rails_138ee77f1e FOREIGN KEY (activity_budget_id) REFERENCES activity_budgets(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_139a1e9f6f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY outgoing_payment_lists
    ADD CONSTRAINT fk_rails_139a1e9f6f FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_142e9deed5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY incoming_payment_modes
    ADD CONSTRAINT fk_rails_142e9deed5 FOREIGN KEY (cash_id) REFERENCES cashes(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_14425ca67e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sales
    ADD CONSTRAINT fk_rails_14425ca67e FOREIGN KEY (responsible_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_1455a8f189; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY fixed_assets
    ADD CONSTRAINT fk_rails_1455a8f189 FOREIGN KEY (scrapped_journal_entry_id) REFERENCES journal_entries(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_15244a5c09; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY outgoing_payments
    ADD CONSTRAINT fk_rails_15244a5c09 FOREIGN KEY (mode_id) REFERENCES outgoing_payment_modes(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_15a2e294c8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY purchases
    ADD CONSTRAINT fk_rails_15a2e294c8 FOREIGN KEY (quantity_gap_on_invoice_journal_entry_id) REFERENCES journal_entries(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_15c34a9137; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY events
    ADD CONSTRAINT fk_rails_15c34a9137 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_168094a0c1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tasks
    ADD CONSTRAINT fk_rails_168094a0c1 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_1697f59d9c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY call_messages
    ADD CONSTRAINT fk_rails_1697f59d9c FOREIGN KEY (call_id) REFERENCES calls(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_17bf9c0601; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY fixed_assets
    ADD CONSTRAINT fk_rails_17bf9c0601 FOREIGN KEY (sold_journal_entry_id) REFERENCES journal_entries(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_18758b2fef; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY attachments
    ADD CONSTRAINT fk_rails_18758b2fef FOREIGN KEY (document_id) REFERENCES documents(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_188c23c1c8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY purchases
    ADD CONSTRAINT fk_rails_188c23c1c8 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_18df73d758; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tokens
    ADD CONSTRAINT fk_rails_18df73d758 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_190dd3dd57; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_ownerships
    ADD CONSTRAINT fk_rails_190dd3dd57 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_1a1d1e5342; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_movements
    ADD CONSTRAINT fk_rails_1a1d1e5342 FOREIGN KEY (product_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_1ab612d163; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY entity_links
    ADD CONSTRAINT fk_rails_1ab612d163 FOREIGN KEY (entity_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_1ad43ba3eb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY loans
    ADD CONSTRAINT fk_rails_1ad43ba3eb FOREIGN KEY (loan_account_id) REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_1c0cb152f3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sales
    ADD CONSTRAINT fk_rails_1c0cb152f3 FOREIGN KEY (transporter_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_1d7b8128b8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY target_distributions
    ADD CONSTRAINT fk_rails_1d7b8128b8 FOREIGN KEY (activity_id) REFERENCES activities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_1d9f8b1813; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY plant_density_abacus_items
    ADD CONSTRAINT fk_rails_1d9f8b1813 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_1db06fd489; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY incoming_payment_modes
    ADD CONSTRAINT fk_rails_1db06fd489 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_1dd9d357c8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY loans
    ADD CONSTRAINT fk_rails_1dd9d357c8 FOREIGN KEY (cash_id) REFERENCES cashes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_1ddb522279; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_variants
    ADD CONSTRAINT fk_rails_1ddb522279 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_1df14f9496; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cashes
    ADD CONSTRAINT fk_rails_1df14f9496 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_1eed0181ba; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY parcels
    ADD CONSTRAINT fk_rails_1eed0181ba FOREIGN KEY (purchase_id) REFERENCES purchases(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_1f156cee14; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY incoming_payments
    ADD CONSTRAINT fk_rails_1f156cee14 FOREIGN KEY (affair_id) REFERENCES affairs(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_1f8a9dfdaa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contracts
    ADD CONSTRAINT fk_rails_1f8a9dfdaa FOREIGN KEY (supplier_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_1facec8a15; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY outgoing_payments
    ADD CONSTRAINT fk_rails_1facec8a15 FOREIGN KEY (list_id) REFERENCES outgoing_payment_lists(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_1fbfd5a9a6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY entity_addresses
    ADD CONSTRAINT fk_rails_1fbfd5a9a6 FOREIGN KEY (entity_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_1ff9dc5ad7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY guides
    ADD CONSTRAINT fk_rails_1ff9dc5ad7 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_201ae150fe; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY parcel_items
    ADD CONSTRAINT fk_rails_201ae150fe FOREIGN KEY (source_product_movement_id) REFERENCES product_movements(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_203d1a69a7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cultivable_zones
    ADD CONSTRAINT fk_rails_203d1a69a7 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_208dc35386; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY intervention_parameters
    ADD CONSTRAINT fk_rails_208dc35386 FOREIGN KEY (group_id) REFERENCES intervention_parameters(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_20a249d6c2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_memberships
    ADD CONSTRAINT fk_rails_20a249d6c2 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_20edf15064; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cashes
    ADD CONSTRAINT fk_rails_20edf15064 FOREIGN KEY (suspense_account_id) REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_21056dd55c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_variant_components
    ADD CONSTRAINT fk_rails_21056dd55c FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_214eda6f83; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY outgoing_payments
    ADD CONSTRAINT fk_rails_214eda6f83 FOREIGN KEY (payee_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_2164a1af56; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY parcel_items
    ADD CONSTRAINT fk_rails_2164a1af56 FOREIGN KEY (product_localization_id) REFERENCES product_localizations(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_21798568ff; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT fk_rails_21798568ff FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_220dd93ab3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_categories
    ADD CONSTRAINT fk_rails_220dd93ab3 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_224bbae11f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY purchases
    ADD CONSTRAINT fk_rails_224bbae11f FOREIGN KEY (affair_id) REFERENCES affairs(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_22d0a3f0b8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_tactics
    ADD CONSTRAINT fk_rails_22d0a3f0b8 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_23228bc874; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY listing_nodes
    ADD CONSTRAINT fk_rails_23228bc874 FOREIGN KEY (item_listing_node_id) REFERENCES listing_nodes(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_23c8753b6d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_budget_items
    ADD CONSTRAINT fk_rails_23c8753b6d FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_242f8003fd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sales
    ADD CONSTRAINT fk_rails_242f8003fd FOREIGN KEY (address_id) REFERENCES entity_addresses(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_247431dffd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY journal_entry_items
    ADD CONSTRAINT fk_rails_247431dffd FOREIGN KEY (journal_id) REFERENCES journals(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_24840fe287; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY identifiers
    ADD CONSTRAINT fk_rails_24840fe287 FOREIGN KEY (net_service_id) REFERENCES net_services(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_24b2772f2f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_localizations
    ADD CONSTRAINT fk_rails_24b2772f2f FOREIGN KEY (container_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_2522e3153b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_ownerships
    ADD CONSTRAINT fk_rails_2522e3153b FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_2538369aad; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY target_distributions
    ADD CONSTRAINT fk_rails_2538369aad FOREIGN KEY (target_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_254fde6f0b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_readings
    ADD CONSTRAINT fk_rails_254fde6f0b FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_2550c1bd00; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_inspection_calibration_natures
    ADD CONSTRAINT fk_rails_2550c1bd00 FOREIGN KEY (scale_id) REFERENCES activity_inspection_calibration_scales(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_26a9328a42; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY georeadings
    ADD CONSTRAINT fk_rails_26a9328a42 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_27135275f7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY interventions
    ADD CONSTRAINT fk_rails_27135275f7 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_277a19f6f0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY incoming_payments
    ADD CONSTRAINT fk_rails_277a19f6f0 FOREIGN KEY (payer_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_2781a3a6d4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY manure_management_plans
    ADD CONSTRAINT fk_rails_2781a3a6d4 FOREIGN KEY (recommender_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_2794712893; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY products
    ADD CONSTRAINT fk_rails_2794712893 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_2817d767a7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY taxes
    ADD CONSTRAINT fk_rails_2817d767a7 FOREIGN KEY (intracommunity_payable_account_id) REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_28aa047268; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_balances
    ADD CONSTRAINT fk_rails_28aa047268 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_28f999c5b0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_variant_components
    ADD CONSTRAINT fk_rails_28f999c5b0 FOREIGN KEY (part_product_nature_variant_id) REFERENCES product_nature_variants(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_2922de5441; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tokens
    ADD CONSTRAINT fk_rails_2922de5441 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_2aa6b66bff; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_enjoyments
    ADD CONSTRAINT fk_rails_2aa6b66bff FOREIGN KEY (product_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_2aafe38ba4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_productions
    ADD CONSTRAINT fk_rails_2aafe38ba4 FOREIGN KEY (activity_id) REFERENCES activities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_2acaa09f8d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY fixed_asset_depreciations
    ADD CONSTRAINT fk_rails_2acaa09f8d FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_2d1499d0c4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contracts
    ADD CONSTRAINT fk_rails_2d1499d0c4 FOREIGN KEY (responsible_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_2d76b2f6e7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY journal_entry_items
    ADD CONSTRAINT fk_rails_2d76b2f6e7 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_2e16afcdeb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY entities
    ADD CONSTRAINT fk_rails_2e16afcdeb FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_2e4b30bd46; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY fixed_assets
    ADD CONSTRAINT fk_rails_2e4b30bd46 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_2e6a787e29; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_category_taxations
    ADD CONSTRAINT fk_rails_2e6a787e29 FOREIGN KEY (product_nature_category_id) REFERENCES product_nature_categories(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_2e8974028b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bank_statement_items
    ADD CONSTRAINT fk_rails_2e8974028b FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_2edbffd09e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY financial_years
    ADD CONSTRAINT fk_rails_2edbffd09e FOREIGN KEY (last_journal_entry_id) REFERENCES journal_entries(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_2f168d0833; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY crumbs
    ADD CONSTRAINT fk_rails_2f168d0833 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_2f5b46f047; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_categories
    ADD CONSTRAINT fk_rails_2f5b46f047 FOREIGN KEY (fixed_asset_allocation_account_id) REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_2fff36f0ae; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY plant_counting_items
    ADD CONSTRAINT fk_rails_2fff36f0ae FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_300666ff43; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY parcel_items
    ADD CONSTRAINT fk_rails_300666ff43 FOREIGN KEY (product_enjoyment_id) REFERENCES product_enjoyments(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_3060c35076; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY purchase_items
    ADD CONSTRAINT fk_rails_3060c35076 FOREIGN KEY (fixed_asset_id) REFERENCES fixed_assets(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_30da003c0e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sale_items
    ADD CONSTRAINT fk_rails_30da003c0e FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_30ddd4e6d1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY parcel_items
    ADD CONSTRAINT fk_rails_30ddd4e6d1 FOREIGN KEY (product_movement_id) REFERENCES product_movements(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_30f73ea054; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY journal_entries
    ADD CONSTRAINT fk_rails_30f73ea054 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_3143e6e260; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY journal_entry_items
    ADD CONSTRAINT fk_rails_3143e6e260 FOREIGN KEY (variant_id) REFERENCES product_nature_variants(id);


--
-- Name: fk_rails_322e93834f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_inspection_calibration_natures
    ADD CONSTRAINT fk_rails_322e93834f FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_326639b9fb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY products
    ADD CONSTRAINT fk_rails_326639b9fb FOREIGN KEY (person_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_32dd8bbd48; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY intervention_parameter_readings
    ADD CONSTRAINT fk_rails_32dd8bbd48 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_335f485521; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_phases
    ADD CONSTRAINT fk_rails_335f485521 FOREIGN KEY (category_id) REFERENCES product_nature_categories(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_33cd67b619; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY products
    ADD CONSTRAINT fk_rails_33cd67b619 FOREIGN KEY (initial_enjoyer_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_33f673c5e9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY purchases
    ADD CONSTRAINT fk_rails_33f673c5e9 FOREIGN KEY (responsible_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_348f32c41e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gap_items
    ADD CONSTRAINT fk_rails_348f32c41e FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_35511d7621; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deliveries
    ADD CONSTRAINT fk_rails_35511d7621 FOREIGN KEY (responsible_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_359c9194c4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tax_declaration_items
    ADD CONSTRAINT fk_rails_359c9194c4 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_362681c4e1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_seasons
    ADD CONSTRAINT fk_rails_362681c4e1 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_363f17ddbf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY supervision_items
    ADD CONSTRAINT fk_rails_363f17ddbf FOREIGN KEY (sensor_id) REFERENCES sensors(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_378db267f0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_localizations
    ADD CONSTRAINT fk_rails_378db267f0 FOREIGN KEY (intervention_id) REFERENCES interventions(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_37d8197291; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY campaigns
    ADD CONSTRAINT fk_rails_37d8197291 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_37ef9db5e6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gaps
    ADD CONSTRAINT fk_rails_37ef9db5e6 FOREIGN KEY (entity_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_388d269bc6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY listing_nodes
    ADD CONSTRAINT fk_rails_388d269bc6 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_39791a8128; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deposits
    ADD CONSTRAINT fk_rails_39791a8128 FOREIGN KEY (responsible_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_3a0809c3e1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_variant_readings
    ADD CONSTRAINT fk_rails_3a0809c3e1 FOREIGN KEY (variant_id) REFERENCES product_nature_variants(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_3ac2c1e009; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY issues
    ADD CONSTRAINT fk_rails_3ac2c1e009 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_3b1dff3097; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY event_participations
    ADD CONSTRAINT fk_rails_3b1dff3097 FOREIGN KEY (participant_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_3c12ca761d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY incoming_payments
    ADD CONSTRAINT fk_rails_3c12ca761d FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_3c84db0730; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY journal_entry_items
    ADD CONSTRAINT fk_rails_3c84db0730 FOREIGN KEY (team_id) REFERENCES teams(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_3c8cb12820; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sale_items
    ADD CONSTRAINT fk_rails_3c8cb12820 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_3cce269863; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY imports
    ADD CONSTRAINT fk_rails_3cce269863 FOREIGN KEY (importer_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_3cdf4c1b00; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY debt_transfers
    ADD CONSTRAINT fk_rails_3cdf4c1b00 FOREIGN KEY (affair_id) REFERENCES affairs(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_3cfeb1455d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_tactics
    ADD CONSTRAINT fk_rails_3cfeb1455d FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_3d11def0dc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY parcel_items
    ADD CONSTRAINT fk_rails_3d11def0dc FOREIGN KEY (product_ownership_id) REFERENCES product_ownerships(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_3d30cc141e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_categories
    ADD CONSTRAINT fk_rails_3d30cc141e FOREIGN KEY (product_account_id) REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_3d42a5dd2b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inspections
    ADD CONSTRAINT fk_rails_3d42a5dd2b FOREIGN KEY (product_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_3d944e2450; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY loan_repayments
    ADD CONSTRAINT fk_rails_3d944e2450 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_3da2ef6103; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cap_statements
    ADD CONSTRAINT fk_rails_3da2ef6103 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_3e60af7d3b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY calls
    ADD CONSTRAINT fk_rails_3e60af7d3b FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_3fb137af04; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sales
    ADD CONSTRAINT fk_rails_3fb137af04 FOREIGN KEY (client_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_3fe2252496; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY affairs
    ADD CONSTRAINT fk_rails_3fe2252496 FOREIGN KEY (cash_session_id) REFERENCES cash_sessions(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_3fed567190; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY parcels
    ADD CONSTRAINT fk_rails_3fed567190 FOREIGN KEY (undelivered_invoice_journal_entry_id) REFERENCES journal_entries(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_400aef7f4c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_variants
    ADD CONSTRAINT fk_rails_400aef7f4c FOREIGN KEY (stock_account_id) REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_40551d1ee4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cashes
    ADD CONSTRAINT fk_rails_40551d1ee4 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_40bd680b0d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY versions
    ADD CONSTRAINT fk_rails_40bd680b0d FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_40d4de14e6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY journals
    ADD CONSTRAINT fk_rails_40d4de14e6 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_40fdc7354a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY subscription_natures
    ADD CONSTRAINT fk_rails_40fdc7354a FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_410e584f30; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY entities
    ADD CONSTRAINT fk_rails_410e584f30 FOREIGN KEY (proposer_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_41134536e7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY products
    ADD CONSTRAINT fk_rails_41134536e7 FOREIGN KEY (default_storage_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_41ba474ceb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY analyses
    ADD CONSTRAINT fk_rails_41ba474ceb FOREIGN KEY (product_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_424d4186e7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_inspection_calibration_scales
    ADD CONSTRAINT fk_rails_424d4186e7 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_4250515aed; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY regularizations
    ADD CONSTRAINT fk_rails_4250515aed FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_431666418f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bank_statement_items
    ADD CONSTRAINT fk_rails_431666418f FOREIGN KEY (bank_statement_id) REFERENCES bank_statements(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_43464d525c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY purchase_items
    ADD CONSTRAINT fk_rails_43464d525c FOREIGN KEY (activity_budget_id) REFERENCES activity_budgets(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_434e943648; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY crumbs
    ADD CONSTRAINT fk_rails_434e943648 FOREIGN KEY (intervention_participation_id) REFERENCES intervention_participations(id);


--
-- Name: fk_rails_43961acabc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY guide_analysis_points
    ADD CONSTRAINT fk_rails_43961acabc FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_4400e36150; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY taxes
    ADD CONSTRAINT fk_rails_4400e36150 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_448f48d42c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_enjoyments
    ADD CONSTRAINT fk_rails_448f48d42c FOREIGN KEY (enjoyer_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_44aac32699; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_productions
    ADD CONSTRAINT fk_rails_44aac32699 FOREIGN KEY (season_id) REFERENCES activity_seasons(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_44d926fde4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY calls
    ADD CONSTRAINT fk_rails_44d926fde4 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_4593a151c9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY purchases
    ADD CONSTRAINT fk_rails_4593a151c9 FOREIGN KEY (contract_id) REFERENCES contracts(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_45943b239d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY purchase_natures
    ADD CONSTRAINT fk_rails_45943b239d FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_45abbf3721; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY catalogs
    ADD CONSTRAINT fk_rails_45abbf3721 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_45de687588; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY affairs
    ADD CONSTRAINT fk_rails_45de687588 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_45e790dee1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY analyses
    ADD CONSTRAINT fk_rails_45e790dee1 FOREIGN KEY (analyser_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_4636191fcb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY purchase_natures
    ADD CONSTRAINT fk_rails_4636191fcb FOREIGN KEY (journal_id) REFERENCES journals(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_46b154cac6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY event_participations
    ADD CONSTRAINT fk_rails_46b154cac6 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_46e683c1c0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY incoming_payment_modes
    ADD CONSTRAINT fk_rails_46e683c1c0 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_46ef37a26f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tax_declaration_items
    ADD CONSTRAINT fk_rails_46ef37a26f FOREIGN KEY (tax_declaration_id) REFERENCES tax_declarations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_48c90f8c33; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY manure_management_plan_zones
    ADD CONSTRAINT fk_rails_48c90f8c33 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_49f670768f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deposits
    ADD CONSTRAINT fk_rails_49f670768f FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_4a6c8e1110; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sale_natures
    ADD CONSTRAINT fk_rails_4a6c8e1110 FOREIGN KEY (journal_id) REFERENCES journals(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_4aac06c209; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY incoming_payments
    ADD CONSTRAINT fk_rails_4aac06c209 FOREIGN KEY (mode_id) REFERENCES incoming_payment_modes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_4aea6afa11; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT fk_rails_4aea6afa11 FOREIGN KEY (recipient_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_4b5a861f47; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY entity_links
    ADD CONSTRAINT fk_rails_4b5a861f47 FOREIGN KEY (linked_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_4be5963038; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cap_land_parcels
    ADD CONSTRAINT fk_rails_4be5963038 FOREIGN KEY (cap_islet_id) REFERENCES cap_islets(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_4c2629dc35; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sales
    ADD CONSTRAINT fk_rails_4c2629dc35 FOREIGN KEY (credited_sale_id) REFERENCES sales(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_4c3553ae69; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY parcels
    ADD CONSTRAINT fk_rails_4c3553ae69 FOREIGN KEY (sender_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_4c3e78700c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_field_choices
    ADD CONSTRAINT fk_rails_4c3e78700c FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_4c9ef7fd24; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY parcel_items
    ADD CONSTRAINT fk_rails_4c9ef7fd24 FOREIGN KEY (variant_id) REFERENCES product_nature_variants(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_4ca49c94ec; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cashes
    ADD CONSTRAINT fk_rails_4ca49c94ec FOREIGN KEY (owner_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_4d03162e54; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bank_statements
    ADD CONSTRAINT fk_rails_4d03162e54 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_4dd2cfe911; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY intervention_parameter_readings
    ADD CONSTRAINT fk_rails_4dd2cfe911 FOREIGN KEY (parameter_id) REFERENCES intervention_parameters(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_4ea5b8b05e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY products
    ADD CONSTRAINT fk_rails_4ea5b8b05e FOREIGN KEY (variant_id) REFERENCES product_nature_variants(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_4eaedbf7c6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_variants
    ADD CONSTRAINT fk_rails_4eaedbf7c6 FOREIGN KEY (nature_id) REFERENCES product_natures(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_4f3833f3ac; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY catalog_items
    ADD CONSTRAINT fk_rails_4f3833f3ac FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_4ff360e94e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_links
    ADD CONSTRAINT fk_rails_4ff360e94e FOREIGN KEY (intervention_id) REFERENCES interventions(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_5059b3f008; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sale_items
    ADD CONSTRAINT fk_rails_5059b3f008 FOREIGN KEY (tax_id) REFERENCES taxes(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_5076105ec1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY journal_entries
    ADD CONSTRAINT fk_rails_5076105ec1 FOREIGN KEY (financial_year_exchange_id) REFERENCES financial_year_exchanges(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_5098025622; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY incoming_payment_modes
    ADD CONSTRAINT fk_rails_5098025622 FOREIGN KEY (depositables_account_id) REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_50befc8562; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_productions
    ADD CONSTRAINT fk_rails_50befc8562 FOREIGN KEY (campaign_id) REFERENCES campaigns(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_518fedc933; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY crumbs
    ADD CONSTRAINT fk_rails_518fedc933 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_523551a98d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deposits
    ADD CONSTRAINT fk_rails_523551a98d FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_525201c121; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY parcels
    ADD CONSTRAINT fk_rails_525201c121 FOREIGN KEY (responsible_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_537959994f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_variant_components
    ADD CONSTRAINT fk_rails_537959994f FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_542f21374a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sensors
    ADD CONSTRAINT fk_rails_542f21374a FOREIGN KEY (host_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_546c6caab4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY event_participations
    ADD CONSTRAINT fk_rails_546c6caab4 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_556d239bea; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_movements
    ADD CONSTRAINT fk_rails_556d239bea FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_557da0b10d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_fields
    ADD CONSTRAINT fk_rails_557da0b10d FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_55ba199c7f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY subscription_natures
    ADD CONSTRAINT fk_rails_55ba199c7f FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_55e243996a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cultivable_zones
    ADD CONSTRAINT fk_rails_55e243996a FOREIGN KEY (owner_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_55f53ebbab; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY documents
    ADD CONSTRAINT fk_rails_55f53ebbab FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_56c5705d5e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tasks
    ADD CONSTRAINT fk_rails_56c5705d5e FOREIGN KEY (sale_opportunity_id) REFERENCES affairs(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_5744d494de; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_memberships
    ADD CONSTRAINT fk_rails_5744d494de FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_581ee777fa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cap_land_parcels
    ADD CONSTRAINT fk_rails_581ee777fa FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_591373f7d5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY call_messages
    ADD CONSTRAINT fk_rails_591373f7d5 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_5a35ce8a3c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_linkages
    ADD CONSTRAINT fk_rails_5a35ce8a3c FOREIGN KEY (carrier_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_5b11b11b0d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY parcels
    ADD CONSTRAINT fk_rails_5b11b11b0d FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_5b99b1a1b2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY parcels
    ADD CONSTRAINT fk_rails_5b99b1a1b2 FOREIGN KEY (transporter_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_5be0cd019c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tax_declaration_item_parts
    ADD CONSTRAINT fk_rails_5be0cd019c FOREIGN KEY (account_id) REFERENCES accounts(id);


--
-- Name: fk_rails_5c5556f807; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY affairs
    ADD CONSTRAINT fk_rails_5c5556f807 FOREIGN KEY (third_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_5d7a8ba713; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inspections
    ADD CONSTRAINT fk_rails_5d7a8ba713 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_5d94a95551; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sale_natures
    ADD CONSTRAINT fk_rails_5d94a95551 FOREIGN KEY (catalog_id) REFERENCES catalogs(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_5e31fb5b82; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY entities
    ADD CONSTRAINT fk_rails_5e31fb5b82 FOREIGN KEY (responsible_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_5e71400e52; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contracts
    ADD CONSTRAINT fk_rails_5e71400e52 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_5ec9de988b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY listing_node_items
    ADD CONSTRAINT fk_rails_5ec9de988b FOREIGN KEY (node_id) REFERENCES listing_nodes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_60713ca369; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY products
    ADD CONSTRAINT fk_rails_60713ca369 FOREIGN KEY (tracking_id) REFERENCES trackings(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_607dd7f27e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_distributions
    ADD CONSTRAINT fk_rails_607dd7f27e FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_6097033ab2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_links
    ADD CONSTRAINT fk_rails_6097033ab2 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_611c37bc8f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_phases
    ADD CONSTRAINT fk_rails_611c37bc8f FOREIGN KEY (nature_id) REFERENCES product_natures(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_61b5d7a3a9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_categories
    ADD CONSTRAINT fk_rails_61b5d7a3a9 FOREIGN KEY (fixed_asset_account_id) REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_61d23da42a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY fixed_assets
    ADD CONSTRAINT fk_rails_61d23da42a FOREIGN KEY (asset_account_id) REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_629d71b0bd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tax_declarations
    ADD CONSTRAINT fk_rails_629d71b0bd FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_62c1aa0bbe; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY purchase_items
    ADD CONSTRAINT fk_rails_62c1aa0bbe FOREIGN KEY (purchase_id) REFERENCES purchases(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_62d4b7a5ff; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cash_sessions
    ADD CONSTRAINT fk_rails_62d4b7a5ff FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_62d92932b7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inventory_items
    ADD CONSTRAINT fk_rails_62d92932b7 FOREIGN KEY (product_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_632a0088d6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY postal_zones
    ADD CONSTRAINT fk_rails_632a0088d6 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_636b786ce8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY guide_analyses
    ADD CONSTRAINT fk_rails_636b786ce8 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_636e8eef20; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY plant_density_abacus_items
    ADD CONSTRAINT fk_rails_636e8eef20 FOREIGN KEY (plant_density_abacus_id) REFERENCES plant_density_abaci(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_63bad1dcb6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inventories
    ADD CONSTRAINT fk_rails_63bad1dcb6 FOREIGN KEY (financial_year_id) REFERENCES financial_years(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_642f17018b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk_rails_642f17018b FOREIGN KEY (role_id) REFERENCES roles(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_64472b9366; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inventories
    ADD CONSTRAINT fk_rails_64472b9366 FOREIGN KEY (responsible_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_64625cb646; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_phases
    ADD CONSTRAINT fk_rails_64625cb646 FOREIGN KEY (intervention_id) REFERENCES interventions(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_64a1cb2780; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cashes
    ADD CONSTRAINT fk_rails_64a1cb2780 FOREIGN KEY (journal_id) REFERENCES journals(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_64cd22b0ee; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contract_items
    ADD CONSTRAINT fk_rails_64cd22b0ee FOREIGN KEY (variant_id) REFERENCES product_nature_variants(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_6511f5959a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_categories
    ADD CONSTRAINT fk_rails_6511f5959a FOREIGN KEY (stock_movement_account_id) REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_6558ea2c9c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY integrations
    ADD CONSTRAINT fk_rails_6558ea2c9c FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_65e7509f5d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY parcels
    ADD CONSTRAINT fk_rails_65e7509f5d FOREIGN KEY (delivery_id) REFERENCES deliveries(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_664f5c7a4f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sale_natures
    ADD CONSTRAINT fk_rails_664f5c7a4f FOREIGN KEY (payment_mode_id) REFERENCES incoming_payment_modes(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_66c0003a0f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY crumbs
    ADD CONSTRAINT fk_rails_66c0003a0f FOREIGN KEY (intervention_parameter_id) REFERENCES intervention_parameters(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_675d471b70; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_linkages
    ADD CONSTRAINT fk_rails_675d471b70 FOREIGN KEY (intervention_id) REFERENCES interventions(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_6840dd6b95; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gaps
    ADD CONSTRAINT fk_rails_6840dd6b95 FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_69339a43d8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inventory_items
    ADD CONSTRAINT fk_rails_69339a43d8 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_699b5b1299; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inventory_items
    ADD CONSTRAINT fk_rails_699b5b1299 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_69b4f722e3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cap_statements
    ADD CONSTRAINT fk_rails_69b4f722e3 FOREIGN KEY (campaign_id) REFERENCES campaigns(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_6a6fe9ea9a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY campaigns
    ADD CONSTRAINT fk_rails_6a6fe9ea9a FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_6a925852c1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_linkages
    ADD CONSTRAINT fk_rails_6a925852c1 FOREIGN KEY (carried_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_6a9fc1a17f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sales
    ADD CONSTRAINT fk_rails_6a9fc1a17f FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_6aa578397c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY dashboards
    ADD CONSTRAINT fk_rails_6aa578397c FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_6b1674aba3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY purchase_items
    ADD CONSTRAINT fk_rails_6b1674aba3 FOREIGN KEY (depreciable_product_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_6c553db953; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_category_taxations
    ADD CONSTRAINT fk_rails_6c553db953 FOREIGN KEY (tax_id) REFERENCES taxes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_6ca49ff545; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY intervention_working_periods
    ADD CONSTRAINT fk_rails_6ca49ff545 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_6cc9da109c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY debt_transfers
    ADD CONSTRAINT fk_rails_6cc9da109c FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_6fcbdd26dc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY products
    ADD CONSTRAINT fk_rails_6fcbdd26dc FOREIGN KEY (initial_movement_id) REFERENCES product_movements(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_703472efb9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY taxes
    ADD CONSTRAINT fk_rails_703472efb9 FOREIGN KEY (deduction_account_id) REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_7043c25edd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY fixed_assets
    ADD CONSTRAINT fk_rails_7043c25edd FOREIGN KEY (allocation_account_id) REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_7072c58d57; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY guide_analyses
    ADD CONSTRAINT fk_rails_7072c58d57 FOREIGN KEY (guide_id) REFERENCES guides(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_70b8f598a0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY outgoing_payments
    ADD CONSTRAINT fk_rails_70b8f598a0 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_710966be99; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY districts
    ADD CONSTRAINT fk_rails_710966be99 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_714e5a35d9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY journal_entries
    ADD CONSTRAINT fk_rails_714e5a35d9 FOREIGN KEY (journal_id) REFERENCES journals(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_71b798326e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY journal_entry_items
    ADD CONSTRAINT fk_rails_71b798326e FOREIGN KEY (tax_declaration_item_id) REFERENCES tax_declaration_items(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_72b04fc498; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY parcels
    ADD CONSTRAINT fk_rails_72b04fc498 FOREIGN KEY (contract_id) REFERENCES contracts(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_734201d412; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cash_sessions
    ADD CONSTRAINT fk_rails_734201d412 FOREIGN KEY (cash_id) REFERENCES cashes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_73738e690f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY supervisions
    ADD CONSTRAINT fk_rails_73738e690f FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_7382f73d03; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY journal_entry_items
    ADD CONSTRAINT fk_rails_7382f73d03 FOREIGN KEY (financial_year_id) REFERENCES financial_years(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_75333ccf01; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_movements
    ADD CONSTRAINT fk_rails_75333ccf01 FOREIGN KEY (intervention_id) REFERENCES interventions(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_75772b1f28; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sequences
    ADD CONSTRAINT fk_rails_75772b1f28 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_75a29a42d4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY documents
    ADD CONSTRAINT fk_rails_75a29a42d4 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_761362dbfb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY identifiers
    ADD CONSTRAINT fk_rails_761362dbfb FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_762630d0fb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY observations
    ADD CONSTRAINT fk_rails_762630d0fb FOREIGN KEY (author_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_763bc367d1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY purchases
    ADD CONSTRAINT fk_rails_763bc367d1 FOREIGN KEY (nature_id) REFERENCES purchase_natures(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_7680a7dd17; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY target_distributions
    ADD CONSTRAINT fk_rails_7680a7dd17 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_76a9bd3581; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sales
    ADD CONSTRAINT fk_rails_76a9bd3581 FOREIGN KEY (delivery_address_id) REFERENCES entity_addresses(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_77e039c42d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY parcel_items
    ADD CONSTRAINT fk_rails_77e039c42d FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_7827a27f9e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY intervention_parameters
    ADD CONSTRAINT fk_rails_7827a27f9e FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_789fa67611; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY observations
    ADD CONSTRAINT fk_rails_789fa67611 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_798f6d11f1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_natures
    ADD CONSTRAINT fk_rails_798f6d11f1 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_7a738ebb13; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_variant_components
    ADD CONSTRAINT fk_rails_7a738ebb13 FOREIGN KEY (parent_id) REFERENCES product_nature_variant_components(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_7a9749733c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY alert_phases
    ADD CONSTRAINT fk_rails_7a9749733c FOREIGN KEY (alert_id) REFERENCES alerts(id);


--
-- Name: fk_rails_7a9ac69852; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY loans
    ADD CONSTRAINT fk_rails_7a9ac69852 FOREIGN KEY (interest_account_id) REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_7af37c85ac; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bank_statement_items
    ADD CONSTRAINT fk_rails_7af37c85ac FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_7b6be7d061; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY plant_countings
    ADD CONSTRAINT fk_rails_7b6be7d061 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_7bbc7b4cef; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY catalog_items
    ADD CONSTRAINT fk_rails_7bbc7b4cef FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_7c50273054; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY net_services
    ADD CONSTRAINT fk_rails_7c50273054 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_7c7753d434; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY entities
    ADD CONSTRAINT fk_rails_7c7753d434 FOREIGN KEY (supplier_account_id) REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_7cbe6a011c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activities
    ADD CONSTRAINT fk_rails_7cbe6a011c FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_7cc0ce7951; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sale_items
    ADD CONSTRAINT fk_rails_7cc0ce7951 FOREIGN KEY (variant_id) REFERENCES product_nature_variants(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_7d0c13ae80; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gap_items
    ADD CONSTRAINT fk_rails_7d0c13ae80 FOREIGN KEY (tax_id) REFERENCES taxes(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_7dc39f42eb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk_rails_7dc39f42eb FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_7e4c597597; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY call_messages
    ADD CONSTRAINT fk_rails_7e4c597597 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_7ecf94116f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY teams
    ADD CONSTRAINT fk_rails_7ecf94116f FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_7f031d8645; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inspection_points
    ADD CONSTRAINT fk_rails_7f031d8645 FOREIGN KEY (nature_id) REFERENCES activity_inspection_point_natures(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_7f53e72b34; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY entity_addresses
    ADD CONSTRAINT fk_rails_7f53e72b34 FOREIGN KEY (mail_postal_zone_id) REFERENCES postal_zones(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_8043b7d279; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY regularizations
    ADD CONSTRAINT fk_rails_8043b7d279 FOREIGN KEY (affair_id) REFERENCES affairs(id);


--
-- Name: fk_rails_8121388822; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY observations
    ADD CONSTRAINT fk_rails_8121388822 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_8131f7240d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deposits
    ADD CONSTRAINT fk_rails_8131f7240d FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_81af047794; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY financial_years
    ADD CONSTRAINT fk_rails_81af047794 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_81d009f630; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY alert_phases
    ADD CONSTRAINT fk_rails_81d009f630 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_82ac1ec325; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY manure_management_plans
    ADD CONSTRAINT fk_rails_82ac1ec325 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_8351acf62c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY map_layers
    ADD CONSTRAINT fk_rails_8351acf62c FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_835ea028eb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY fixed_asset_depreciations
    ADD CONSTRAINT fk_rails_835ea028eb FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_83b193d99d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY loan_repayments
    ADD CONSTRAINT fk_rails_83b193d99d FOREIGN KEY (loan_id) REFERENCES loans(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_84e680e296; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY interventions
    ADD CONSTRAINT fk_rails_84e680e296 FOREIGN KEY (request_intervention_id) REFERENCES interventions(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_85183adb8f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_labellings
    ADD CONSTRAINT fk_rails_85183adb8f FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_8619415b3f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY events
    ADD CONSTRAINT fk_rails_8619415b3f FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_86efedd5e8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY manure_management_plan_zones
    ADD CONSTRAINT fk_rails_86efedd5e8 FOREIGN KEY (activity_production_id) REFERENCES activity_productions(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_8736bbc708; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY analysis_items
    ADD CONSTRAINT fk_rails_8736bbc708 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_8767e3fcaf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_seasons
    ADD CONSTRAINT fk_rails_8767e3fcaf FOREIGN KEY (activity_id) REFERENCES activities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_87b5af7ee5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY postal_zones
    ADD CONSTRAINT fk_rails_87b5af7ee5 FOREIGN KEY (district_id) REFERENCES districts(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_87f1c9c7bd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY preferences
    ADD CONSTRAINT fk_rails_87f1c9c7bd FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_88921ec412; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY districts
    ADD CONSTRAINT fk_rails_88921ec412 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_88b1b0398c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY fixed_asset_depreciations
    ADD CONSTRAINT fk_rails_88b1b0398c FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_88ce500f27; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY parcel_items
    ADD CONSTRAINT fk_rails_88ce500f27 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_88d513bf29; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY interventions
    ADD CONSTRAINT fk_rails_88d513bf29 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_88e7174912; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY alerts
    ADD CONSTRAINT fk_rails_88e7174912 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_8903897a2c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY intervention_working_periods
    ADD CONSTRAINT fk_rails_8903897a2c FOREIGN KEY (intervention_id) REFERENCES interventions(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_8948164f25; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY loans
    ADD CONSTRAINT fk_rails_8948164f25 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_89506052d0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY products
    ADD CONSTRAINT fk_rails_89506052d0 FOREIGN KEY (parent_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_8986b00a83; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY attachments
    ADD CONSTRAINT fk_rails_8986b00a83 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_89a4ed37ee; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY analysis_items
    ADD CONSTRAINT fk_rails_89a4ed37ee FOREIGN KEY (analysis_id) REFERENCES analyses(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_8afb65e773; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY intervention_labellings
    ADD CONSTRAINT fk_rails_8afb65e773 FOREIGN KEY (intervention_id) REFERENCES interventions(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_8c3e9ae316; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY intervention_parameter_readings
    ADD CONSTRAINT fk_rails_8c3e9ae316 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_8cfb047f14; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY crumbs
    ADD CONSTRAINT fk_rails_8cfb047f14 FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_8d232610f0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY outgoing_payments
    ADD CONSTRAINT fk_rails_8d232610f0 FOREIGN KEY (cash_id) REFERENCES cashes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_8d7e169b3d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY incoming_payments
    ADD CONSTRAINT fk_rails_8d7e169b3d FOREIGN KEY (responsible_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_8dc5597158; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY incoming_payments
    ADD CONSTRAINT fk_rails_8dc5597158 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_8f242fc2da; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY map_layers
    ADD CONSTRAINT fk_rails_8f242fc2da FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_8f4e5f48f5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY trackings
    ADD CONSTRAINT fk_rails_8f4e5f48f5 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_8f6c3c0890; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY products
    ADD CONSTRAINT fk_rails_8f6c3c0890 FOREIGN KEY (initial_father_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_8f87ec8500; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY supervision_items
    ADD CONSTRAINT fk_rails_8f87ec8500 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_8fc55593ba; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY listing_nodes
    ADD CONSTRAINT fk_rails_8fc55593ba FOREIGN KEY (item_listing_id) REFERENCES listings(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_8fde2f5f19; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_enjoyments
    ADD CONSTRAINT fk_rails_8fde2f5f19 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_9012acf72a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY accounts
    ADD CONSTRAINT fk_rails_9012acf72a FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_9030c3d14f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY prescriptions
    ADD CONSTRAINT fk_rails_9030c3d14f FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_9069600c37; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY incoming_payment_modes
    ADD CONSTRAINT fk_rails_9069600c37 FOREIGN KEY (commission_account_id) REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_9077e8306e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY incoming_payment_modes
    ADD CONSTRAINT fk_rails_9077e8306e FOREIGN KEY (depositables_journal_id) REFERENCES journals(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_90ef6576c4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY entity_links
    ADD CONSTRAINT fk_rails_90ef6576c4 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_90f914c9f6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY intervention_labellings
    ADD CONSTRAINT fk_rails_90f914c9f6 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_91018e4d60; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY document_templates
    ADD CONSTRAINT fk_rails_91018e4d60 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_91e7d02ff1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_distributions
    ADD CONSTRAINT fk_rails_91e7d02ff1 FOREIGN KEY (activity_id) REFERENCES activities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_920d2d0fd3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY analyses
    ADD CONSTRAINT fk_rails_920d2d0fd3 FOREIGN KEY (sensor_id) REFERENCES sensors(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_92682e5545; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY journal_entry_items
    ADD CONSTRAINT fk_rails_92682e5545 FOREIGN KEY (account_id) REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_926dc7cb5c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY parcel_items
    ADD CONSTRAINT fk_rails_926dc7cb5c FOREIGN KEY (analysis_id) REFERENCES analyses(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_929c0d57e2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY outgoing_payment_modes
    ADD CONSTRAINT fk_rails_929c0d57e2 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_930f08f448; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY intervention_participations
    ADD CONSTRAINT fk_rails_930f08f448 FOREIGN KEY (intervention_id) REFERENCES interventions(id);


--
-- Name: fk_rails_934846f787; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY journal_entry_items
    ADD CONSTRAINT fk_rails_934846f787 FOREIGN KEY (activity_budget_id) REFERENCES activity_budgets(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_938eba6751; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY parcels
    ADD CONSTRAINT fk_rails_938eba6751 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_93b19e800d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inventories
    ADD CONSTRAINT fk_rails_93b19e800d FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_94c0f53848; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY net_services
    ADD CONSTRAINT fk_rails_94c0f53848 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_952d21f266; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sales
    ADD CONSTRAINT fk_rails_952d21f266 FOREIGN KEY (quantity_gap_on_invoice_journal_entry_id) REFERENCES journal_entries(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_95928219de; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY listings
    ADD CONSTRAINT fk_rails_95928219de FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_95aaec528d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY delivery_tools
    ADD CONSTRAINT fk_rails_95aaec528d FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_964829961a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY synchronization_operations
    ADD CONSTRAINT fk_rails_964829961a FOREIGN KEY (notification_id) REFERENCES notifications(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_966fdd868b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_labellings
    ADD CONSTRAINT fk_rails_966fdd868b FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_9709540324; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY synchronization_operations
    ADD CONSTRAINT fk_rails_9709540324 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_97b45071f0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cap_islets
    ADD CONSTRAINT fk_rails_97b45071f0 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_98336a2803; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY alerts
    ADD CONSTRAINT fk_rails_98336a2803 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_9926dd709a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_labellings
    ADD CONSTRAINT fk_rails_9926dd709a FOREIGN KEY (product_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_997b34ead2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY manure_management_plan_zones
    ADD CONSTRAINT fk_rails_997b34ead2 FOREIGN KEY (plan_id) REFERENCES manure_management_plans(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_9a2ac8cd4f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY purchase_natures
    ADD CONSTRAINT fk_rails_9a2ac8cd4f FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_9a513f6995; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY entity_addresses
    ADD CONSTRAINT fk_rails_9a513f6995 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_9ac6f7d662; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY integrations
    ADD CONSTRAINT fk_rails_9ac6f7d662 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_9b698982dd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tasks
    ADD CONSTRAINT fk_rails_9b698982dd FOREIGN KEY (executor_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_9b9d36a9a5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_phases
    ADD CONSTRAINT fk_rails_9b9d36a9a5 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_9c0a384816; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY loans
    ADD CONSTRAINT fk_rails_9c0a384816 FOREIGN KEY (bank_guarantee_account_id) REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_9d08cd4dc8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tax_declaration_item_parts
    ADD CONSTRAINT fk_rails_9d08cd4dc8 FOREIGN KEY (tax_declaration_item_id) REFERENCES tax_declaration_items(id);


--
-- Name: fk_rails_9d50c7d5b5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inspection_calibrations
    ADD CONSTRAINT fk_rails_9d50c7d5b5 FOREIGN KEY (inspection_id) REFERENCES inspections(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_9d5b19ba0c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_distributions
    ADD CONSTRAINT fk_rails_9d5b19ba0c FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_9d958cd7e3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cashes
    ADD CONSTRAINT fk_rails_9d958cd7e3 FOREIGN KEY (main_account_id) REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_9e2551606f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sale_natures
    ADD CONSTRAINT fk_rails_9e2551606f FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_9e8f4919fb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY delivery_tools
    ADD CONSTRAINT fk_rails_9e8f4919fb FOREIGN KEY (delivery_id) REFERENCES deliveries(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_9e9409872a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_ownerships
    ADD CONSTRAINT fk_rails_9e9409872a FOREIGN KEY (owner_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_9ec998a7c7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY catalog_items
    ADD CONSTRAINT fk_rails_9ec998a7c7 FOREIGN KEY (catalog_id) REFERENCES catalogs(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_9eef05dc48; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY dashboards
    ADD CONSTRAINT fk_rails_9eef05dc48 FOREIGN KEY (owner_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_9f2172c524; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_budget_items
    ADD CONSTRAINT fk_rails_9f2172c524 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_9f8a555075; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_balances
    ADD CONSTRAINT fk_rails_9f8a555075 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_a0a27ea478; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY plant_countings
    ADD CONSTRAINT fk_rails_a0a27ea478 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_a0f2b95a5c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deliveries
    ADD CONSTRAINT fk_rails_a0f2b95a5c FOREIGN KEY (transporter_purchase_id) REFERENCES purchases(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_a1a464afc1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY plant_countings
    ADD CONSTRAINT fk_rails_a1a464afc1 FOREIGN KEY (plant_density_abacus_id) REFERENCES plant_density_abaci(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_a20d5951d8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY outgoing_payment_modes
    ADD CONSTRAINT fk_rails_a20d5951d8 FOREIGN KEY (cash_id) REFERENCES cashes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_a2563c1567; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sale_items
    ADD CONSTRAINT fk_rails_a2563c1567 FOREIGN KEY (sale_id) REFERENCES sales(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_a31061effa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY alerts
    ADD CONSTRAINT fk_rails_a31061effa FOREIGN KEY (sensor_id) REFERENCES sensors(id);


--
-- Name: fk_rails_a3377f786b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activities
    ADD CONSTRAINT fk_rails_a3377f786b FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_a3644fda81; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_phases
    ADD CONSTRAINT fk_rails_a3644fda81 FOREIGN KEY (variant_id) REFERENCES product_nature_variants(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_a3b8e101cb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY debt_transfers
    ADD CONSTRAINT fk_rails_a3b8e101cb FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_a46c002667; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY synchronization_operations
    ADD CONSTRAINT fk_rails_a46c002667 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_a4c2fc2286; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sales
    ADD CONSTRAINT fk_rails_a4c2fc2286 FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_a4e34a5691; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY listing_node_items
    ADD CONSTRAINT fk_rails_a4e34a5691 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_a54e8f4ede; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY fixed_asset_depreciations
    ADD CONSTRAINT fk_rails_a54e8f4ede FOREIGN KEY (financial_year_id) REFERENCES financial_years(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_a5982f51a1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_memberships
    ADD CONSTRAINT fk_rails_a5982f51a1 FOREIGN KEY (intervention_id) REFERENCES interventions(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_a5daca9b43; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY analysis_items
    ADD CONSTRAINT fk_rails_a5daca9b43 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_a63582aef6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY catalog_items
    ADD CONSTRAINT fk_rails_a63582aef6 FOREIGN KEY (variant_id) REFERENCES product_nature_variants(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_a693cb13d3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bank_statements
    ADD CONSTRAINT fk_rails_a693cb13d3 FOREIGN KEY (cash_id) REFERENCES cashes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_a7d82208a6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inventory_items
    ADD CONSTRAINT fk_rails_a7d82208a6 FOREIGN KEY (product_movement_id) REFERENCES product_movements(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_a7dc109dcc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inventory_items
    ADD CONSTRAINT fk_rails_a7dc109dcc FOREIGN KEY (inventory_id) REFERENCES inventories(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_a83e320232; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tax_declaration_items
    ADD CONSTRAINT fk_rails_a83e320232 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_a8b4bacaf6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY listing_nodes
    ADD CONSTRAINT fk_rails_a8b4bacaf6 FOREIGN KEY (listing_id) REFERENCES listings(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_a8df640e2f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_category_taxations
    ADD CONSTRAINT fk_rails_a8df640e2f FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_a927142781; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY purchases
    ADD CONSTRAINT fk_rails_a927142781 FOREIGN KEY (undelivered_invoice_journal_entry_id) REFERENCES journal_entries(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_a9a5bf49cb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inspection_points
    ADD CONSTRAINT fk_rails_a9a5bf49cb FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_a9b45798a3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY intervention_working_periods
    ADD CONSTRAINT fk_rails_a9b45798a3 FOREIGN KEY (intervention_participation_id) REFERENCES intervention_participations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_aa10c3a347; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY identifiers
    ADD CONSTRAINT fk_rails_aa10c3a347 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_ab0dc98cd1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY catalog_items
    ADD CONSTRAINT fk_rails_ab0dc98cd1 FOREIGN KEY (reference_tax_id) REFERENCES taxes(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_ab70952940; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT fk_rails_ab70952940 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_ab751b897f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inspection_points
    ADD CONSTRAINT fk_rails_ab751b897f FOREIGN KEY (inspection_id) REFERENCES inspections(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_ab7802fc73; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY trackings
    ADD CONSTRAINT fk_rails_ab7802fc73 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_ab81bb3c66; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY guide_analysis_points
    ADD CONSTRAINT fk_rails_ab81bb3c66 FOREIGN KEY (analysis_id) REFERENCES guide_analyses(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_abab34866d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY analysis_items
    ADD CONSTRAINT fk_rails_abab34866d FOREIGN KEY (product_reading_id) REFERENCES product_readings(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_abfd5fdb89; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY products
    ADD CONSTRAINT fk_rails_abfd5fdb89 FOREIGN KEY (initial_mother_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_ac0d7cee29; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sales
    ADD CONSTRAINT fk_rails_ac0d7cee29 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_ac6f38d4ac; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_natures
    ADD CONSTRAINT fk_rails_ac6f38d4ac FOREIGN KEY (category_id) REFERENCES product_nature_categories(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_ac85e67549; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cap_statements
    ADD CONSTRAINT fk_rails_ac85e67549 FOREIGN KEY (declarant_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_ac8ddb6347; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cash_sessions
    ADD CONSTRAINT fk_rails_ac8ddb6347 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_ad3756d355; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY guide_analyses
    ADD CONSTRAINT fk_rails_ad3756d355 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_ad52186b75; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk_rails_ad52186b75 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_adb1cc875c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tax_declaration_item_parts
    ADD CONSTRAINT fk_rails_adb1cc875c FOREIGN KEY (journal_entry_item_id) REFERENCES journal_entry_items(id);


--
-- Name: fk_rails_adcb9942df; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY plant_density_abaci
    ADD CONSTRAINT fk_rails_adcb9942df FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_ade187df46; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inspection_points
    ADD CONSTRAINT fk_rails_ade187df46 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_ae14a5013f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk_rails_ae14a5013f FOREIGN KEY (invited_by_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_ae656485f6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_enjoyments
    ADD CONSTRAINT fk_rails_ae656485f6 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_aec8ee8a4d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY purchases
    ADD CONSTRAINT fk_rails_aec8ee8a4d FOREIGN KEY (delivery_address_id) REFERENCES entity_addresses(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_aeca6fd7f4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_inspection_calibration_scales
    ADD CONSTRAINT fk_rails_aeca6fd7f4 FOREIGN KEY (activity_id) REFERENCES activities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_af2b916821; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY subscriptions
    ADD CONSTRAINT fk_rails_af2b916821 FOREIGN KEY (subscriber_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_af37b1690e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_inspection_point_natures
    ADD CONSTRAINT fk_rails_af37b1690e FOREIGN KEY (activity_id) REFERENCES activities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_af9d0ee56f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cash_transfers
    ADD CONSTRAINT fk_rails_af9d0ee56f FOREIGN KEY (emission_cash_id) REFERENCES cashes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_afbef296b7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_budgets
    ADD CONSTRAINT fk_rails_afbef296b7 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_afd13ecd2d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY products
    ADD CONSTRAINT fk_rails_afd13ecd2d FOREIGN KEY (address_id) REFERENCES entity_addresses(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_afde822745; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tax_declaration_item_parts
    ADD CONSTRAINT fk_rails_afde822745 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_b0114aace7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY plant_counting_items
    ADD CONSTRAINT fk_rails_b0114aace7 FOREIGN KEY (plant_counting_id) REFERENCES plant_countings(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_b0b78337cd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY event_participations
    ADD CONSTRAINT fk_rails_b0b78337cd FOREIGN KEY (event_id) REFERENCES events(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_b0b9eeae24; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY fixed_assets
    ADD CONSTRAINT fk_rails_b0b9eeae24 FOREIGN KEY (expenses_account_id) REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_b0d41baea4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sale_items
    ADD CONSTRAINT fk_rails_b0d41baea4 FOREIGN KEY (credited_item_id) REFERENCES sale_items(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_b16e7ed972; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY teams
    ADD CONSTRAINT fk_rails_b16e7ed972 FOREIGN KEY (parent_id) REFERENCES teams(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_b170b89c1e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY financial_years
    ADD CONSTRAINT fk_rails_b170b89c1e FOREIGN KEY (accountant_id) REFERENCES entities(id);


--
-- Name: fk_rails_b2b9ed1c3c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_inspection_point_natures
    ADD CONSTRAINT fk_rails_b2b9ed1c3c FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_b2bbf87303; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk_rails_b2bbf87303 FOREIGN KEY (team_id) REFERENCES teams(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_b30a4d9a0c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY georeadings
    ADD CONSTRAINT fk_rails_b30a4d9a0c FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_b33d50bba4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tax_declarations
    ADD CONSTRAINT fk_rails_b33d50bba4 FOREIGN KEY (responsible_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_b357460f64; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_category_taxations
    ADD CONSTRAINT fk_rails_b357460f64 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_b3cb6e366b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deliveries
    ADD CONSTRAINT fk_rails_b3cb6e366b FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_b400e49c5b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY catalogs
    ADD CONSTRAINT fk_rails_b400e49c5b FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_b452653626; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY journals
    ADD CONSTRAINT fk_rails_b452653626 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_b579603a4f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY fixed_assets
    ADD CONSTRAINT fk_rails_b579603a4f FOREIGN KEY (product_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_b5bca24e73; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_tactics
    ADD CONSTRAINT fk_rails_b5bca24e73 FOREIGN KEY (activity_id) REFERENCES activities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_b5fc2df3f2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tax_declarations
    ADD CONSTRAINT fk_rails_b5fc2df3f2 FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_b61d539c1e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inspections
    ADD CONSTRAINT fk_rails_b61d539c1e FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_b640153bf4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_productions
    ADD CONSTRAINT fk_rails_b640153bf4 FOREIGN KEY (tactic_id) REFERENCES activity_tactics(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_b64a681866; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY subscriptions
    ADD CONSTRAINT fk_rails_b64a681866 FOREIGN KEY (nature_id) REFERENCES subscription_natures(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_b7a848d6c5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY events
    ADD CONSTRAINT fk_rails_b7a848d6c5 FOREIGN KEY (affair_id) REFERENCES affairs(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_b7d383496c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sale_items
    ADD CONSTRAINT fk_rails_b7d383496c FOREIGN KEY (activity_budget_id) REFERENCES activity_budgets(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_b8dc1a0d87; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY delivery_tools
    ADD CONSTRAINT fk_rails_b8dc1a0d87 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_b963294bf2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_localizations
    ADD CONSTRAINT fk_rails_b963294bf2 FOREIGN KEY (product_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_b977a1531a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY trackings
    ADD CONSTRAINT fk_rails_b977a1531a FOREIGN KEY (producer_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_baa0305f81; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY intervention_working_periods
    ADD CONSTRAINT fk_rails_baa0305f81 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_bbf64ef98c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inventories
    ADD CONSTRAINT fk_rails_bbf64ef98c FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_bc0f113a81; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cash_transfers
    ADD CONSTRAINT fk_rails_bc0f113a81 FOREIGN KEY (emission_journal_entry_id) REFERENCES journal_entries(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_bc70e1376f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY incoming_payments
    ADD CONSTRAINT fk_rails_bc70e1376f FOREIGN KEY (commission_account_id) REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_bcbe95f2a5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY taxes
    ADD CONSTRAINT fk_rails_bcbe95f2a5 FOREIGN KEY (fixed_asset_deduction_account_id) REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_be2c094f63; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contract_items
    ADD CONSTRAINT fk_rails_be2c094f63 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_be4d04c726; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY journals
    ADD CONSTRAINT fk_rails_be4d04c726 FOREIGN KEY (accountant_id) REFERENCES entities(id);


--
-- Name: fk_rails_be7b82f7bc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_variants
    ADD CONSTRAINT fk_rails_be7b82f7bc FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_beed244415; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY listing_nodes
    ADD CONSTRAINT fk_rails_beed244415 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_bf17fb6e33; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY journal_entry_items
    ADD CONSTRAINT fk_rails_bf17fb6e33 FOREIGN KEY (entry_id) REFERENCES journal_entries(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_bf6a9f8864; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY purchases
    ADD CONSTRAINT fk_rails_bf6a9f8864 FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_bfca04d991; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY supervisions
    ADD CONSTRAINT fk_rails_bfca04d991 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_bfedaef179; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY affairs
    ADD CONSTRAINT fk_rails_bfedaef179 FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_c097302cb9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_phases
    ADD CONSTRAINT fk_rails_c097302cb9 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_c0b1e2d9f4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY accounts
    ADD CONSTRAINT fk_rails_c0b1e2d9f4 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_c0d8bf56b7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_linkages
    ADD CONSTRAINT fk_rails_c0d8bf56b7 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_c1a4df2134; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY products
    ADD CONSTRAINT fk_rails_c1a4df2134 FOREIGN KEY (nature_id) REFERENCES product_natures(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_c1fb5b1040; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_readings
    ADD CONSTRAINT fk_rails_c1fb5b1040 FOREIGN KEY (product_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_c26ae9ccd1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gaps
    ADD CONSTRAINT fk_rails_c26ae9ccd1 FOREIGN KEY (affair_id) REFERENCES affairs(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_c26affc045; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY parcel_items
    ADD CONSTRAINT fk_rails_c26affc045 FOREIGN KEY (sale_item_id) REFERENCES sale_items(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_c28ea21f98; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY entity_links
    ADD CONSTRAINT fk_rails_c28ea21f98 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_c36368f019; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY entities
    ADD CONSTRAINT fk_rails_c36368f019 FOREIGN KEY (employee_account_id) REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_c3e0671264; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY listing_nodes
    ADD CONSTRAINT fk_rails_c3e0671264 FOREIGN KEY (parent_id) REFERENCES listing_nodes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_c41b1f2d2f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY interventions
    ADD CONSTRAINT fk_rails_c41b1f2d2f FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_c5b1c295f7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY fixed_asset_depreciations
    ADD CONSTRAINT fk_rails_c5b1c295f7 FOREIGN KEY (fixed_asset_id) REFERENCES fixed_assets(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_c5cdda2c28; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY fixed_assets
    ADD CONSTRAINT fk_rails_c5cdda2c28 FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_c5fec06d9f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cap_islets
    ADD CONSTRAINT fk_rails_c5fec06d9f FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_c606f6d9a6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_readings
    ADD CONSTRAINT fk_rails_c606f6d9a6 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_c7865e52f6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY parcel_items
    ADD CONSTRAINT fk_rails_c7865e52f6 FOREIGN KEY (parcel_id) REFERENCES parcels(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_c7b4c318e9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY labels
    ADD CONSTRAINT fk_rails_c7b4c318e9 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_c7d341d886; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cultivable_zones
    ADD CONSTRAINT fk_rails_c7d341d886 FOREIGN KEY (farmer_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_c8ab6746c4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY plant_counting_items
    ADD CONSTRAINT fk_rails_c8ab6746c4 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_c8efb2ba24; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY analyses
    ADD CONSTRAINT fk_rails_c8efb2ba24 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_c95edcd27c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_budgets
    ADD CONSTRAINT fk_rails_c95edcd27c FOREIGN KEY (campaign_id) REFERENCES campaigns(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_c9792c1723; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_categories
    ADD CONSTRAINT fk_rails_c9792c1723 FOREIGN KEY (stock_account_id) REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_c9ced0a36d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY outgoing_payments
    ADD CONSTRAINT fk_rails_c9ced0a36d FOREIGN KEY (affair_id) REFERENCES affairs(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_ca705bfe3e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_enjoyments
    ADD CONSTRAINT fk_rails_ca705bfe3e FOREIGN KEY (intervention_id) REFERENCES interventions(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_ca9854019b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY regularizations
    ADD CONSTRAINT fk_rails_ca9854019b FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id);


--
-- Name: fk_rails_cad079f0aa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY products
    ADD CONSTRAINT fk_rails_cad079f0aa FOREIGN KEY (initial_owner_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_cb206cf597; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY affairs
    ADD CONSTRAINT fk_rails_cb206cf597 FOREIGN KEY (responsible_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_cb31131f55; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_categories
    ADD CONSTRAINT fk_rails_cb31131f55 FOREIGN KEY (fixed_asset_expenses_account_id) REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_cb5f89a8bf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY outgoing_payments
    ADD CONSTRAINT fk_rails_cb5f89a8bf FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_cb96f325f8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY subscriptions
    ADD CONSTRAINT fk_rails_cb96f325f8 FOREIGN KEY (sale_item_id) REFERENCES sale_items(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_cc06328e61; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY guides
    ADD CONSTRAINT fk_rails_cc06328e61 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_cc58d98a36; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gap_items
    ADD CONSTRAINT fk_rails_cc58d98a36 FOREIGN KEY (gap_id) REFERENCES gaps(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_cc5a693262; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY fixed_assets
    ADD CONSTRAINT fk_rails_cc5a693262 FOREIGN KEY (journal_id) REFERENCES journals(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_cc62845c82; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT fk_rails_cc62845c82 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_cc917f1879; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY debt_transfers
    ADD CONSTRAINT fk_rails_cc917f1879 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_ccb13dba93; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_field_choices
    ADD CONSTRAINT fk_rails_ccb13dba93 FOREIGN KEY (custom_field_id) REFERENCES custom_fields(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_ccfbd2df30; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_inspection_point_natures
    ADD CONSTRAINT fk_rails_ccfbd2df30 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_cd24cbd865; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY purchase_items
    ADD CONSTRAINT fk_rails_cd24cbd865 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_cd664bc9e5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gaps
    ADD CONSTRAINT fk_rails_cd664bc9e5 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_cdd21f96e9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY financial_year_exchanges
    ADD CONSTRAINT fk_rails_cdd21f96e9 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_ce2caa1b49; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY taxes
    ADD CONSTRAINT fk_rails_ce2caa1b49 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_ced7a3672d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY manure_management_plans
    ADD CONSTRAINT fk_rails_ced7a3672d FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_ceff8da867; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY loans
    ADD CONSTRAINT fk_rails_ceff8da867 FOREIGN KEY (lender_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_cf4f610309; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY manure_management_plans
    ADD CONSTRAINT fk_rails_cf4f610309 FOREIGN KEY (campaign_id) REFERENCES campaigns(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_cf62c420d0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_budgets
    ADD CONSTRAINT fk_rails_cf62c420d0 FOREIGN KEY (activity_id) REFERENCES activities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_cf7a077991; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_phases
    ADD CONSTRAINT fk_rails_cf7a077991 FOREIGN KEY (product_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_cfe6558602; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_linkages
    ADD CONSTRAINT fk_rails_cfe6558602 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_d130aefd64; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY purchase_items
    ADD CONSTRAINT fk_rails_d130aefd64 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_d156cd6a41; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY trackings
    ADD CONSTRAINT fk_rails_d156cd6a41 FOREIGN KEY (product_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_d1579746f0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cashes
    ADD CONSTRAINT fk_rails_d1579746f0 FOREIGN KEY (container_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_d17f517176; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sales
    ADD CONSTRAINT fk_rails_d17f517176 FOREIGN KEY (nature_id) REFERENCES sale_natures(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_d27e499c6d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY products
    ADD CONSTRAINT fk_rails_d27e499c6d FOREIGN KEY (member_variant_id) REFERENCES product_nature_variants(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_d2f0f97cca; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY intervention_labellings
    ADD CONSTRAINT fk_rails_d2f0f97cca FOREIGN KEY (label_id) REFERENCES labels(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_d323fe0873; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tax_declaration_items
    ADD CONSTRAINT fk_rails_d323fe0873 FOREIGN KEY (tax_id) REFERENCES taxes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_d39b757070; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_memberships
    ADD CONSTRAINT fk_rails_d39b757070 FOREIGN KEY (member_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_d52e70fbe8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY debt_transfers
    ADD CONSTRAINT fk_rails_d52e70fbe8 FOREIGN KEY (debt_transfer_affair_id) REFERENCES affairs(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_d5a4a29aa1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY interventions
    ADD CONSTRAINT fk_rails_d5a4a29aa1 FOREIGN KEY (prescription_id) REFERENCES prescriptions(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_d65931a8e4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY regularizations
    ADD CONSTRAINT fk_rails_d65931a8e4 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_d6f7814e0e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY analyses
    ADD CONSTRAINT fk_rails_d6f7814e0e FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_d7838b06ec; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_variants
    ADD CONSTRAINT fk_rails_d7838b06ec FOREIGN KEY (stock_movement_account_id) REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_d799cedbe1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY listing_node_items
    ADD CONSTRAINT fk_rails_d799cedbe1 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_d79c9dc8ea; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY subscriptions
    ADD CONSTRAINT fk_rails_d79c9dc8ea FOREIGN KEY (parent_id) REFERENCES subscriptions(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_d96ea1637c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cash_transfers
    ADD CONSTRAINT fk_rails_d96ea1637c FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_d97dabdc3c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY interventions
    ADD CONSTRAINT fk_rails_d97dabdc3c FOREIGN KEY (event_id) REFERENCES events(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_d99acdd0d9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_categories
    ADD CONSTRAINT fk_rails_d99acdd0d9 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_d9c6a35b96; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sale_items
    ADD CONSTRAINT fk_rails_d9c6a35b96 FOREIGN KEY (team_id) REFERENCES teams(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_da0b90db9b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY labels
    ADD CONSTRAINT fk_rails_da0b90db9b FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_da15698b2e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY outgoing_payment_lists
    ADD CONSTRAINT fk_rails_da15698b2e FOREIGN KEY (mode_id) REFERENCES outgoing_payment_modes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_da924f0e62; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sale_natures
    ADD CONSTRAINT fk_rails_da924f0e62 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_daa87f3cf1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY subscriptions
    ADD CONSTRAINT fk_rails_daa87f3cf1 FOREIGN KEY (address_id) REFERENCES entity_addresses(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_daccd84513; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY journal_entry_items
    ADD CONSTRAINT fk_rails_daccd84513 FOREIGN KEY (bank_statement_id) REFERENCES bank_statements(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_dad8733537; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gap_items
    ADD CONSTRAINT fk_rails_dad8733537 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_dbbcd08797; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deliveries
    ADD CONSTRAINT fk_rails_dbbcd08797 FOREIGN KEY (driver_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_dbd399fab4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_labellings
    ADD CONSTRAINT fk_rails_dbd399fab4 FOREIGN KEY (label_id) REFERENCES labels(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_dbd835ff0a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY imports
    ADD CONSTRAINT fk_rails_dbd835ff0a FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_dc4baa5334; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY fixed_assets
    ADD CONSTRAINT fk_rails_dc4baa5334 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_dcb639d6eb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY analyses
    ADD CONSTRAINT fk_rails_dcb639d6eb FOREIGN KEY (host_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_dd65d7922d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY parcel_items
    ADD CONSTRAINT fk_rails_dd65d7922d FOREIGN KEY (product_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_dd6a64e5ac; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY parcels
    ADD CONSTRAINT fk_rails_dd6a64e5ac FOREIGN KEY (recipient_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_de22eb0a5b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_productions
    ADD CONSTRAINT fk_rails_de22eb0a5b FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_de51678599; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cash_transfers
    ADD CONSTRAINT fk_rails_de51678599 FOREIGN KEY (reception_cash_id) REFERENCES cashes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_de82d40cf3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_links
    ADD CONSTRAINT fk_rails_de82d40cf3 FOREIGN KEY (product_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_dfd3a85c11; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contract_items
    ADD CONSTRAINT fk_rails_dfd3a85c11 FOREIGN KEY (contract_id) REFERENCES contracts(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_e190c1cbe3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY purchase_items
    ADD CONSTRAINT fk_rails_e190c1cbe3 FOREIGN KEY (variant_id) REFERENCES product_nature_variants(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_e1ce72bdb3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY purchases
    ADD CONSTRAINT fk_rails_e1ce72bdb3 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_e2618c6595; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY entities
    ADD CONSTRAINT fk_rails_e2618c6595 FOREIGN KEY (client_account_id) REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_e29563a8d1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tax_declarations
    ADD CONSTRAINT fk_rails_e29563a8d1 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_e2990326d4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cash_transfers
    ADD CONSTRAINT fk_rails_e2990326d4 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_e3914ad73f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sales
    ADD CONSTRAINT fk_rails_e3914ad73f FOREIGN KEY (affair_id) REFERENCES affairs(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_e3dc9793dd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_budgets
    ADD CONSTRAINT fk_rails_e3dc9793dd FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_e3e1503bdd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tax_declarations
    ADD CONSTRAINT fk_rails_e3e1503bdd FOREIGN KEY (financial_year_id) REFERENCES financial_years(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_e41a4268d9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY intervention_participations
    ADD CONSTRAINT fk_rails_e41a4268d9 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_e59af3b5a5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_seasons
    ADD CONSTRAINT fk_rails_e59af3b5a5 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_e65232891c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inspection_calibrations
    ADD CONSTRAINT fk_rails_e65232891c FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_e65e8daaae; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_productions
    ADD CONSTRAINT fk_rails_e65e8daaae FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_e71a03ed65; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY target_distributions
    ADD CONSTRAINT fk_rails_e71a03ed65 FOREIGN KEY (activity_production_id) REFERENCES activity_productions(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_e71babc34b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deposits
    ADD CONSTRAINT fk_rails_e71babc34b FOREIGN KEY (cash_id) REFERENCES cashes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_e77d3f8295; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY intervention_labellings
    ADD CONSTRAINT fk_rails_e77d3f8295 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_e7a9800a14; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY outgoing_payment_lists
    ADD CONSTRAINT fk_rails_e7a9800a14 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_e7bc99340e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_variant_readings
    ADD CONSTRAINT fk_rails_e7bc99340e FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_e7cc2188c0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY delivery_tools
    ADD CONSTRAINT fk_rails_e7cc2188c0 FOREIGN KEY (tool_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_e7e2b4d76a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY financial_years
    ADD CONSTRAINT fk_rails_e7e2b4d76a FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_e81467e70f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY intervention_participations
    ADD CONSTRAINT fk_rails_e81467e70f FOREIGN KEY (product_id) REFERENCES products(id);


--
-- Name: fk_rails_e85bcf0527; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY plant_density_abaci
    ADD CONSTRAINT fk_rails_e85bcf0527 FOREIGN KEY (activity_id) REFERENCES activities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_e86614b748; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY products
    ADD CONSTRAINT fk_rails_e86614b748 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_e86d77856a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sensors
    ADD CONSTRAINT fk_rails_e86d77856a FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_e86ef519fd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_inspection_calibration_natures
    ADD CONSTRAINT fk_rails_e86ef519fd FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_e91046c79d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY journal_entries
    ADD CONSTRAINT fk_rails_e91046c79d FOREIGN KEY (financial_year_id) REFERENCES financial_years(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_ea08878b20; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY entity_addresses
    ADD CONSTRAINT fk_rails_ea08878b20 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_ea79769f4e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deliveries
    ADD CONSTRAINT fk_rails_ea79769f4e FOREIGN KEY (transporter_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_eb0115299a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cap_islets
    ADD CONSTRAINT fk_rails_eb0115299a FOREIGN KEY (cap_statement_id) REFERENCES cap_statements(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_eb82c567f6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY parcel_items
    ADD CONSTRAINT fk_rails_eb82c567f6 FOREIGN KEY (source_product_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_eb8abdd849; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cultivable_zones
    ADD CONSTRAINT fk_rails_eb8abdd849 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_eb9f5e479a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_inspection_calibration_scales
    ADD CONSTRAINT fk_rails_eb9f5e479a FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_ebed2fed37; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deposits
    ADD CONSTRAINT fk_rails_ebed2fed37 FOREIGN KEY (mode_id) REFERENCES incoming_payment_modes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_ec80cec384; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY taxes
    ADD CONSTRAINT fk_rails_ec80cec384 FOREIGN KEY (fixed_asset_collect_account_id) REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_ed47671544; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_field_choices
    ADD CONSTRAINT fk_rails_ed47671544 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_ed769d71f9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deliveries
    ADD CONSTRAINT fk_rails_ed769d71f9 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_edc6917863; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY target_distributions
    ADD CONSTRAINT fk_rails_edc6917863 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_ee442881bb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY attachments
    ADD CONSTRAINT fk_rails_ee442881bb FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_ee7f4b868c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY prescriptions
    ADD CONSTRAINT fk_rails_ee7f4b868c FOREIGN KEY (prescriptor_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_ee973f6d0f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY outgoing_payments
    ADD CONSTRAINT fk_rails_ee973f6d0f FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_ef730be79e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inspection_calibrations
    ADD CONSTRAINT fk_rails_ef730be79e FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_eff13fccbc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY preferences
    ADD CONSTRAINT fk_rails_eff13fccbc FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_f0120f1957; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY financial_year_exchanges
    ADD CONSTRAINT fk_rails_f0120f1957 FOREIGN KEY (financial_year_id) REFERENCES financial_years(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_f03743680a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inspection_calibrations
    ADD CONSTRAINT fk_rails_f03743680a FOREIGN KEY (nature_id) REFERENCES activity_inspection_calibration_natures(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_f1020c5cb0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_variants
    ADD CONSTRAINT fk_rails_f1020c5cb0 FOREIGN KEY (category_id) REFERENCES product_nature_categories(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_f115750855; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY parcels
    ADD CONSTRAINT fk_rails_f115750855 FOREIGN KEY (sale_id) REFERENCES sales(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_f18fbd8fb0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY parcels
    ADD CONSTRAINT fk_rails_f18fbd8fb0 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_f26f955b38; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY loan_repayments
    ADD CONSTRAINT fk_rails_f26f955b38 FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_f2846f9b81; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY plant_density_abacus_items
    ADD CONSTRAINT fk_rails_f2846f9b81 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_f2a3cf3b09; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY intervention_participations
    ADD CONSTRAINT fk_rails_f2a3cf3b09 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_f2cfd10eca; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY supervision_items
    ADD CONSTRAINT fk_rails_f2cfd10eca FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_f2ed409ccb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY supervision_items
    ADD CONSTRAINT fk_rails_f2ed409ccb FOREIGN KEY (supervision_id) REFERENCES supervisions(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_f306eb3f32; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_nature_variant_components
    ADD CONSTRAINT fk_rails_f306eb3f32 FOREIGN KEY (product_nature_variant_id) REFERENCES product_nature_variants(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_f3078bcf9c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY incoming_payments
    ADD CONSTRAINT fk_rails_f3078bcf9c FOREIGN KEY (deposit_id) REFERENCES deposits(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_f32346dd3c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY affairs
    ADD CONSTRAINT fk_rails_f32346dd3c FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_f32e0d6ebc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bank_statements
    ADD CONSTRAINT fk_rails_f32e0d6ebc FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_f37c890ca8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_natures
    ADD CONSTRAINT fk_rails_f37c890ca8 FOREIGN KEY (subscription_nature_id) REFERENCES subscription_natures(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_f3923eee15; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY documents
    ADD CONSTRAINT fk_rails_f3923eee15 FOREIGN KEY (template_id) REFERENCES document_templates(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_f3e5781e9c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_balances
    ADD CONSTRAINT fk_rails_f3e5781e9c FOREIGN KEY (account_id) REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_f3e65f91cb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY purchase_items
    ADD CONSTRAINT fk_rails_f3e65f91cb FOREIGN KEY (account_id) REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_f408b4c430; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY subscriptions
    ADD CONSTRAINT fk_rails_f408b4c430 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_f42ac4b14b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY postal_zones
    ADD CONSTRAINT fk_rails_f42ac4b14b FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_f47001aca4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sales
    ADD CONSTRAINT fk_rails_f47001aca4 FOREIGN KEY (invoice_address_id) REFERENCES entity_addresses(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_f4b8509a1c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inspections
    ADD CONSTRAINT fk_rails_f4b8509a1c FOREIGN KEY (activity_id) REFERENCES activities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_f5abb16f3c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY plant_countings
    ADD CONSTRAINT fk_rails_f5abb16f3c FOREIGN KEY (plant_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_f6fc263383; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_ownerships
    ADD CONSTRAINT fk_rails_f6fc263383 FOREIGN KEY (product_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_f7545f5b42; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY listings
    ADD CONSTRAINT fk_rails_f7545f5b42 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_f764c609bb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_productions
    ADD CONSTRAINT fk_rails_f764c609bb FOREIGN KEY (support_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_f7974da644; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_productions
    ADD CONSTRAINT fk_rails_f7974da644 FOREIGN KEY (cultivable_zone_id) REFERENCES cultivable_zones(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_f7b1b0a735; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY journal_entry_items
    ADD CONSTRAINT fk_rails_f7b1b0a735 FOREIGN KEY (tax_id) REFERENCES taxes(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_f7c0078559; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY loans
    ADD CONSTRAINT fk_rails_f7c0078559 FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_f836ce4ee4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY plant_countings
    ADD CONSTRAINT fk_rails_f836ce4ee4 FOREIGN KEY (plant_density_abacus_item_id) REFERENCES plant_density_abacus_items(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_f89fd15b33; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_ownerships
    ADD CONSTRAINT fk_rails_f89fd15b33 FOREIGN KEY (intervention_id) REFERENCES interventions(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_f985373083; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tasks
    ADD CONSTRAINT fk_rails_f985373083 FOREIGN KEY (entity_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_fa0c0b3301; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sensors
    ADD CONSTRAINT fk_rails_fa0c0b3301 FOREIGN KEY (product_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_fa4b71925a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY entities
    ADD CONSTRAINT fk_rails_fa4b71925a FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_fa67535741; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk_rails_fa67535741 FOREIGN KEY (person_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_fa6f4b7fad; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sales
    ADD CONSTRAINT fk_rails_fa6f4b7fad FOREIGN KEY (undelivered_invoice_journal_entry_id) REFERENCES journal_entries(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_fac9226698; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY parcel_items
    ADD CONSTRAINT fk_rails_fac9226698 FOREIGN KEY (purchase_item_id) REFERENCES purchase_items(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_fad88f8a82; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_fields
    ADD CONSTRAINT fk_rails_fad88f8a82 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_fb06c390a8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY taxes
    ADD CONSTRAINT fk_rails_fb06c390a8 FOREIGN KEY (collect_account_id) REFERENCES accounts(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fk_rails_fb915499a4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY products
    ADD CONSTRAINT fk_rails_fb915499a4 FOREIGN KEY (category_id) REFERENCES product_nature_categories(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_fc1df6d1cb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY guide_analysis_points
    ADD CONSTRAINT fk_rails_fc1df6d1cb FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_fc71cb5550; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY subscriptions
    ADD CONSTRAINT fk_rails_fc71cb5550 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_fc7673abb6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_localizations
    ADD CONSTRAINT fk_rails_fc7673abb6 FOREIGN KEY (creator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_fd0b101ea2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY purchases
    ADD CONSTRAINT fk_rails_fd0b101ea2 FOREIGN KEY (supplier_id) REFERENCES entities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_fd2486c15d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT fk_rails_fd2486c15d FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_fd37432253; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY financial_year_exchanges
    ADD CONSTRAINT fk_rails_fd37432253 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_fd381f1532; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY loans
    ADD CONSTRAINT fk_rails_fd381f1532 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_fd3dbd16a6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_links
    ADD CONSTRAINT fk_rails_fd3dbd16a6 FOREIGN KEY (linked_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_rails_fea6a2ffc0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY entities
    ADD CONSTRAINT fk_rails_fea6a2ffc0 FOREIGN KEY (supplier_payment_mode_id) REFERENCES outgoing_payment_modes(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_ff0246bf65; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY loan_repayments
    ADD CONSTRAINT fk_rails_ff0246bf65 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_ff7432b90c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cap_land_parcels
    ADD CONSTRAINT fk_rails_ff7432b90c FOREIGN KEY (support_id) REFERENCES activity_productions(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: fk_rails_ff7aec82d3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY imports
    ADD CONSTRAINT fk_rails_ff7aec82d3 FOREIGN KEY (updater_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

SET search_path TO "public", "postgis";

INSERT INTO schema_migrations (version) VALUES ('20121212122000');

INSERT INTO schema_migrations (version) VALUES ('20140407091156');

INSERT INTO schema_migrations (version) VALUES ('20140415075729');

INSERT INTO schema_migrations (version) VALUES ('20140428085206');

INSERT INTO schema_migrations (version) VALUES ('20140429184401');

INSERT INTO schema_migrations (version) VALUES ('20140507065135');

INSERT INTO schema_migrations (version) VALUES ('20140509084901');

INSERT INTO schema_migrations (version) VALUES ('20140516084901');

INSERT INTO schema_migrations (version) VALUES ('20140528161301');

INSERT INTO schema_migrations (version) VALUES ('20140602145001');

INSERT INTO schema_migrations (version) VALUES ('20140611084801');

INSERT INTO schema_migrations (version) VALUES ('20140717071149');

INSERT INTO schema_migrations (version) VALUES ('20140717154544');

INSERT INTO schema_migrations (version) VALUES ('20140806082909');

INSERT INTO schema_migrations (version) VALUES ('20140813215326');

INSERT INTO schema_migrations (version) VALUES ('20140831135204');

INSERT INTO schema_migrations (version) VALUES ('20140912131515');

INSERT INTO schema_migrations (version) VALUES ('20140918155113');

INSERT INTO schema_migrations (version) VALUES ('20140923153017');

INSERT INTO schema_migrations (version) VALUES ('20140925090818');

INSERT INTO schema_migrations (version) VALUES ('20140925091652');

INSERT INTO schema_migrations (version) VALUES ('20140925220644');

INSERT INTO schema_migrations (version) VALUES ('20141021082742');

INSERT INTO schema_migrations (version) VALUES ('20141120134356');

INSERT INTO schema_migrations (version) VALUES ('20141223102001');

INSERT INTO schema_migrations (version) VALUES ('20141224091401');

INSERT INTO schema_migrations (version) VALUES ('20150109085549');

INSERT INTO schema_migrations (version) VALUES ('20150110223621');

INSERT INTO schema_migrations (version) VALUES ('20150114074551');

INSERT INTO schema_migrations (version) VALUES ('20150114093417');

INSERT INTO schema_migrations (version) VALUES ('20150114144130');

INSERT INTO schema_migrations (version) VALUES ('20150116152730');

INSERT INTO schema_migrations (version) VALUES ('20150206104748');

INSERT INTO schema_migrations (version) VALUES ('20150208093000');

INSERT INTO schema_migrations (version) VALUES ('20150212214601');

INSERT INTO schema_migrations (version) VALUES ('20150215210401');

INSERT INTO schema_migrations (version) VALUES ('20150225112858');

INSERT INTO schema_migrations (version) VALUES ('20150225142832');

INSERT INTO schema_migrations (version) VALUES ('20150313100824');

INSERT INTO schema_migrations (version) VALUES ('20150315115732');

INSERT INTO schema_migrations (version) VALUES ('20150319084703');

INSERT INTO schema_migrations (version) VALUES ('20150418013301');

INSERT INTO schema_migrations (version) VALUES ('20150418225701');

INSERT INTO schema_migrations (version) VALUES ('20150421185537');

INSERT INTO schema_migrations (version) VALUES ('20150423095929');

INSERT INTO schema_migrations (version) VALUES ('20150430095404');

INSERT INTO schema_migrations (version) VALUES ('20150507135310');

INSERT INTO schema_migrations (version) VALUES ('20150518133024');

INSERT INTO schema_migrations (version) VALUES ('20150526101330');

INSERT INTO schema_migrations (version) VALUES ('20150529080607');

INSERT INTO schema_migrations (version) VALUES ('20150530123724');

INSERT INTO schema_migrations (version) VALUES ('20150530123845');

INSERT INTO schema_migrations (version) VALUES ('20150530193726');

INSERT INTO schema_migrations (version) VALUES ('20150605211111');

INSERT INTO schema_migrations (version) VALUES ('20150605225025');

INSERT INTO schema_migrations (version) VALUES ('20150605225026');

INSERT INTO schema_migrations (version) VALUES ('20150606185500');

INSERT INTO schema_migrations (version) VALUES ('20150613084318');

INSERT INTO schema_migrations (version) VALUES ('20150613103941');

INSERT INTO schema_migrations (version) VALUES ('20150624224705');

INSERT INTO schema_migrations (version) VALUES ('20150713153906');

INSERT INTO schema_migrations (version) VALUES ('20150813223705');

INSERT INTO schema_migrations (version) VALUES ('20150813223710');

INSERT INTO schema_migrations (version) VALUES ('20150814095555');

INSERT INTO schema_migrations (version) VALUES ('20150821235105');

INSERT INTO schema_migrations (version) VALUES ('20150822190206');

INSERT INTO schema_migrations (version) VALUES ('20150904144552');

INSERT INTO schema_migrations (version) VALUES ('20150905114009');

INSERT INTO schema_migrations (version) VALUES ('20150907134647');

INSERT INTO schema_migrations (version) VALUES ('20150907163339');

INSERT INTO schema_migrations (version) VALUES ('20150908084329');

INSERT INTO schema_migrations (version) VALUES ('20150908214101');

INSERT INTO schema_migrations (version) VALUES ('20150909120000');

INSERT INTO schema_migrations (version) VALUES ('20150909121646');

INSERT INTO schema_migrations (version) VALUES ('20150909145831');

INSERT INTO schema_migrations (version) VALUES ('20150909161528');

INSERT INTO schema_migrations (version) VALUES ('20150918151337');

INSERT INTO schema_migrations (version) VALUES ('20150919135830');

INSERT INTO schema_migrations (version) VALUES ('20150920094748');

INSERT INTO schema_migrations (version) VALUES ('20150922091317');

INSERT INTO schema_migrations (version) VALUES ('20150923120603');

INSERT INTO schema_migrations (version) VALUES ('20150926110217');

INSERT INTO schema_migrations (version) VALUES ('20151027085923');

INSERT INTO schema_migrations (version) VALUES ('20151107080001');

INSERT INTO schema_migrations (version) VALUES ('20151107135008');

INSERT INTO schema_migrations (version) VALUES ('20151108001401');

INSERT INTO schema_migrations (version) VALUES ('20160112135638');

INSERT INTO schema_migrations (version) VALUES ('20160113212017');

INSERT INTO schema_migrations (version) VALUES ('20160128123152');

INSERT INTO schema_migrations (version) VALUES ('20160202143716');

INSERT INTO schema_migrations (version) VALUES ('20160203104038');

INSERT INTO schema_migrations (version) VALUES ('20160206212413');

INSERT INTO schema_migrations (version) VALUES ('20160207143859');

INSERT INTO schema_migrations (version) VALUES ('20160207171458');

INSERT INTO schema_migrations (version) VALUES ('20160209070523');

INSERT INTO schema_migrations (version) VALUES ('20160210083955');

INSERT INTO schema_migrations (version) VALUES ('20160224221201');

INSERT INTO schema_migrations (version) VALUES ('20160323151501');

INSERT INTO schema_migrations (version) VALUES ('20160324082737');

INSERT INTO schema_migrations (version) VALUES ('20160330074338');

INSERT INTO schema_migrations (version) VALUES ('20160331142401');

INSERT INTO schema_migrations (version) VALUES ('20160407141401');

INSERT INTO schema_migrations (version) VALUES ('20160408225701');

INSERT INTO schema_migrations (version) VALUES ('20160420121330');

INSERT INTO schema_migrations (version) VALUES ('20160421141812');

INSERT INTO schema_migrations (version) VALUES ('20160425212301');

INSERT INTO schema_migrations (version) VALUES ('20160427133601');

INSERT INTO schema_migrations (version) VALUES ('20160502125101');

INSERT INTO schema_migrations (version) VALUES ('20160503125501');

INSERT INTO schema_migrations (version) VALUES ('20160512182701');

INSERT INTO schema_migrations (version) VALUES ('20160517070433');

INSERT INTO schema_migrations (version) VALUES ('20160517074938');

INSERT INTO schema_migrations (version) VALUES ('20160518061327');

INSERT INTO schema_migrations (version) VALUES ('20160619102723');

INSERT INTO schema_migrations (version) VALUES ('20160619105233');

INSERT INTO schema_migrations (version) VALUES ('20160619130247');

INSERT INTO schema_migrations (version) VALUES ('20160619155843');

INSERT INTO schema_migrations (version) VALUES ('20160620092810');

INSERT INTO schema_migrations (version) VALUES ('20160621084836');

INSERT INTO schema_migrations (version) VALUES ('20160630091845');

INSERT INTO schema_migrations (version) VALUES ('20160706132116');

INSERT INTO schema_migrations (version) VALUES ('20160712195829');

INSERT INTO schema_migrations (version) VALUES ('20160718095119');

INSERT INTO schema_migrations (version) VALUES ('20160718110335');

INSERT INTO schema_migrations (version) VALUES ('20160718133147');

INSERT INTO schema_migrations (version) VALUES ('20160718150935');

INSERT INTO schema_migrations (version) VALUES ('20160721122006');

INSERT INTO schema_migrations (version) VALUES ('20160725090113');

INSERT INTO schema_migrations (version) VALUES ('20160725182008');

INSERT INTO schema_migrations (version) VALUES ('20160726082348');

INSERT INTO schema_migrations (version) VALUES ('20160726112542');

INSERT INTO schema_migrations (version) VALUES ('20160726181305');

INSERT INTO schema_migrations (version) VALUES ('20160726184811');

INSERT INTO schema_migrations (version) VALUES ('20160727094402');

INSERT INTO schema_migrations (version) VALUES ('20160727201017');

INSERT INTO schema_migrations (version) VALUES ('20160728162003');

INSERT INTO schema_migrations (version) VALUES ('20160728192642');

INSERT INTO schema_migrations (version) VALUES ('20160729080926');

INSERT INTO schema_migrations (version) VALUES ('20160730070743');

INSERT INTO schema_migrations (version) VALUES ('20160817133216');

INSERT INTO schema_migrations (version) VALUES ('20160822225001');

INSERT INTO schema_migrations (version) VALUES ('20160824160125');

INSERT INTO schema_migrations (version) VALUES ('20160825161606');

INSERT INTO schema_migrations (version) VALUES ('20160826125039');

INSERT INTO schema_migrations (version) VALUES ('20160831144010');

INSERT INTO schema_migrations (version) VALUES ('20160906112630');

INSERT INTO schema_migrations (version) VALUES ('20160910200730');

INSERT INTO schema_migrations (version) VALUES ('20160910224234');

INSERT INTO schema_migrations (version) VALUES ('20160911140029');

INSERT INTO schema_migrations (version) VALUES ('20160913133355');

INSERT INTO schema_migrations (version) VALUES ('20160913133407');

INSERT INTO schema_migrations (version) VALUES ('20160915094302');

INSERT INTO schema_migrations (version) VALUES ('20160916220901');

INSERT INTO schema_migrations (version) VALUES ('20160918152301');

INSERT INTO schema_migrations (version) VALUES ('20160919141500');

INSERT INTO schema_migrations (version) VALUES ('20160920083312');

INSERT INTO schema_migrations (version) VALUES ('20160921144623');

INSERT INTO schema_migrations (version) VALUES ('20160921185801');

INSERT INTO schema_migrations (version) VALUES ('20160922161801');

INSERT INTO schema_migrations (version) VALUES ('20160923233801');

INSERT INTO schema_migrations (version) VALUES ('20160927192301');

INSERT INTO schema_migrations (version) VALUES ('20160928121727');

INSERT INTO schema_migrations (version) VALUES ('20160930111020');

INSERT INTO schema_migrations (version) VALUES ('20160930142110');

INSERT INTO schema_migrations (version) VALUES ('20161007151444');

INSERT INTO schema_migrations (version) VALUES ('20161010205901');

INSERT INTO schema_migrations (version) VALUES ('20161012145400');

INSERT INTO schema_migrations (version) VALUES ('20161012145500');

INSERT INTO schema_migrations (version) VALUES ('20161012145600');

INSERT INTO schema_migrations (version) VALUES ('20161012145700');

INSERT INTO schema_migrations (version) VALUES ('20161013023259');

INSERT INTO schema_migrations (version) VALUES ('20161018162500');

INSERT INTO schema_migrations (version) VALUES ('20161019235101');

INSERT INTO schema_migrations (version) VALUES ('20161020191401');

INSERT INTO schema_migrations (version) VALUES ('20161026094401');

INSERT INTO schema_migrations (version) VALUES ('20161026102134');

INSERT INTO schema_migrations (version) VALUES ('20161105212807');

INSERT INTO schema_migrations (version) VALUES ('20161106140253');

INSERT INTO schema_migrations (version) VALUES ('20161107065331');

INSERT INTO schema_migrations (version) VALUES ('20161108140009');

INSERT INTO schema_migrations (version) VALUES ('20161114091835');

INSERT INTO schema_migrations (version) VALUES ('20161114101401');

INSERT INTO schema_migrations (version) VALUES ('20161114112858');

INSERT INTO schema_migrations (version) VALUES ('20161115163443');

INSERT INTO schema_migrations (version) VALUES ('20161118150610');

INSERT INTO schema_migrations (version) VALUES ('20161120153801');

INSERT INTO schema_migrations (version) VALUES ('20161121033801');

INSERT INTO schema_migrations (version) VALUES ('20161121171401');

INSERT INTO schema_migrations (version) VALUES ('20161122155003');

INSERT INTO schema_migrations (version) VALUES ('20161122161646');

INSERT INTO schema_migrations (version) VALUES ('20161122203438');

INSERT INTO schema_migrations (version) VALUES ('20161124093205');

INSERT INTO schema_migrations (version) VALUES ('20161201142213');

INSERT INTO schema_migrations (version) VALUES ('20161205185328');

INSERT INTO schema_migrations (version) VALUES ('20161212183910');

INSERT INTO schema_migrations (version) VALUES ('20161214091911');

INSERT INTO schema_migrations (version) VALUES ('20161216171308');

INSERT INTO schema_migrations (version) VALUES ('20161219092100');

INSERT INTO schema_migrations (version) VALUES ('20161219131051');

INSERT INTO schema_migrations (version) VALUES ('20161231180401');

INSERT INTO schema_migrations (version) VALUES ('20161231200612');

INSERT INTO schema_migrations (version) VALUES ('20161231223002');

INSERT INTO schema_migrations (version) VALUES ('20161231233003');

INSERT INTO schema_migrations (version) VALUES ('20161231234533');

INSERT INTO schema_migrations (version) VALUES ('20170101110136');

INSERT INTO schema_migrations (version) VALUES ('20170110083324');

INSERT INTO schema_migrations (version) VALUES ('20170124133351');

INSERT INTO schema_migrations (version) VALUES ('20170125162958');

INSERT INTO schema_migrations (version) VALUES ('20170203135031');

INSERT INTO schema_migrations (version) VALUES ('20170203181700');

INSERT INTO schema_migrations (version) VALUES ('20170207131958');

INSERT INTO schema_migrations (version) VALUES ('20170208150219');

INSERT INTO schema_migrations (version) VALUES ('20170209151943');

INSERT INTO schema_migrations (version) VALUES ('20170209191230');

INSERT INTO schema_migrations (version) VALUES ('20170209205737');

INSERT INTO schema_migrations (version) VALUES ('20170209212237');

INSERT INTO schema_migrations (version) VALUES ('20170209224614');

INSERT INTO schema_migrations (version) VALUES ('20170209235705');

INSERT INTO schema_migrations (version) VALUES ('20170210132452');

INSERT INTO schema_migrations (version) VALUES ('20170210145316');

INSERT INTO schema_migrations (version) VALUES ('20170210153841');

INSERT INTO schema_migrations (version) VALUES ('20170210174219');

INSERT INTO schema_migrations (version) VALUES ('20170210175448');

INSERT INTO schema_migrations (version) VALUES ('20170214130330');

INSERT INTO schema_migrations (version) VALUES ('20170215155700');

INSERT INTO schema_migrations (version) VALUES ('20170215171400');

INSERT INTO schema_migrations (version) VALUES ('20170220123437');

INSERT INTO schema_migrations (version) VALUES ('20170220164259');

INSERT INTO schema_migrations (version) VALUES ('20170220171804');

INSERT INTO schema_migrations (version) VALUES ('20170220192042');

INSERT INTO schema_migrations (version) VALUES ('20170222100614');

INSERT INTO schema_migrations (version) VALUES ('20170222222222');

INSERT INTO schema_migrations (version) VALUES ('20170227143414');

INSERT INTO schema_migrations (version) VALUES ('20170307103213');

INSERT INTO schema_migrations (version) VALUES ('20170307171442');

INSERT INTO schema_migrations (version) VALUES ('20170312183557');

INSERT INTO schema_migrations (version) VALUES ('20170313090000');

INSERT INTO schema_migrations (version) VALUES ('20170315221501');

INSERT INTO schema_migrations (version) VALUES ('20170316085711');

INSERT INTO schema_migrations (version) VALUES ('20170328125742');

INSERT INTO schema_migrations (version) VALUES ('20170407143621');

INSERT INTO schema_migrations (version) VALUES ('20170408094408');

INSERT INTO schema_migrations (version) VALUES ('20170413073501');

INSERT INTO schema_migrations (version) VALUES ('20170413185630');

INSERT INTO schema_migrations (version) VALUES ('20170413211525');

INSERT INTO schema_migrations (version) VALUES ('20170413222518');

INSERT INTO schema_migrations (version) VALUES ('20170413222519');

INSERT INTO schema_migrations (version) VALUES ('20170413222520');

INSERT INTO schema_migrations (version) VALUES ('20170413222521');

INSERT INTO schema_migrations (version) VALUES ('20170414071529');

INSERT INTO schema_migrations (version) VALUES ('20170414092904');

INSERT INTO schema_migrations (version) VALUES ('20170415141801');

INSERT INTO schema_migrations (version) VALUES ('20170415163650');

INSERT INTO schema_migrations (version) VALUES ('20170416180218');

