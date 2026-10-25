DROP TABLE IF EXISTS master_production_documentations;

        CREATE TABLE master_production_documentations (
          production_reference_name character varying NOT NULL,
          source                    character varying NOT NULL,
          url                       character varying NOT NULL,
          PRIMARY KEY (production_reference_name, source)
        );
        CREATE INDEX master_production_documentations_source
          ON master_production_documentations(source);
