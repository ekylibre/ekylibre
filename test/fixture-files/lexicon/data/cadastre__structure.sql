DROP TABLE IF EXISTS cadastral_land_parcel_zones;
DROP TABLE IF EXISTS registered_building_zones;

        CREATE UNLOGGED TABLE registered_building_zones(
          nature character varying,
          shape postgis.geometry(MultiPolygon, 4326) NOT NULL,
          centroid postgis.geometry(Point, 4326)
        );

        CREATE INDEX registered_building_zones_shape ON registered_building_zones USING GIST (shape);
        CREATE INDEX registered_building_zones_centroid ON registered_building_zones USING GIST (centroid);

        CREATE UNLOGGED TABLE cadastral_land_parcel_zones(
          id character varying PRIMARY KEY NOT NULL,
          section character varying,
          work_number character varying,
          net_surface_area integer,
          shape postgis.geometry(MultiPolygon, 4326) NOT NULL,
          centroid postgis.geometry(Point, 4326)
        );

        CREATE INDEX cadastral_land_parcel_zones_shape ON cadastral_land_parcel_zones USING GIST (shape);
        CREATE INDEX cadastral_land_parcel_zones_centroid ON cadastral_land_parcel_zones USING GIST (centroid);
