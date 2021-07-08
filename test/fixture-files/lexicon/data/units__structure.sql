DROP TABLE IF EXISTS master_packaging;
DROP TABLE IF EXISTS master_units;
DROP TABLE IF EXISTS master_dimensions;

CREATE TABLE master_dimensions (
  reference_name character varying PRIMARY KEY NOT NULL,
  symbol character varying NOT NULL,
  translation_id character varying NOT NULL
);

CREATE INDEX master_dimensions_reference_name ON master_dimensions(reference_name);

CREATE TABLE master_units (
  reference_name character varying PRIMARY KEY NOT NULL,
  dimension character varying NOT NULL,
  symbol character varying NOT NULL,
  a numeric(25,10),
  d numeric(25,10),
  b numeric(25,10),
  translation_id character varying NOT NULL
);

CREATE INDEX master_units_reference_name ON master_units(reference_name);

CREATE TABLE master_packaging (
  reference_name character varying PRIMARY KEY NOT NULL,
  capacity numeric(25,10) NOT NULL,
  capacity_unit character varying NOT NULL,
  translation_id character varying NOT NULL
);

CREATE INDEX master_packaging_reference_name ON master_packaging(reference_name);
