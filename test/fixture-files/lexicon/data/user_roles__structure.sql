DROP TABLE IF EXISTS user_roles;

        CREATE TABLE user_roles (
          id integer PRIMARY KEY NOT NULL,
          reference_name character varying,
          name jsonb,
          label_fra character varying,
          accesses text[]
        )
