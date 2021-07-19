DROP TABLE IF EXISTS registered_cadastral_parcels;
DROP TABLE IF EXISTS registered_cadastral_buildings;

        CREATE TABLE registered_cadastral_buildings(
          nature character varying,
          shape postgis.geometry(MultiPolygon, 4326) NOT NULL,
          centroid postgis.geometry(Point, 4326)
        );

        CREATE INDEX registered_cadastral_buildings_shape ON registered_cadastral_buildings USING GIST (shape);
        CREATE INDEX registered_cadastral_buildings_centroid ON registered_cadastral_buildings USING GIST (centroid);

        CREATE TABLE registered_cadastral_parcels(
          id character varying PRIMARY KEY NOT NULL,
          section character varying,
          work_number character varying,
          net_surface_area integer,
          shape postgis.geometry(MultiPolygon, 4326) NOT NULL,
          centroid postgis.geometry(Point, 4326)
        );

        CREATE INDEX registered_cadastral_parcels_shape ON registered_cadastral_parcels USING GIST (shape);
        CREATE INDEX registered_cadastral_parcels_centroid ON registered_cadastral_parcels USING GIST (centroid);
