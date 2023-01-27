DROP TABLE IF EXISTS registered_protected_water_zones;

        CREATE TABLE registered_protected_water_zones (
          id character varying NOT NULL,
          administrative_zone character varying,
          creator_name character varying,
          name character varying,
          updated_on date,
          shape postgis.geometry(MultiPolygon, 4326) NOT NULL
        );

        CREATE INDEX registered_protected_water_zones_id ON registered_protected_water_zones (id);
        CREATE INDEX registered_protected_water_zones_shape ON registered_protected_water_zones USING GIST (shape);
