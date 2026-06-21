DROP TABLE IF EXISTS master_agricultural_pictures;

        CREATE TABLE master_agricultural_pictures (
          id        SERIAL PRIMARY KEY NOT NULL,
          domain    character varying NOT NULL,
          name      character varying NOT NULL,
          extension character varying NOT NULL,
          picture   BYTEA NOT NULL,
          UNIQUE (domain, name, extension)
        );
        CREATE INDEX master_agricultural_pictures_id ON master_agricultural_pictures(id);
        CREATE INDEX master_agricultural_pictures_domain ON master_agricultural_pictures(domain);
        CREATE INDEX master_agricultural_pictures_domain_name ON master_agricultural_pictures(domain, name);
