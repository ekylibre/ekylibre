DROP TABLE IF EXISTS master_vine_varieties;

        CREATE UNLOGGED TABLE master_vine_varieties (
          id character varying NOT NULL,
          specie_name character varying NOT NULL,
          specie_long_name character varying,
          category_name character varying NOT NULL,
          fr_validated character varying,
          utility character varying,
          color character varying,
          customs_code character varying
        );

        CREATE INDEX master_vine_varieties_id ON master_vine_varieties(id);
