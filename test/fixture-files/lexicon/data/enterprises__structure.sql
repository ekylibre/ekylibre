DROP TABLE IF EXISTS registered_enterprises;

        CREATE TABLE registered_enterprises (
          establishment_number character varying PRIMARY KEY NOT NULL,
          french_main_activity_code character varying NOT NULL,
          name character varying,
          address character varying,
          postal_code character varying,
          city character varying,
          insee_code character varying,
          country character varying,
          centroid postgis.geometry(Point,4326),
          siren character varying
        );

        CREATE INDEX registered_enterprises_french_main_activity_code ON registered_enterprises(french_main_activity_code);
        CREATE INDEX registered_enterprises_name ON registered_enterprises(name);
        CREATE INDEX registered_enterprises_siren ON registered_enterprises(siren);
        CREATE INDEX registered_enterprises_establishment_number ON registered_enterprises(establishment_number);
        CREATE INDEX registered_enterprises_insee_code ON registered_enterprises(insee_code);
        CREATE INDEX registered_enterprises_postal_code ON registered_enterprises(postal_code);
        CREATE INDEX registered_enterprises_city ON registered_enterprises(city);
        CREATE INDEX registered_enterprises_centroid ON registered_enterprises USING GIST (centroid);
