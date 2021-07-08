DROP TABLE IF EXISTS master_translations;

CREATE TABLE master_translations (
  id character varying PRIMARY KEY NOT NULL,
  fra character varying NOT NULL,
  eng character varying NOT NULL
)
