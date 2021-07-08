DROP TABLE IF EXISTS master_taxonomy;

CREATE TABLE master_taxonomy (
  reference_name character varying PRIMARY KEY NOT NULL,
  parent character varying,
  taxonomic_rank character varying,
  translation_id character varying NOT NULL
);

CREATE INDEX master_taxonomy_reference_name ON master_taxonomy(reference_name);
