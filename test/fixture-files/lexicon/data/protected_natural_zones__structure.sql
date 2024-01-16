DROP TABLE IF EXISTS registered_natural_zones;

        CREATE TABLE registered_natural_zones (
          id character varying NOT NULL,
          name character varying,
          nature character varying NOT NULL,            
          shape postgis.geometry(MultiPolygon, 4326) NOT NULL
        );

        CREATE INDEX registered_natural_zones_id ON registered_natural_zones (id);
        CREATE INDEX registered_natural_zones_nature ON registered_natural_zones (nature);
        CREATE INDEX registered_natural_zones_shape ON registered_natural_zones USING GIST (shape);
