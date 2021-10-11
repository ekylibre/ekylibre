DROP TABLE IF EXISTS master_user_roles;

CREATE TABLE master_user_roles (
  reference_name character varying PRIMARY KEY NOT NULL,
  accesses text[],
  translation_id character varying NOT NULL
)
