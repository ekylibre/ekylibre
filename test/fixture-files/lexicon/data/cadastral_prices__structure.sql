DROP TABLE IF EXISTS registered_cadastral_prices;

        CREATE TABLE registered_cadastral_prices (
          id SERIAL PRIMARY KEY NOT NULL,
          mutation_id character varying,
          mutation_date DATE,
          mutation_reference character varying,
          mutation_nature character varying,
          cadastral_price numeric(14,2),
          cadastral_parcel_id character varying,
          building_nature character varying,
          building_area integer,
          cadastral_parcel_area integer,
          address character varying,
          postal_code character varying,
          city character varying,
          department character varying,
          centroid postgis.geometry(Point,4326)
        );

        CREATE INDEX registered_cadastral_prices_id ON registered_cadastral_prices(id);
        CREATE INDEX registered_cadastral_prices_cadastral_parcel_id ON registered_cadastral_prices(cadastral_parcel_id);
        CREATE INDEX registered_cadastral_prices_department ON registered_cadastral_prices(department);
        CREATE INDEX registered_cadastral_prices_centroid ON registered_cadastral_prices USING GIST (centroid);
