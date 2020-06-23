DROP TABLE IF EXISTS registered_postal_zones;

        CREATE TABLE registered_postal_zones (
          id character varying PRIMARY KEY NOT NULL,
          country character varying NOT NULL,
          code character varying NOT NULL,
          city_name character varying NOT NULL,
          postal_code character varying NOT NULL,
          city_delivery_name character varying,
          city_delivery_detail character varying,
          city_centroid postgis.geometry(Point,4326)
      );

        CREATE INDEX registered_postal_zones_country ON registered_postal_zones(country);
        CREATE INDEX registered_postal_zones_city_name ON registered_postal_zones(city_name);
        CREATE INDEX registered_postal_zones_postal_code ON registered_postal_zones(postal_code);
        CREATE INDEX registered_postal_zones_centroid ON registered_postal_zones USING GIST (city_centroid);
