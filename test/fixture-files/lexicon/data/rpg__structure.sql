DROP TABLE IF EXISTS registered_crop_zones;

        CREATE UNLOGGED TABLE registered_crop_zones (
          id character varying NOT NULL,
          city_name character varying,
          shape postgis.geometry(Polygon, 4326) NOT NULL,
          centroid postgis.geometry(Point, 4326)
        );

        CREATE INDEX ON registered_crop_zones (id);
        CREATE INDEX registered_crop_zones_shape ON registered_crop_zones USING GIST (shape);
        CREATE INDEX registered_crop_zones_centroid ON registered_crop_zones USING GIST (centroid);
